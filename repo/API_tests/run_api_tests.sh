#!/usr/bin/env bash
# =============================================================================
# API Interface Functional Tests
# Tests all major API endpoints against a running server
# Requires: curl, jq
# =============================================================================
set -uo pipefail

BASE_URL="${API_BASE_URL:-http://localhost:8080}"
TOTAL=0
PASSED=0
FAILED=0
FAIL_DETAILS=""

# ── helpers ──────────────────────────────────────────────────────────────────

pass() {
    TOTAL=$((TOTAL + 1))
    PASSED=$((PASSED + 1))
    echo "  ✓ PASS: $1"
}

fail() {
    TOTAL=$((TOTAL + 1))
    FAILED=$((FAILED + 1))
    echo "  ✗ FAIL: $1 -- $2"
    FAIL_DETAILS="${FAIL_DETAILS}\n  - $1: $2"
}

assert_status() {
    local test_name="$1" expected="$2" actual="$3"
    if [ "$actual" = "$expected" ]; then
        pass "$test_name"
    else
        fail "$test_name" "expected HTTP $expected, got $actual"
    fi
}

assert_json_field() {
    local test_name="$1" body="$2" field="$3" expected="$4"
    actual=$(echo "$body" | jq -r "$field" 2>/dev/null)
    if [ "$actual" = "$expected" ]; then
        pass "$test_name"
    else
        fail "$test_name" "expected $field=$expected, got $actual"
    fi
}

# Perform HTTP request returning "STATUS_CODE\nBODY"
do_request() {
    local method="$1" url="$2" data="${3:-}" token="${4:-}"
    local headers=(-s -w "\n%{http_code}")
    [ -n "$token" ] && headers+=(-H "Authorization: Bearer $token")
    if [ -n "$data" ]; then
        headers+=(-H "Content-Type: application/json" -d "$data")
    fi
    curl -X "$method" "${headers[@]}" "$url" 2>/dev/null
}

parse_status() { echo "$1" | tail -1; }
parse_body()   { echo "$1" | sed '$d'; }

wait_for_server() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Waiting for server at $BASE_URL ..."
    for i in $(seq 1 60); do
        if curl -s "$BASE_URL/health" > /dev/null 2>&1; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Server is ready."
            return 0
        fi
        sleep 2
    done
    echo "ERROR: Server did not become ready within 120 seconds."
    exit 1
}

echo "=============================================="
echo "  API FUNCTIONAL TESTS"
echo "=============================================="
echo ""

wait_for_server

# ─────────────────────────────────────────────────────────────────────────────
# 1. HEALTH ENDPOINTS
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 1. Health & Observability ──"

RESP=$(do_request GET "$BASE_URL/health")
assert_status "GET /health returns 200" "200" "$(parse_status "$RESP")"
assert_json_field "GET /health status=ok" "$(parse_body "$RESP")" ".status" "ok"

RESP=$(do_request GET "$BASE_URL/health/detailed")
assert_status "GET /health/detailed returns 200" "200" "$(parse_status "$RESP")"
assert_json_field "detailed health db check" "$(parse_body "$RESP")" '.checks.database' "ok"

RESP=$(do_request GET "$BASE_URL/metrics")
assert_status "GET /metrics returns 200" "200" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 2. AUTH: Create admin account via first-run, then login
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 2. Authentication ──"

# Login with bad credentials
RESP=$(do_request POST "$BASE_URL/auth/login" '{"username":"nonexistent","password":"WrongPass123!"}')
assert_status "Login with invalid credentials returns 401" "401" "$(parse_status "$RESP")"

# Login with missing fields
RESP=$(do_request POST "$BASE_URL/auth/login" '{"username":""}')
assert_status "Login with empty username returns 400" "400" "$(parse_status "$RESP")"

# We need to create an admin account. Since there's no bootstrap endpoint,
# we'll test that unauthenticated access to protected routes fails first.

RESP=$(do_request GET "$BASE_URL/api/accounts")
assert_status "GET /api/accounts without auth returns 401" "401" "$(parse_status "$RESP")"

RESP=$(do_request POST "$BASE_URL/auth/refresh" '{"refresh_token":"invalid-token"}')
assert_status "Refresh with invalid token returns 401" "401" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 3. SEED: Insert admin account directly via psql for test bootstrapping
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 3. Bootstrap admin account ──"

# Create admin via SQL (bcrypt hash for "AdminPass123!")
ADMIN_HASH='$2a$12$0QF3u1PlBf3GxsvzNRWtkOCBAd6a6GqItoqPtPb5f61pvSXfUK.9e'
ADMIN_ID="00000000-0000-0000-0000-000000000001"

# Try docker compose exec first, fall back to direct psql
PSQL_CMD=""
if docker compose exec -T db psql -U authuser -d authdb -c "SELECT 1" > /dev/null 2>&1; then
    PSQL_CMD="docker compose exec -T db psql -U authuser -d authdb"
elif docker-compose exec -T db psql -U authuser -d authdb -c "SELECT 1" > /dev/null 2>&1; then
    PSQL_CMD="docker-compose exec -T db psql -U authuser -d authdb"
elif psql "postgres://authuser:authpass@localhost:5432/authdb?sslmode=disable" -c "SELECT 1" > /dev/null 2>&1; then
    PSQL_CMD="psql postgres://authuser:authpass@localhost:5432/authdb?sslmode=disable"
fi

if [ -n "$PSQL_CMD" ]; then
    $PSQL_CMD -c "
        INSERT INTO accounts (id, username, password_hash, role, status, created_at, updated_at)
        VALUES ('$ADMIN_ID', 'admin_test', '$ADMIN_HASH', 'Administrator', 'Active', NOW(), NOW())
        ON CONFLICT (username) DO NOTHING;
    " > /dev/null 2>&1
    pass "Admin account seeded"
else
    fail "Admin seed" "Could not connect to database to seed admin"
    echo ""
    echo "=============================================="
    echo "  Cannot proceed without DB access for seeding."
    echo "  Skipping authenticated API tests."
    echo "=============================================="
    echo ""
    echo "=============================================="
    echo "  API TEST SUMMARY"
    echo "=============================================="
    echo "  Total:  $TOTAL"
    echo "  Passed: $PASSED"
    echo "  Failed: $FAILED"
    echo "=============================================="
    if [ "$FAILED" -gt 0 ]; then
        echo "  STATUS: FAILED"
        echo -e "  Failures:$FAIL_DETAILS"
        exit 1
    fi
    exit 0
fi

# ── Login as admin ──
RESP=$(do_request POST "$BASE_URL/auth/login" '{"username":"admin_test","password":"AdminPass123!"}')
assert_status "Admin login returns 200" "200" "$(parse_status "$RESP")"
ADMIN_TOKEN=$(parse_body "$RESP" | jq -r '.access_token')
ADMIN_REFRESH=$(parse_body "$RESP" | jq -r '.refresh_token')

if [ -z "$ADMIN_TOKEN" ] || [ "$ADMIN_TOKEN" = "null" ]; then
    fail "Admin login" "Could not get admin token"
    echo "Aborting remaining tests."
    echo "Total: $TOTAL  Passed: $PASSED  Failed: $FAILED"
    exit 1
fi
pass "Admin token obtained"

# ─────────────────────────────────────────────────────────────────────────────
# 4. TOKEN REFRESH
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 4. Token Refresh ──"

RESP=$(do_request POST "$BASE_URL/auth/refresh" "{\"refresh_token\":\"$ADMIN_REFRESH\"}")
assert_status "Token refresh returns 200" "200" "$(parse_status "$RESP")"
NEW_TOKEN=$(parse_body "$RESP" | jq -r '.access_token')
if [ -n "$NEW_TOKEN" ] && [ "$NEW_TOKEN" != "null" ]; then
    pass "New access token received after refresh"
    ADMIN_TOKEN="$NEW_TOKEN"
else
    fail "Token refresh" "No new token in response"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 5. ACCOUNT MANAGEMENT
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 5. Account Management ──"

# Create account - missing fields
RESP=$(do_request POST "$BASE_URL/api/accounts" '{"username":""}' "$ADMIN_TOKEN")
assert_status "Create account with empty fields returns 400" "400" "$(parse_status "$RESP")"

