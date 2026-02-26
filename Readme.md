# 🚀 **Ejercicio: CI/CD de una API de Spring Boot con GitHub Actions y AWS ECR y ECS**

## 🎯**Contexto**
Integración y despliegue continuo de una API Java creada con Spring Boot, utilizando los servicios de AWS **Elastic Container Registry (ECR)** y **Elastic Container Service (ECS)**.  
El despliegue se realizará en **AWS Fargate**, permitiendo ejecutar contenedores en modo *serverless* sin gestionar servidores.

---

## 🥅 **Objetivo**
Realizar el despliegue automatizado de la API mediante un pipeline CI/CD que construya la imagen Docker, la publique en ECR y actualice el servicio ECS con Fargate.

---

## 📦 **Tipo de aplicación**
- **Framework:** Spring Boot 4.x  
- **Lenguaje:** Java 21  
- **Tipo:** API REST

---

## ⛓️ Endpoints
| Método | Endpoint        | Descripción                         | Parámetros | Respuesta |
|--------|-----------------|-------------------------------------|------------|-----------|
| GET    | /api            | Endpoint base de la API             | —          | Retorna un text plano |

---

## 📌 **Prerequisitos**

- Cuenta en **GitHub**
- Cuenta de **Docker**
- Cliente de Docker instalado
- **AWS CLI** instalado y configurado (`aws configure`) (Entorno de pruebas proporcionará las credenciales)

---

## 🛠️ **Pasos a seguir**

### **1. Creación del Dockerfile**

Crea un archivo llamado `Dockerfile` en la raíz del proyecto.

---

### 🤖 **2. Crear el workflow de GitHub Actions**

Este workflow construira la pipeline. Deberías iniciar con la plantilla proporcionada por GitHub.
```
Archivo: `.github/workflows/deploy.yml`
```

Incluye pasos como:

- Checkout del repositorio  
- Configuración de AWS credenciales  
- Login en AWS ECR  
- Construcción, etiquetado y Push de la imagen en ECR
- Despliegue de la aplicación en ECS

---

### 🔐 Recuerda configurar los secretos en GitHub:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`

---

### ✅ **3. Comprobar la ejecución correcta**
- Verifica que el workflow en GitHub Actions finaliza sin errores.  
- Comprueba en AWS ECR que la imagen se ha subido correctamente.  
- Revisa en ECS que el servicio se ha actualizado y la tarea está en estado **RUNNING**.  
- Accede al endpoint público del servicio Fargate o del Load Balancer.
- Modifica el string de respuesta de la API (ver archivo HomeController.java)
- Realiza el push a 'main'
- Comprueba que la API se hayá actualizado.

---

## 🎉 **Resultado final**
Un pipeline CI/CD completamente funcional que:

- Construye la API de Spring Boot  
- Genera la imagen Docker  
- La publica en AWS ECR  
- Actualiza automáticamente el servicio ECS con Fargate  
- Permite un despliegue *serverless*, escalable y automatizado
