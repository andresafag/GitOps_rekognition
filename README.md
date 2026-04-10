# Rekognition Infrastructure

This project implements an AWS-based image processing pipeline using Terraform.

## Architecture

- **S3 Bucket**: Stores uploaded images
- **SQS Queue**: Receives notifications when images are uploaded
- **Lambda Functions**: 
  - Presigned URL generator (Python)
  - Rekognition processor (Python)
- **API Gateway**: HTTP API for requesting upload URLs

## Project Structure

```
├── lambda/                          # Lambda function source code
│   ├── pre_signed_url/
│   │   └── index.py
│   └── rekognition_consumer/
│       └── index.py
├── infrastructure/                  # Terraform configuration
│   ├── environments/                # Environment-specific configurations
│   │   ├── dev/
│   │   │   └── terraform.tfvars
│   │   └── prod/
│   │       └── terraform.tfvars
│   ├── backend.tf                   # S3 backend configuration
│   ├── provider.tf                  # AWS provider configuration
│   ├── variables.tf                 # Input variables
│   ├── outputs.tf                   # Output values
│   ├── main.tf                      # Main infrastructure resources
│   └── terraform.tfvars.example     # Example variables
└── README.md                        # This file
```

## Usage

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.5.0

### Deployment

1. Navigate to the infrastructure directory:
   ```bash
   cd infrastructure
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Plan deployment for a specific environment:
   ```bash
   # For development
   terraform plan -var-file=environments/dev/terraform.tfvars

   # For production
   terraform plan -var-file=environments/prod/terraform.tfvars
   ```

4. Apply the configuration:
   ```bash
   # For development
   terraform apply -var-file=environments/dev/terraform.tfvars

   # For production
   terraform apply -var-file=environments/prod/terraform.tfvars
   ```

### Testing

1. Get a presigned upload URL:
   ```bash
   curl -X POST https://your-api-endpoint/upload \
     -H "Content-Type: application/json"
   ```

2. Upload an image using the returned URL:
   ```bash
   curl -X PUT "presigned-url-from-step-1" \
     -H "Content-Type: image/jpeg" \
     --data-binary @path/to/image.jpg
   ```

3. Check Rekognition results in the S3 bucket under `results/` folder.

## Cleanup

```bash
terraform destroy -var-file=environments/dev/terraform.tfvars
```