# Create account - weak password
RESP=$(do_request POST "$BASE_URL/api/accounts" '{"username":"weakuser","password":"short","role":"Scheduler"}' "$ADMIN_TOKEN")
assert_status "Create account with weak password returns 400" "400" "$(parse_status "$RESP")"

# Create account - invalid role (Fix #5: now returns 400 not 500)
RESP=$(do_request POST "$BASE_URL/api/accounts" '{"username":"badrole","password":"ValidPass123!","role":"SuperAdmin"}' "$ADMIN_TOKEN")
assert_status "Create account with invalid role returns 400" "400" "$(parse_status "$RESP")"

# Create scheduler account
RESP=$(do_request POST "$BASE_URL/api/accounts" '{"username":"scheduler_test","password":"SchedulerP1!","role":"Scheduler"}' "$ADMIN_TOKEN")
assert_status "Create scheduler account returns 201" "201" "$(parse_status "$RESP")"
SCHEDULER_ID=$(parse_body "$RESP" | jq -r '.id')

# Create instructor account
RESP=$(do_request POST "$BASE_URL/api/accounts" '{"username":"instructor_test","password":"InstructorP1","role":"Instructor"}' "$ADMIN_TOKEN")
assert_status "Create instructor account returns 201" "201" "$(parse_status "$RESP")"
INSTRUCTOR_ID=$(parse_body "$RESP" | jq -r '.id')

# Create finance clerk
RESP=$(do_request POST "$BASE_URL/api/accounts" '{"username":"finance_test","password":"FinanceClerk1","role":"Finance Clerk"}' "$ADMIN_TOKEN")
assert_status "Create finance clerk returns 201" "201" "$(parse_status "$RESP")"
FINANCE_ID=$(parse_body "$RESP" | jq -r '.id')

# Create reviewer
RESP=$(do_request POST "$BASE_URL/api/accounts" '{"username":"reviewer_test","password":"ReviewerP123","role":"Reviewer"}' "$ADMIN_TOKEN")
assert_status "Create reviewer account returns 201" "201" "$(parse_status "$RESP")"
REVIEWER_ID=$(parse_body "$RESP" | jq -r '.id')

# Create auditor
RESP=$(do_request POST "$BASE_URL/api/accounts" '{"username":"auditor_test","password":"AuditorPass1","role":"Auditor"}' "$ADMIN_TOKEN")
assert_status "Create auditor account returns 201" "201" "$(parse_status "$RESP")"

# List accounts
RESP=$(do_request GET "$BASE_URL/api/accounts" "" "$ADMIN_TOKEN")
assert_status "List accounts returns 200" "200" "$(parse_status "$RESP")"

# Get specific account
RESP=$(do_request GET "$BASE_URL/api/accounts/$SCHEDULER_ID" "" "$ADMIN_TOKEN")
assert_status "Get account by ID returns 200" "200" "$(parse_status "$RESP")"
assert_json_field "Account username matches" "$(parse_body "$RESP")" ".username" "scheduler_test"

# Duplicate username (Fix #5: now returns 409 not 500)
RESP=$(do_request POST "$BASE_URL/api/accounts" '{"username":"scheduler_test","password":"AnotherP1xxx","role":"Scheduler"}' "$ADMIN_TOKEN")
assert_status "Duplicate username returns 409" "409" "$(parse_status "$RESP")"

# Freeze account
RESP=$(do_request PUT "$BASE_URL/api/accounts/$SCHEDULER_ID/status" '{"status":"Frozen"}' "$ADMIN_TOKEN")
assert_status "Freeze account returns 200" "200" "$(parse_status "$RESP")"

# Reactivate
RESP=$(do_request PUT "$BASE_URL/api/accounts/$SCHEDULER_ID/status" '{"status":"Active"}' "$ADMIN_TOKEN")
assert_status "Reactivate account returns 200" "200" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 6. LOGIN AS OTHER ROLES & PERMISSION CHECKS
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 6. Role-Based Access Control ──"

# Login as scheduler
RESP=$(do_request POST "$BASE_URL/auth/login" '{"username":"scheduler_test","password":"SchedulerP1!"}')
assert_status "Scheduler login returns 200" "200" "$(parse_status "$RESP")"
SCHED_TOKEN=$(parse_body "$RESP" | jq -r '.access_token')

# Scheduler cannot create accounts
RESP=$(do_request POST "$BASE_URL/api/accounts" '{"username":"x","password":"y","role":"Auditor"}' "$SCHED_TOKEN")
assert_status "Scheduler cannot create accounts (403)" "403" "$(parse_status "$RESP")"

# Login as instructor
RESP=$(do_request POST "$BASE_URL/auth/login" '{"username":"instructor_test","password":"InstructorP1"}')
INSTR_TOKEN=$(parse_body "$RESP" | jq -r '.access_token')

# Login as finance clerk
RESP=$(do_request POST "$BASE_URL/auth/login" '{"username":"finance_test","password":"FinanceClerk1"}')
FINANCE_TOKEN=$(parse_body "$RESP" | jq -r '.access_token')

# Login as reviewer
RESP=$(do_request POST "$BASE_URL/auth/login" '{"username":"reviewer_test","password":"ReviewerP123"}')
REVIEWER_TOKEN=$(parse_body "$RESP" | jq -r '.access_token')

# Login as auditor
RESP=$(do_request POST "$BASE_URL/auth/login" '{"username":"auditor_test","password":"AuditorPass1"}')
AUDITOR_TOKEN=$(parse_body "$RESP" | jq -r '.access_token')

# Instructor cannot access scheduling
RESP=$(do_request POST "$BASE_URL/api/seasons" '{"name":"x","start_date":"2025-01-01","end_date":"2025-06-01"}' "$INSTR_TOKEN")
assert_status "Instructor cannot create season (403)" "403" "$(parse_status "$RESP")"

# Finance clerk cannot access courses
RESP=$(do_request POST "$BASE_URL/api/courses" '{"title":"x"}' "$FINANCE_TOKEN")
assert_status "Finance clerk cannot create course (403)" "403" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 7. SEASONS, TEAMS, VENUES
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 7. Seasons, Teams & Venues ──"

RESP=$(do_request POST "$BASE_URL/api/seasons" '{"name":"Fall 2025","start_date":"2025-09-01","end_date":"2025-12-15"}' "$SCHED_TOKEN")
assert_status "Create season returns 201" "201" "$(parse_status "$RESP")"
SEASON_ID=$(parse_body "$RESP" | jq -r '.id')

# Invalid dates
RESP=$(do_request POST "$BASE_URL/api/seasons" '{"name":"Bad","start_date":"2025-12-01","end_date":"2025-01-01"}' "$SCHED_TOKEN")
assert_status "Season with end<start returns 400" "400" "$(parse_status "$RESP")"

RESP=$(do_request GET "$BASE_URL/api/seasons" "" "$SCHED_TOKEN")
assert_status "List seasons returns 200" "200" "$(parse_status "$RESP")"

# Create teams
RESP=$(do_request POST "$BASE_URL/api/teams" "{\"name\":\"Eagles\",\"season_id\":\"$SEASON_ID\"}" "$SCHED_TOKEN")
assert_status "Create team Eagles returns 201" "201" "$(parse_status "$RESP")"
TEAM_A=$(parse_body "$RESP" | jq -r '.id')

RESP=$(do_request POST "$BASE_URL/api/teams" "{\"name\":\"Hawks\",\"season_id\":\"$SEASON_ID\"}" "$SCHED_TOKEN")
assert_status "Create team Hawks returns 201" "201" "$(parse_status "$RESP")"
TEAM_B=$(parse_body "$RESP" | jq -r '.id')

RESP=$(do_request GET "$BASE_URL/api/teams/season/$SEASON_ID" "" "$SCHED_TOKEN")
assert_status "List teams returns 200" "200" "$(parse_status "$RESP")"

# Create venue
RESP=$(do_request POST "$BASE_URL/api/venues" '{"name":"Main Arena","location":"Campus North","capacity":5000}' "$SCHED_TOKEN")
assert_status "Create venue returns 201" "201" "$(parse_status "$RESP")"
VENUE_ID=$(parse_body "$RESP" | jq -r '.id')

# ─────────────────────────────────────────────────────────────────────────────
# 8. MATCHES & SCHEDULING VALIDATION
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 8. Matches & Scheduling ──"

