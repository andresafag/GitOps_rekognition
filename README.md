🏗️ Arquitectura del Sistema
El flujo de trabajo es totalmente automatizado y desacoplado:
API Gateway: Punto de entrada para solicitar URLs pre-firmadas 🔑.
S3 Bucket: Repositorio de imágenes analizadas y almacenamiento de resultados 📥.
SQS Queue: Desacopla la subida del análisis, garantizando escalabilidad 📬.
Lambda Functions:
Pre-signed URL: Genera accesos temporales para subidas seguras.
Rekognition Processor: El "cerebro" que detecta etiquetas y celebridades.

.
├── 📂 lambda/                       # 🐍 Código fuente de las funciones
│   ├── 📂 pre_signed_url/           # Generador de tickets de carga
│   │   └── index.py
│   └── 📂 rekognition_consumer/      # Consumidor de SQS e IA
│       └── index.py
├── 📂 infrastructure/               # 🏗️ Configuración de Terraform
│   ├── 📂 environments/             # 🌍 Configuración por entorno
│   │   ├── 🔹 dev/                  # Desarrollo
│   │   └── 🔸 prod/                 # Producción
│   ├── backend.tf                   # Estado remoto en S3
│   ├── variables.tf                 # Entradas dinámicas
│   └── main.tf                      # Recursos núcleo
└── 📂 .github/workflows             # 🤖 GitOps: CodeQL & Snyk Scan


🛡️ Seguridad y GitOps (DevSecOps)
Este repositorio no solo despliega infraestructura, sino que la protege mediante un pipeline de CI/CD integrado con:
CodeQL: Análisis estático de seguridad profundo por GitHub.
Snyk Scan: Escaneo de vulnerabilidades en código Python y archivos de Terraform (IaC).
Automated Deployment: Cada cambio en main se valida rigurosamente.

🚀 Guía de Despliegue
1️⃣ Requisitos Previos
Terraform >= 1.5.0
AWS CLI configurado con permisos de Admin.
Token de Snyk (opcional, para el pipeline).
2️⃣ Pasos para Desplegar

# Entrar al directorio
cd infrastructure

# Inicializar Terraform
terraform init

# Elegir entorno (dev o prod)
terraform plan -var-file=environments/dev/terraform.tfvars

# ¡Lanzar a la nube! ☁️
terraform apply -var-file=environments/dev/terraform.tfvars


🧪 Pruebas (Testing)
¡Haz que la magia ocurra! 🪄


Obtén tu URL de carga:

curl -X POST https://TU_API_ENDPOINT/upload

Sube una foto

curl -X PUT "URL_RECIBIDA" --data-binary @mi_foto.jpg


Revisa los resultados: Mira en tu bucket S3 la carpeta /results para ver los JSON generados por la IA. 🕵️‍♂️

🧹 Limpieza
Para evitar cargos inesperados en tu cuenta de AWS:

terraform destroy -var-file=environments/dev/terraform.tfvars

Hecho con ❤️ por andresafag