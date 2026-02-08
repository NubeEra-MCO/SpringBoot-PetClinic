# Deploy Containerized Web Application with MySQL and Take Backup
---

## **Step 1: Prepare directories**

```bash
mkdir -p ~/mujahed/mysqldata    # Persistent MySQL storage
mkdir -p ~/mujahed/webapp       # Petclinic application source
```

Clone the updated repository:

```bash
cd ~/mujahed/webapp
git clone https://github.com/NubeEra-MCO/SpringBoot-PetClinic.git .
```

---

## **Step 2: Install prerequisites**

```bash
sudo apt update
sudo apt install -y docker.io openjdk-17-jdk-headless maven
```

Verify installation:

```bash
java -version
javac -version
mvn --version
```

---

## **Step 3: Create Docker network**

```bash
docker network create mujahed-network
```

---

## **Step 4: Run MySQL container**

```bash
docker run -d \
  --name mujahed-mysql \
  --network mujahed-network \
  -e MYSQL_USER=mujahed \
  -e MYSQL_PASSWORD=123 \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=pcdb \
  -v ~/mujahed/mysqldata:/var/lib/mysql \
  -p 3300:3306 \
  mysql:9.5
```

Check MySQL container:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

---

## **Step 5: Access MySQL container and create users (optional)**

```bash
docker exec -it mujahed-mysql bash
```

Login as root:

```bash
mysql -u root -proot
```

Optional: grant privileges (if needed):

```sql
ALTER USER 'root'@'%' IDENTIFIED BY 'root';
ALTER USER 'mujahed'@'%' IDENTIFIED BY '123';
GRANT ALL PRIVILEGES ON pcdb.* TO 'mujahed'@'%';
FLUSH PRIVILEGES;
EXIT;
```

---

## **Step 6: Backup `pcdb` database**

**Option 1: Using container bash**

```bash
docker exec -it mujahed-mysql bash
mysqldump -u root -proot --single-transaction --routines --triggers pcdb > /tmp/pcdb.sql
exit
docker cp mujahed-mysql:/tmp/pcdb.sql ~/mujahed/pcdb.sql
```

**Option 2: Directly from host with timestamped backup**

```bash
docker exec mujahed-mysql \
  mysqldump -u root -proot \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  --set-gtid-purged=OFF \
  --databases pcdb \
  > ~/mujahed/pcdb_$(date +%F).sql
```

---

## **Step 7: Insert sample data into `types` table**

Login to MySQL:

```bash
docker exec -it mujahed-mysql bash
mysql -u mujahed -p123 pcdb
```

Run SQL commands:

```sql
INSERT INTO types (name) VALUES ('Dog');
INSERT INTO types (name) VALUES ('Cat');
INSERT INTO types (name) VALUES ('Bird');
EXIT;
```

---

## **Step 8: Notes on application-mysql.properties**

You **don’t need to put contents here**, but the file is located at:

```
~/mujahed/webapp/src/main/resources/application-mysql.properties
```

It should define MySQL connection details and port for Spring Boot.

---

✅ **Outcome:**

* MySQL container is running with database `pcdb`
* Persistent data stored at `~/mujahed/mysqldata`
* Database backup exists as `~/mujahed/pcdb.sql` or `~/mujahed/pcdb_YYYY-MM-DD.sql`
* Sample `types` data inserted
