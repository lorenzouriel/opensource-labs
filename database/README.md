# sqlserver-lab

SQL Server 2025 (Developer) lab in Docker for DP-800 — *Developing AI-Enabled
Database Solutions*. No SQL Server installed on the host.

## Layout
```
database/
├── docker-compose.yml       prod1 (default); prod2 behind the ha profile;
│                            dev/staging behind the dev/staging profiles;
│                            db-build + db-deploy-* build & publish the schema
├── .env.example             copy to .env — SA password, ports, memory, APP_DB
├── .gitignore                keeps .env and .bak out of git
├── scripts/
│   ├── 01-restore.sql       restore a .bak, auto-derives MOVE targets
│   └── 02-ag-setup.sql      cert-based HADR endpoints + availability group
├── database/database/       SSDT SQL project (database.sqlproj, SDK-style) —
│                            Tables/, Security/, Stored Procedures/, Functions/
├── restore/                 ← drop .bak files here (mounted read-only)
└── backups/                 ← BACKUP DATABASE writes here
```

## One-time setup

```powershell
Copy-Item .env.example .env
New-Item -ItemType Directory -Force -Path restore, backups | Out-Null

# image runs non-root as uid 10001; fix ownership on the bind mounts via a
# throwaway container (no native chown on Windows)
docker run --rm -v "${PWD}:/data" busybox sh -c "chown -R 10001:0 /data/backups /data/restore && chmod 775 /data/backups"

notepad .env   # set MSSQL_SA_PASSWORD
```

Every session, load `.env` into the current PowerShell tab before running any
`sqlcmd`/`$env:` command below — `docker compose` reads `.env` on its own for
compose-file substitution, but the raw `sqlcmd` calls need it as a real
environment variable too:

```powershell
Get-Content .env | Where-Object { $_ -match '^\s*[^#].+?=' } | ForEach-Object {
    $name, $value = $_ -split '=', 2
    [Environment]::SetEnvironmentVariable($name.Trim(), $value.Trim())
}
```

---

## Use case 1 — prod1: start, restore, back up, deploy schema

```powershell
docker compose up -d prod1           # start
```

Plain `docker compose up` also brings up `db-build` and `db-deploy-prod1`
(neither is profile-gated) — see *Use case 2 — schema build & deploy* below.

Connect from SSMS / Azure Data Studio / DBeaver: `localhost,1401`, user `sa`,
**Trust server certificate = on** (the instance uses a self-signed cert). Or
from the shell:

```powershell
docker compose exec prod1 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$env:MSSQL_SA_PASSWORD" -C
```

**Restore a database.** Drop `billing.bak` into `./restore/`, then:

```powershell
$env:SEED_DB = "billing"; $env:SEED_BAK = "billing.bak"
docker compose --profile seed run --rm seed
```

`01-restore.sql` reads the backup header and generates the `MOVE` clauses, so
Windows-authored backups with `C:\` paths restore cleanly. It also forces
compat level 170 and turns on Query Store and preview features.

**Back up a database.** `BACKUP DATABASE` can't target the bind-mounted
`./backups/` folder directly on Docker Desktop for Windows (see *Why*
below), so back up into the `prod1-data` named volume and copy the file out:

```powershell
$env:DB = "billing"
docker compose exec prod1 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$env:MSSQL_SA_PASSWORD" -C -b -Q `
  "BACKUP DATABASE [$env:DB] TO DISK='/var/opt/mssql/data/$env:DB.bak' WITH INIT, COMPRESSION, STATS=10"