# Create match
RESP=$(do_request POST "$BASE_URL/api/matches" "{
    \"season_id\":\"$SEASON_ID\", \"round\":1,
    \"home_team_id\":\"$TEAM_A\", \"away_team_id\":\"$TEAM_B\",
    \"venue_id\":\"$VENUE_ID\", \"scheduled_at\":\"2025-09-15T14:00:00Z\"
}" "$SCHED_TOKEN")
assert_status "Create match returns 201" "201" "$(parse_status "$RESP")"
MATCH_ID=$(parse_body "$RESP" | jq -r '.id')
assert_json_field "Match status is Draft" "$(parse_body "$RESP")" ".status" "Draft"

# Same team pairing in same round - should require override
RESP=$(do_request POST "$BASE_URL/api/matches" "{
    \"season_id\":\"$SEASON_ID\", \"round\":1,
    \"home_team_id\":\"$TEAM_B\", \"away_team_id\":\"$TEAM_A\",
    \"venue_id\":\"$VENUE_ID\", \"scheduled_at\":\"2025-09-15T18:00:00Z\"
}" "$SCHED_TOKEN")
assert_status "Duplicate pairing in round requires override (409)" "409" "$(parse_status "$RESP")"

# Home and away same team
RESP=$(do_request POST "$BASE_URL/api/matches" "{
    \"season_id\":\"$SEASON_ID\", \"round\":2,
    \"home_team_id\":\"$TEAM_A\", \"away_team_id\":\"$TEAM_A\",
    \"venue_id\":\"$VENUE_ID\", \"scheduled_at\":\"2025-09-22T14:00:00Z\"
}" "$SCHED_TOKEN")
assert_status "Same home/away team returns 400" "400" "$(parse_status "$RESP")"

# Transition: Draft -> Scheduled
RESP=$(do_request PUT "$BASE_URL/api/matches/$MATCH_ID/status" '{"status":"Scheduled"}' "$SCHED_TOKEN")
assert_status "Transition Draft->Scheduled returns 200" "200" "$(parse_status "$RESP")"
assert_json_field "Match status is Scheduled" "$(parse_body "$RESP")" ".status" "Scheduled"

# Invalid transition: Scheduled -> Draft
RESP=$(do_request PUT "$BASE_URL/api/matches/$MATCH_ID/status" '{"status":"Draft"}' "$SCHED_TOKEN")
assert_status "Invalid transition Scheduled->Draft returns 409" "409" "$(parse_status "$RESP")"

# Transition: Scheduled -> In-Progress -> Final
RESP=$(do_request PUT "$BASE_URL/api/matches/$MATCH_ID/status" '{"status":"In-Progress"}' "$SCHED_TOKEN")
assert_status "Transition Scheduled->InProgress returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request PUT "$BASE_URL/api/matches/$MATCH_ID/status" '{"status":"Final"}' "$SCHED_TOKEN")
assert_status "Transition InProgress->Final returns 200" "200" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 9. COURSES & RESOURCES
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 9. Courses & Resources ──"

RESP=$(do_request POST "$BASE_URL/api/courses" '{"title":"Intro to Athletics","description":"Fundamentals course"}' "$INSTR_TOKEN")
assert_status "Create course returns 201" "201" "$(parse_status "$RESP")"
COURSE_ID=$(parse_body "$RESP" | jq -r '.id')
assert_json_field "Course status is Draft" "$(parse_body "$RESP")" ".status" "Draft"

# Create outline node (chapter)
RESP=$(do_request POST "$BASE_URL/api/outline-nodes" "{
    \"course_id\":\"$COURSE_ID\", \"node_type\":\"Chapter\",
    \"title\":\"Chapter 1: Basics\", \"order_index\":0
}" "$INSTR_TOKEN")
assert_status "Create chapter returns 201" "201" "$(parse_status "$RESP")"
CHAPTER_ID=$(parse_body "$RESP" | jq -r '.id')

# Create unit under chapter
RESP=$(do_request POST "$BASE_URL/api/outline-nodes" "{
    \"course_id\":\"$COURSE_ID\", \"parent_id\":\"$CHAPTER_ID\",
    \"node_type\":\"Unit\", \"title\":\"Unit 1.1: Warm-ups\", \"order_index\":0
}" "$INSTR_TOKEN")
assert_status "Create unit returns 201" "201" "$(parse_status "$RESP")"

# Get outline tree
RESP=$(do_request GET "$BASE_URL/api/outline-nodes/course/$COURSE_ID" "" "$INSTR_TOKEN")
assert_status "Get outline tree returns 200" "200" "$(parse_status "$RESP")"

# Create link resource
RESP=$(do_request POST "$BASE_URL/api/resources" "{
    \"course_id\":\"$COURSE_ID\", \"title\":\"Reference Guide\",
    \"resource_type\":\"Link\", \"visibility\":\"Enrolled\",
    \"link_url\":\"https://example.com/guide\", \"tags\":[\"guide\",\"reference\"]
}" "$INSTR_TOKEN")
assert_status "Create link resource returns 201" "201" "$(parse_status "$RESP")"
RESOURCE_ID=$(parse_body "$RESP" | jq -r '.id')

