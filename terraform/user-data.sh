#!/bin/bash
set -e
set -x

# Update packages
apt-get update -y

# Install prerequisites
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    gnupg \
    git \
    lsb-release \
    openssl \
    jq \
    unzip
    

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

# Enable Docker service
systemctl enable docker
systemctl start docker
sleep 5

# Install Docker Compose
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) \
    -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Clone my repository
mkdir -p /opt
cd /opt
if [ ! -d "simple-app" ]; then
    git clone https://github.com/Alkaponees/simple-app.git
fi
cd simple-app

# Create certificates
# mkdir -p certs
# openssl req -x509 -newkey rsa:4096 \
#     -keyout certs/nginx-selfsigned.key \
#     -out certs/nginx-selfsigned.crt \
#     -sha256 -days 365 -nodes \
#     -subj "/CN=localhost"

# Fetch  secrets 
aws secretsmanager get-secret-value \
  --secret-id simple-app-env \
  --query SecretString \
  --output text | jq -r 'to_entries|map("\(.key)=\(.value)")|.[]' > .env

aws secretsmanager get-secret-value \
  --secret-id simple-app-env-db \
  --query SecretString \
  --output text | jq -r 'to_entries|map("\(.key)=\(.value)")|.[]' > .env_db



# Start Docker Compose app
docker-compose -f docker-compose.yml up -d
