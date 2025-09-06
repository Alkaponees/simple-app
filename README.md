# Simple App Infrastructure
<img width="1459" height="796" alt="image" src="https://github.com/user-attachments/assets/6bd63d02-2c33-4d1f-9327-f5fc211edc7f" />

This project provisions a simple application stack on **AWS EC2** using **Terraform** and runs it with **Docker Compose**.  

It includes:  
- VPC, subnet, and security groups  
- EC2 instance with Docker & Docker Compose  
- CloudFront distribution (optional)  
- Self-signed SSL certificates for local HTTPS  

---

## 🚀 Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.6  
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured (`aws configure`)  
- An **AWS key pair** (imported into AWS EC2 or created via Terraform)  
- Git & Docker installed locally (if testing certificates)  

---

## ⚡ Deploy with Terraform

1. Clone the repository:

```bash
git clone https://github.com/Alkaponees/simple-app.git
cd simple-app/terraform
```
2. Initialize Terraform:
``` bash
terraform init
```
3. Validate the configuration:
``` bash
terraform validate
```
4. Apply the configuration:
``` bash
terraform apply -auto-approve
```
This will:
- Create a new VPC, subnet, and security group
- Provision an EC2 instance with Docker & Docker Compose
- Attach an Elastic IP
- Configure CloudFront

## Project structure:
```
.
├── backend
│   ├── Dockerfile
│   ...
├── terraform
│    ├── ...
│   └── main.tf
├── docker-compose.yaml
├── docker-compose.override.yaml
├── .gitignore
├── .dockerignore
├── nginx
│   ├── nginx.conf
│   ...
├── frontend
│   ├── ...
│   └── Dockerfile
├── LICENSE
└── README.md
```
[_docker-compose.yaml_](docker-compose.yaml)
```
services:
 services:
  backend:
    build:
      args:
      - NODE_ENV=development
      context: backend
      target: development
    image: alkaponees/simple-app-backend:dev
    env_file:
      - .env
    ports:
      - "8000"
    volumes:
      - backend:/opt/app/node_modules
    ...

  db:
    # We use a mariadb image which supports both amd64 & arm64 architecture
    image: mariadb:10.6.4-focal
    # If you really want to use MySQL, uncomment the following line
    #image: mysql:8.0.27
    command: '--default-authentication-plugin=mysql_native_password'
    restart: always
    volumes:
      - db-data:/var/lib/mysql
    ...

  frontend:
    build:
      context: frontend
      target: development
    image: alkaponees/simple-app-frontend:dev 
    ports:
      - "3000"
    ...
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      # - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
      # - ./certs:/etc/nginx/certs:ro
    depends_on:
      - frontend
      - backend
    ...

networks:
  public:
  private:
volumes:
  backend:
  db-data:

```
The compose file defines an application with three services: `frontend`, `backend`, `db`, and `nginx`.
When deploying the application, Docker Compose maps port 80  of the nginx service container to port 80 (443 local) of the host as specified in the file.
Make sure port 80 on the host is not already in use.

## 🧹 Clean Up
To destroy all AWS resources created by Terraform:
```bash
terraform destroy -auto-approve
```

## Generate Local Certificates (Self-Signed)

If you want to use self-signed certificates (default setup for local testing):

1. Create a certs directory in your project root:
``` bash
mkdir -p certs
```
2. Generate the certificates:
``` bash
openssl req -x509 -newkey rsa:4096 \
  -keyout certs/nginx-selfsigned.key \
  -out certs/nginx-selfsigned.crt \
  -sha256 -days 365 -nodes \
  -subj "/CN=localhost"
```
3. Run project using docker-compose.override.yml file
``` bash
docker compose -f docker-compose.override.yml up -d
```