# Too many tags
TAGS_JSON=$(python3 -c "import json; print(json.dumps([f'tag{i}' for i in range(25)]))" 2>/dev/null || echo '["t1","t2","t3","t4","t5","t6","t7","t8","t9","t10","t11","t12","t13","t14","t15","t16","t17","t18","t19","t20","t21"]')
RESP=$(do_request POST "$BASE_URL/api/resources" "{
    \"course_id\":\"$COURSE_ID\", \"title\":\"Too Many Tags\",
    \"resource_type\":\"Link\", \"visibility\":\"Staff\",
    \"link_url\":\"https://example.com\", \"tags\":$TAGS_JSON
}" "$INSTR_TOKEN")
assert_status "Too many tags returns 400" "400" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 9a. OBJECT-LEVEL AUTHORIZATION (Fix #1)
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 9a. Object-Level Authorization ──"

# Non-member (finance clerk) cannot access draft course
RESP=$(do_request GET "$BASE_URL/api/courses/$COURSE_ID" "" "$FINANCE_TOKEN")
assert_status "Non-member cannot access draft course (403)" "403" "$(parse_status "$RESP")"

# Non-member cannot view course outline
RESP=$(do_request GET "$BASE_URL/api/outline-nodes/course/$COURSE_ID" "" "$FINANCE_TOKEN")
assert_status "Non-member cannot view course outline (403)" "403" "$(parse_status "$RESP")"

# Non-member cannot list course members
RESP=$(do_request GET "$BASE_URL/api/courses/$COURSE_ID/members" "" "$FINANCE_TOKEN")
assert_status "Non-member cannot list members (403)" "403" "$(parse_status "$RESP")"

# Non-member cannot list course resources
RESP=$(do_request GET "$BASE_URL/api/resources?course_id=$COURSE_ID" "" "$FINANCE_TOKEN")
assert_status "Non-member cannot list resources (403)" "403" "$(parse_status "$RESP")"

# Non-member cannot search course resources
RESP=$(do_request GET "$BASE_URL/api/resources/search?course_id=$COURSE_ID&q=guide" "" "$FINANCE_TOKEN")
assert_status "Non-member cannot search resources (403)" "403" "$(parse_status "$RESP")"

# Non-member cannot get specific resource
RESP=$(do_request GET "$BASE_URL/api/resources/$RESOURCE_ID" "" "$FINANCE_TOKEN")
assert_status "Non-member cannot get resource (403)" "403" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 9b. SCHEDULE GENERATION (Fix #3)
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 9b. Schedule Generation ──"

# Create a fresh season and teams for generation test
RESP=$(do_request POST "$BASE_URL/api/seasons" '{"name":"Gen Test 2025","start_date":"2025-10-01","end_date":"2025-12-31"}' "$SCHED_TOKEN")
assert_status "Create generation season returns 201" "201" "$(parse_status "$RESP")"
GEN_SEASON=$(parse_body "$RESP" | jq -r '.id')

RESP=$(do_request POST "$BASE_URL/api/teams" "{\"name\":\"Alpha\",\"season_id\":\"$GEN_SEASON\"}" "$SCHED_TOKEN")
GEN_T1=$(parse_body "$RESP" | jq -r '.id')
RESP=$(do_request POST "$BASE_URL/api/teams" "{\"name\":\"Beta\",\"season_id\":\"$GEN_SEASON\"}" "$SCHED_TOKEN")
GEN_T2=$(parse_body "$RESP" | jq -r '.id')
RESP=$(do_request POST "$BASE_URL/api/teams" "{\"name\":\"Gamma\",\"season_id\":\"$GEN_SEASON\"}" "$SCHED_TOKEN")
GEN_T3=$(parse_body "$RESP" | jq -r '.id')
RESP=$(do_request POST "$BASE_URL/api/teams" "{\"name\":\"Delta\",\"season_id\":\"$GEN_SEASON\"}" "$SCHED_TOKEN")
GEN_T4=$(parse_body "$RESP" | jq -r '.id')

RESP=$(do_request POST "$BASE_URL/api/venues" '{"name":"Gen Arena"}' "$SCHED_TOKEN")
GEN_VENUE=$(parse_body "$RESP" | jq -r '.id')

# Generate schedule
RESP=$(do_request POST "$BASE_URL/api/matches/generate" "{
    \"season_id\":\"$GEN_SEASON\",
    \"venue_ids\":[\"$GEN_VENUE\"],
    \"start_date\":\"2025-10-01\",
    \"interval_days\":7,
    \"start_time\":\"15:00\"
}" "$SCHED_TOKEN")
assert_status "Generate schedule returns 201" "201" "$(parse_status "$RESP")"
GEN_CREATED=$(parse_body "$RESP" | jq -r '.created')
GEN_ROUNDS=$(parse_body "$RESP" | jq -r '.rounds')
if [ "$GEN_ROUNDS" = "3" ]; then
    pass "Generated 3 rounds for 4 teams"
else
    fail "Schedule generation rounds" "expected 3 rounds, got $GEN_ROUNDS"
fi
if [ "$GEN_CREATED" = "6" ]; then
    pass "Generated 6 matches (3 rounds x 2 per round)"
else
    fail "Schedule generation match count" "expected 6, got $GEN_CREATED"
fi

# Missing venues
RESP=$(do_request POST "$BASE_URL/api/matches/generate" "{
    \"season_id\":\"$GEN_SEASON\",
    \"venue_ids\":[],
    \"start_date\":\"2025-10-01\",
    \"interval_days\":7
}" "$SCHED_TOKEN")
assert_status "Generate with no venues returns 400" "400" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 10. MODERATION
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 10. Moderation ──"

# Create dictionary (admin only)
RESP=$(do_request POST "$BASE_URL/api/moderation/dictionaries" '{"name":"Profanity","description":"Bad words filter"}' "$ADMIN_TOKEN")
assert_status "Create dictionary returns 201" "201" "$(parse_status "$RESP")"
DICT_ID=$(parse_body "$RESP" | jq -r '.id')

# Add words
RESP=$(do_request POST "$BASE_URL/api/moderation/dictionaries/$DICT_ID/words" '{"word":"badword","severity":"high"}' "$ADMIN_TOKEN")
assert_status "Add word returns 201" "201" "$(parse_status "$RESP")"

# Check clean content
RESP=$(do_request POST "$BASE_URL/api/moderation/check" '{"text":"This is a clean sentence."}' "$ADMIN_TOKEN")
assert_status "Check clean content returns 200" "200" "$(parse_status "$RESP")"
assert_json_field "Clean content is clean" "$(parse_body "$RESP")" ".clean" "true"

# Check flagged content
RESP=$(do_request POST "$BASE_URL/api/moderation/check" '{"text":"This contains badword in it."}' "$ADMIN_TOKEN")
assert_status "Check flagged content returns 200" "200" "$(parse_status "$RESP")"
assert_json_field "Flagged content not clean" "$(parse_body "$RESP")" ".clean" "false"

# Non-admin cannot create dictionary
RESP=$(do_request POST "$BASE_URL/api/moderation/dictionaries" '{"name":"X"}' "$REVIEWER_TOKEN")
assert_status "Reviewer cannot create dictionary (403)" "403" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 11. REPORTS
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 11. Reports ──"

RESP=$(do_request POST "$BASE_URL/api/reports" "{
    \"target_type\":\"course\", \"target_id\":\"$COURSE_ID\",
    \"category\":\"Spam\", \"description\":\"Suspicious content\"
}" "$INSTR_TOKEN")
assert_status "Create report returns 201" "201" "$(parse_status "$RESP")"
REPORT_ID=$(parse_body "$RESP" | jq -r '.id')

# Missing category
RESP=$(do_request POST "$BASE_URL/api/reports" "{
    \"target_type\":\"course\", \"target_id\":\"$COURSE_ID\",
    \"category\":\"InvalidCat\", \"description\":\"test\"
}" "$INSTR_TOKEN")
assert_status "Report with invalid category returns 400" "400" "$(parse_status "$RESP")"

# List reports (reviewer)
RESP=$(do_request GET "$BASE_URL/api/reports" "" "$REVIEWER_TOKEN")
assert_status "List reports returns 200" "200" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 12. REVIEW WORKFLOW
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 12. Review Workflow ──"

# Create review config (admin)
RESP=$(do_request POST "$BASE_URL/api/reviews/configs" '{"review_type":"course_publish","description":"Course publication review","required_levels":2}' "$ADMIN_TOKEN")
assert_status "Create review config returns 201" "201" "$(parse_status "$RESP")"

# Invalid levels
RESP=$(do_request POST "$BASE_URL/api/reviews/configs" '{"review_type":"x","required_levels":5}' "$ADMIN_TOKEN")
assert_status "Review config with 5 levels returns 400" "400" "$(parse_status "$RESP")"

# Submit review request
RESP=$(do_request POST "$BASE_URL/api/reviews/requests" "{
    \"review_type\":\"course_publish\",
    \"entity_type\":\"course\", \"entity_id\":\"$COURSE_ID\"
}" "$INSTR_TOKEN")
assert_status "Submit review request returns 201" "201" "$(parse_status "$RESP")"
REVIEW_REQ_ID=$(parse_body "$RESP" | jq -r '.id')
assert_json_field "Review has 2 levels" "$(parse_body "$RESP")" ".required_levels" "2"

# Get review with levels
RESP=$(do_request GET "$BASE_URL/api/reviews/requests/$REVIEW_REQ_ID" "" "$REVIEWER_TOKEN")
assert_status "Get review request returns 200" "200" "$(parse_status "$RESP")"
LEVEL1_ID=$(parse_body "$RESP" | jq -r '.levels[0].id')

# Approve level 1
RESP=$(do_request PUT "$BASE_URL/api/reviews/levels/$LEVEL1_ID/decide" '{"decision":"Approved","annotation":"Looks good"}' "$REVIEWER_TOKEN")
assert_status "Approve level 1 returns 200" "200" "$(parse_status "$RESP")"
assert_json_field "Request still in review after L1" "$(parse_body "$RESP")" ".status" "In Review"
assert_json_field "Current level advanced to 2" "$(parse_body "$RESP")" ".current_level" "2"

# Get updated review to find level 2 ID
RESP=$(do_request GET "$BASE_URL/api/reviews/requests/$REVIEW_REQ_ID" "" "$REVIEWER_TOKEN")
LEVEL2_ID=$(parse_body "$RESP" | jq -r '.levels[1].id')

# Approve level 2 (final)
RESP=$(do_request PUT "$BASE_URL/api/reviews/levels/$LEVEL2_ID/decide" '{"decision":"Approved","annotation":"Final approval"}' "$ADMIN_TOKEN")
assert_status "Approve level 2 (final) returns 200" "200" "$(parse_status "$RESP")"
assert_json_field "Request approved after L2" "$(parse_body "$RESP")" ".status" "Approved"

# ─────────────────────────────────────────────────────────────────────────────
# 13. PAYMENTS & RECONCILIATION
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 13. Payments & Reconciliation ──"

# Create payment
RESP=$(do_request POST "$BASE_URL/api/payments" "{
    \"account_id\":\"$ADMIN_ID\", \"idempotency_key\":\"pay-test-001\",
    \"amount_usd\":\"250.00\", \"channel\":\"Cash\",
    \"description\":\"Test payment\"
}" "$FINANCE_TOKEN")
assert_status "Create payment returns 201" "201" "$(parse_status "$RESP")"
PAYMENT_ID=$(parse_body "$RESP" | jq -r '.id')
assert_json_field "Payment status is Obligation" "$(parse_body "$RESP")" ".status" "Obligation"

# Idempotency - same key returns 200 (not 201)
RESP=$(do_request POST "$BASE_URL/api/payments" "{
    \"account_id\":\"$ADMIN_ID\", \"idempotency_key\":\"pay-test-001\",
    \"amount_usd\":\"250.00\", \"channel\":\"Cash\"
}" "$FINANCE_TOKEN")
assert_status "Duplicate idempotency key returns 200" "200" "$(parse_status "$RESP")"
assert_json_field "Returns same payment ID" "$(parse_body "$RESP")" ".id" "$PAYMENT_ID"

# Invalid amount
RESP=$(do_request POST "$BASE_URL/api/payments" "{
    \"account_id\":\"$ADMIN_ID\", \"idempotency_key\":\"pay-neg\",
    \"amount_usd\":\"-50.00\", \"channel\":\"Cash\"
}" "$FINANCE_TOKEN")
assert_status "Negative amount returns 400" "400" "$(parse_status "$RESP")"

# Sign posting (settle)
RESP=$(do_request PUT "$BASE_URL/api/payments/$PAYMENT_ID/sign" '{}' "$FINANCE_TOKEN")
assert_status "Sign posting returns 200" "200" "$(parse_status "$RESP")"
assert_json_field "Payment settled" "$(parse_body "$RESP")" ".status" "Settled"

# Cannot sign again
RESP=$(do_request PUT "$BASE_URL/api/payments/$PAYMENT_ID/sign" '{}' "$FINANCE_TOKEN")
assert_status "Double sign returns 409" "409" "$(parse_status "$RESP")"

# Create another payment, fail it, and retry
RESP=$(do_request POST "$BASE_URL/api/payments" "{
    \"account_id\":\"$ADMIN_ID\", \"idempotency_key\":\"pay-test-002\",
    \"amount_usd\":\"100.00\", \"channel\":\"Check\"
}" "$FINANCE_TOKEN")
PAY2_ID=$(parse_body "$RESP" | jq -r '.id')

RESP=$(do_request PUT "$BASE_URL/api/payments/$PAY2_ID/fail" '{}' "$FINANCE_TOKEN")
assert_status "Fail settlement returns 200" "200" "$(parse_status "$RESP")"
assert_json_field "Payment failed" "$(parse_body "$RESP")" ".status" "Failed"

RESP=$(do_request PUT "$BASE_URL/api/payments/$PAY2_ID/retry" '{}' "$FINANCE_TOKEN")
assert_status "Retry settlement returns 200" "200" "$(parse_status "$RESP")"
assert_json_field "Payment back to Obligation" "$(parse_body "$RESP")" ".status" "Obligation"
assert_json_field "Retry count is 1" "$(parse_body "$RESP")" ".retry_count" "1"

# Reconciliation summary
TODAY=$(date '+%Y-%m-%d')
RESP=$(do_request GET "$BASE_URL/api/reconciliation/summary?date=$TODAY" "" "$FINANCE_TOKEN")
assert_status "Daily summary returns 200" "200" "$(parse_status "$RESP")"

# Generate reconciliation report
RESP=$(do_request POST "$BASE_URL/api/reconciliation/reports" "{\"date\":\"$TODAY\"}" "$FINANCE_TOKEN")
assert_status "Generate reconciliation returns 201" "201" "$(parse_status "$RESP")"
RECON_ID=$(parse_body "$RESP" | jq -r '.id')

# Download CSV
RESP=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $FINANCE_TOKEN" "$BASE_URL/api/reconciliation/reports/$RECON_ID/csv" 2>/dev/null)
assert_status "Download reconciliation CSV returns 200" "200" "$RESP"

# ─────────────────────────────────────────────────────────────────────────────
# 14. AUDIT LOGS & HASH CHAIN
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 14. Audit & Compliance ──"

RESP=$(do_request GET "$BASE_URL/api/audit/logs" "" "$AUDITOR_TOKEN")
assert_status "Query audit logs returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request GET "$BASE_URL/api/audit/logs/tier-counts" "" "$AUDITOR_TOKEN")
assert_status "Tier counts returns 200" "200" "$(parse_status "$RESP")"

# Fix #2: Auditor is read-only - write operations require Administrator
RESP=$(do_request POST "$BASE_URL/api/audit/hash-chain/build" "{\"date\":\"$TODAY\"}" "$AUDITOR_TOKEN")
assert_status "Auditor cannot build hash chain (403)" "403" "$(parse_status "$RESP")"

RESP=$(do_request POST "$BASE_URL/api/audit/purge-expired" '{}' "$AUDITOR_TOKEN")
assert_status "Auditor cannot purge (403)" "403" "$(parse_status "$RESP")"

# Admin CAN build hash chain
RESP=$(do_request POST "$BASE_URL/api/audit/hash-chain/build" "{\"date\":\"$TODAY\"}" "$ADMIN_TOKEN")
assert_status "Admin can build hash chain (201)" "201" "$(parse_status "$RESP")"

# Admin CAN purge expired audit logs
RESP=$(do_request POST "$BASE_URL/api/audit/purge-expired" '{}' "$ADMIN_TOKEN")
assert_status "Admin can purge expired audit logs (200)" "200" "$(parse_status "$RESP")"

# Auditor CAN verify (read-only)
RESP=$(do_request GET "$BASE_URL/api/audit/hash-chain/verify?date=$TODAY" "" "$AUDITOR_TOKEN")
assert_status "Auditor can verify hash chain (200)" "200" "$(parse_status "$RESP")"
assert_json_field "Hash chain valid" "$(parse_body "$RESP")" ".valid" "true"

# Auditor CAN export (read-only)
RESP=$(do_request GET "$BASE_URL/api/audit/logs/export" "" "$AUDITOR_TOKEN")
STATUS=$(parse_status "$RESP")
if [ "$STATUS" = "200" ]; then
    pass "Auditor can export audit CSV (200)"
else
    fail "Auditor export" "expected 200, got $STATUS"
fi

# Non-auditor cannot access audit logs
RESP=$(do_request GET "$BASE_URL/api/audit/logs" "" "$INSTR_TOKEN")
assert_status "Instructor cannot access audit (403)" "403" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 17. SEASONS & VENUES – remaining endpoint coverage
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 17. Seasons & Venues – remaining coverage ──"

RESP=$(do_request GET "$BASE_URL/api/seasons/$SEASON_ID" "" "$SCHED_TOKEN")
assert_status "GET /api/seasons/:id returns 200" "200" "$(parse_status "$RESP")"
assert_json_field "Season name matches" "$(parse_body "$RESP")" ".name" "Fall 2025"

RESP=$(do_request GET "$BASE_URL/api/venues" "" "$SCHED_TOKEN")
assert_status "GET /api/venues returns 200" "200" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 18. MATCHES – remaining endpoint coverage
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 18. Matches – remaining coverage ──"

RESP=$(do_request GET "$BASE_URL/api/matches?season_id=$SEASON_ID" "" "$SCHED_TOKEN")
assert_status "GET /api/matches returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request GET "$BASE_URL/api/matches/$MATCH_ID" "" "$SCHED_TOKEN")
assert_status "GET /api/matches/:id returns 200" "200" "$(parse_status "$RESP")"

# Create a Draft match for PUT and assignment tests (GEN_SEASON round 20 – avoids overlap)
RESP=$(do_request POST "$BASE_URL/api/matches" "{
    \"season_id\":\"$GEN_SEASON\", \"round\":20,
    \"home_team_id\":\"$GEN_T3\", \"away_team_id\":\"$GEN_T4\",
    \"venue_id\":\"$GEN_VENUE\", \"scheduled_at\":\"2025-12-20T14:00:00Z\"
}" "$SCHED_TOKEN")
assert_status "Create Draft match for coverage tests returns 201" "201" "$(parse_status "$RESP")"
DRAFT_MATCH_ID=$(parse_body "$RESP" | jq -r '.id')

RESP=$(do_request PUT "$BASE_URL/api/matches/$DRAFT_MATCH_ID" "{
    \"scheduled_at\":\"2025-12-21T10:00:00Z\"
}" "$SCHED_TOKEN")
assert_status "PUT /api/matches/:id returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request POST "$BASE_URL/api/matches/import" "{
    \"season_id\":\"$GEN_SEASON\",
    \"matches\":[{
        \"round\":30,
        \"home_team_id\":\"$GEN_T1\",
        \"away_team_id\":\"$GEN_T2\",
        \"venue_id\":\"$GEN_VENUE\",
        \"scheduled_at\":\"2025-12-28T14:00:00Z\"
    }]
}" "$SCHED_TOKEN")
assert_status "POST /api/matches/import returns 201" "201" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 19. ASSIGNMENTS – full endpoint coverage
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 19. Assignments ──"

