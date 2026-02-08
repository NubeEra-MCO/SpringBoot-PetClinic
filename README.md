# **Deploy Containerized Web Application with PostgreSQL and Take Backup**

---

## **Step 1: Prepare directories**

Create directories for persistent database storage and web app source:

```bash
mkdir -p ~/mujahed/pgdata       # Persistent PostgreSQL storage
mkdir -p ~/mujahed/webapp       # Petclinic application source
```

Clone the updated repository:

```bash
cd ~/mujahed/webapp
git clone --branch postgresql  https://github.com/NubeEra-MCO/SpringBoot-PetClinic.git .
```

---

## **Step 2: Install prerequisites**

Install Docker, Java 17, and Maven:

```bash
sudo apt update
sudo apt install -y docker.io openjdk-17-jdk-headless maven
sudo chmod 777 /var/run/docker*
```

Verify installations:

```bash
java -version
javac -version
mvn --version
docker info
```

---

## **Step 3: Create Docker network**

Create a network for PostgreSQL and web app communication:

```bash
docker network create mujahed-network
```

---

## **Step 4: Run PostgreSQL container**

Start PostgreSQL container with persistent storage:

```bash
docker run -d \
  --name mujahed-postgres \
  --network mujahed-network \
  -e POSTGRES_USER=mujahed \
  -e POSTGRES_PASSWORD=123 \
  -e POSTGRES_DB=pcdb \
  -v ~/mujahed/pgdata:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:16
```

Verify container status:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

---

## **Step 5: Access PostgreSQL container (optional)**

Enter the container:

```bash
docker exec -it mujahed-postgres bash
```

Login as user:

```bash
psql -U mujahed -d pcdb
```

*You can create additional users or modify privileges here if needed.*

---

## **Step 6: Backup `pcdb` database**

**Option 1: Inside container**

```bash
docker exec -it mujahed-postgres bash
pg_dump -U mujahed pcdb > /tmp/pcdb.sql
exit
docker cp mujahed-postgres:/tmp/pcdb.sql ~/mujahed/pcdb.sql
```

**Option 2: Directly from host with timestamp**

```bash
docker exec mujahed-postgres \
  pg_dump -U mujahed pcdb \
  > ~/mujahed/pcdb_$(date +%F).sql
```

---

## **Step 7: Insert sample data into `types` table**

Login to PostgreSQL:

```bash
docker exec -it mujahed-postgres psql -U mujahed -d pcdb
```

Insert sample records:

```sql
INSERT INTO types (name) VALUES ('Dog');
INSERT INTO types (name) VALUES ('Cat');
INSERT INTO types (name) VALUES ('Bird');
\q
```

---

## **Step 8: Notes on `application-postgres.properties`**

File location:

```
~/mujahed/webapp/src/main/resources/application-postgres.properties
```

It should define PostgreSQL connection details and Spring Boot server port (e.g., 8000).

Example:

```properties
spring.datasource.url=jdbc:postgresql://mujahed-postgres:5432/pcdb
spring.datasource.username=mujahed
spring.datasource.password=123
server.port=8000
```

---

## **Step 9: Build, Tag, and Push Docker Image (PostgreSQL version)**

1. **Build Spring Boot app with Maven**:

```bash
cd ~/mujahed/webapp
mvn clean package -DskipTests
```

2. **Dockerfile** (already provided):

```dockerfile
FROM eclipse-temurin:17-jre

WORKDIR /app

# Copy pre-built jar
COPY target/*.jar app.jar

# Expose Spring Boot port
EXPOSE 8000

# Run with postgres profile
ENTRYPOINT ["java", "-Dspring.profiles.active=postgres", "-jar", "app.jar", "--server.port=8000"]
```

3. **Build Docker image**:

```bash
docker build -t mujahed-pcwebapp-postgres:v1 .
```

4. **Tag image for Docker Hub**:

```bash
docker tag mujahed-pcwebapp-postgres:v1 mujahed/springboot-postgres:v1
```

5. **Push image to Docker Hub**:

```bash
docker push mujahed/springboot-postgres:v1
```

6. **Verify image locally**:

```bash
docker images | grep postgres
```

---

## **Step 10: Run the Web Application container**

Run Spring Boot web app container connected to PostgreSQL network:

```bash
docker run -d \
  --name mujahed-pcwebapp \
  --network mujahed-network \
  -p 8000:8000 \
  mujahed/springboot-postgres:v1
```

Verify container is running:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

Now your web app should be accessible at:

```
http://localhost:8000
```

---

## **Outcome**

* PostgreSQL container running with database `pcdb`
* Persistent data stored at `~/mujahed/pgdata`
* Database backup exists as `~/mujahed/pcdb.sql` or `~/mujahed/pcdb_YYYY-MM-DD.sql`
* Sample `types` data inserted
* Docker image built for PostgreSQL profile, tagged, and pushed to Docker Hub
* Web application container running and accessible on port 8000

---