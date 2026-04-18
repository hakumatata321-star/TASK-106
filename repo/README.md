# Eagle Point API

**Project type: backend**

A Go (Echo) backend providing authentication, scheduling, course management, moderation, payments, audit logging, and multi-level review workflows. Runs on **port 8080**.

---

## Quick Start

```bash
docker-compose up
```

The API is available at `http://localhost:8080` once the `api` container reports healthy.

> **What it starts:** PostgreSQL 16 (internal port 5432) + the Go API (port 8080). Migrations run automatically on startup.

To rebuild after code changes:

```bash
docker-compose up --build
```

---

## Access

| Item | Value |
|------|-------|
| Base URL | `http://localhost:8080` |
| Health check | `GET http://localhost:8080/health` |
| Metrics | `GET http://localhost:8080/metrics` |

---

## Verify the Service

```bash
# Basic health check
curl http://localhost:8080/health

# Detailed health (database connectivity)
curl http://localhost:8080/health/detailed
```

Expected response:
```json
{"status": "ok"}
```

---

## Authentication

All `/api/*` routes require a JWT bearer token. Obtain one via:

```bash
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin_test","password":"AdminPass123!"}'
```

Response:
```json
{
  "access_token": "<JWT>",
  "refresh_token": "<UUID>"
}
```

Use the token:
```bash
curl -H "Authorization: Bearer <access_token>" http://localhost:8080/api/accounts
```

Refresh an expired access token:
```bash
curl -X POST http://localhost:8080/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"<refresh_token>"}'
```

### Test Users by Role

The test suite seeds the following accounts (created in `API_tests/run_api_tests.sh`):

| Username | Password | Role |
|----------|----------|------|
| `admin_test` | `AdminPass123!` | Administrator |
| `scheduler_test` | `SchedulerP1!` | Scheduler |
| `instructor_test` | `InstructorP1` | Instructor |
| `finance_test` | `FinanceClerk1` | Finance Clerk |
| `reviewer_test` | `ReviewerP123` | Reviewer |
| `auditor_test` | `AuditorPass1` | Auditor |

> **Note:** These accounts are seeded by the test script via a direct `psql` insert. They do not exist in a fresh database — run the test suite or seed them manually before using the multi-role curl examples above.

---

## Running Tests

Development is **fully Docker-contained**. All dependencies (database, migrations, file storage) are managed by `docker-compose up`. No local Go or PostgreSQL installation is required.

### Full Test Suite (Docker)

```bash
bash run_tests.sh
```

This starts `docker-compose up`, waits for the server to be healthy, runs unit tests then all API tests, and tears down containers with volumes removed on completion.

### Unit Tests (with coverage)

Unit tests live in `unit_tests/` and run without Docker. To run them with Go coverage instrumentation:

```bash
go test -v -count=1 -coverprofile=coverage.out ./unit_tests/...
go tool cover -func=coverage.out
```

The `run_tests.sh` script runs unit tests automatically (via `unit_tests/run_unit_tests.sh`) and prints the per-function coverage summary to stdout.

### API Tests

The API test suite (`API_tests/run_api_tests.sh`) provides **100% HTTP endpoint coverage** for all **114 endpoints** defined in `internal/router/router.go` and `cmd/server/main.go`. Every endpoint is exercised with live curl requests against a running Docker instance — no mocking.

```bash
docker-compose up -d
bash API_tests/run_api_tests.sh
```

Override the target URL:

```bash
API_BASE_URL=http://localhost:9090 bash API_tests/run_api_tests.sh
```

Prerequisites: `curl` and `jq` must be on `PATH`.

---

## Environment Variables

| Variable | Default (compose) | Description |
|----------|-------------------|-------------|
| `SERVER_PORT` | `:8080` | Listen address |
| `DATABASE_URL` | `postgres://authuser:authpass@db:5432/authdb?sslmode=disable` | PostgreSQL DSN |
| `JWT_SECRET` | *(set in compose)* | HS256 signing key (min 32 bytes) |
| `DEVICE_FINGERPRINT_SALT` | *(set in compose)* | Salt for device fingerprinting |
| `BCRYPT_COST` | `12` | Bcrypt work factor |
| `MIGRATIONS_PATH` | `/app/migrations` | Path to SQL migration files |
| `STORAGE_PATH` | `/app/storage` | File storage root (mounted volume) |

Development is **fully Docker-contained**. All infrastructure (database, migrations, file storage) is managed by `docker-compose up`. No local Go or PostgreSQL installation is required to run or test the service.

---

## API Domains & Endpoints

### Public
| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Liveness check |
| GET | `/health/detailed` | Health + DB connectivity |
| GET | `/metrics` | Prometheus metrics |
| POST | `/auth/login` | Obtain access + refresh tokens |
| POST | `/auth/refresh` | Refresh access token |

### Account Management *(Administrator)*
`POST /api/accounts` · `GET /api/accounts` · `GET /api/accounts/:id` · `PUT /api/accounts/:id/status`
`PUT /api/accounts/:id/password` *(self-access only, any authenticated user)*

