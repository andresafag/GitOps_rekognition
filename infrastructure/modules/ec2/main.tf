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

    mkdir -p /etc/prometheus

    # Prometheus config: scrape YACE exporter on localhost:9116
    cat > /etc/prometheus/prometheus.yml <<'PROMY'
global:
  scrape_interval: 30s
scrape_configs:
  - job_name: 'yace'
    static_configs:
      - targets: ['localhost:9116']
PROMY

    # Pull images (best-effort) and run containers
    docker pull nerdswords/yet-another-cloudwatch-exporter:latest || true
    docker pull prom/prometheus:latest || true

    docker rm -f yace || true
    docker run -d --name yace -p 9116:9116 \
      --restart unless-stopped \
      -e AWS_REGION=${var.aws_region} \
      nerdswords/yet-another-cloudwatch-exporter:latest || true

    docker rm -f prometheus || true
    docker run -d --name prometheus -p ${var.prometheus_port}:9090 \
      --restart unless-stopped \
      -v /etc/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
      prom/prometheus:latest --config.file=/etc/prometheus/prometheus.yml || true
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
