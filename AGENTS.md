# AGENTS.md

Notes for running this repository in the Base44 sandbox. Everything here is a
finding you would not get from the manifests alone.

## What this repository is

`RuoYi-Cloud` **backend only** (Spring Cloud microservices, Java 17, Spring Boot
4.1.0 / Spring Cloud 2025.1.2). The admin UI (`ruoyi-ui`) is a **separate repository**
(Vue 2/3); it is not part of this checkout and `docker/nginx/html/dist/` only contains a
placeholder. `docker/docker-compose.yml` expects prebuilt jars dropped into
`docker/ruoyi/*/jar/`, so it cannot run the current source — use
`docker-compose.base44.yml` instead.

Modules: `ruoyi-gateway` (8080), `ruoyi-auth` (9200), `ruoyi-modules/ruoyi-system`
(9201), `ruoyi-gen` (9202), `ruoyi-job` (9203), `ruoyi-file` (9300),
`ruoyi-visual/ruoyi-monitor` (9100).

## Running it

```bash
docker compose -f docker-compose.base44.yml up -d      # first run: ~6 min Maven build
docker compose -f docker-compose.base44.yml ps         # every service should be (healthy)
```

* The one-shot `build` service runs `mvn -DskipTests package` against the bind-mounted
  repo and writes the jars into `./<module>/target/`. Compose waits for it before starting
  the application services, so `up -d` blocks until the build finishes.
* **There is no hot reload for Java.** After editing Java source, rebuild and restart the
  affected service:
  `docker compose -f docker-compose.base44.yml run --rm build`
  then `docker compose -f docker-compose.base44.yml up -d <service>`.
  `reload_preview` afterwards.
* Runtime images are `maven:3.9-eclipse-temurin-17` (same base as the build, so the JDK and
  `curl` for healthchecks are guaranteed to be present).

## Configuration lives in Nacos, not in the repo

Each service's `src/main/resources/bootstrap.yml` only holds `server.port` and Nacos
addresses; **all real configuration is fetched from the Nacos config centre**
(`application-dev.yml` + `<service>-dev.yml`). Those configs are seeded into the MySQL
database `ry-config` from `sql/ry_config_20260918.sql` on first MySQL start.

Consequences:

* The seeded configs point at `localhost` for MySQL and Redis. The compose file therefore
  passes `SPRING_DATA_REDIS_HOST`, `SPRING_DATASOURCE_DYNAMIC_DATASOURCE_MASTER_URL` /
  `SPRING_DATASOURCE_URL` etc. as environment variables, which outrank the imported Nacos
  config. If a service cannot reach MySQL/Redis, that override — not the Nacos config — is
  what to check.
* The same reason: `file.path` / `file.domain` from Nacos are Windows paths, overridden with
  `FILE_PATH` / `FILE_DOMAIN`.
* Bootstrap YAML binds Nacos at `127.0.0.1:8848`; compose overrides it with
  `SPRING_CLOUD_NACOS_{DISCOVERY,CONFIG}_SERVER_ADDR=nacos:8848`.
* MySQL init scripts (`sql/*.sql`) run **only when the `mysql-data` volume is empty**. To
  re-seed from scratch: `docker compose -f docker-compose.base44.yml down -v` (destroys data).

## Verifying it works

```bash
# services registered in Nacos (expect 7: gateway, auth, system, gen, job, file, monitor)
docker exec ruoyi-cloud-base44-nacos-1 \
  curl -s "http://127.0.0.1:8848/nacos/v1/ns/service/list?pageNo=1&pageSize=30"

# web entry point (placeholder page, /prod-api/ proxied to the gateway)
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:3000/
curl -s -H 'Accept: text/plain' http://localhost:3000/prod-api/code   # captcha
```

### The captcha is served by the gateway, not by ruoyi-auth

`RouterFunctionConfiguration` maps `GET /code` to `ValidateCodeHandler` in **ruoyi-gateway**.
Because it is a WebFlux `RouterFunction` it is handled before the gateway's `AuthFilter`, so
it needs no token — that is why `/code` is absent from `security.ignore.whites`. Through the
web entry point the URL is `/prod-api/code`. There is no `/auth/code` endpoint.