RESP=$(do_request POST "$BASE_URL/api/assignments" "{
    \"match_id\":\"$DRAFT_MATCH_ID\",
    \"account_id\":\"$SCHEDULER_ID\",
    \"role\":\"Referee\"
}" "$SCHED_TOKEN")
assert_status "POST /api/assignments returns 201" "201" "$(parse_status "$RESP")"
ASSIGNMENT_ID=$(parse_body "$RESP" | jq -r '.id')

RESP=$(do_request GET "$BASE_URL/api/assignments/match/$DRAFT_MATCH_ID" "" "$SCHED_TOKEN")
assert_status "GET /api/assignments/match/:match_id returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request PUT "$BASE_URL/api/assignments/$ASSIGNMENT_ID/reassign" "{
    \"new_account_id\":\"$REVIEWER_ID\",
    \"reason\":\"Scheduling conflict requires reassignment\"
}" "$SCHED_TOKEN")
assert_status "PUT /api/assignments/:id/reassign returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request DELETE "$BASE_URL/api/assignments/$ASSIGNMENT_ID" "" "$SCHED_TOKEN")
assert_status "DELETE /api/assignments/:id returns 204" "204" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 20. COURSES – remaining endpoint coverage
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 20. Courses – remaining coverage ──"

RESP=$(do_request GET "$BASE_URL/api/courses" "" "$INSTR_TOKEN")
assert_status "GET /api/courses returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request GET "$BASE_URL/api/courses/$COURSE_ID" "" "$INSTR_TOKEN")
assert_status "GET /api/courses/:id returns 200 for member" "200" "$(parse_status "$RESP")"

