# 03 - Prometheus

Prometheus is a monitoring and observability tool focused mainly on metrics.

Think:

> "Prometheus goes around asking applications: 'Give me your metrics.'"

---

# Architecture

```text
Application
    |
    | /metrics
    v
Prometheus
    |
    v
Time-series data
```

Prometheus commonly **pulls/scrapes** metrics.

---

# What Is a Metric?

Example:

```text
http_requests_total 150
```

Prometheus stores values over time.

Imagine:

```text
10:00 -> 100 requests
10:01 -> 120 requests
10:02 -> 150 requests
```

Now we can graph the number.

---

# Start Prometheus

Make sure Docker is running.

```bash
docker compose up -d
```

#### 💡 Command Breakdown (`cmd-explained`):
- `docker compose`: The command to manage multi-container Docker applications defined in a `docker-compose.yml` file.
- `up`: Builds, creates, starts, and attaches to containers defined in the Compose file. If the network or volumes don't exist yet, it creates them automatically.
- `-d` (or `--detach`): Runs containers in the background (**detached mode**) and leaves them running, printing container IDs and immediately releasing your shell prompt so you can continue typing commands.
- *What if `--build` is added (`docker compose up -d --build`)?*: Forces Docker Compose to re-read any local `Dockerfile`s and rebuild container images from scratch before starting containers, bypassing previously cached image layers.
- **Theory Connection**: Instantiates Prometheus as an isolated, containerized server with persistent storage bindings and port mappings defined declaratively.

Check:

```bash
docker compose ps
```

#### 💡 Command Breakdown (`cmd-explained`):
- `ps`: Lists the process status of all containers belonging to the current Compose project.
- Displays container name, command, operational state (`running`, `exited`), health check status, and port bindings (e.g., `0.0.0.0:9090->9090/tcp`).
- **Theory Connection**: Verifies that Prometheus initialized successfully and bound its HTTP listener to host port 9090.

Expected shape:

```text
NAME                    STATUS
session20-prometheus    running
```

Open:

```text
http://localhost:9090
```

---

# Check Prometheus Metrics

Open:

```text
http://localhost:9090/metrics
```

You will see Prometheus's own metrics.

You can also query:

```text
up
```

In the Prometheus UI.

Expected result contains:

```text
up{instance="prometheus:9090",job="prometheus"} 1
```

`1` means the target is up.

---

# Query Examples

Try:

```text
up
```

#### 💡 Query Breakdown (`query-explained`):
- **Type**: Instant Vector Selector.
- **Meaning**: Evaluates the health status of every configured scrape job right now.
- `1` = Target is reachable and HTTP `/metrics` returned HTTP 200 OK within the scrape timeout.
- `0` = Target is down or scrape timed out.

Then:

```text
prometheus_http_requests_total
```

#### 💡 Query Breakdown (`query-explained`):
- **Type**: Counter Metric.
- **Meaning**: Tracks the cumulative total count of HTTP requests served by the Prometheus web server since container startup.
- Because it is a **Counter**, this number is monotonically increasing (it only goes up or resets to 0 if Prometheus restarts).

Then:

```text
process_cpu_seconds_total
```

#### 💡 Query Breakdown (`query-explained`):
- **Type**: Counter Metric.
- **Meaning**: Total user and system CPU time spent by the Prometheus process in seconds.
- Used with functions like `rate(process_cpu_seconds_total[1m])` to calculate real-time CPU percentage consumption.

The exact number of returned series changes as Prometheus runs.

---

# Important Prometheus Words

```text
Target
Scrape
Metric
Label
Query
```

Example:

```text
Prometheus
    |
    +-- Target: application
    |
    +-- Scrape: GET /metrics
    |
    +-- Store: time-series
    |
    +-- Query: PromQL
```

---

# PromQL

PromQL is Prometheus Query Language.

Simple:

```text
up
```

Aggregation example:

```text
sum(up)
```

#### 💡 Query Breakdown (`query-explained`):
- `sum(...)`: Aggregation operator. Adds together the sample values of all time-series returned by the enclosed expression.
- If you are scraping 5 microservices and all are healthy (`up=1`), `sum(up)` returns `5`. If one fails, it drops to `4`.

For a beginner, remember:

> PromQL is the language we use to ask Prometheus questions.

---

# Stop

```bash
docker compose down
```

#### 💡 Command Breakdown (`cmd-explained`):
- `down`: Stops all running containers defined in the Compose file, and cleanly removes containers and networks created by `up`.
- *Note on persistent data*: To also wipe named volumes (erasing recorded time-series metric databases), you would append `-v` (`docker compose down -v`). Without `-v`, data volumes persist across restarts.

---

### 📚 Tech Jargons Demystified:
- **Pull vs Push Model**: Prometheus uses a **Pull model**—it reaches out over HTTP at regular intervals (`scrape_interval`, e.g., every 15s) to fetch `/metrics` endpoints. In contrast, push systems require apps to actively send data to a central collector.
- **Time-Series Data**: A sequence of data points indexed in successive time order, composed of: Metric Name + Label Key/Value pairs + Timestamp + Float64 sample value.
- **Exporter**: A lightweight sidecar or agent that translates non-Prometheus metrics into Prometheus-formatted metrics (e.g., `node_exporter` for Linux host metrics, `blackbox_exporter` for endpoint probing).
- **Gauge vs Counter**:
  - **Counter**: Value only increases (e.g., total requests, errors).
  - **Gauge**: Value can fluctuate up and down (e.g., current memory usage, temperature, active concurrent connections).


# Practice

Answer:

1. What does Prometheus collect?
2. What is a scrape?
3. What does `up` mean?
4. What is PromQL?
5. Is Prometheus primarily a metrics system or a log storage system?

Expected:

```text
Metrics
Scrape = collecting metrics
up = target health
PromQL = query language
Metrics
```
