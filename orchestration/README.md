# orchestration

Apache Airflow 3.1.3 lab in Docker — CeleryExecutor, Postgres, Redis, and a
StatsD → Prometheus metrics bridge. Includes the Weaviate provider and
LangChain so DAGs can drive RAG/vector-ingestion pipelines directly.

## Layout

```
orchestration/
├── docker-compose.yml    redis, postgres, airflow-{apiserver,scheduler,
│                         dag-processor,triggerer,worker,init,cli}, statsd-exporter
├── Dockerfile            apache/airflow:3.1.3 + build deps + requirements.txt
├── requirements.txt      weaviate provider, langchain, pyarrow, PyPDF2
├── statsd_mapping.yml    StatsD → Prometheus metric name/label mapping
├── .dockerignore / .gitignore
└── scripts/
    ├── backup-db.sh      pg_dump the airflow metadata DB, gzip, timestamp
    └── restore-db.sh     drop/recreate + restore from a backup file
```

`dags/`, `logs/`, `plugins/`, `config/`, and `include/` are bind-mounted into
every Airflow container but aren't part of the repo — `airflow-init` creates
them on first run.

## One-time setup

```bash
cp .env.example .env   # create if missing — see Required env vars below
mkdir -p backups
docker compose up airflow-init
```

`airflow-init` creates the mounted directories, chowns them to
`AIRFLOW_UID`, runs the DB migration, and creates the `_AIRFLOW_WWW_USER_*`
admin account, then exits — that's expected, not a failure.

### Required env vars (`.env`)

```
AIRFLOW_UID=50000
POSTGRES_USER=airflow
POSTGRES_PASSWORD=airflow
POSTGRES_DB=airflow
AIRFLOW__CORE__FERNET_KEY=            # python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
AIRFLOW__API_AUTH__JWT_SECRET=        # openssl rand -hex 32
_AIRFLOW_WWW_USER_USERNAME=admin
_AIRFLOW_WWW_USER_PASSWORD=admin
```

`POSTGRES_HOST` defaults to `postgres` (the compose service name) — only set
it if pointing at an external database.

## Everyday commands

```bash
docker compose up -d              # start everything (init runs first via depends_on)
docker compose ps                 # container status / healthchecks
docker compose logs -f airflow-scheduler
docker compose run --rm airflow-cli airflow dags list   # debug profile
docker compose down                # stop (volumes survive)
docker compose down -v             # full reset — destroys the postgres volume too
```

Webserver/API: `http://localhost:8080`. Prometheus scrape target (StatsD
metrics translated by `statsd-exporter`): `http://localhost:9102/metrics`.

## Backup / restore

```bash
./scripts/backup-db.sh              # writes ./backups/airflow_backup_<ts>.sql.gz
./scripts/restore-db.sh ./backups/airflow_backup_20260101_120000.sql.gz
```

`restore-db.sh` stops the Airflow services (leaving Postgres up), drops and
recreates `POSTGRES_DB`, restores from the given file, and restarts the
services. It prompts for confirmation before dropping anything.
`backup-db.sh` prunes backups older than `BACKUP_RETENTION_DAYS` (default 7).

## Why the pieces are the way they are

**CeleryExecutor + Redis, not LocalExecutor.** Gives real worker isolation
and horizontal scaling for parallel DAG runs, at the cost of needing a
broker — Redis is the lightest option for a single-host lab.

**`statsd-exporter` sits between Airflow and Prometheus.** Airflow only
speaks StatsD natively (`AIRFLOW__METRICS__STATSD_*`); `statsd_mapping.yml`
rewrites dotted StatsD names (`airflow.dagrun.<dag_id>.<run_type>.duration`)
into labeled Prometheus metrics so `dag_id`/`task_id`/`pool` become queryable
labels instead of being baked into the metric name.

**Weaviate provider + LangChain in `requirements.txt`.** This lab's DAGs are
meant to orchestrate document ingestion (PyPDF2 → LangChain text splitters →
Weaviate) rather than just move rows around — that's the intended use case
for the `airflow-worker` containers' extra build deps in the `Dockerfile`.

**`container_name: airflow-metabase-1` on the Postgres service.** The backup/
restore scripts target this container name directly via `docker exec`
instead of `docker compose exec`, so they work the same whether invoked from
a shell that has the compose project context loaded or not.
