# object-storage

[RustFS](https://github.com/rustfs/rustfs) in Docker — an S3-compatible object
storage server written in Rust (Apache 2.0, MinIO-alternative), running as a
single node with 4 local data paths for erasure coding.

## Layout

```
object-storage/
├── docker-compose.yml    rustfs, volume-permissions (init), mc (client profile)
├── .env.example           credentials, ports, image tag
└── .gitignore             keeps .env out of git
```

Data lives in named Docker volumes (`rustfs-data-0..3`, `rustfs-logs`), not
bind mounts — RustFS writes as uid/gid `10001:10001`, and named volumes avoid
the host-permission dance that bind mounts need for that.

## One-time setup

```bash
cp .env.example .env   # edit RUSTFS_ACCESS_KEY / RUSTFS_SECRET_KEY at minimum
docker compose up -d
```

`volume-permissions` runs once, chowns the data/log volumes to `10001:10001`,
and exits — that's expected, not a failure. `rustfs` starts after it
completes.

## Everyday commands

```bash
docker compose ps                  # container status / healthcheck
docker compose logs -f rustfs
docker compose down                # stop (volumes survive)
docker compose down -v             # full reset — destroys all data
```

Console UI: `http://localhost:9001` (login with `RUSTFS_ACCESS_KEY` /
`RUSTFS_SECRET_KEY`). S3 API endpoint: `http://localhost:9000`.

## Using the S3 API

Any S3 SDK/CLI works against `http://localhost:9000` with path-style
addressing. The `mc` (MinIO Client) profile is included for quick checks
without installing anything locally (`quay.io/minio/mc` — Docker Hub's
`minio/mc` was retired):

```bash
docker compose --profile client run --rm mc mb rustfs/test-bucket
echo "hello rustfs" | docker compose --profile client run --rm -T mc pipe rustfs/test-bucket/hello.txt
docker compose --profile client run --rm mc ls rustfs/test-bucket
```

(`pipe` avoids mounting a host file into the one-shot `mc` container; to copy
a real local file instead, add a bind mount to the `mc` service and use
`mc cp`.)

`MC_HOST_rustfs` (set in the `mc` service) encodes the endpoint and
credentials, so `rustfs/<bucket>` is all each command needs.