RESP=$(do_request PUT "$BASE_URL/api/courses/$COURSE_ID" "{
    \"description\":\"Updated fundamentals course description\"
}" "$INSTR_TOKEN")
assert_status "PUT /api/courses/:id returns 200" "200" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 21. OUTLINE NODES – remaining endpoint coverage
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 21. Outline Nodes – remaining coverage ──"

RESP=$(do_request POST "$BASE_URL/api/outline-nodes" "{
    \"course_id\":\"$COURSE_ID\", \"node_type\":\"Chapter\",
    \"title\":\"Chapter 2: Advanced\", \"order_index\":1
}" "$INSTR_TOKEN")
assert_status "Create node for update/delete tests returns 201" "201" "$(parse_status "$RESP")"
TEMP_NODE_ID=$(parse_body "$RESP" | jq -r '.id')

RESP=$(do_request PUT "$BASE_URL/api/outline-nodes/$TEMP_NODE_ID" "{
    \"title\":\"Chapter 2: Advanced Topics\"
}" "$INSTR_TOKEN")
assert_status "PUT /api/outline-nodes/:id returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request DELETE "$BASE_URL/api/outline-nodes/$TEMP_NODE_ID" "" "$INSTR_TOKEN")
assert_status "DELETE /api/outline-nodes/:id returns 204" "204" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 22. COURSE MEMBERS – remaining endpoint coverage
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 22. Course Members – remaining coverage ──"

RESP=$(do_request POST "$BASE_URL/api/courses/$COURSE_ID/members" "{
    \"account_id\":\"$REVIEWER_ID\",
    \"role\":\"Enrolled\"
}" "$INSTR_TOKEN")
assert_status "POST /api/courses/:course_id/members returns 201" "201" "$(parse_status "$RESP")"
MEMBERSHIP_ID=$(parse_body "$RESP" | jq -r '.id')

RESP=$(do_request GET "$BASE_URL/api/courses/$COURSE_ID/members" "" "$INSTR_TOKEN")
assert_status "GET /api/courses/:course_id/members returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request DELETE "$BASE_URL/api/courses/$COURSE_ID/members/$MEMBERSHIP_ID" "" "$INSTR_TOKEN")
assert_status "DELETE /api/courses/:course_id/members/:id returns 204" "204" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 23. RESOURCES – remaining endpoint coverage
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 23. Resources – remaining coverage ──"

RESP=$(do_request GET "$BASE_URL/api/resources?course_id=$COURSE_ID" "" "$INSTR_TOKEN")
assert_status "GET /api/resources returns 200 for member" "200" "$(parse_status "$RESP")"

RESP=$(do_request GET "$BASE_URL/api/resources/search?course_id=$COURSE_ID&q=guide" "" "$INSTR_TOKEN")
assert_status "GET /api/resources/search returns 200 for member" "200" "$(parse_status "$RESP")"

RESP=$(do_request GET "$BASE_URL/api/resources/$RESOURCE_ID" "" "$INSTR_TOKEN")
assert_status "GET /api/resources/:id returns 200 for member" "200" "$(parse_status "$RESP")"

RESP=$(do_request PUT "$BASE_URL/api/resources/$RESOURCE_ID" "{
    \"title\":\"Updated Reference Guide\"
}" "$INSTR_TOKEN")
assert_status "PUT /api/resources/:id returns 200" "200" "$(parse_status "$RESP")"

# Create a Document resource for file version upload test
RESP=$(do_request POST "$BASE_URL/api/resources" "{
    \"course_id\":\"$COURSE_ID\", \"title\":\"Course Document Resource\",
    \"resource_type\":\"Document\", \"visibility\":\"Enrolled\"
}" "$INSTR_TOKEN")
assert_status "Create Document resource for upload test returns 201" "201" "$(parse_status "$RESP")"
DOC_RESOURCE_ID=$(parse_body "$RESP" | jq -r '.id')

echo "Resource test content for upload" > /tmp/test_resource_api.txt
VERSION_RESP=$(curl -s -w "\n%{http_code}" \
    -H "Authorization: Bearer $INSTR_TOKEN" \
    -F "file=@/tmp/test_resource_api.txt;type=text/plain" \
    "$BASE_URL/api/resources/$DOC_RESOURCE_ID/versions" 2>/dev/null)
assert_status "POST /api/resources/:id/versions returns 201" "201" "$(parse_status "$VERSION_RESP")"
VERSION_ID=$(parse_body "$VERSION_RESP" | jq -r '.id // empty')

RESP=$(do_request GET "$BASE_URL/api/resources/$DOC_RESOURCE_ID/versions" "" "$INSTR_TOKEN")
assert_status "GET /api/resources/:id/versions returns 200" "200" "$(parse_status "$RESP")"

if [ -n "$VERSION_ID" ] && [ "$VERSION_ID" != "null" ]; then
    DL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $INSTR_TOKEN" \
        "$BASE_URL/api/resources/versions/$VERSION_ID/download" 2>/dev/null)
    assert_status "GET /api/resources/versions/:version_id/download returns 200" "200" "$DL_STATUS"

    RESP=$(do_request GET "$BASE_URL/api/resources/versions/$VERSION_ID/preview" "" "$INSTR_TOKEN")
    assert_status "GET /api/resources/versions/:version_id/preview returns 200" "200" "$(parse_status "$RESP")"
else
    fail "Resource version download/preview" "no version_id from upload; skipping"
fi
rm -f /tmp/test_resource_api.txt

# ─────────────────────────────────────────────────────────────────────────────
# 24. MODERATION – remaining endpoint coverage
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 24. Moderation – remaining coverage ──"

