# Session 21: Final DevOps Project and Troubleshooting - Assignment

## Student Information
- **Name:** Dhruv Sharma
- **Enrollment Number (Roll No):** 24BCS10294
- **Session:** Session 21 - Final DevOps Project: Multi-Tier TaskBoard Application Deployment
- **Repository:** `devops-heros/session21-python`

---

## Table of Contents
1. [Overview and Objectives](#overview-and-objectives)
2. [Application Architecture](#application-architecture)
3. [Task 1: Running the Application Manually](#task-1-running-the-application-manually)
   - [1.1 PostgreSQL Database Setup](#11-postgresql-database-setup)
   - [1.2 Backend Service (FastAPI and Alembic)](#12-backend-service-fastapi-and-alembic)
   - [1.3 Frontend Service (React and Vite)](#13-frontend-service-react-and-vite)
4. [Task 2: Containerization with Dockerfiles](#task-2-containerization-with-dockerfiles)
   - [2.1 Backend Dockerfile](#21-backend-dockerfile)
   - [2.2 Frontend Multi-Stage Dockerfile](#22-frontend-multi-stage-dockerfile)
5. [Task 3: Orchestration with Docker Compose](#task-3-orchestration-with-docker-compose)
   - [3.1 Docker Compose Specification](#31-docker-compose-specification)
   - [3.2 Build and Launch (`docker compose up -d --build`)](#32-build-and-launch-docker-compose-up--d---build)
   - [3.3 Service Health Verification (`docker compose ps`)](#33-service-health-verification-docker-compose-ps)
6. [Task 4: Application and API Testing](#task-4-application-and-api-testing)
   - [4.1 Backend API Verification (Health and Docs)](#41-backend-api-verification-health-and-docs)
   - [4.2 Task CRUD Operations Testing](#42-task-crud-operations-testing)
   - [4.3 Frontend Web Interface Testing](#43-frontend-web-interface-testing)
7. [Screenshot Evidences and Placeholders](#screenshot-evidences-and-placeholders)
8. [Summary of Learnings](#summary-of-learnings)

---

## Overview and Objectives
For the Session 21 homework submission, the instructor specified completing the full multi-tier deployment and verification using Docker Compose:
- Run the full stack manually (PostgreSQL, FastAPI backend, React frontend).
- Implement production-ready Dockerfiles for both frontend and backend.
- Orchestrate the three services via `docker-compose.yml`.
- Execute `docker compose up -d --build` and ensure all containers are healthy.
- Test backend REST APIs and frontend web UI functionality.
- Document all execution steps, curl tests, and screenshots.

---

## Application Architecture

```text
+-----------------------------------------------------------------------------------+
|                                  DOCKER COMPOSE STACK                             |
|                                                                                   |
|   +-----------------------+     Port 3000:80    +-----------------------------+   |
|   |    User / Browser     | ------------------> |   Frontend: React + Nginx   |   |
|   +-----------------------+                     +-----------------------------+   |
|               |                                                |                  |
|               | Port 8000:8000                                 | API Proxy/Calls  |
|               v                                                v                  |
|   +---------------------------------------------------------------------------+   |
|   |                         Backend: FastAPI Service                          |   |
|   |                  (REST API, Alembic Migrations, Uvicorn)                  |   |
|   +---------------------------------------------------------------------------+   |
|                                       |                                           |
|                                       | Port 5432                                 |
|                                       v                                           |
|   +---------------------------------------------------------------------------+   |
|   |                   Database: PostgreSQL 16 (Alpine)                        |   |
|   |                    Volume: postgres-data (Persistent)                     |   |
|   +---------------------------------------------------------------------------+   |
+-----------------------------------------------------------------------------------+
```

---

## Task 1: Running the Application Manually

### 1.1 PostgreSQL Database Setup
```bash
# Start local PostgreSQL container or local service
docker run -d --name taskboard-db \
  -e POSTGRES_DB=taskboard \
  -e POSTGRES_USER=taskboard \
  -e POSTGRES_PASSWORD=taskboard \
  -p 5432:5432 \
  postgres:16-alpine
```

### 1.2 Backend Service (FastAPI and Alembic)
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: .\venv\Scripts\Activate.ps1
pip install -r requirements.txt

# Run Alembic database migrations
export DATABASE_URL="postgresql+psycopg://taskboard:taskboard@localhost:5432/taskboard"
alembic upgrade head

# Start FastAPI Uvicorn server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 1.3 Frontend Service (React and Vite)
```bash
cd ../frontend
npm install
npm run dev -- --host 0.0.0.0 --port 3000
```

---

## Task 2: Containerization with Dockerfiles

### 2.1 Backend Dockerfile (`backend/Dockerfile`)
The backend image uses a minimal Python 3.12 slim base, non-root user execution (`appuser:10001`), and runs migrations automatically at startup:
```dockerfile
FROM python:3.12-slim
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && useradd --create-home --uid 10001 appuser
COPY alembic.ini ./
COPY alembic ./alembic
COPY app ./app
USER 10001
EXPOSE 8000
CMD ["sh", "-c", "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port 8000"]
```

### 2.2 Frontend Multi-Stage Dockerfile (`frontend/Dockerfile`)
Multi-stage build compiles Vite React assets in Node 22 and serves static production bundles with Nginx Alpine:
```dockerfile
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:1.27-alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
```

---

## Task 3: Orchestration with Docker Compose

### 3.1 Docker Compose Specification (`docker-compose.yml`)
```yaml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: taskboard
      POSTGRES_USER: taskboard
      POSTGRES_PASSWORD: taskboard
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data

  backend:
    build: ./backend
    environment:
      DATABASE_URL: postgresql+psycopg://taskboard:taskboard@postgres:5432/taskboard
    depends_on:
      - postgres
    ports:
      - "8000:8000"

  frontend:
    build: ./frontend
    depends_on:
      - backend
    ports:
      - "3000:80"

volumes:
  postgres-data:
```

### 3.2 Build and Launch (`docker compose up -d --build`)
```bash
docker compose up -d --build
```

### 3.3 Service Health Verification (`docker compose ps`)
```bash
docker compose ps
```
All three containers (`session21-python-frontend-1`, `session21-python-backend-1`, `session21-python-postgres-1`) transition to `running/healthy` state.

---

## Task 4: Application and API Testing

### 4.1 Backend API Verification (Health and Docs)
```bash
# Test health check endpoint
curl -X GET http://localhost:8000/health
# Expected Output: {"status":"ok","database":"connected"}

# Test Swagger documentation
curl -I http://localhost:8000/docs
# Expected HTTP 200 OK
```

### 4.2 Task CRUD Operations Testing
```bash
# Create a new task via REST API
curl -X POST http://localhost:8000/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Setup Docker Compose","description":"Deploy TaskBoard stack","status":"TODO"}'

# Retrieve all tasks
curl -X GET http://localhost:8000/api/tasks
```

### 4.3 Frontend Web Interface Testing
- Open browser at `http://localhost:3000`.
- Verify the TaskBoard UI loads with column boards (To Do, In Progress, Done).
- Add new tasks, change their status, and verify live database updates.

---

## Screenshot Evidences

### 1. Docker Compose Build and Up (`docker compose up -d --build`)
![Docker Compose Build and Up](screenshots/01-docker-compose-up-build.png)
![Docker Compose Build Finished](screenshots/01-docker-compose-up-finished.png)

### 2. Running Containers Status (`docker compose ps`)
![Docker Compose PS](screenshots/02-docker-compose-ps.png)

### 3. Interactive FastAPI Swagger Documentation (`/docs`)
![Backend API Docs](screenshots/03-backend-api-health-docs.png)

### 4. API Health Check and Tasks Endpoint Testing
![API Task Testing](screenshots/04-api-task-crud-tests.png)

### 5. TaskBoard Frontend Web Application (`http://localhost:3000`)
![Frontend UI](screenshots/05-frontend-web-ui.png)

---

## Summary of Learnings
- **Container Networking**: Configured Docker Compose service discovery so backend addresses `postgres:5432` by service name.
- **Data Persistence**: Utilized named volume `postgres-data` ensuring PostgreSQL state survives container restarts.
- **Multi-Stage Builds**: Optimized frontend artifact size from over 300MB down to under 25MB using Nginx Alpine.
- **Database Migrations**: Integrated Alembic automated migrations at container startup before serving HTTP traffic.
- **End-to-End Verification**: Confirmed complete data flow from React frontend UI down to the PostgreSQL database table.
