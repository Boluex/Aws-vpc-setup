#!/bin/bash
set -e

PROFILE="vera"
ENDPOINT="http://localhost:5003"

source ~/vera-project/vars.sh

echo "==> Creating Bastion Security Group..."
BASTION_SG_ID=$(aws ec2 create-security-group \
  --group-name bastion-sg \
  --description "Bastion host security group" \
  --vpc-id $VPC_ID \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT \
  --query 'GroupId' \
  --output text)
echo "BASTION_SG_ID=$BASTION_SG_ID"

# Allow SSH inbound from anywhere
aws ec2 authorize-security-group-ingress \
  --group-id $BASTION_SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0 \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT

echo "==> Creating Frontend Security Group..."
FRONTEND_SG_ID=$(aws ec2 create-security-group \
  --group-name frontend-sg \
  --description "Nginx frontend security group" \
  --vpc-id $VPC_ID \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT \
  --query 'GroupId' \
  --output text)
echo "FRONTEND_SG_ID=$FRONTEND_SG_ID"

# Allow HTTP from anywhere
aws ec2 authorize-security-group-ingress \
  --group-id $FRONTEND_SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT

# Allow HTTPS from anywhere
aws ec2 authorize-security-group-ingress \
  --group-id $FRONTEND_SG_ID \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0 \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT

# Allow SSH from bastion only
aws ec2 authorize-security-group-ingress \
  --group-id $FRONTEND_SG_ID \
  --protocol tcp \
  --port 22 \
  --source-group $BASTION_SG_ID \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT

echo "==> Creating Backend Security Group..."
BACKEND_SG_ID=$(aws ec2 create-security-group \
  --group-name backend-sg \
  --description "Django backend security group" \
  --vpc-id $VPC_ID \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT \
  --query 'GroupId' \
  --output text)
echo "BACKEND_SG_ID=$BACKEND_SG_ID"

# Allow Django port 8000 from frontend only
aws ec2 authorize-security-group-ingress \
  --group-id $BACKEND_SG_ID \
  --protocol tcp \
  --port 8000 \
  --source-group $FRONTEND_SG_ID \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT

# Allow SSH from bastion only
aws ec2 authorize-security-group-ingress \
  --group-id $BACKEND_SG_ID \
  --protocol tcp \
  --port 22 \
  --source-group $BASTION_SG_ID \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT

echo "==> Creating Database Security Group..."
DB_SG_ID=$(aws ec2 create-security-group \
  --group-name database-sg \
  --description "PostgreSQL database security group" \
  --vpc-id $VPC_ID \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT \
  --query 'GroupId' \
  --output text)
echo "DB_SG_ID=$DB_SG_ID"

# Allow PostgreSQL from backend only
aws ec2 authorize-security-group-ingress \
  --group-id $DB_SG_ID \
  --protocol tcp \
  --port 5432 \
  --source-group $BACKEND_SG_ID \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT

# Allow SSH from bastion only
aws ec2 authorize-security-group-ingress \
  --group-id $DB_SG_ID \
  --protocol tcp \
  --port 22 \
  --source-group $BASTION_SG_ID \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT

# Save variables
cat >> ~/vera-project/vars.sh << VARS
export BASTION_SG_ID=$BASTION_SG_ID
export FRONTEND_SG_ID=$FRONTEND_SG_ID
export BACKEND_SG_ID=$BACKEND_SG_ID
export DB_SG_ID=$DB_SG_ID
VARS

echo ""
echo "====== Security Groups Complete ======"
echo "Bastion SG:   $BASTION_SG_ID"
echo "Frontend SG:  $FRONTEND_SG_ID"
echo "Backend SG:   $BACKEND_SG_ID"
echo "Database SG:  $DB_SG_ID"
echo "======================================"
