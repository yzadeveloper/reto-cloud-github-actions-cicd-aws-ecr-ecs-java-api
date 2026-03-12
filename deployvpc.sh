#!/bin/bash

set -e

REGION="us-west-2"

echo "Creating VPC..."

VPC_ID=$(aws ec2 create-vpc \
  --region $REGION \
  --cidr-block 10.0.0.0/16 \
  --no-amazon-provided-ipv6-cidr-block \
  --instance-tenancy default \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=spring-api-vpc-vpc}]' \
  --query 'Vpc.VpcId' \
  --output text)

echo "VPC: $VPC_ID"

echo "Enabling DNS hostnames..."

aws ec2 modify-vpc-attribute \
  --region $REGION \
  --vpc-id $VPC_ID \
  --enable-dns-hostnames '{"Value":true}'

echo "Creating S3 VPC endpoint..."

VPCE_ID=$(aws ec2 create-vpc-endpoint \
  --region $REGION \
  --vpc-id $VPC_ID \
  --service-name com.amazonaws.$REGION.s3 \
  --tag-specifications 'ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=spring-api-vpc-vpce-s3}]' \
  --query 'VpcEndpoint.VpcEndpointId' \
  --output text)

echo "VPC Endpoint: $VPCE_ID"

echo "Creating public subnets..."

SUBNET_PUBLIC_1=$(aws ec2 create-subnet \
  --region $REGION \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.0.0/20 \
  --availability-zone ${REGION}a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=spring-api-vpc-subnet-public1-us-west-2a}]' \
  --query 'Subnet.SubnetId' \
  --output text)

SUBNET_PUBLIC_2=$(aws ec2 create-subnet \
  --region $REGION \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.16.0/20 \
  --availability-zone ${REGION}b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=spring-api-vpc-subnet-public2-us-west-2b}]' \
  --query 'Subnet.SubnetId' \
  --output text)

echo "Public subnets: $SUBNET_PUBLIC_1 $SUBNET_PUBLIC_2"

echo "Creating private subnets..."

SUBNET_PRIVATE_1=$(aws ec2 create-subnet \
  --region $REGION \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.128.0/20 \
  --availability-zone ${REGION}a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=spring-api-vpc-subnet-private1-us-west-2a}]' \
  --query 'Subnet.SubnetId' \
  --output text)

SUBNET_PRIVATE_2=$(aws ec2 create-subnet \
  --region $REGION \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.144.0/20 \
  --availability-zone ${REGION}b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=spring-api-vpc-subnet-private2-us-west-2b}]' \
  --query 'Subnet.SubnetId' \
  --output text)

echo "Private subnets: $SUBNET_PRIVATE_1 $SUBNET_PRIVATE_2"

echo "Creating Internet Gateway..."

IGW_ID=$(aws ec2 create-internet-gateway \
  --region $REGION \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=spring-api-vpc-igw}]' \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)

echo "IGW: $IGW_ID"

aws ec2 attach-internet-gateway \
  --region $REGION \
  --internet-gateway-id $IGW_ID \
  --vpc-id $VPC_ID

echo "Creating public route table..."

RTB_PUBLIC=$(aws ec2 create-route-table \
  --region $REGION \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=spring-api-vpc-rtb-public}]' \
  --query 'RouteTable.RouteTableId' \
  --output text)

aws ec2 create-route \
  --region $REGION \
  --route-table-id $RTB_PUBLIC \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID

echo "Allocating Elastic IPs..."

EIP_ALLOC_1=$(aws ec2 allocate-address \
  --region $REGION \
  --domain vpc \
  --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=spring-api-vpc-eip-us-west-2a}]' \
  --query 'AllocationId' \
  --output text)

EIP_ALLOC_2=$(aws ec2 allocate-address \
  --region $REGION \
  --domain vpc \
  --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=spring-api-vpc-eip-us-west-2b}]' \
  --query 'AllocationId' \
  --output text)

echo "Creating NAT Gateways..."

NAT_1=$(aws ec2 create-nat-gateway \
  --region $REGION \
  --subnet-id $SUBNET_PUBLIC_1 \
  --allocation-id $EIP_ALLOC_1 \
  --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=spring-api-vpc-nat-public1-us-west-2a}]' \
  --query 'NatGateway.NatGatewayId' \
  --output text)

NAT_2=$(aws ec2 create-nat-gateway \
  --region $REGION \
  --subnet-id $SUBNET_PUBLIC_2 \
  --allocation-id $EIP_ALLOC_2 \
  --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=spring-api-vpc-nat-public2-us-west-2b}]' \
  --query 'NatGateway.NatGatewayId' \
  --output text)

echo "Waiting for NAT gateways..."

aws ec2 wait nat-gateway-available --region $REGION --nat-gateway-ids $NAT_1
aws ec2 wait nat-gateway-available --region $REGION --nat-gateway-ids $NAT_2

echo "Creating private route tables..."

RTB_PRIVATE_1=$(aws ec2 create-route-table \
  --region $REGION \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=spring-api-vpc-rtb-private1-us-west-2a}]' \
  --query 'RouteTable.RouteTableId' \
  --output text)

aws ec2 create-route \
  --region $REGION \
  --route-table-id $RTB_PRIVATE_1 \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id $NAT_1

RTB_PRIVATE_2=$(aws ec2 create-route-table \
  --region $REGION \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=spring-api-vpc-rtb-private2-us-west-2b}]' \
  --query 'RouteTable.RouteTableId' \
  --output text)

aws ec2 create-route \
  --region $REGION \
  --route-table-id $RTB_PRIVATE_2 \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id $NAT_2

echo "Adding route tables to VPC endpoint..."

aws ec2 modify-vpc-endpoint \
  --region $REGION \
  --vpc-endpoint-id $VPCE_ID \
  --add-route-table-ids $RTB_PRIVATE_1 $RTB_PRIVATE_2

echo "Done."