docker compose cp prod1:/var/opt/mssql/data/$env:DB.bak ./backups/$env:DB.bak
docker compose exec prod1 rm -f /var/opt/mssql/data/$env:DB.bak
```

---

## Use case 2 — schema build & deploy (SSDT project)

`database/database/database.sqlproj` is an SDK-style SQL project (converted
from the original VS/SSDT format via the `Microsoft.Build.Sql` NuGet SDK, so
it builds cross-platform with `dotnet build` — no Visual Studio needed). It
holds the app schema: `Security/` (schema definitions), `Tables/`, and
placeholders for `Stored Procedures/`/`Functions/`.

`db-build` (no profile, so it runs on every plain `up`) compiles the project
into `database.dacpac` and installs the `sqlpackage` CLI into a shared
`db-artifacts` volume. One `db-deploy-<name>` service per instance then runs
`sqlpackage /Action:Publish` against it — each gated behind the same profile
as its target instance, so it only fires when that instance is actually
coming up:

```powershell
docker compose up -d prod1                       # → runs db-build + db-deploy-prod1
docker compose --profile ha up -d prod2           # → also runs db-deploy-prod2
docker compose --profile dev up -d dev            # → also runs db-deploy-dev
docker compose --profile staging up -d staging    # → also runs db-deploy-staging
```

`sqlpackage /Action:Publish` creates the target database automatically if it
doesn't exist yet, then reconciles its schema to match the dacpac — safe to
re-run after editing any `.sql` file under `database/database/`. The database
name is `$env:APP_DB` (default `AppDB`) on every instance; override it in
`.env` if you want a different name.

To rebuild/redeploy without restarting the instance:

```powershell
docker compose up db-build db-deploy-prod1
```

---

## Use case 3 — prod2 + Availability Group

Two independent containers, no domain and no WSFC/Pacemaker, so this brings
up a `CLUSTER_TYPE = NONE` AG (manual failover only) using certificate-based
endpoint auth. `02-ag-setup.sql` hops between both instances with sqlcmd's
`:CONNECT`, exchanges HADR certs, opens the mirroring endpoints, and creates
`ag1` with automatic seeding — no manual backup/restore step needed for the
AG database itself.

```powershell
docker compose --profile ha up -d prod2         # bring up the secondary, localhost,1402
docker compose --profile ha run --rm ag-setup   # certs, endpoints, create + join ag1
```

`ag-setup` creates a small `agdb` database if one doesn't already exist
(override with `$env:AGDB = "yourdb"` before running, as long as that
database exists and is reachable on prod1). Seeding runs asynchronously —
check sync state:

```powershell
docker compose exec prod1 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$env:MSSQL_SA_PASSWORD" -C -Q `
  "SELECT ag.name, r.replica_server_name, rs.role_desc, drs.synchronization_state_desc, drs.is_local FROM sys.availability_groups ag JOIN sys.availability_replicas r ON ag.group_id = r.group_id JOIN sys.dm_hadr_availability_replica_states rs ON r.replica_id = rs.replica_id LEFT JOIN sys.dm_hadr_database_replica_states drs ON drs.replica_id = rs.replica_id;"
