#!/bin/bash
set -e

PROFILE="vera"
ENDPOINT="http://localhost:5003"
REGION="us-east-1a"

echo "==> Creating VPC..."
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT \
  --query 'Vpc.VpcId' \
  --output text)
echo "VPC_ID=$VPC_ID"

echo "==> Creating subnets..."
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone $REGION \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT \
  --query 'Subnet.SubnetId' \
  --output text)

PRIVATE_SUBNET_ID_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/24 \
  --availability-zone $REGION \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT \
  --query 'Subnet.SubnetId' \
  --output text)

PRIVATE_SUBNET_ID_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.3.0/24 \
  --availability-zone $REGION \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT \
  --query 'Subnet.SubnetId' \
  --output text)

echo "Public Subnet: $PUBLIC_SUBNET_ID"
echo "Private Subnet 1: $PRIVATE_SUBNET_ID_1"
echo "Private Subnet 2: $PRIVATE_SUBNET_ID_2"

echo "==> Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)
echo "IGW_ID=$IGW_ID"

echo "==> Attaching Internet Gateway to VPC..."
aws ec2 attach-internet-gateway \
  --internet-gateway-id $IGW_ID \
  --vpc-id $VPC_ID \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT

echo "==> Creating Elastic IP for NAT Gateway..."
EIP_ALLOC_ID=$(aws ec2 allocate-address \
  --domain vpc \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT \
  --query 'AllocationId' \
  --output text)
echo "EIP_ALLOC_ID=$EIP_ALLOC_ID"

echo "==> Creating NAT Gateway in public subnet..."
NAT_GW_ID=$(aws ec2 create-nat-gateway \
  --subnet-id $PUBLIC_SUBNET_ID \
  --allocation-id $EIP_ALLOC_ID \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT \
  --query 'NatGateway.NatGatewayId' \
  --output text)
echo "NAT_GW_ID=$NAT_GW_ID"

echo "==> Creating route tables..."
PUBLIC_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT \
  --query 'RouteTable.RouteTableId' \
  --output text)

PRIVATE_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT \
  --query 'RouteTable.RouteTableId' \
  --output text)

echo "Public RT: $PUBLIC_RT_ID"
echo "Private RT: $PRIVATE_RT_ID"

echo "==> Adding routes..."
aws ec2 create-route \
  --route-table-id $PUBLIC_RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT

aws ec2 create-route \
  --route-table-id $PRIVATE_RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id $NAT_GW_ID \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT

echo "==> Associating route tables to subnets..."
aws ec2 associate-route-table \
  --subnet-id $PUBLIC_SUBNET_ID \
  --route-table-id $PUBLIC_RT_ID \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT

aws ec2 associate-route-table \
  --subnet-id $PRIVATE_SUBNET_ID_1 \
  --route-table-id $PRIVATE_RT_ID \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT

aws ec2 associate-route-table \
  --subnet-id $PRIVATE_SUBNET_ID_2 \
  --route-table-id $PRIVATE_RT_ID \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT

echo "==> Enabling auto-assign public IP for public subnet..."
aws ec2 modify-subnet-attribute \
  --subnet-id $PUBLIC_SUBNET_ID \
  --map-public-ip-on-launch \
  --profile $PROFILE \
  --endpoint-url $ENDPOINT

echo "==> Saving variables..."
cat > ~/vera-project/vars.sh << VARS
export VPC_ID=$VPC_ID
export PUBLIC_SUBNET_ID=$PUBLIC_SUBNET_ID
export PRIVATE_SUBNET_ID_1=$PRIVATE_SUBNET_ID_1
export PRIVATE_SUBNET_ID_2=$PRIVATE_SUBNET_ID_2
export IGW_ID=$IGW_ID
export EIP_ALLOC_ID=$EIP_ALLOC_ID
export NAT_GW_ID=$NAT_GW_ID
export PUBLIC_RT_ID=$PUBLIC_RT_ID
export PRIVATE_RT_ID=$PRIVATE_RT_ID
VARS

echo ""
echo "====== VPC Setup Complete ======"
echo "VPC ID:             $VPC_ID"
echo "Public Subnet:      $PUBLIC_SUBNET_ID"
echo "Private Subnet 1:   $PRIVATE_SUBNET_ID_1"
echo "Private Subnet 2:   $PRIVATE_SUBNET_ID_2"
echo "Internet Gateway:   $IGW_ID"
echo "NAT Gateway:        $NAT_GW_ID"
echo "Public RT:          $PUBLIC_RT_ID"
echo "Private RT:         $PRIVATE_RT_ID"
echo "================================"
