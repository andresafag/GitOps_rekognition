# 🚀 GitOps_rekognition

![Github repo](https://img.shields.io/badge/github-repo-blue?style=for-the-badge&logo=github)
![Terraform](https://img.shields.io/badge/terraform-purple?style=for-the-badge&logo=terraform)
![AWS](https://img.shields.io/badge/aws-orange.svg?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCI+PHBhdGggZD0ibTE4LjggMTEuNC0uOC0uMS0uOC0uM0gxN2wtLjEuMnYuNWwuMi4yLjguMyAxIC4xIDEtLjEuNy0uNC41LS42LjItLjgtLjMtLjktMS0uNi0xLS4zLS43LS40LS4yLS41LjMtLjYuOS0uMSAxLjIuMmguM2wuMi0uMXYtLjRsLS4xLS4yLS4yLS4yaC0uM0wyMCA2bC0uNC0uMUgxOWwtLjguMS0uNy40LS41LjUtLjIuNy4zIDFhMiAyIDAgMCAwIDEuMS43bDEgLjMuNy40LjIuNGExIDEgMCAwIDEtLjQuN3ptLTUuOS00Ljl2LS4zaC0xLjJ2LjNsLTEgNC40LTEuMi00LjQtLjItLjNoLS45bC0uMS4xdi4zbDEuNiA1LjEuMS4zaDEuMWwuMS0uMyAxLTQuMiAxIDQuMi4xLjNoMS4xbC4yLS4zIDEuNi01LjF2LS4ybC0uMi0uMmgtLjlsLS4xLjMtMSA0LjV6TTUuOCA4LjZINWEyIDIgMCAwIDAtMS43LjUgMiAyIDAgMCAwLS42IDEuNCAyIDIgMCAwIDAgLjUgMS4yIDIgMiAwIDAgMCAxLjMuNSAzIDMgMCAwIDAgMi0uOWwuMi40LjMuM2guNGwuNC0uMy4xLS4ydi0uMWwtLjItLjVWOC4yYTIgMiAwIDAgMC0uNi0xLjZBMiAyIDAgMCAwIDUuMyA2bC0xIC4xLS44LjMtLjIuMlY3cTAgLjMuMi4yaC4zbC42LS4zaC43YTIgMiAwIDAgMSAxLjEuMmwuMyAxdi42em0uNyAxdi44bC0uMy40LS42LjQtLjcuMi0uNy0uMy0uMi0uNy4zLS44IDEtLjJINnpNMTkuOSAxNWEyMCAyMCAwIDAgMS03LjYgMS41QTIwIDIwIDAgMCAxIDIuMyAxNHEtLjQgMC0uMi4zQTE1IDE1IDAgMCAwIDEyIDE4YTE0IDE0IDAgMCAwIDguMS0yLjVxLjMtLjYtLjMtLjUiLz48cGF0aCBkPSJNMTguNCAxNHEtLjMuMyAwIC40Yy43LS4xIDIuMy0uMyAyLjYgMHMtLjMgMS45LS42IDIuNXEwIC4zLjMuMmE0IDQgMCAwIDAgMS4yLTMuNCA0IDQgMCAwIDAtMy41LjQiLz48L3N2Zz4=)
![Javascript](https://img.shields.io/badge/javascript-black?style=for-the-badge&logo=javascript)
![Snyk](https://img.shields.io/badge/snyk-black.svg?style=for-the-badge&logo=snyk)
![Githubactions](https://img.shields.io/badge/github_actions-black.svg?style=for-the-badge&logo=githubactions)


> **Infrastructure as Code (IaC)** project using Terraform to deploy a fully event-driven image processing pipeline powered by AWS Rekognition.

---

## 🧭 Table of Contents

- [🚀 GitOps\_rekognition](#-gitops_rekognition)
  - [🧭 Table of Contents](#-table-of-contents)
  - [📌 Overview](#-overview)
  - [🧰 Tech Stack](#-tech-stack)
    - [✨ Highlights](#-highlights)
  - [🏗️ Architecture](#️-architecture)
  - [📁 Project Structure](#-project-structure)
  - [🔐 CI/CD \& Security Scanning](#-cicd--security-scanning)
    - [🛡️ CodeQL Analysis](#️-codeql-analysis)
    - [🔎 Snyk Security Scans](#-snyk-security-scans)
      - [🏗️ Infrastructure as Code (IaC)](#️-infrastructure-as-code-iac)
      - [🧠 Static Application Security Testing (SAST)](#-static-application-security-testing-sast)
      - [📦 Open Source Dependency Scanning](#-open-source-dependency-scanning)
    - [⚙️ Pipeline Overview](#️-pipeline-overview)
  - [🔄 Workflow](#-workflow)
  - [📡 API Endpoints](#-api-endpoints)
  - [📊 Monitoring](#-monitoring)
  - [Live Demo](#live-demo)
  - [🧪 Features](#-features)
  - [License](#license)
  - [✍️ Author](#️-author)

---

## 📌 Overview

**GitOps_rekognition** provisions a complete serverless architecture on AWS that enables:

- 📤 Image upload via a web interface
- 🔗 API Gateway-triggered Lambda functions
- 📬 Event-driven processing using SQS & SNS
- 🧠 Image analysis with AWS Rekognition
- ⚡ Real-time results via WebSocket API

The system detects:
- 👤 Celebrities in images
- 🏷️ Labels and objects

Results are pushed back to the frontend in real time.

---


## 🧰 Tech Stack

<div align="center">

| 🧩 Layer            | ⚙️ Technology                                                                 |
|--------------------|------------------------------------------------------------------------------|
| 🎨 Frontend        | `HTML5` · `CSS3` · `JavaScript (Vanilla)`                                    |
| ⚡ Backend         | `AWS Lambda` · `Python 3.10`                                                 |
| 🏗️ Infrastructure | `Terraform` (Infrastructure as Code)                                         |
| ☁️ Cloud           | `Amazon Web Services (AWS)`                                                  |
| 📦 Storage         | `Amazon S3`                                                                  |
| 📬 Messaging       | `Amazon SQS` · `Amazon SNS`                                                  |
| 🌐 API Layer       | `Amazon API Gateway` (HTTP + WebSocket)                                      |
| 🧠 AI / ML         | `Amazon Rekognition`                                                         |
| 🔐 Security        | `IAM Roles & Policies` · `Snyk` · `CodeQL`                                   |
| 📊 Monitoring      | `Amazon CloudWatch`                                                          |

</div>

---

### ✨ Highlights

- **Fully Serverless Architecture** – No server management required  
- **Event-Driven Design** – Scalable and decoupled components  
- **Real-Time Communication** – Powered by WebSockets  
- **AI-Powered Image Analysis** – Using AWS Rekognition  
- **DevSecOps Ready** – Integrated security scanning with Snyk & CodeQL  

---

## 🏗️ Architecture

```text
Client (Web)
   │
   ▼
API Gateway (HTTP)
   │
   ▼
Lambda (Generate Pre-Signed URL)
   │
   ▼
S3 (Image Upload)
   │
   ▼
SQS Queue ───► DLQ (Failures)
   │
   ▼
Lambda (Rekognition Consumer)
   │
   ├──► AWS Rekognition
   └──► API Gateway (WebSocket)
                │
                ▼
          Real-time Frontend
```


## 📁 Project Structure
```
GitOps_rekognition/
│
├── .github/
│   └── workflows/
│       └── codeql.yml
│
├── terraform/
│   ├── infrastructure/
│   │   ├── environments/
│   │   └── lambda/
│   │
│   ├── .terraform/
│   ├── .terraform.lock.hcl
│   ├── backend.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── terraform.tfvars.example
│   └── variables.tf
│
├── lambda/
│   ├── pre_signed_url/
│   └── rekognition_consumer/
│
├── src/
│   ├── index.html
│   ├── script.js
│   ├── site.js
│   └── style.css
│
└── README.md
```

---

## 🔐 CI/CD & Security Scanning

This project integrates **GitHub Actions** to enforce code quality and security best practices through automated analysis pipelines.

### 🛡️ CodeQL Analysis

We use **CodeQL** to perform static code analysis across multiple languages:

- ✅ JavaScript
- ✅ Python

**Key Features:**
- Multi-language support via matrix strategy
- Automated security vulnerability detection
- No build required (`build-mode: none`)
- Runs on every workflow execution

**Workflow Highlights:**
- Repository checkout
- CodeQL initialization per language
- Automated analysis with categorized results

---

### 🔎 Snyk Security Scans

We leverage **Snyk** to perform comprehensive security checks across:

#### 🏗️ Infrastructure as Code (IaC)
- Scans Terraform files for misconfigurations
- Enforces **high severity threshold**

#### 🧠 Static Application Security Testing (SAST)
- Analyzes Python Lambda code directly
- No dependency files required

#### 📦 Open Source Dependency Scanning
- Detects vulnerabilities in dependencies
- Automatically scans all projects if dependency files exist
- Non-blocking if no dependencies are found

---

### ⚙️ Pipeline Overview

```text
GitHub Actions Pipeline
│
├── 🛡️ CodeQL Analysis
│   ├── JavaScript / TypeScript
│   └── Python
│
└── 🔎 Snyk Security
    ├── Terraform IaC Scan
    ├── Python Code SAST
    └── Open Source Dependency Scan
```
---

## 🔄 Workflow

1. User uploads an image via the web interface.
2. Frontend requests a pre-signed URL from the API Gateway.
3. Lambda generates the URL and returns it to the frontend.
4. Frontend uploads the image directly to S3 using the pre-signed URL.
5. S3 triggers an event that sends a message to the SQS queue.
6. Rekognition Consumer Lambda processes the SQS message, analyzes the image with AWS Rekognition
    Detects labels
    Recognizes celebrities
WebSocket pushes results to frontend in real time

---
## 📡 API Endpoints

| Method | Endpoint     | Description                            |
| ------ | ------------ | -------------------------------------- |
| POST   | `/labels`    | Upload image for label detection       |
| POST   | `/celebrity` | Upload image for celebrity recognition |
| WS     | `/sockets`   | Real-time communication channel        |

---
## 📊 Monitoring

📈 CloudWatch Dashboard included:
Lambda invocations & duration
SQS queue depth
Rekognition requests
Error rates
🚨 Alerts:
Dead Letter Queue (DLQ) monitoring via SNS

---

🔐 Security
🔒 IAM roles with least privilege
🔐 S3 server-side encryption (AES256)
🌐 CORS enabled for API Gateway
📩 DLQ for failed message handling
🔑 Secure pre-signed URLs for uploads

---

##  Live Demo

👉 [Demo](https://rekoglabelify.com)

## 🧪 Features

- ✅ Celebrity recognition
- ✅ Label detection
- ✅ Real-time results via WebSocket
- ✅ Event-driven architecture
- ✅ Serverless deployment with Terraform
- ✅ Comprehensive monitoring and alerting
- ✅ Secure IAM roles and S3 encryption
- ✅ Dead Letter Queue for failure handling
- ✅ CI/CD pipeline with GitHub Actions

🚀 Benefits
🔐 Early detection of vulnerabilities
📉 Reduced security risks in infrastructure and code
⚡ Automated and consistent analysis
🧩 Seamless integration with GitOps workflows

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ✍️ Author

**Andrés Acosta**
*  [My LinkedIn profile](https://linkedin.com/in/andrés-acosta-203923238)