```

`role_desc` shows `PRIMARY`/`SECONDARY`; watch `synchronization_state_desc`
go from `SYNCHRONIZING` to `SYNCHRONIZED` on both rows once seeding catches
up (`database_state_desc` is normal to see as `NULL` for the non-local row —
only `synchronization_state_desc` is reliable cross-replica). There is no
listener (no virtual IP without a cluster manager) — connect to `prod1,1401`
or `prod2,1402` directly, or query `role_desc` to find the current primary.

---

## Use case 4 — dev and staging instances

Separate, isolated instances for a dev → staging → prod-like chain, all on
this one machine. Each is its own container with its own data volume, so
schema experiments in `dev` can't touch `staging`'s state and vice versa.

```powershell
docker compose --profile dev up -d dev          # localhost,1403
docker compose --profile staging up -d staging  # localhost,1404
```

Both mount `./scripts` and `./restore` like prod1, so `seed` profile restores
work against them too — just override `-S`/`$env:SEED_DB` target, since the
compose `seed` service is wired to prod1 by default. Neither runs
`MSSQL_ENABLE_HADR`, so they can't join the AG — they're plain standalone
instances. Both also get the app schema automatically via `db-deploy-dev` /
`db-deploy-staging` (see *Use case 2*).

---

## Use case 5 — AI: external model + vector columns (Azure OpenAI)

`sp_invoke_external_rest_endpoint` only works against endpoints with a
publicly-trusted TLS certificate — see *Known gaps* below for why a local
Ollama/self-signed setup doesn't work here. Azure OpenAI's embeddings
endpoint is publicly trusted, needs no extra cert plumbing, and matches the
exam wording. See `scripts/10-ai-model.sql` for the `CREATE DATABASE SCOPED
CREDENTIAL`, `CREATE EXTERNAL MODEL`, and vector column / `VECTOR_SEARCH`
patterns — fill in your own Azure OpenAI resource, deployment, and API key.

---

## Everyday commands

```powershell
docker compose ps                    # container status
docker compose logs -f prod1         # tail prod1 errorlog
docker compose restart prod1         # restart prod1
docker compose --profile ha --profile dev --profile staging down     # stop everything (volumes survive)
docker compose --profile ha --profile dev --profile staging down -v  # full reset — destroys volumes too
```

## Why the pieces are the way they are

**Developer, not Express.** Express caps the buffer pool at 1410 MB, databases
at 10 GB, and has no SQL Agent. Developer is free and gives you the full
Enterprise surface.

**Pinned to `2025-latest`.** The DP-800 blueprint is built on SQL Server 2025
features — `vector`, `CREATE EXTERNAL MODEL`, `AI_GENERATE_EMBEDDINGS`,
DiskANN, `sp_invoke_external_rest_endpoint`. None of it exists in 2022.

**`$$MSSQL_SA_PASSWORD` in the healthcheck.** A single `$` gets interpolated by
Compose at parse time, baking the plaintext password into the container config
where `docker inspect` shows it. `CMD-SHELL` + `$$` defers expansion to the
container's shell. `-C` is required or sqlcmd 18 fails the TLS handshake.

**`chown 10001:0` on the bind mounts.** The image runs non-root as uid 10001;
without it `BACKUP DATABASE` returns OS error 5 and restores can't read the file.

**Two backup folders.** `restore/` is read-only (source `.bak` files you bring
in), `backups/` is writable (what the engine produces). One folder means either
backups fail or the container can write to your source files.

**`BACKUP DATABASE` can't target `./backups/` directly on Docker Desktop for
Windows.** The engine pre-allocates the `.bak` file, then shrinks it to the
real size once the write completes — that final `DiskChangeFileSize` call
isn't supported through the Windows bind-mount passthrough and fails with OS
error 31 right at the finish line, after all the pages are already written.
Backing up into the `prod1-data` *named* volume (a real Linux filesystem
inside the Docker VM) and then `docker compose cp`-ing the file out works
fine — that's what Use case 1 and 3 above do.

**SDK-style `.sqlproj` instead of the original VS/SSDT format.** The original
project requires Visual Studio's SSDT workload (Windows-only) to build. The
`Microsoft.Build.Sql` SDK produces the same `.dacpac` via plain `dotnet build`,
so `db-build` can compile it inside a Linux container — no VS/SSDT install
needed anywhere, on the host or in Docker.

**`CLUSTER_TYPE = NONE` for the AG.** Real Always On needs a cluster manager
(WSFC or Pacemaker) for automatic failover; neither is worth standing up for
two containers on one Docker host. `NONE` gives a real AG — replication,
automatic seeding, `sys.dm_hadr_*` — with manual failover, which is enough
for the DP-800 HA/DR objectives. Endpoint auth uses certificates instead of
Windows auth for the same reason: prod1 and prod2 share no domain.

## Known gaps

**Always Encrypted with secure enclaves** needs VBS, which is Windows-only.
Basic Always Encrypted, RLS, DDM, and TDE all work here; the enclave scenarios
in domain 2 stay theoretical unless you spin up a Windows VM.

**Local Ollama behind a self-signed/local-CA proxy doesn't work with
`sp_invoke_external_rest_endpoint`.** An earlier version of this lab ran
Ollama behind Caddy (`tls internal`) and trusted Caddy's root CA via
`update-ca-certificates` in a custom prod1 image. `openssl`/`wget` inside the
container verified that chain fine, but `sp_invoke_external_rest_endpoint`
failed identically (`HRESULT: 0x80070008`) against that endpoint *and* against
a known-untrusted public self-signed site (`self-signed.badssl.com`) — proof
it isn't consulting the OS trust store `update-ca-certificates` populates,
even though `sqlservr` links the same `libssl.so.3`/`libcrypto.so.3` that
`openssl` uses. Setting `SSL_CERT_FILE`/`SSL_CERT_DIR`/`CURL_CA_BUNDLE` on the
container made no difference. Current build tested: SQL Server 2025
RTM-CU8 (17.0.4085.5). Net effect: this stored procedure only trusts
publicly-rooted CAs on this platform, so local/offline embedding endpoints
need a real publicly-trusted certificate (e.g. via ACME DNS-01) to work —
Azure OpenAI (Use case 5) sidesteps the problem entirely.
