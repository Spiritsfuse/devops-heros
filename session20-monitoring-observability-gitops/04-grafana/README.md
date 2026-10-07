# 04 - Grafana

Prometheus stores and queries metrics.

Grafana helps us **see** them.

Think:

```text
Prometheus = Data
Grafana    = Beautiful dashboard
```

---

# Architecture

```text
Application
     |
     v
 Prometheus
     |
     v
  Metrics
     |
     v
  Grafana
     |
     v
 Dashboard
```

---

# Start

```bash
docker compose up -d
```

#### 💡 Command Breakdown (`cmd-explained`):
- `docker compose`: Runs the multi-container stack defined in `docker-compose.yml`.
- `up`: Provisions both `prometheus` and `grafana` services simultaneously, creating a private user-defined Docker bridge network.
- `-d` (or `--detach`): Launches containers in the background, freeing your terminal shell while keeping both servers active.
- *What if `--build` is passed (`docker compose up -d --build`)?*: Re-builds any custom container images specified in compose service declarations before spinning up the containers.
- **Theory Connection**: Spins up both the metric store (Prometheus) and the visualization engine (Grafana) in isolated environments that can communicate over Docker's internal virtual network.

Check:

```bash
docker compose ps
```

#### 💡 Command Breakdown (`cmd-explained`):
- `ps`: Inspects and prints state of all services in the active Compose stack.
- Displays container status (e.g., `Up`), exposed ports, and mapped host ports (`9090:9090` for Prometheus, `3000:3000` for Grafana).

Expected shape:

```text
session20-prometheus    running
session20-grafana       running
```

Open:

```text
Prometheus:
http://localhost:9090

Grafana:
http://localhost:3000
```

---

# Grafana Login

For this classroom demo:

```text
Username: admin
Password: admin
```

Grafana may ask you to change the password after login.

Do not use these default credentials in production.

---

# Add Prometheus Data Source

Inside Grafana:

```text
Connections
   |
Data sources
   |
Add data source
   |
Prometheus
```

Use this URL:

```text
http://prometheus:9090
```

Important:

The Grafana container talks to the Prometheus container using the Docker Compose service name.

> **💡 Container Networking Explained:**
> If you typed `http://localhost:9090` inside Grafana's settings, the connection would **fail**. Why? Inside a container, `localhost` refers to *the Grafana container itself*, which is not running Prometheus. Because both containers run on the same Docker Compose network, Docker's embedded DNS resolves the service hostname `prometheus` directly to the Prometheus container's internal IP address!

Then click:

```text
Save & test
```

Expected:

```text
Successfully queried the Prometheus API.
```

The exact UI wording can vary by Grafana version.

---

# Create a Simple Dashboard

Create:

```text
Dashboard
   |
Add visualization
```

Select the Prometheus data source.

Query:

```text
up
```

#### 💡 Query Breakdown (`query-explained`):
- `up`: Instant vector returning the boolean health status of all scrape targets (`1` = healthy, `0` = unhealthy).
- In a Grafana **Stat** panel, returning `1` displays a bold green indicator representing system availability.

Choose a visualization such as:

```text
Stat
```

You should see:

```text
1
```

Meaning the Prometheus target is up.

---

# Why Grafana?

Imagine having:

```text
CPU
Memory
Requests
Errors
Latency
```

A dashboard can put everything together:

```text
+----------------+----------------+
| CPU            | Memory         |
| 72%            | 61%            |
+----------------+----------------+
| Requests/sec   | Error Rate     |
| 150            | 1.2%           |
+----------------+----------------+
| Latency                         |
| 230 ms                          |
+---------------------------------+
```

Humans understand pictures faster than raw numbers.

---

# Stop

```bash
docker compose down
```

#### 💡 Command Breakdown (`cmd-explained`):
- `down`: Gracefully sends SIGTERM to both Prometheus and Grafana containers, stops them, and tears down the Docker bridge network.

---

# Key Point

Remember:

```text
Prometheus -> collects/stores metrics
Grafana    -> visualizes metrics
```

---

### 📚 Tech Jargons Demystified:
- **Data Source**: A backend connection configured in Grafana that tells it where to fetch metrics, logs, or traces (e.g., Prometheus, Elasticsearch, Loki, AWS CloudWatch).
- **Panel**: A single visual tile on a Grafana dashboard (e.g., Time series graph, Gauge, Bar chart, Stat display).
- **Provisioning**: Storing Grafana dashboards and data source configs as YAML/JSON files in Git rather than clicking through the UI, ensuring infrastructure-as-code consistency.
- **Alerting**: Evaluating PromQL expressions periodically inside Grafana or Prometheus Alertmanager to fire notifications to Slack, PagerDuty, or Webhooks.
