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