Login is captcha-protected (`security.captcha.enabled: true` in `ruoyi-gateway-dev.yml`), so
a scripted login must fetch `/prod-api/code` first and read the issued answer from Redis
(`captcha_codes:<uuid>`) before POSTing `/prod-api/auth/login`. Documented default account:
`admin` / `admin123` (see README).

End-to-end check that exercises the whole chain (nginx → gateway → auth → redis → Feign →
ruoyi-system → MySQL):

```bash
BASE=http://localhost:3000/prod-api
RESP=$(curl -s -H 'Accept: text/plain' "$BASE/code")
UUID=$(echo "$RESP" | python3 -c 'import sys,json;print(json.load(sys.stdin)["uuid"])')
CODE=$(docker exec ruoyi-cloud-base44-redis-1 redis-cli --raw get "captcha_codes:$UUID" | tr -d '"')
TOKEN=$(curl -s -X POST "$BASE/auth/login" -H 'Content-Type: application/json' \
  -d "{\"username\":\"admin\",\"password\":\"admin123\",\"code\":\"$CODE\",\"uuid\":\"$UUID\"}" \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["access_token"])')
curl -s "$BASE/system/user/list" -H "Authorization: Bearer $TOKEN"
curl -s -X DELETE "$BASE/auth/logout" -H "Authorization: Bearer $TOKEN"
```

## Sandbox-specific notes

* Host port **3000** is the web entry point: a small nginx (`docker/base44/nginx.conf`,
  modelled on `docker/nginx/conf/nginx.conf`) that serves `docker/base44/html/index.html` at
  `/` and proxies `/prod-api/` to the gateway. Single origin, so cookies/sessions are not
  affected by CORS. Drop the real `ruoyi-ui` build into `docker/base44/html/` to see the
  admin UI at the same address.
  (`docker/nginx/html/dist/` is git-ignored by the repo's `.gitignore` (`dist/`), which is why
  the placeholder lives under `docker/base44/`.)
* Nacos 3 moved the health endpoints to the console port and `410`s them on 8848, so the
  Nacos healthcheck probes the config API it actually serves
  (`/nacos/v1/cs/configs?...`), which also proves the MySQL config store is reachable.
* Dashboard ports: Nacos console `8088` (nacos / nacos), Spring Boot Admin monitor `9100`
  (ruoyi / 123456), gateway API `8080`.
* **Sentinel in the gateway — must not point at `127.0.0.1`:** `ruoyi-gateway`'s
  `bootstrap.yml` hardcodes `spring.cloud.sentinel.datasource.ds1.nacos.server-addr:
  127.0.0.1:8848` (and `sentinel.transport.dashboard: 127.0.0.1:8718`). Inside a container
  neither address exists, so that second Nacos client never connected, logged
  `Client not connected, current status:STARTING` in a tight loop, and **the gateway flow
  rules were silently never loaded**. Compose fixes it with
  `SPRING_CLOUD_SENTINEL_DATASOURCE_DS1_NACOS_SERVER_ADDR=nacos:8848`. Confirm the rules
  really arrive with:
  `docker compose -f docker-compose.base44.yml logs ruoyi-gateway | grep notify-ok`
  (expect `sentinel-ruoyi-gateway ... [notify-ok]` with an md5).
* No Sentinel dashboard or Seata server runs in this stack (the repo's own compose omits both),
  so `SPRING_CLOUD_SENTINEL_TRANSPORT_DASHBOARD` is set empty rather than heartbeating a dead
  `127.0.0.1:8718`. Seata is genuinely unused: `ruoyi-common-seata` appears only in the root
  `dependencyManagement`, no module depends on it.
* No host- or origin-allowlist changes were needed (nothing in this stack checks `Host` or
  `Origin`), and no third-party credentials are required: file storage is local (`file.path`).
  Because no code or shared config is gated, `BASE44_PREVIEW_MODE` is not used here.
