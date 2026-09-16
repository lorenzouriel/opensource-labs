# monitor

Observability stack in Docker — OpenTelemetry Collector, Prometheus, Loki,
Tempo, and Grafana, covering the three pillars (metrics, logs, traces) with
Grafana pre-wired to all three and trace-to-log/metric correlation enabled.

## Layout

```
monitor/
├── docker-compose.yml    otel-collector, prometheus, loki, tempo, grafana
├── config/
│   ├── otel-config.yaml       receivers/exporters/pipelines
│   ├── prometheus.yml         scrape targets
│   ├── loki-config.yaml       single-node, filesystem storage
│   ├── tempo-config.yaml      single-node, filesystem storage
│   └── grafana/provisioning/  datasources (auto-configured) + dashboards
├── docs/                 field-by-field notes on each config file
└── .gitignore
```

## One-time setup

```bash
docker compose up -d
```

Nothing else to configure — datasources and dashboards are provisioned
automatically on first boot.

## Everyday commands

```bash
docker compose ps                  # container status / healthchecks
docker compose logs -f grafana
docker compose restart otel-collector
docker compose down                # stop (volumes survive)
docker compose down -v             # full reset — destroys all data
```

## Access

- **Grafana**: http://localhost:3000 (`admin`/`admin`)
- **Prometheus**: http://localhost:9090
- **Loki**: http://localhost:3100
- **Tempo**: http://localhost:3200
- **OTel Collector**: `4317` (OTLP gRPC), `4318` (OTLP HTTP), `9464` (Prometheus metrics)

## Sending data in

Point any OpenTelemetry SDK at the collector
(`OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317`) — it fans out logs to
Loki, traces to Tempo, and metrics to its own Prometheus exporter. To scrape
an app directly instead, add a job to
[config/prometheus.yml](config/prometheus.yml):

```yaml
- job_name: 'my-app'
  static_configs:
    - targets: ['my-app:8000']
```

See [docs/](docs/) for a field-by-field breakdown of each config file.
