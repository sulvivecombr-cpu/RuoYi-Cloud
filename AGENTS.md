# AGENTS.md

Notes for running this repository in the Base44 sandbox. Everything here is a
finding you would not get from the manifests alone.

## What this repository is

`RuoYi-Cloud` — Spring Cloud microservices, Java 17, Spring Boot 4.1.0 / Spring Cloud
2025.1.2 (version 3.6.8). The admin UI is **not checked in here**: it is a separate
project, `RuoYi-Cloud-Vue3` (v3.6.8, Vue 3 + Vite + Element Plus). `docker-compose.base44.yml`
clones it into the git-ignored `./ruoyi-ui` directory on first start, so the stack comes up
complete.

The repo's own `docker/docker-compose.yml` expects prebuilt jars dropped into
`docker/ruoyi/*/jar/`, so it cannot run the current source — use `docker-compose.base44.yml`.

Backend modules: `ruoyi-gateway` (8080), `ruoyi-auth` (9200), `ruoyi-modules/ruoyi-system`
(9201), `ruoyi-gen` (9202), `ruoyi-job` (9203), `ruoyi-file` (9300),
`ruoyi-visual/ruoyi-monitor` (9100). Frontend: `ruoyi-ui` (Vite dev server, internal :80).

## Running it

```bash
docker compose -f docker-compose.base44.yml up -d      # cold start: ~6 min Maven build + UI npm install
docker compose -f docker-compose.base44.yml ps         # every service should be (healthy)
```

* The one-shot `build` service runs `mvn -DskipTests package` against the bind-mounted
  repo and writes the jars into `./<module>/target/`. Compose waits for it before starting
  the application services, so `up -d` blocks until the build finishes.
* **Java has no hot reload.** After editing Java source, rebuild and restart the affected
  service: `docker compose -f docker-compose.base44.yml run --rm build` then
  `docker compose -f docker-compose.base44.yml up -d <service>`, then `reload_preview`.
* **The UI does hot-reload** (Vite dev server, `npm run dev`). Frontend edits under
  `ruoyi-ui/` — which is a clone, so they are local only and lost on a fresh checkout.
* Backend runtime images are `maven:3.9-eclipse-temurin-17` (same base as the build, so the
  JDK and `curl` for healthchecks are present). The UI runs on `node:22`.

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

