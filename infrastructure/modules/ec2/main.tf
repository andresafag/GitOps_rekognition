data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


resource "aws_security_group" "prometheus_sg" {
  name        = "prometheus-yace-sg"
  description = "Allow Prometheus access on port ${var.prometheus_port}"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = var.prometheus_port
    to_port     = var.prometheus_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr != "" ? [var.allowed_cidr] : [data.aws_vpc.default.cidr_block]
    description = "Prometheus UI"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  # allow egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ Name = var.instance_name }, var.tags)
}

resource "aws_instance" "prometheus" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.prometheus_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = var.iam_instance_profile != "" ? var.iam_instance_profile : null
  key_name = var.key_name
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # O "optional" si usas IMDSv1
    http_put_response_hop_limit = 2          # <--- ESTO ES LO CRÍTICO PARA DOCKER
    instance_metadata_tags      = "enabled"
  }
  tags = merge({ Name = var.instance_name }, var.tags)

  user_data = <<-EOF
    #!/bin/bash
    set -ex
    exec > /var/log/user-data.log 2>&1

    # Update and install docker with retries (network may be unavailable in some subnets)
    yum update -y || true
    if ! command -v docker >/dev/null 2>&1; then
      amazon-linux-extras enable docker || true
      yum install -y docker || yum install -y docker-engine || true
    fi

    systemctl enable docker || true
    systemctl start docker || true

    # wait for docker daemon
    for i in 1 2 3 4 5; do
      docker version >/dev/null 2>&1 && break || sleep 5
    done

    usermod -a -G docker ec2-user || true

    mkdir -p /etc/prometheus && mkdir -p /config/confg.yml

    # Prometheus config: Scrape CloudWatch exporter on localhost (works via network=host)
    cat > /etc/prometheus/prometheus.yml <<PROMY
global:
  scrape_interval: 30s
scrape_configs:
      - job_name: 'cloudwatch_exporter'
        static_configs:
          - targets: ['localhost:9106']
PROMY

    # Write Prometheus CloudWatch exporter config with the correct official schema
    mkdir -p /etc/yace
    cat > /etc/yace/config.yml <<YACECFG
region: ${var.aws_region}
metrics:
  - aws_namespace: AWS/Lambda
    aws_metric_name: Invocations
    aws_dimensions: [FunctionName] 
    aws_dimension_select:
      FunctionName: [rekognition-presigned-url-lambda]
    aws_statistics: [Sum, Average]
    period_seconds: 300

  - aws_namespace: AWS/Lambda
    aws_metric_name: Errors
    aws_dimensions: [FunctionName]
    aws_dimension_select:
      FunctionName: [rekognition-consumer-lambda]
    aws_statistics: [Sum, Average]
    period_seconds: 300

  - aws_namespace: AWS/Lambda
    aws_metric_name: Duration
    aws_dimensions: [FunctionName]
    aws_dimension_select:
      FunctionName: [video_proccessing]
    aws_statistics: [Sum, Average]
    period_seconds: 300

  # Las métricas globales se quedan exactamente igual (sin dimensiones)
  - aws_namespace: AWS/Lambda
    aws_metric_name: ConcurrentExecutions
    aws_statistics: [Maximum, Average]
    period_seconds: 300

  - aws_namespace: AWS/Lambda
    aws_metric_name: Throttles
    aws_statistics: [Sum]
    period_seconds: 300
YACECFG

    # Pull images (best-effort)
    docker pull prom/cloudwatch-exporter:latest || true
    docker pull prom/prometheus:latest || true

    # Remove existing containers if present
    docker rm -f yace || true
    docker rm -f prometheus || true

    # Create systemd unit for CloudWatch exporter (Using network=host and proper mapping)
    cat > /etc/systemd/system/yace.service <<'YACESVC'
[Unit]
Description=CloudWatch Exporter (container)
After=docker.service
Requires=docker.service

[Service]
Restart=always
RestartSec=5
ExecStartPre=/usr/bin/docker pull prom/cloudwatch-exporter:latest
ExecStartPre=/usr/bin/docker rm -f yace || true
ExecStart=/usr/bin/docker run --name yace --network=host -v /etc/yace/config.yml:/config/config.yml prom/cloudwatch-exporter:latest
ExecStop=/usr/bin/docker stop -t 10 yace || true
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
YACESVC

    # Create systemd unit for Prometheus (Using network=host)
    cat > /etc/systemd/system/prometheus.service <<'PROMSVC'
[Unit]
Description=Prometheus (container)
After=docker.service
Requires=docker.service

[Service]
Restart=always
RestartSec=5
ExecStartPre=/usr/bin/docker pull prom/prometheus:latest
ExecStartPre=/usr/bin/docker rm -f prometheus || true
ExecStart=/usr/bin/docker run --name prometheus --network=host -v /etc/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus:latest --config.file=/etc/prometheus/prometheus.yml
ExecStop=/usr/bin/docker stop -t 10 prometheus || true
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
PROMSVC

    # Reload systemd, enable and start services
    systemctl daemon-reload || true
    systemctl enable --now yace.service || true
    systemctl enable --now prometheus.service || true
EOF

}

output "instance_id" {
  value = aws_instance.prometheus.id
}

output "instance_public_ip" {
  value = aws_instance.prometheus.public_ip
}

output "security_group_id" {
  value = aws_security_group.prometheus_sg.id
}
