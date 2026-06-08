# 🚀 GitOps_rekognition

![Github repo](https://img.shields.io/badge/github-repo-blue?style=for-the-badge&logo=github)
![Terraform](https://img.shields.io/badge/terraform-purple?style=for-the-badge&logo=terraform)
![AWS](https://img.shields.io/badge/aws-orange?style=for-the-badge&logo=amazonaws)
![Python](https://img.shields.io/badge/python-blue?style=for-the-badge&logo=python)
![JavaScript](https://img.shields.io/badge/javascript-black?style=for-the-badge&logo=javascript)
![CloudFront](https://img.shields.io/badge/cloudfront-232F3E?style=for-the-badge&logo=amazonaws)
![AWS WAF](https://img.shields.io/badge/aws_waf-FF9900?style=for-the-badge&logo=amazonaws)
![GitHub Actions](https://img.shields.io/badge/github_actions-black?style=for-the-badge&logo=githubactions)
![Snyk](https://img.shields.io/badge/snyk-black?style=for-the-badge&logo=snyk)

> **Production-grade serverless AWS platform** built with Terraform, GitOps, and DevSecOps practices to deliver real-time AI-powered image analysis using Amazon Rekognition.

---

# 🧭 Table of Contents

- [🚀 GitOps\_rekognition](#-gitops_rekognition)
- [🧭 Table of Contents](#-table-of-contents)
- [📌 Overview](#-overview)
- [Demo](#demo)
- [🏗️ Architecture](#️-architecture)
  - [🔥 Core AWS Services Used](#-core-aws-services-used)
  - [🧱 High-Level Architecture](#-high-level-architecture)
- [✨ Enterprise Highlights](#-enterprise-highlights)
  - [☁️ Cloud-Native Architecture](#️-cloud-native-architecture)
  - [⚡ Real-Time Processing](#-real-time-processing)
  - [🔐 Production Security](#-production-security)
  - [📈 Observability](#-observability)
  - [🌍 Global Delivery](#-global-delivery)
- [🔐 Security \& DevSecOps](#-security--devsecops)
  - [🛡️ Security Best Practices](#️-security-best-practices)
  - [🔎 Automated Security Scanning](#-automated-security-scanning)
    - [CodeQL Analysis](#codeql-analysis)
    - [Snyk Security Scans](#snyk-security-scans)
      - [🏗️ Infrastructure as Code (IaC)](#️-infrastructure-as-code-iac)
      - [🧠 Static Application Security Testing (SAST)](#-static-application-security-testing-sast)
      - [📦 Dependency Scanning](#-dependency-scanning)
- [📊 Monitoring \& Observability](#-monitoring--observability)
  - [CloudWatch Dashboards](#cloudwatch-dashboards)
  - [🚨 Alerts](#-alerts)
- [📡 API Endpoints](#-api-endpoints)
- [📈 Highlights](#-highlights)
  - [☁️ Cloud Engineering](#️-cloud-engineering)
  - [🏗️ DevOps Engineering](#️-devops-engineering)
  - [🔐 DevSecOps](#-devsecops)
  - [📊 Site Reliability Engineering (SRE)](#-site-reliability-engineering-sre)
  - [📦 Prometheus Integration (Observability for a DevOps Portfolio)](#-prometheus-integration-observability-for-a-devops-portfolio)
    - [Goals](#goals)
    - [Quick local access](#quick-local-access)
    - [Cloud deployment options](#cloud-deployment-options)
    - [Scraping strategy for serverless (Lambda + API Gateway)](#scraping-strategy-for-serverless-lambda--api-gateway)
    - [Example `prometheus.yml` (scrape `cloudwatch_exporter`)](#example-prometheusyml-scrape-cloudwatch_exporter)
    - [Alerting — example PromQL alerts (Prometheus Alertmanager rules)](#alerting--example-promql-alerts-prometheus-alertmanager-rules)
    - [Dashboard suggestions (panels \& PromQL)](#dashboard-suggestions-panels--promql)
    - [Terraform: minimal example for AWS Managed Service for Prometheus (AMP)](#terraform-minimal-example-for-aws-managed-service-for-prometheus-amp)
    - [Security \& cost considerations](#security--cost-considerations)
    - [Verification \& demonstration steps (what to include in portfolio)](#verification--demonstration-steps-what-to-include-in-portfolio)
    - [What to show in your DevOps portfolio entry](#what-to-show-in-your-devops-portfolio-entry)
  - [⚡ Backend Engineering](#-backend-engineering)
  - [☁️ Cloud Engineering](#️-cloud-engineering-1)
  - [🏗️ DevOps Engineering](#️-devops-engineering-1)
  - [🔐 DevSecOps](#-devsecops-1)
  - [📊 Site Reliability Engineering (SRE)](#-site-reliability-engineering-sre-1)
  - [⚡ Backend Engineering](#-backend-engineering-1)
  - [📜 License](#-license)

---

# 📌 Overview

**GitOps_rekognition** is a cloud-native, event-driven AWS platform that demonstrates modern:

- ☁️ DevOps Engineering
- 🔐 DevSecOps Automation
- 🏗️ Infrastructure as Code (IaC)
- ⚡ Serverless Architecture
- 📡 Real-Time Communication

The platform allows users to upload images and receive **real-time AI-powered image analysis** using **Amazon Rekognition**.

The infrastructure is fully provisioned using **Terraform** and follows production-grade AWS architecture patterns.

---

# Demo
[rekoglabelify.com](http://rekoglabelify.com)

---

# 🏗️ Architecture

## 🔥 Core AWS Services Used

- Amazon API Gateway (HTTP + WebSocket)
- AWS Lambda
- Amazon S3
- Amazon SQS
- Amazon SNS
- Amazon Rekognition
- Amazon DynamoDB
- Amazon CloudWatch
- Amazon CloudFront
- AWS WAF
- AWS KMS
- Amazon Route53
- AWS Certificate Manager (ACM)

---

## 🧱 High-Level Architecture

```text
                    ┌────────────────────────┐
                    │ Route53 + ACM TLS Cert │
                    └────────────┬───────────┘
                                 │
                                 ▼
                       ┌──────────────────┐
                       │  CloudFront CDN  │
                       └────────┬─────────┘
                                │
                                ▼
                        ┌──────────────┐
                        │  S3 Website  │
                        └──────┬───────┘
                               │
                               ▼
                  ┌────────────────────────┐
                  │ API Gateway (HTTP API)│
                  └──────────┬────────────┘
                             │
                             ▼
             ┌────────────────────────────────┐
             │ Lambda - Generate Signed URL  │
             └───────────────┬────────────────┘
                             │
                             ▼
                      ┌─────────────┐
                      │ S3 Uploads  │
                      └──────┬──────┘
                             │
                             ▼
                       ┌───────────┐
                       │ SQS Queue │
                       └─────┬─────┘
                             │
                             ▼
            ┌────────────────────────────────┐
            │ Lambda - Rekognition Consumer │
            └───────────────┬────────────────┘
                            │
            ┌───────────────┴────────────────┐
            ▼                                ▼
   ┌──────────────────┐             ┌────────────────┐
   │ Amazon Rekognition│             │ DynamoDB Store │
   └─────────┬────────┘             └────────────────┘
             │
             ▼
      ┌────────────────────┐
      │ API Gateway (WS)   │
      └─────────┬──────────┘
                ▼
         Real-Time Frontend

```

| 🧩 Layer             | ⚙️ Technology                      |
| -------------------- | ---------------------------------- |
| 🎨 Frontend          | HTML5 · CSS3 · Vanilla JavaScript  |
| ⚡ Backend            | AWS Lambda (Python 3.10)           |
| 🏗️ Infrastructure   | Terraform                          |
| ☁️ Cloud             | AWS                                |
| 🌐 Networking        | API Gateway · CloudFront · Route53 |
| 📦 Storage           | Amazon S3                          |
| 📬 Messaging         | Amazon SQS · Amazon SNS            |
| 🧠 AI / ML           | Amazon Rekognition                 |
| 🗄️ Database         | Amazon DynamoDB                    |
| 🔐 Security          | IAM · AWS WAF · AWS KMS            |
| 📊 Monitoring        | Amazon CloudWatch                  |
| 🚀 CI/CD             | GitHub Actions                     |
| 🔎 Security Scanning | Snyk · CodeQL                      |


✨ Enterprise Highlights
# ✨ Enterprise Highlights

## ☁️ Cloud-Native Architecture
- Fully serverless AWS infrastructure
- Event-driven asynchronous workflows
- Infrastructure provisioned entirely with Terraform

## ⚡ Real-Time Processing
- WebSocket-based live communication
- Secure pre-signed uploads
- Async image processing with SQS

## 🔐 Production Security
- IAM least privilege model
- AWS WAF protection
- KMS encryption
- DLQ resiliency
- Secure bucket policies

## 📈 Observability
- CloudWatch dashboards
- SNS alerting
- Lambda logging
- Queue monitoring
- Error tracking

## 🌍 Global Delivery
- CloudFront CDN acceleration
- Route53 DNS management
- HTTPS using ACM certificates

```text
GitOps_rekognition/
│
├── .github/
│   └── workflows/
│       ├── codeql.yml
│       └── security.yml
│
├── terraform/
│   ├── infrastructure/
│   │   ├── apigateway/
│   │   ├── cloudfront/
│   │   ├── cloudwatch/
│   │   ├── dynamodb/
│   │   ├── iam/
│   │   ├── lambda/
│   │   ├── route53/
│   │   ├── s3/
│   │   ├── sns/
│   │   ├── sqs/
│   │   ├── waf/
│   │   └── environments/
│   │
│   ├── backend.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── variables.tf
│   └── terraform.tfvars.example
│
├── lambda/
│   ├── pre_signed_url/
│   ├── rekognition_consumer/
│   └── video_processing/
│
├── src/
│   ├── index.html
│   ├── script.js
│   ├── site.js
│   └── style.css
│
└── README.md

```

🔐 Security & DevSecOps
# 🔐 Security & DevSecOps

## 🛡️ Security Best Practices

- IAM least privilege access
- AWS WAF integration
- S3 server-side encryption
- KMS-managed encryption keys
- Secure pre-signed URLs
- HTTPS enforced via ACM
- CloudFront Origin Access Identity
- SQS Dead Letter Queue (DLQ)

---

## 🔎 Automated Security Scanning

### CodeQL Analysis

Static analysis for:
- Python
- JavaScript

### Snyk Security Scans

#### 🏗️ Infrastructure as Code (IaC)
- Terraform misconfiguration scanning
- High-severity enforcement

#### 🧠 Static Application Security Testing (SAST)
- Lambda source code scanning
- Vulnerability detection

#### 📦 Dependency Scanning
- Open-source dependency analysis
- Continuous vulnerability monitoring

📊 Monitoring & Observability

# 📊 Monitoring & Observability

## CloudWatch Dashboards

Included monitoring:
- Lambda invocations
- Lambda duration
- API Gateway metrics
- WebSocket metrics
- Queue depth
- Error rates
- Rekognition requests

## 🚨 Alerts

SNS notifications for:
- DLQ spikes
- Lambda failures
- CloudWatch alarms
- Queue processing failures

📡 API Endpoints 

# 📡 API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| POST | `/labels` | Label detection |
| POST | `/celebrity` | Celebrity recognition |
| POST | `/videos` | Video/image processing |
| WS | `/sockets` | Real-time communication |

# 📈 Highlights

This project demonstrates practical experience with:

## ☁️ Cloud Engineering
- AWS serverless architecture
- Event-driven distributed systems
- CloudFront CDN optimization
- Route53 + ACM production networking

## 🏗️ DevOps Engineering
- Terraform Infrastructure as Code
- GitHub Actions CI/CD pipelines
- Automated deployments
- Modular infrastructure design

## 🔐 DevSecOps
- Snyk security automation
- CodeQL static analysis
- IAM least privilege implementation
- Secure cloud architecture patterns

## 📊 Site Reliability Engineering (SRE)
- CloudWatch dashboards
- Monitoring & alerting
- Queue resiliency patterns

---

## 📦 Prometheus Integration (Observability for a DevOps Portfolio)

This project includes a Prometheus-based observability option that demonstrates how to collect, store, alert on, and visualize metrics for a serverless AWS architecture. The documentation below explains cloud deployment options (self-hosted Prometheus or AWS Managed Service for Prometheus), scraping strategy (via CloudWatch Exporter), sample Prometheus configuration, Alertmanager rules, dashboard examples, Terraform snippets, and verification steps — all of which are portfolio-ready artifacts you can present to hiring engineers.

### Goals
- Collect metrics for Lambdas, API Gateway, SQS, DynamoDB, and CloudFront
- Expose CloudWatch metrics to Prometheus via `cloudwatch_exporter`
- Centralize metrics in Prometheus (or AMP) for visualization
- Configure Alertmanager rules for SLO/alerting (errors, high latency, DLQ spikes)
- Demonstrate infrastructure as code (Terraform) to deploy monitoring components

---

### Quick local access
I use this command locally to access Prometheus via an SSH tunnel:

```bash
ssh -i Downloads/original.pem -L 9090:localhost:9090 ec2-user@ec2-compute-1.amazonaws.com
```

---

### Cloud deployment options

Option A — Self-hosted Prometheus (EC2/ECS/EKS)
- Pros: Full control, easy to demo, familiar to SRE teams
- Cons: Management overhead

Option B — AWS Managed Service for Prometheus (AMP)
- Pros: Fully managed, scales with ingest, integrates with AWS security
- Cons: Service cost, slightly different experience for some open-source integrations

Portfolio recommendation: show both — a self-hosted demo (Docker/EC2) and an AMP Terraform example to prove cloud-native production readiness.

---

### Scraping strategy for serverless (Lambda + API Gateway)

- Direct scraping of Lambda is not possible; use CloudWatch metrics as the source of truth.
- Deploy `cloudwatch_exporter` (open-source) which retrieves metric time series from CloudWatch and serves them for Prometheus to scrape.
- Scrape intervals: 30s–60s for most metrics; use longer intervals for high-cardinality metrics.

CloudWatch metrics to surface (recommended):
- `AWS/Lambda` — Invocations, Errors, Duration (p95/p99 via summary metrics), Throttles, IteratorAge
- `AWS/ApiGateway` — 4XX, 5XX, Latency
- `AWS/SQS` — ApproximateNumberOfMessagesVisible, ApproximateAgeOfOldestMessage
- `AWS/DynamoDB` — ConsumedRead/WriteCapacityUnits, ThrottledRequests
- `AWS/CloudFront` — Requests, 5xxErrors

---

### Example `prometheus.yml` (scrape `cloudwatch_exporter`)

```yaml
global:
  scrape_interval: 60s
  evaluation_interval: 60s

scrape_configs:
  - job_name: 'cloudwatch'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['cloudwatch-exporter:9106']

  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']
```

Example `cloudwatch_exporter` config (`cloudwatch_exporter.yml`) — include namespaces and metrics to minimize API cost:

```yaml
region: us-east-1
metrics:
  - aws_namespace: AWS/Lambda
    aws_metric_name: Errors
    aws_dimensions: [FunctionName]
    range_seconds: 600
    period_seconds: 60
    delay_seconds: 60

  - aws_namespace: AWS/Lambda
    aws_metric_name: Duration
    aws_dimensions: [FunctionName]
    range_seconds: 600
    period_seconds: 60
    delay_seconds: 60

  - aws_namespace: AWS/SQS
    aws_metric_name: ApproximateNumberOfMessagesVisible
    aws_dimensions: [QueueName]
    range_seconds: 600
    period_seconds: 60
    delay_seconds: 60
```

---

### Alerting — example PromQL alerts (Prometheus Alertmanager rules)

Save these as `/rules/alerts.yml` and reference them in Prometheus `rule_files`.

```yaml
groups:
- name: rekognition-alerts
  rules:
  - alert: LambdaErrorsHigh
    expr: increase(aws_lambda_errors_total[5m]) > 3
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "High Lambda error rate for {{ $labels.FunctionName }}"
      description: "{{ $labels.FunctionName }} is returning errors. See CloudWatch / logs."

  - alert: LambdaDurationHigh
    expr: histogram_quantile(0.95, sum(rate(aws_lambda_duration_seconds_bucket[5m])) by (le, FunctionName)) > 300
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High Lambda 95th percentile duration"

  - alert: SQSQueueDepthHigh
    expr: avg_over_time(aws_sqs_ApproximateNumberOfMessagesVisible[5m]) > 100
    for: 10m
    labels:
      severity: critical
    annotations:
      summary: "SQS queue depth high"

  - alert: DLQMessagesDetected
    expr: increase(aws_sqs_dead_letter_queue_messages_visible[5m]) > 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Messages in DLQ detected"
```

Alertmanager can be configured to send alerts to SNS, Slack, PagerDuty, or email. For a portfolio, include screenshots of an alert firing and a runbook that explains remediation steps.

---

### Dashboard suggestions (panels & PromQL)

- Lambda Overview (Invocations, Errors, Duration p50/p95/p99)
  - Invocations: sum(rate(aws_lambda_invocations_total[5m])) by (FunctionName)
  - Errors: sum(rate(aws_lambda_errors_total[5m])) by (FunctionName)
  - Duration (p95): histogram_quantile(0.95, sum(rate(aws_lambda_duration_seconds_bucket[5m])) by (le, FunctionName))

- API Gateway (Latency, 4xx/5xx rates)
  - 5xx Errors: sum(rate(aws_apigateway_5xx_errors[5m]))
  - Latency: avg(aws_apigateway_latency)

- SQS Processing
  - Visible messages: aws_sqs_ApproximateNumberOfMessagesVisible
  - Age of oldest message: aws_sqs_ApproximateAgeOfOldestMessage

- DynamoDB Capacity
  - Consumed RCUs/WCUs

Include annotations for deployments and incidents so reviewers can correlate spikes with releases.

---

### Terraform: minimal example for AWS Managed Service for Prometheus (AMP)

This snippet creates an AMP workspace and a rule group namespace for alerting. (Requires `aws` provider >= 4.x)

```hcl
resource "aws_prometheus_workspace" "rekognition_metrics" {
  alias = "rekognition-metrics"
}

resource "aws_prometheus_rule_group_namespace" "rekognition_alerts" {
  workspace = aws_prometheus_workspace.rekognition_metrics.id
  name      = "rekognition-alerts"
  data      = file("./prometheus_rules.yaml")
}

output "amp_workspace_endpoint" {
  value = aws_prometheus_workspace.rekognition_metrics.prometheus_endpoint
}
```

Note: To push metrics or remote write from Prometheus to AMP, configure Prometheus `remote_write` with signed SigV4 requests or use the Prometheus AMP remote write helper.

---

### Security & cost considerations

- Use least-privilege IAM roles for `cloudwatch_exporter` or Prometheus instances.
- Minimize CloudWatch API calls by scoping metrics and increasing `period_seconds` where appropriate.
- AMP costs are based on ingestion and storage — include a cost estimate in your portfolio and show how you tuned scraping frequency to reduce cost.

---

### Verification & demonstration steps (what to include in portfolio)

1. Start local demo (`docker-compose up`) and show Prometheus targets page showing `cloudwatch_exporter`.
2. Trigger a Lambda invocation (upload an image) and show the metric increment in Prometheus graph (invocations, duration, errors).
3. Force an error (e.g., send bad payload) and show Alertmanager sending a notification (screenshot/recording).
4. Show dashboard panels with p95 latency and invocation trends. Export dashboard JSON and include it in the repo under `observability/dashboards/`.
5. Include a `prometheus` directory in the repo with `prometheus.yml`, `alerts.yml`, and exporter config so reviewers can reproduce.

Suggested repo layout for reproducibility:

```
observability/
├── prometheus/
│   ├── prometheus.yml
│   ├── alerts.yml
│   └── cloudwatch_exporter.yml
├── dashboards/
│   └── rekognition-overview.json
└── terraform/
  └── amp.tf
```

---

### What to show in your DevOps portfolio entry

- Architecture diagram showing CloudWatch -> cloudwatch_exporter -> Prometheus/AMP -> dashboards -> Alertmanager
- Terraform snippets (AMP workspace, IAM roles, S3 for dashboards backup)
- Dashboard screenshots + exported JSON
- Alertmanager config and example alert delivery (Slack/SNS)
- A short walkthrough video (30–90s) demonstrating:
  - Triggering a Lambda and seeing metrics update
  - Alert firing and acknowledgement
  - Dashboard navigation

---

If you'd like, I can:
- Add the `observability/` folder with `prometheus.yml`, `alerts.yml`, and `cloudwatch_exporter.yml` example files in this repo.
- Add a Docker Compose file that runs Prometheus, Alertmanager, and cloudwatch-exporter for a local demo.

Tell me which of those you'd like me to generate next and I'll add them to the repository.
- Operational observability

## ⚡ Backend Engineering
- Asynchronous message processing
- WebSocket communication
- Scalable serverless APIs
- Real-time event streaming


🌍 Live Demo

👉 https://rekoglabelify.com

🧪 Features
- ✅ Celebrity recognition
- ✅ Label detection
- ✅ Event-driven architecture
- ✅ Real-time WebSocket updates
- ✅ Terraform IaC deployment
- ✅ CloudFront CDN integration
- ✅ Route53 domain management
- ✅ AWS WAF protection
- ✅ DynamoDB persistence
- ✅ CloudWatch dashboards
- ✅ SNS alerting
- ✅ Secure S3 uploads
- ✅ DLQ resiliency
- ✅ GitHub Actions CI/CD
- ✅ Snyk & CodeQL DevSecOps scanning


This project demonstrates practical experience with:

## ☁️ Cloud Engineering
- AWS serverless architecture
- Event-driven distributed systems
- CloudFront CDN optimization
- Route53 + ACM production networking
## 🏗️ DevOps Engineering
- Terraform Infrastructure as Code
- GitHub Actions CI/CD pipelines
- Automated deployments
- Modular infrastructure design
## 🔐 DevSecOps
- Snyk security automation
- CodeQL static analysis
- IAM least privilege implementation
- Secure cloud architecture patterns
## 📊 Site Reliability Engineering (SRE)
- CloudWatch dashboards
- Monitoring & alerting
- Queue resiliency patterns
- Operational observability
## ⚡ Backend Engineering
- Asynchronous message processing
- WebSocket communication
- Scalable serverless APIs
- Real-time event streaming

## 📜 License

This project is licensed under the MIT License.

See the LICENSE file for details.

✍️ Author
Andrés Acosta
LinkedIn: https://linkedin.com/in/andrés-acosta-203923238
DevOps | AWS | Terraform | Cloud | DevSecOps