# web entry point: the admin UI, and the API behind the same origin
curl -s http://localhost:3000/ | grep -o "<title>.*</title>"          # 若依管理系统
curl -s -H 'Accept: text/plain' http://localhost:3000/prod-api/code    # captcha JSON
```

### The captcha blocks scripted UI login

`RouterFunctionConfiguration` maps `GET /code` to `ValidateCodeHandler` in **ruoyi-gateway**
(a WebFlux `RouterFunction`, so it runs before the gateway's `AuthFilter` and needs no token —
that is why `/code` is absent from `security.ignore.whites`). Through the entry point it is
`/prod-api/code`. There is no `/auth/code`.

Login is captcha-protected (`security.captcha.enabled: true` in `ruoyi-gateway-dev.yml`) and
the answer only ever lives in Redis (`captcha_codes:<uuid>`), never in the image, so
**a browser-only script cannot complete the login form**. The login page does prefill
`admin` / `admin123` (see `src/views/login.vue`), so a person only types the captcha.

API-level end-to-end check (nginx → gateway → auth → redis → Feign → ruoyi-system → MySQL):

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

To verify the *signed-in* UI without the form, take a token from the block above and set the
UI's cookie (`Admin-Token`, see `ruoyi-ui/src/utils/auth.js`) in the browser — that is a real
session created by the app's own login API.

## Sandbox-specific notes

* Host port **3000** is the web entry point (`docker/base44/nginx.conf`, modelled on
  `docker/nginx/conf/nginx.conf`):
  `/` → `ruoyi-ui` (Vite), `/prod-api/` and `/dev-api/` → `ruoyi-gateway`. One origin, so no
  CORS and cookies just work.
  * The UI is pointed at `/prod-api` with `VITE_APP_BASE_API` (an existing env hook in the
    frontend — no source edit). `/dev-api/`, the value in the frontend's own
    `.env.development`, is proxied as well so either value works.
  * `__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS` is passed through bare (Vite >= 6.1 appends it to
    `server.allowedHosts`, letting the preview host reach the dev server), and `BROWSER=none`
    stops `server.open` from spawning `xdg-open` in the container.
  * `ruoyi-ui/` is git-ignored: it is an external repo, cloned at startup when absent.
* Nacos 3 moved the health endpoints to the console port and `410`s them on 8848, so the
  Nacos healthcheck probes the config API it actually serves
  (`/nacos/v1/cs/configs?...`), which also proves the MySQL config store is reachable.
* Dashboard ports (each also publicly reachable on its own host port):
  Nacos console `8088` (nacos / nacos), Spring Boot Admin monitor `9100` — use
  `9100/login` (ruoyi / 123456), the root answers `401` — and gateway API `8080`.
* **Console dashboard menu links — rewritten during the MySQL first boot.** The seeded menus
  point at `http://localhost:<port>` (112 Nacos控制台 `:8848/nacos`, 113 Admin控制台
  `:9100/login`, 116 系统接口 `:8080/swagger-ui/index.html`), and localhost in a browser is
  the *viewer's* own machine, so none of them opened. `sql/zz_base44_menu_urls_init.sh` rides
  the `sql/` mount the mysql service already gets (a second mount inside that read-only
  directory cannot be created) and its name sorts after the seeds, so the entrypoint sources
  it once with `sys_menu` already populated: it points those three rows at
  `https://<port>-${BASE44_PUBLIC_HOST_SUFFIX}` and hides menu 111 (Sentinel控制台 `:8718` —
  no Sentinel dashboard runs here). It logs what it did, and does nothing when the variable is
  unset (outside the sandbox).
  * Init scripts run **only while `mysql-data` is empty**, so this is not re-applied when the
    volume already exists. After a sandbox host change, re-run the same statements by hand —
    they are the `UPDATE`s in that file, with `$BASE44_PUBLIC_HOST_SUFFIX` expanded:
    `docker compose -f docker-compose.base44.yml exec -T mysql mysql -uroot -ppassword ry-cloud -e "UPDATE sys_menu SET path='https://9100-${BASE44_PUBLIC_HOST_SUFFIX}/login' WHERE menu_id=113; ..."`
  * Verify with
    `docker compose -f docker-compose.base44.yml exec -T mysql mysql -uroot -ppassword -N -e "select menu_id, path, visible from sys_menu where menu_id in (111,112,113,116)"`:
    the three URLs must carry the current `BASE44_PUBLIC_HOST_SUFFIX`. The UI shows them after
    a page reload — the tree comes from `GET /system/menu/getRouters`.
* **Language: Brazilian Portuguese.** Two halves, and only one of them lives in this repository.
  * *Menu names and permission names* are data (`sys_menu`): all 84 rows — navigation plus the
    permission tree — were translated to pt-BR in `sql/ry_20260417.sql` and in the running
    database. Changing one later is a plain `UPDATE sys_menu SET menu_name=...`.
  * *Widget copy* (date pickers, month/week names, pagination, tables, dialogs, uploads) comes
    from Element Plus, whose locale the UI hardcodes to `zh-cn` in `src/main.js`.
    `docker/base44/ui-ptbr.sh` rewrites that one line to `element-plus/es/locale/lang/pt-br`;
    `ruoyi-ui` mounts it and runs it after the clone, so it survives a fresh checkout. Re-run it
    by hand with
    `docker compose -f docker-compose.base44.yml exec -T ruoyi-ui sh /usr/local/bin/ui-ptbr.sh`.
  * *Page copy* — table headers, form labels, buttons, the home page — is hardcoded Chinese inside
    the separate UI project. Nothing in this repository can translate it, and `ruoyi-ui/` is
    git-ignored, so edits there are local only. **Not translated yet.**
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
* No host- or origin-allowlist changes were needed beyond Vite's, and no third-party
  credentials are required: file storage is local (`file.path`). Because no code or shared
  config is gated, `BASE44_PREVIEW_MODE` is not used here.
* Known cosmetic console noise: the navbar avatar is rendered as `<img :src="avatar">` and the
  seeded `admin` user has no avatar, so the browser requests the page URL as an image once and
  logs `Failed to load img ...`. Harmless; the navbar falls back to the user name.
