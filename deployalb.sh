#!/bin/bash

set -e

REGION="us-west-2"
echo "Detecting VPC..."
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=spring-api-vpc-vpc" \
  --query 'Vpcs[0].VpcId' \
  --output text)

if [ -z "$VPC_ID" ]; then
  echo "Error: VPC not found. Make sure the VPC exists and has the tag Name=spring-api-vpc-vpc."
  exit 1
fi

echo "VPC_ID=$VPC_ID"

echo "Detecting public subnets..."
SUBNET_PUBLIC_1=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=spring-api-vpc-subnet-public1-us-west-2a" \
  --query 'Subnets[0].SubnetId' \
  --output text)

SUBNET_PUBLIC_2=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=spring-api-vpc-subnet-public2-us-west-2b" \
  --query 'Subnets[0].SubnetId' \
  --output text)

if [ -z "$SUBNET_PUBLIC_1" ] || [ -z "$SUBNET_PUBLIC_2" ]; then
  echo "Error: Public subnets not found. Make sure they exist with the correct tags."
  exit 1
fi

echo "Public subnets: $SUBNET_PUBLIC_1 $SUBNET_PUBLIC_2"

echo "Creating Target Group..."

TG_ARN=$(aws elbv2 create-target-group \
  --name spring-api-tg \
  --protocol HTTP \
  --port 8080 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --health-check-protocol HTTP \
  --health-check-port 8080 \
  --health-check-path "/api" \
  --region $REGION \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

echo "Target Group ARN: $TG_ARN"

echo "Creating Security Group..."

SG_ID=$(aws ec2 create-security-group \
  --group-name spring-api-alb-seg \
  --description "Security group for spring api alb" \
  --vpc-id $VPC_ID \
  --region $REGION \
  --query 'GroupId' \
  --output text)

echo "Security Group: $SG_ID"

echo "Adding inbound rules..."

aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 \
  --region $REGION

aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 8080 \
  --cidr 0.0.0.0/0 \
  --region $REGION

echo "Creating Application Load Balancer..."

ALB_ARN=$(aws elbv2 create-load-balancer \
  --name spring-api-alb \
  --type application \
  --scheme internet-facing \
  --subnets $SUBNET_PUBLIC_1 $SUBNET_PUBLIC_2 \
  --security-groups $SG_ID \
  --region $REGION \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)

echo "ALB ARN: $ALB_ARN"

echo "Waiting for ALB to become active..."

aws elbv2 wait load-balancer-available \
  --load-balancer-arns $ALB_ARN \
  --region $REGION

echo "Creating Listener..."

aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN \
  --region $REGION

echo "Application Load Balancer setup completed."
