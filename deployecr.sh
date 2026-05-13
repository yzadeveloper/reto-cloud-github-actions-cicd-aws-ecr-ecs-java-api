#!/bin/bash

set -e

# VARIABLES
REGION="us-west-2"
REPO_NAME="spring-api"
IMAGE_NAME="spring-api"
IMAGE_TAG="latest"

echo "Obteniendo AWS Account ID..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Account ID: $ACCOUNT_ID"

ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME"

echo "ECR URI: $ECR_URI"

echo "--------------------------------------"
echo "1️⃣ Construyendo imagen Docker"
echo "--------------------------------------"

docker build -t $IMAGE_NAME:$IMAGE_TAG .

echo "--------------------------------------"
echo "2️⃣ Creando repositorio ECR (si no existe)"
echo "--------------------------------------"

aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION >/dev/null 2>&1 || \
aws ecr create-repository \
  --repository-name $REPO_NAME \
  --region $REGION

echo "Repositorio listo"

echo "--------------------------------------"
echo "3️⃣ Login en ECR"
echo "--------------------------------------"

aws ecr get-login-password --region $REGION | \
docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

echo "--------------------------------------"
echo "4️⃣ Tag imagen"
echo "--------------------------------------"

docker tag $IMAGE_NAME:$IMAGE_TAG $ECR_URI:$IMAGE_TAG

echo "--------------------------------------"
echo "5️⃣ Subiendo imagen a ECR"
echo "--------------------------------------"

docker push $ECR_URI:$IMAGE_TAG

echo "--------------------------------------"
echo "✅ Imagen subida correctamente"
echo "--------------------------------------"

echo "URI de la imagen:"
echo "$ECR_URI:$IMAGE_TAG"
