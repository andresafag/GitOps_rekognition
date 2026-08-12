output "aws_default_ip" {
    value = aws_instance.prometheus.public_ip
}