#!/bin/bash
set -e

# -----------------------------
# VARIABLES
# -----------------------------
REGION="us-west-2"
REPO_NAME="spring-api"
IMAGE_TAG="latest"
STACK_NAME="spring-api-prod"
TEMPLATE_FILE="spring-api-prod.yaml"

# Obtener Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME"

echo "AWS Account ID: $ACCOUNT_ID"
echo "ECR URI: $ECR_URI"

# -----------------------------
# 1️⃣ Crear repositorio ECR si no existe
# -----------------------------
if ! aws ecr describe-repositories --repository-names "$REPO_NAME" --region $REGION >/dev/null 2>&1; then
  echo "Repositorio ECR no existe. Creando..."
  aws ecr create-repository --repository-name "$REPO_NAME" --region $REGION
else
  echo "Repositorio ECR ya existe."
fi

# -----------------------------
# 2️⃣ Login en ECR
# -----------------------------
echo "Logueando en ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URI

# -----------------------------
# 3️⃣ Build de la imagen Docker
# -----------------------------
echo "Construyendo imagen Docker..."
docker build -t "$REPO_NAME:$IMAGE_TAG" .

# -----------------------------
# 4️⃣ Tag de la imagen para ECR
# -----------------------------
docker tag "$REPO_NAME:$IMAGE_TAG" "$ECR_URI:$IMAGE_TAG"

# -----------------------------
# 5️⃣ Push a ECR
# -----------------------------
echo "Subiendo imagen a ECR..."
docker push "$ECR_URI:$IMAGE_TAG"

# -----------------------------
# 6️⃣ Desplegar/Actualizar stack CloudFormation
# -----------------------------
echo "Desplegando stack CloudFormation..."
aws cloudformation deploy \
  --template-file "$TEMPLATE_FILE" \
  --stack-name "$STACK_NAME" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides ContainerImage="$ECR_URI:$IMAGE_TAG"

# -----------------------------
# 7️⃣ Mostrar URL del ALB
# -----------------------------
ALB_URL=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='ALBEndpoint'].OutputValue" \
  --output text)

echo "--------------------------------------"
echo "✅ Despliegue completado!"
echo "URL de tu API Java: http://$ALB_URL"
echo "--------------------------------------"
