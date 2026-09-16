# lakehouse

Apache Iceberg (REST catalog) + Trino in Docker, using `object-storage`'s
rustfs as the warehouse — a MinIO/S3-compatible lakehouse stack.

## Layout

```
lakehouse/
├── docker-compose.yml       bucket-init (init), iceberg-rest, trino
├── trino/catalog/
│   └── iceberg.properties   Trino's iceberg connector, wired to the REST catalog + rustfs
├── duckdb-client/           native (no Docker) query path — see its README
├── .env.example
└── .gitignore
```

## Why REST catalog

`iceberg-rest` (tabulario image) is the Iceberg REST Catalog spec's reference
implementation — any REST-catalog-aware engine (Trino, Spark, DuckDB,
PyIceberg) can share the same tables without a Hive Metastore. If you later
want Git-like table branching/tagging across engines, swap it for
[Project Nessie](https://projectnessie.org/) or
[Apache Polaris](https://polaris.apache.org/) — both speak the same REST
protocol, so `iceberg.rest-catalog.uri` in `trino/catalog/iceberg.properties`
is the only thing that changes on the Trino side.

## One-time setup

Requires `object-storage`'s stack running first (Trino/iceberg-rest resolve
`rustfs` by joining its Docker network):

```bash
cd ../object-storage && docker compose up -d && cd -

cp .env.example .env   # match RUSTFS_ACCESS_KEY/SECRET_KEY to object-storage/.env
docker compose up -d
```

`bucket-init` creates the `warehouse` bucket on rustfs and exits — expected,
not a failure.

## Everyday commands

```bash
docker compose ps                  # container status / healthchecks
docker compose logs -f trino
docker compose down                # stop (rustfs data untouched, it's a separate stack)
```

Trino UI: `http://localhost:8080`. Iceberg REST catalog API:
`http://localhost:8181`.

## Quick test

```bash
docker exec -it trino trino

trino> CREATE SCHEMA iceberg.lab WITH (location = 's3://warehouse/lab/');
trino> CREATE TABLE iceberg.lab.events (id BIGINT, name VARCHAR, ts TIMESTAMP(6));
trino> INSERT INTO iceberg.lab.events VALUES (1, 'hello', now());
trino> SELECT * FROM iceberg.lab.events;
```

Check the data landed in rustfs (from `object-storage/`):

```bash
docker compose --profile client run --rm mc ls rustfs/warehouse/lab/events/data
```

## Querying without a server

`duckdb-client/` reads the same warehouse straight from the host — no
Trino/JVM needed, good for quick local exploration. See
[duckdb-client/README.md](duckdb-client/README.md).

## Notes

- `fs.native-s3.enabled` + `s3.*` properties are Trino's current
  (post-435-ish) native S3 filesystem config. If you pin an older Trino
  version, use the legacy `hive.s3.*` property names instead.
- Credentials/bucket name flow through `${ENV:...}` substitution in
  `iceberg.properties` — Trino resolves those from the container's
  environment at startup, so there's one source of truth (`.env`) instead of
  duplicating values in the properties file.
