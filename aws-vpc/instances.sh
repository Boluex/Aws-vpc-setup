#!/bin/bash
set -e

PROFILE="vera"
ENDPOINT="http://localhost:5003"

source ~/vera-project/vars.sh

INSTANCE_TYPE="t2.micro"

echo "==> Launching Bastion EC2..."
BASTION_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --subnet-id $PUBLIC_SUBNET_ID \
  --security-group-ids $BASTION_SG_ID \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=bastion},{Key=Role,Value=bastion}]' \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT \
  --query 'Instances[0].InstanceId' \
  --output text)
echo "BASTION_ID=$BASTION_ID"

echo "==> Launching Frontend EC2..."
FRONTEND_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --subnet-id $PUBLIC_SUBNET_ID \
  --security-group-ids $FRONTEND_SG_ID \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=frontend},{Key=Role,Value=nginx}]' \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT \
  --query 'Instances[0].InstanceId' \
  --output text)
echo "FRONTEND_ID=$FRONTEND_ID"

echo "==> Launching Backend EC2..."
BACKEND_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --subnet-id $PRIVATE_SUBNET_ID_1 \
  --security-group-ids $BACKEND_SG_ID \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=backend},{Key=Role,Value=django}]' \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT \
  --query 'Instances[0].InstanceId' \
  --output text)
echo "BACKEND_ID=$BACKEND_ID"

echo "==> Launching Database EC2..."
DB_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --subnet-id $PRIVATE_SUBNET_ID_2 \
  --security-group-ids $DB_SG_ID \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=database},{Key=Role,Value=postgresql}]' \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT \
  --query 'Instances[0].InstanceId' \
  --output text)
echo "DB_ID=$DB_ID"

# Save variables
cat >> ~/vera-project/vars.sh << VARS
export BASTION_ID=$BASTION_ID
export FRONTEND_ID=$FRONTEND_ID
export BACKEND_ID=$BACKEND_ID
export DB_ID=$DB_ID
VARS

echo ""
echo "====== EC2 Instances Complete ======"
echo "Bastion:  $BASTION_ID"
echo "Frontend: $FRONTEND_ID"
echo "Backend:  $BACKEND_ID"
echo "Database: $DB_ID"
echo "===================================="