### Scheduling *(Scheduler, Administrator)*
- **Seasons:** `POST /api/seasons` · `GET /api/seasons` · `GET /api/seasons/:id`
- **Teams:** `POST /api/teams` · `GET /api/teams/season/:season_id`
- **Venues:** `POST /api/venues` · `GET /api/venues`
- **Matches:** `POST /api/matches` · `POST /api/matches/import` · `POST /api/matches/generate` · `GET /api/matches` · `GET /api/matches/:id` · `PUT /api/matches/:id` · `PUT /api/matches/:id/status`
- **Assignments:** `POST /api/assignments` · `GET /api/assignments/match/:match_id` · `PUT /api/assignments/:id/reassign` · `DELETE /api/assignments/:id`

### Courses *(Instructor, Administrator; enrolled members for read)*
- **Courses:** `POST /api/courses` · `GET /api/courses` · `GET /api/courses/:id` · `PUT /api/courses/:id`
- **Outline:** `POST /api/outline-nodes` · `GET /api/outline-nodes/course/:course_id` · `PUT /api/outline-nodes/:id` · `DELETE /api/outline-nodes/:id`
- **Members:** `POST /api/courses/:course_id/members` · `GET /api/courses/:course_id/members` · `DELETE /api/courses/:course_id/members/:id`
- **Resources:** `POST /api/resources` · `GET /api/resources` · `GET /api/resources/search` · `GET /api/resources/:id` · `PUT /api/resources/:id`
- **Versions:** `POST /api/resources/:id/versions` · `GET /api/resources/:id/versions` · `GET /api/resources/versions/:version_id/download` · `GET /api/resources/versions/:version_id/preview`

### Moderation *(Administrator for dictionaries; Reviewer+ for reviews)*
- **Dictionaries:** `POST/GET /api/moderation/dictionaries` · `GET/PUT/DELETE /api/moderation/dictionaries/:id`
- **Words:** `POST /api/moderation/dictionaries/:dict_id/words` · `POST …/bulk` · `GET …/words` · `DELETE /api/moderation/words/:id`
- **Check:** `POST /api/moderation/check` *(any authenticated user)*
- **Reviews:** `POST/GET /api/moderation/reviews` · `GET /api/moderation/reviews/:id` · `PUT /api/moderation/reviews/:id/decide`

### Reports *(any authenticated user creates; Reviewer+ manages)*
`POST /api/reports` · `GET /api/reports` · `GET /api/reports/:id` · `PUT /api/reports/:id/status` · `PUT /api/reports/:id/assign`
- **Evidence:** `POST /api/reports/:id/evidence` · `GET /api/reports/:id/evidence` · `GET /api/reports/evidence/:evidence_id/download`
- **Notes:** `POST /api/reports/:id/notes` · `GET /api/reports/:id/notes`

### Review Workflow *(Administrator configures; Reviewer+ manages)*
- **Configs:** `POST/GET /api/reviews/configs` · `GET/PUT/DELETE /api/reviews/configs/:id`
- **Requests:** `POST /api/reviews/requests` *(any auth)* · `GET /api/reviews/requests` · `GET …/by-entity` · `GET …/:id` · `GET …/:id/follow-up-requests` · `POST …/:id/resubmit`
- **Levels:** `GET /api/reviews/my-assignments` · `GET /api/reviews/levels/request/:request_id` · `PUT /api/reviews/levels/:id/assign` · `PUT /api/reviews/levels/:id/decide`
- **Follow-ups:** `POST /api/reviews/requests/:id/follow-ups` · `GET /api/reviews/requests/:id/follow-ups`

### Payments & Reconciliation *(Finance Clerk, Administrator)*
- **Payments:** `POST/GET /api/payments` · `GET /api/payments/failed-retriable` · `GET /api/payments/:id` · `GET /api/payments/account/:account_id` · `PUT /api/payments/:id/sign` · `PUT /api/payments/:id/fail` · `PUT /api/payments/:id/retry`
- **Reconciliation:** `GET /api/reconciliation/summary` · `GET /api/reconciliation/summary/range` · `POST/GET /api/reconciliation/reports` · `GET /api/reconciliation/reports/:id` · `GET /api/reconciliation/reports/:id/csv`

### Audit *(Auditor, Administrator for read; Administrator for write)*
- **Logs:** `GET /api/audit/logs` · `GET /api/audit/logs/export` · `GET /api/audit/logs/by-entity` · `GET /api/audit/logs/by-actor/:actor_id` · `GET /api/audit/logs/:id` · `GET /api/audit/logs/tier-counts`
- **Hash chain:** `GET /api/audit/hash-chain` · `GET /api/audit/hash-chain/verify` · `POST /api/audit/hash-chain/build` *(Administrator)* · `POST /api/audit/purge-expired` *(Administrator)*

---

## Roles & Security

| Role | Scope |
|------|-------|
| **Administrator** | Full access to all endpoints |
| **Scheduler** | Seasons, teams, venues, matches, assignments |
| **Instructor** | Courses, outline nodes, resources (own courses) |
| **Finance Clerk** | Payments, reconciliation |
| **Reviewer** | Moderation reviews, reports, review workflow |
| **Auditor** | Read-only audit logs and hash chain |

All protected routes use **JWT HS256** bearer tokens. Tokens are issued by `POST /auth/login` and refreshed via `POST /auth/refresh`. Device fingerprinting is applied to refresh tokens. Rate limiting is enforced on auth routes via a sliding-window limiter.