RESP=$(do_request GET "$BASE_URL/api/moderation/dictionaries" "" "$ADMIN_TOKEN")
assert_status "GET /api/moderation/dictionaries returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request GET "$BASE_URL/api/moderation/dictionaries/$DICT_ID" "" "$ADMIN_TOKEN")
assert_status "GET /api/moderation/dictionaries/:id returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request PUT "$BASE_URL/api/moderation/dictionaries/$DICT_ID" "{
    \"description\":\"Updated bad words filter\"
}" "$ADMIN_TOKEN")
assert_status "PUT /api/moderation/dictionaries/:id returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request POST "$BASE_URL/api/moderation/dictionaries/$DICT_ID/words/bulk" "{
    \"words\":[
        {\"word\":\"spam1\",\"severity\":\"low\"},
        {\"word\":\"spam2\",\"severity\":\"medium\"}
    ]
}" "$ADMIN_TOKEN")
assert_status "POST dictionaries/:dict_id/words/bulk returns 201" "201" "$(parse_status "$RESP")"

RESP=$(do_request GET "$BASE_URL/api/moderation/dictionaries/$DICT_ID/words" "" "$ADMIN_TOKEN")
assert_status "GET dictionaries/:dict_id/words returns 200" "200" "$(parse_status "$RESP")"
WORD_ID=$(parse_body "$RESP" | jq -r '.[0].id // empty')

if [ -n "$WORD_ID" ] && [ "$WORD_ID" != "null" ]; then
    RESP=$(do_request DELETE "$BASE_URL/api/moderation/words/$WORD_ID" "" "$ADMIN_TOKEN")
    assert_status "DELETE /api/moderation/words/:id returns 204" "204" "$(parse_status "$RESP")"
else
    fail "DELETE /api/moderation/words/:id" "no word found in dictionary to delete"
fi

RESP=$(do_request POST "$BASE_URL/api/moderation/dictionaries" '{"name":"Temp Dictionary for Deletion Test"}' "$ADMIN_TOKEN")
assert_status "Create temp dictionary for deletion returns 201" "201" "$(parse_status "$RESP")"
DICT2_ID=$(parse_body "$RESP" | jq -r '.id')

RESP=$(do_request DELETE "$BASE_URL/api/moderation/dictionaries/$DICT2_ID" "" "$ADMIN_TOKEN")
assert_status "DELETE /api/moderation/dictionaries/:id returns 204" "204" "$(parse_status "$RESP")"

RESP=$(do_request POST "$BASE_URL/api/moderation/reviews" "{
    \"content_type\":\"course\",
    \"content_id\":\"$COURSE_ID\"
}" "$REVIEWER_TOKEN")
assert_status "POST /api/moderation/reviews returns 201" "201" "$(parse_status "$RESP")"
MOD_REVIEW_ID=$(parse_body "$RESP" | jq -r '.id')

RESP=$(do_request GET "$BASE_URL/api/moderation/reviews" "" "$REVIEWER_TOKEN")
assert_status "GET /api/moderation/reviews returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request GET "$BASE_URL/api/moderation/reviews/$MOD_REVIEW_ID" "" "$REVIEWER_TOKEN")
assert_status "GET /api/moderation/reviews/:id returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request PUT "$BASE_URL/api/moderation/reviews/$MOD_REVIEW_ID/decide" "{
    \"status\":\"Approved\",
    \"reason\":\"Content is appropriate for the platform\"
}" "$REVIEWER_TOKEN")
assert_status "PUT /api/moderation/reviews/:id/decide returns 200" "200" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 25. REPORTS – remaining endpoint coverage
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 25. Reports – remaining coverage ──"

RESP=$(do_request GET "$BASE_URL/api/reports/$REPORT_ID" "" "$REVIEWER_TOKEN")
assert_status "GET /api/reports/:id returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request PUT "$BASE_URL/api/reports/$REPORT_ID/status" "{
    \"status\":\"Under Review\"
}" "$REVIEWER_TOKEN")
assert_status "PUT /api/reports/:id/status returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request PUT "$BASE_URL/api/reports/$REPORT_ID/assign" "{
    \"assigned_to\":\"$REVIEWER_ID\"
}" "$REVIEWER_TOKEN")
assert_status "PUT /api/reports/:id/assign returns 200" "200" "$(parse_status "$RESP")"

echo "Evidence file content for testing" > /tmp/test_evidence_api.txt
EVID_RESP=$(curl -s -w "\n%{http_code}" \
    -H "Authorization: Bearer $REVIEWER_TOKEN" \
    -F "file=@/tmp/test_evidence_api.txt;type=text/plain" \
    "$BASE_URL/api/reports/$REPORT_ID/evidence" 2>/dev/null)
assert_status "POST /api/reports/:id/evidence returns 201" "201" "$(parse_status "$EVID_RESP")"
EVIDENCE_ID=$(parse_body "$EVID_RESP" | jq -r '.id // empty')

RESP=$(do_request GET "$BASE_URL/api/reports/$REPORT_ID/evidence" "" "$REVIEWER_TOKEN")
assert_status "GET /api/reports/:id/evidence returns 200" "200" "$(parse_status "$RESP")"

if [ -n "$EVIDENCE_ID" ] && [ "$EVIDENCE_ID" != "null" ]; then
    DL_EVID=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $REVIEWER_TOKEN" \
        "$BASE_URL/api/reports/evidence/$EVIDENCE_ID/download" 2>/dev/null)
    assert_status "GET /api/reports/evidence/:evidence_id/download returns 200" "200" "$DL_EVID"
else
    fail "Evidence download" "no evidence_id returned from upload"
fi
rm -f /tmp/test_evidence_api.txt

RESP=$(do_request POST "$BASE_URL/api/reports/$REPORT_ID/notes" "{
    \"content\":\"Reviewed and assigned for investigation.\"
}" "$REVIEWER_TOKEN")
assert_status "POST /api/reports/:id/notes returns 201" "201" "$(parse_status "$RESP")"

RESP=$(do_request GET "$BASE_URL/api/reports/$REPORT_ID/notes" "" "$REVIEWER_TOKEN")
assert_status "GET /api/reports/:id/notes returns 200" "200" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 26. REVIEW WORKFLOW – remaining endpoint coverage
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 26. Review Workflow – remaining coverage ──"

RESP=$(do_request GET "$BASE_URL/api/reviews/configs" "" "$ADMIN_TOKEN")
assert_status "GET /api/reviews/configs returns 200" "200" "$(parse_status "$RESP")"
CONFIG_ID=$(parse_body "$RESP" | jq -r '.[0].id // empty')

if [ -n "$CONFIG_ID" ] && [ "$CONFIG_ID" != "null" ]; then
    RESP=$(do_request GET "$BASE_URL/api/reviews/configs/$CONFIG_ID" "" "$ADMIN_TOKEN")
    assert_status "GET /api/reviews/configs/:id returns 200" "200" "$(parse_status "$RESP")"

    RESP=$(do_request PUT "$BASE_URL/api/reviews/configs/$CONFIG_ID" "{
        \"description\":\"Updated review configuration description\"
    }" "$ADMIN_TOKEN")
    assert_status "PUT /api/reviews/configs/:id returns 200" "200" "$(parse_status "$RESP")"
fi

RESP=$(do_request POST "$BASE_URL/api/reviews/configs" '{"review_type":"temp_deletion_config","required_levels":1}' "$ADMIN_TOKEN")
assert_status "Create temp review config for deletion returns 201" "201" "$(parse_status "$RESP")"
TEMP_CONFIG_ID=$(parse_body "$RESP" | jq -r '.id')

RESP=$(do_request DELETE "$BASE_URL/api/reviews/configs/$TEMP_CONFIG_ID" "" "$ADMIN_TOKEN")
assert_status "DELETE /api/reviews/configs/:id returns 204" "204" "$(parse_status "$RESP")"

RESP=$(do_request GET "$BASE_URL/api/reviews/requests" "" "$REVIEWER_TOKEN")
assert_status "GET /api/reviews/requests returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request GET "$BASE_URL/api/reviews/requests/by-entity?entity_type=course&entity_id=$COURSE_ID" "" "$REVIEWER_TOKEN")
assert_status "GET /api/reviews/requests/by-entity returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request GET "$BASE_URL/api/reviews/my-assignments" "" "$REVIEWER_TOKEN")
assert_status "GET /api/reviews/my-assignments returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request GET "$BASE_URL/api/reviews/levels/request/$REVIEW_REQ_ID" "" "$REVIEWER_TOKEN")
assert_status "GET /api/reviews/levels/request/:request_id returns 200" "200" "$(parse_status "$RESP")"

# Create a 1-level config for the resubmit flow (Returned -> resubmit)
RESP=$(do_request POST "$BASE_URL/api/reviews/configs" '{"review_type":"returned_flow_test","required_levels":1}' "$ADMIN_TOKEN")
assert_status "Create returned-flow config returns 201" "201" "$(parse_status "$RESP")"

RESP=$(do_request POST "$BASE_URL/api/reviews/requests" "{
    \"review_type\":\"returned_flow_test\",
    \"entity_type\":\"course\", \"entity_id\":\"$COURSE_ID\"
}" "$INSTR_TOKEN")
assert_status "Submit returned-flow request returns 201" "201" "$(parse_status "$RESP")"
RETURN_REQ_ID=$(parse_body "$RESP" | jq -r '.id')
RETURN_LEVEL_ID=$(parse_body "$RESP" | jq -r '.levels[0].id // empty')

if [ -n "$RETURN_LEVEL_ID" ] && [ "$RETURN_LEVEL_ID" != "null" ]; then
    RESP=$(do_request PUT "$BASE_URL/api/reviews/levels/$RETURN_LEVEL_ID/assign" "{
        \"assignee_id\":\"$REVIEWER_ID\"
    }" "$ADMIN_TOKEN")
    assert_status "PUT /api/reviews/levels/:id/assign returns 200" "200" "$(parse_status "$RESP")"

    RESP=$(do_request PUT "$BASE_URL/api/reviews/levels/$RETURN_LEVEL_ID/decide" "{
        \"decision\":\"Returned\",
        \"annotation\":\"Please provide additional details\"
    }" "$REVIEWER_TOKEN")
    assert_status "Decide level Returned returns 200" "200" "$(parse_status "$RESP")"

    RESP=$(do_request POST "$BASE_URL/api/reviews/requests/$RETURN_REQ_ID/resubmit" "" "$REVIEWER_TOKEN")
    assert_status "POST /api/reviews/requests/:id/resubmit returns 200" "200" "$(parse_status "$RESP")"
else
    fail "Returned-flow level tests" "no level_id from request submission"
fi

# Submit a child request with parent_id to test follow-up-requests list
RESP=$(do_request POST "$BASE_URL/api/reviews/requests" "{
    \"review_type\":\"course_publish\",
    \"entity_type\":\"course\", \"entity_id\":\"$COURSE_ID\",
    \"parent_id\":\"$REVIEW_REQ_ID\"
}" "$INSTR_TOKEN")
assert_status "Submit child review request (parent_id set) returns 201" "201" "$(parse_status "$RESP")"

RESP=$(do_request GET "$BASE_URL/api/reviews/requests/$REVIEW_REQ_ID/follow-up-requests" "" "$REVIEWER_TOKEN")
assert_status "GET /api/reviews/requests/:id/follow-up-requests returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request POST "$BASE_URL/api/reviews/requests/$REVIEW_REQ_ID/follow-ups" "{
    \"content\":\"Follow-up comment: additional context provided.\"
}" "$REVIEWER_TOKEN")
assert_status "POST /api/reviews/requests/:id/follow-ups returns 201" "201" "$(parse_status "$RESP")"

RESP=$(do_request GET "$BASE_URL/api/reviews/requests/$REVIEW_REQ_ID/follow-ups" "" "$REVIEWER_TOKEN")
assert_status "GET /api/reviews/requests/:id/follow-ups returns 200" "200" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 27. PAYMENTS – remaining endpoint coverage
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 27. Payments – remaining coverage ──"

RESP=$(do_request GET "$BASE_URL/api/payments" "" "$FINANCE_TOKEN")
assert_status "GET /api/payments returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request GET "$BASE_URL/api/payments/failed-retriable" "" "$FINANCE_TOKEN")
assert_status "GET /api/payments/failed-retriable returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request GET "$BASE_URL/api/payments/$PAYMENT_ID" "" "$FINANCE_TOKEN")
assert_status "GET /api/payments/:id returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request GET "$BASE_URL/api/payments/account/$ADMIN_ID" "" "$FINANCE_TOKEN")
assert_status "GET /api/payments/account/:account_id returns 200" "200" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 28. RECONCILIATION – remaining endpoint coverage
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 28. Reconciliation – remaining coverage ──"

YESTERDAY=$(date -d "yesterday" '+%Y-%m-%d' 2>/dev/null || date -v-1d '+%Y-%m-%d' 2>/dev/null || echo "$TODAY")
RESP=$(do_request GET "$BASE_URL/api/reconciliation/summary/range?start_date=$YESTERDAY&end_date=$TODAY" "" "$FINANCE_TOKEN")
assert_status "GET /api/reconciliation/summary/range returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request GET "$BASE_URL/api/reconciliation/reports" "" "$FINANCE_TOKEN")
assert_status "GET /api/reconciliation/reports returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request GET "$BASE_URL/api/reconciliation/reports/$RECON_ID" "" "$FINANCE_TOKEN")
assert_status "GET /api/reconciliation/reports/:id returns 200" "200" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 29. AUDIT – remaining endpoint coverage
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 29. Audit – remaining coverage ──"

RESP=$(do_request GET "$BASE_URL/api/audit/logs/by-entity?entity_type=account&entity_id=$ADMIN_ID" "" "$AUDITOR_TOKEN")
assert_status "GET /api/audit/logs/by-entity returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request GET "$BASE_URL/api/audit/logs/by-actor/$ADMIN_ID" "" "$AUDITOR_TOKEN")
assert_status "GET /api/audit/logs/by-actor/:actor_id returns 200" "200" "$(parse_status "$RESP")"

RESP=$(do_request GET "$BASE_URL/api/audit/logs" "" "$AUDITOR_TOKEN")
FIRST_LOG_ID=$(parse_body "$RESP" | jq -r 'if type == "array" then .[0].id else null end // empty')
if [ -n "$FIRST_LOG_ID" ] && [ "$FIRST_LOG_ID" != "null" ]; then
    RESP=$(do_request GET "$BASE_URL/api/audit/logs/$FIRST_LOG_ID" "" "$AUDITOR_TOKEN")
    assert_status "GET /api/audit/logs/:id returns 200" "200" "$(parse_status "$RESP")"
else
    fail "GET /api/audit/logs/:id" "no audit log entry found to retrieve by ID"
fi

RESP=$(do_request GET "$BASE_URL/api/audit/hash-chain" "" "$AUDITOR_TOKEN")
assert_status "GET /api/audit/hash-chain returns 200" "200" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 15. LOGOUT
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 15. Logout ──"

RESP=$(do_request POST "$BASE_URL/api/auth/logout" '{"refresh_token":"some-old-token"}' "$ADMIN_TOKEN")
assert_status "Logout returns 204" "204" "$(parse_status "$RESP")"

# ─────────────────────────────────────────────────────────────────────────────
# 16. PASSWORD CHANGE
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 16. Password Change ──"

RESP=$(do_request PUT "$BASE_URL/api/accounts/$SCHEDULER_ID/password" "{
    \"old_password\":\"SchedulerP1!\", \"new_password\":\"NewScheduler1!\"
}" "$SCHED_TOKEN")
assert_status "Change own password returns 200" "200" "$(parse_status "$RESP")"

# Cannot change someone else's password
RESP=$(do_request PUT "$BASE_URL/api/accounts/$ADMIN_ID/password" "{
    \"old_password\":\"x\", \"new_password\":\"NewPass12345!\"
}" "$SCHED_TOKEN")
assert_status "Cannot change other's password (403)" "403" "$(parse_status "$RESP")"

# =============================================================================
# SUMMARY
# =============================================================================
echo ""
echo "=============================================="
echo "  API TEST SUMMARY"
echo "=============================================="
echo "  Total:  $TOTAL"
echo "  Passed: $PASSED"
echo "  Failed: $FAILED"
echo "=============================================="

if [ "$FAILED" -gt 0 ]; then
    echo "  STATUS: FAILED"
    echo -e "  Failures:$FAIL_DETAILS"
    echo "=============================================="
    exit 1
else
    echo "  STATUS: ALL PASSED"
    echo "=============================================="
    exit 0
fi
