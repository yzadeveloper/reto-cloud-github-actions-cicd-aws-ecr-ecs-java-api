# ===== STAGE 1: COMPILAR LA APP =====
FROM eclipse-temurin:21 AS build
WORKDIR /app

# 1) Copiamos primero archivos de build para aprovechar cache de Docker
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# 2) Damos permisos y descargamos dependencias
RUN chmod +x mvnw && ./mvnw -q -DskipTests dependency:go-offline

# 3) Copiamos el código fuente
COPY src src

# 4) Compilamos y empaquetamos (genera el .jar)
RUN ./mvnw -q -DskipTests package

# ===== STAGE 2: IMAGEN FINAL DE EJECUCIÓN =====
FROM eclipse-temurin:21-jre
WORKDIR /app

# Copiamos el jar generado en el stage anterior
COPY --from=build /app/target/*.jar app.jar

# Spring Boot normalmente escucha en 8080
EXPOSE 8080

# Comando de arranque del contenedor
ENTRYPOINT ["java", "-jar", "app.jar"]