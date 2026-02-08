FROM eclipse-temurin:17-jre

WORKDIR /app

# Copy pre-built jar
COPY target/*.jar app.jar

# Expose Spring Boot port
EXPOSE 8000

# Run with mysql profile
ENTRYPOINT ["java", "-Dspring.profiles.active=mysql", "-jar", "app.jar", "--server.port=8000"]
