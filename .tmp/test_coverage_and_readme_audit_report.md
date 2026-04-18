# Test Coverage Audit

Project type declaration check: README top does not contain an exact strict token (`backend|fullstack|web|android|ios|desktop`); inferred type = **backend** from `repo/README.md:1` and Go server entrypoint `repo/cmd/server/main.go:30`.

## Backend Endpoint Inventory

Total resolved endpoints: **114**.

| # | Endpoint | Route Evidence |
|---|---|---|
| 1 | `GET /api/accounts` | `internal/router/router.go:57` |
| 2 | `POST /api/accounts` | `internal/router/router.go:56` |
| 3 | `GET /api/accounts/:id` | `internal/router/router.go:61` |
| 4 | `PUT /api/accounts/:id/password` | `internal/router/router.go:64` |
| 5 | `PUT /api/accounts/:id/status` | `internal/router/router.go:58` |
| 6 | `POST /api/assignments` | `internal/router/router.go:97` |
| 7 | `DELETE /api/assignments/:id` | `internal/router/router.go:100` |
| 8 | `PUT /api/assignments/:id/reassign` | `internal/router/router.go:99` |
| 9 | `GET /api/assignments/match/:match_id` | `internal/router/router.go:98` |
| 10 | `GET /api/audit/hash-chain` | `internal/router/router.go:248` |
| 11 | `POST /api/audit/hash-chain/build` | `internal/router/router.go:252` |
| 12 | `GET /api/audit/hash-chain/verify` | `internal/router/router.go:247` |
| 13 | `GET /api/audit/logs` | `internal/router/router.go:239` |
| 14 | `GET /api/audit/logs/:id` | `internal/router/router.go:243` |
| 15 | `GET /api/audit/logs/by-actor/:actor_id` | `internal/router/router.go:242` |
| 16 | `GET /api/audit/logs/by-entity` | `internal/router/router.go:241` |
| 17 | `GET /api/audit/logs/export` | `internal/router/router.go:240` |
| 18 | `GET /api/audit/logs/tier-counts` | `internal/router/router.go:244` |
| 19 | `POST /api/audit/purge-expired` | `internal/router/router.go:253` |
| 20 | `POST /api/auth/logout` | `internal/router/router.go:50` |
| 21 | `GET /api/courses` | `internal/router/router.go:107` |
| 22 | `POST /api/courses` | `internal/router/router.go:106` |
| 23 | `GET /api/courses/:course_id/members` | `internal/router/router.go:121` |
| 24 | `POST /api/courses/:course_id/members` | `internal/router/router.go:120` |
| 25 | `DELETE /api/courses/:course_id/members/:id` | `internal/router/router.go:122` |
| 26 | `GET /api/courses/:id` | `internal/router/router.go:108` |
| 27 | `PUT /api/courses/:id` | `internal/router/router.go:109` |
| 28 | `GET /api/matches` | `internal/router/router.go:90` |
| 29 | `POST /api/matches` | `internal/router/router.go:87` |
| 30 | `GET /api/matches/:id` | `internal/router/router.go:91` |
| 31 | `PUT /api/matches/:id` | `internal/router/router.go:92` |
| 32 | `PUT /api/matches/:id/status` | `internal/router/router.go:93` |
| 33 | `POST /api/matches/generate` | `internal/router/router.go:89` |
| 34 | `POST /api/matches/import` | `internal/router/router.go:88` |
| 35 | `POST /api/moderation/check` | `internal/router/router.go:157` |
| 36 | `GET /api/moderation/dictionaries` | `internal/router/router.go:145` |
| 37 | `POST /api/moderation/dictionaries` | `internal/router/router.go:144` |
| 38 | `GET /api/moderation/dictionaries/:dict_id/words` | `internal/router/router.go:153` |
| 39 | `POST /api/moderation/dictionaries/:dict_id/words` | `internal/router/router.go:151` |
| 40 | `POST /api/moderation/dictionaries/:dict_id/words/bulk` | `internal/router/router.go:152` |
| 41 | `GET /api/moderation/dictionaries/:id` | `internal/router/router.go:146` |
| 42 | `PUT /api/moderation/dictionaries/:id` | `internal/router/router.go:147` |
| 43 | `DELETE /api/moderation/dictionaries/:id` | `internal/router/router.go:148` |
| 44 | `GET /api/moderation/reviews` | `internal/router/router.go:162` |
| 45 | `POST /api/moderation/reviews` | `internal/router/router.go:161` |
| 46 | `GET /api/moderation/reviews/:id` | `internal/router/router.go:163` |
| 47 | `PUT /api/moderation/reviews/:id/decide` | `internal/router/router.go:164` |
| 48 | `DELETE /api/moderation/words/:id` | `internal/router/router.go:154` |
| 49 | `POST /api/outline-nodes` | `internal/router/router.go:113` |
| 50 | `PUT /api/outline-nodes/:id` | `internal/router/router.go:115` |
| 51 | `DELETE /api/outline-nodes/:id` | `internal/router/router.go:116` |
| 52 | `GET /api/outline-nodes/course/:course_id` | `internal/router/router.go:114` |
| 53 | `GET /api/payments` | `internal/router/router.go:218` |
| 54 | `POST /api/payments` | `internal/router/router.go:217` |
| 55 | `GET /api/payments/:id` | `internal/router/router.go:220` |
| 56 | `PUT /api/payments/:id/fail` | `internal/router/router.go:223` |
| 57 | `PUT /api/payments/:id/retry` | `internal/router/router.go:224` |
| 58 | `PUT /api/payments/:id/sign` | `internal/router/router.go:222` |
| 59 | `GET /api/payments/account/:account_id` | `internal/router/router.go:221` |
| 60 | `GET /api/payments/failed-retriable` | `internal/router/router.go:219` |
| 61 | `GET /api/reconciliation/reports` | `internal/router/router.go:231` |
| 62 | `POST /api/reconciliation/reports` | `internal/router/router.go:230` |
| 63 | `GET /api/reconciliation/reports/:id` | `internal/router/router.go:232` |
| 64 | `GET /api/reconciliation/reports/:id/csv` | `internal/router/router.go:233` |
| 65 | `GET /api/reconciliation/summary` | `internal/router/router.go:228` |
| 66 | `GET /api/reconciliation/summary/range` | `internal/router/router.go:229` |
| 67 | `GET /api/reports` | `internal/router/router.go:169` |
| 68 | `POST /api/reports` | `internal/router/router.go:167` |
| 69 | `GET /api/reports/:id` | `internal/router/router.go:170` |
| 70 | `PUT /api/reports/:id/assign` | `internal/router/router.go:172` |
| 71 | `GET /api/reports/:id/evidence` | `internal/router/router.go:176` |
| 72 | `POST /api/reports/:id/evidence` | `internal/router/router.go:175` |
| 73 | `GET /api/reports/:id/notes` | `internal/router/router.go:179` |
| 74 | `POST /api/reports/:id/notes` | `internal/router/router.go:178` |
| 75 | `PUT /api/reports/:id/status` | `internal/router/router.go:171` |
| 76 | `GET /api/reports/evidence/:evidence_id/download` | `internal/router/router.go:177` |
| 77 | `GET /api/resources` | `internal/router/router.go:127` |
| 78 | `POST /api/resources` | `internal/router/router.go:126` |
| 79 | `GET /api/resources/:id` | `internal/router/router.go:129` |
| 80 | `PUT /api/resources/:id` | `internal/router/router.go:130` |
| 81 | `GET /api/resources/:id/versions` | `internal/router/router.go:134` |
| 82 | `POST /api/resources/:id/versions` | `internal/router/router.go:133` |
| 83 | `GET /api/resources/search` | `internal/router/router.go:128` |
| 84 | `GET /api/resources/versions/:version_id/download` | `internal/router/router.go:135` |
| 85 | `GET /api/resources/versions/:version_id/preview` | `internal/router/router.go:136` |
| 86 | `GET /api/reviews/configs` | `internal/router/router.go:185` |
| 87 | `POST /api/reviews/configs` | `internal/router/router.go:184` |
| 88 | `GET /api/reviews/configs/:id` | `internal/router/router.go:186` |
| 89 | `PUT /api/reviews/configs/:id` | `internal/router/router.go:187` |
| 90 | `DELETE /api/reviews/configs/:id` | `internal/router/router.go:188` |
| 91 | `PUT /api/reviews/levels/:id/assign` | `internal/router/router.go:205` |
| 92 | `PUT /api/reviews/levels/:id/decide` | `internal/router/router.go:206` |
| 93 | `GET /api/reviews/levels/request/:request_id` | `internal/router/router.go:204` |
| 94 | `GET /api/reviews/my-assignments` | `internal/router/router.go:200` |
| 95 | `GET /api/reviews/requests` | `internal/router/router.go:193` |
| 96 | `POST /api/reviews/requests` | `internal/router/router.go:191` |
| 97 | `GET /api/reviews/requests/:id` | `internal/router/router.go:195` |
| 98 | `GET /api/reviews/requests/:id/follow-up-requests` | `internal/router/router.go:196` |
| 99 | `GET /api/reviews/requests/:id/follow-ups` | `internal/router/router.go:210` |
| 100 | `POST /api/reviews/requests/:id/follow-ups` | `internal/router/router.go:209` |
| 101 | `POST /api/reviews/requests/:id/resubmit` | `internal/router/router.go:197` |
| 102 | `GET /api/reviews/requests/by-entity` | `internal/router/router.go:194` |
| 103 | `GET /api/seasons` | `internal/router/router.go:72` |
| 104 | `POST /api/seasons` | `internal/router/router.go:71` |
| 105 | `GET /api/seasons/:id` | `internal/router/router.go:73` |
| 106 | `POST /api/teams` | `internal/router/router.go:77` |
| 107 | `GET /api/teams/season/:season_id` | `internal/router/router.go:78` |
| 108 | `GET /api/venues` | `internal/router/router.go:83` |
| 109 | `POST /api/venues` | `internal/router/router.go:82` |
| 110 | `POST /auth/login` | `internal/router/router.go:39` |
| 111 | `POST /auth/refresh` | `internal/router/router.go:40` |
| 112 | `GET /health` | `cmd/server/main.go:146` |
| 113 | `GET /health/detailed` | `internal/router/router.go:33` |
| 114 | `GET /metrics` | `internal/router/router.go:34` |

## API Test Mapping Table

| Endpoint | Covered | Test Type | Test File(s) | Evidence |
|---|---|---|---|---|
| `GET /api/accounts` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:57`; request `repo/API_tests/run_api_tests.sh:117`, `repo/API_tests/run_api_tests.sh:246` |
| `POST /api/accounts` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:56`; request `repo/API_tests/run_api_tests.sh:210`, `repo/API_tests/run_api_tests.sh:214`, `repo/API_tests/run_api_tests.sh:218` |
| `GET /api/accounts/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:61`; request `repo/API_tests/run_api_tests.sh:250` |
| `PUT /api/accounts/:id/password` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:64`; request `repo/API_tests/run_api_tests.sh:1184`, `repo/API_tests/run_api_tests.sh:1190` |
| `PUT /api/accounts/:id/status` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:58`; request `repo/API_tests/run_api_tests.sh:259`, `repo/API_tests/run_api_tests.sh:263` |
| `POST /api/assignments` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:97`; request `repo/API_tests/run_api_tests.sh:783` |
| `DELETE /api/assignments/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:100`; request `repo/API_tests/run_api_tests.sh:800` |
| `PUT /api/assignments/:id/reassign` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:99`; request `repo/API_tests/run_api_tests.sh:794` |
| `GET /api/assignments/match/:match_id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:98`; request `repo/API_tests/run_api_tests.sh:791` |
| `GET /api/audit/hash-chain` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:248`; request `repo/API_tests/run_api_tests.sh:1166` |
| `POST /api/audit/hash-chain/build` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:252`; request `repo/API_tests/run_api_tests.sh:698`, `repo/API_tests/run_api_tests.sh:705` |
| `GET /api/audit/hash-chain/verify` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:247`; request `repo/API_tests/run_api_tests.sh:709` |
| `GET /api/audit/logs` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:239`; request `repo/API_tests/run_api_tests.sh:691`, `repo/API_tests/run_api_tests.sh:723`, `repo/API_tests/run_api_tests.sh:1157` |
| `GET /api/audit/logs/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:243`; request `repo/API_tests/run_api_tests.sh:694`, `repo/API_tests/run_api_tests.sh:714`, `repo/API_tests/run_api_tests.sh:1151` |
| `GET /api/audit/logs/by-actor/:actor_id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:242`; request `repo/API_tests/run_api_tests.sh:1154` |
| `GET /api/audit/logs/by-entity` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:241`; request `repo/API_tests/run_api_tests.sh:1151` |
| `GET /api/audit/logs/export` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:240`; request `repo/API_tests/run_api_tests.sh:714` |
| `GET /api/audit/logs/tier-counts` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:244`; request `repo/API_tests/run_api_tests.sh:694` |
| `POST /api/audit/purge-expired` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:253`; request `repo/API_tests/run_api_tests.sh:701` |
| `POST /api/auth/logout` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:50`; request `repo/API_tests/run_api_tests.sh:1175` |
| `GET /api/courses` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:107`; request `repo/API_tests/run_api_tests.sh:809` |
| `POST /api/courses` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:106`; request `repo/API_tests/run_api_tests.sh:302`, `repo/API_tests/run_api_tests.sh:393` |
| `GET /api/courses/:course_id/members` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:121`; request `repo/API_tests/run_api_tests.sh:450`, `repo/API_tests/run_api_tests.sh:854` |
| `POST /api/courses/:course_id/members` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:120`; request `repo/API_tests/run_api_tests.sh:847` |
| `DELETE /api/courses/:course_id/members/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:122`; request `repo/API_tests/run_api_tests.sh:857` |
| `GET /api/courses/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:108`; request `repo/API_tests/run_api_tests.sh:442`, `repo/API_tests/run_api_tests.sh:812` |
| `PUT /api/courses/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:109`; request `repo/API_tests/run_api_tests.sh:815` |
| `GET /api/matches` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:90`; request `repo/API_tests/run_api_tests.sh:745` |
| `POST /api/matches` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:87`; request `repo/API_tests/run_api_tests.sh:346`, `repo/API_tests/run_api_tests.sh:356`, `repo/API_tests/run_api_tests.sh:364` |
| `GET /api/matches/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:91`; request `repo/API_tests/run_api_tests.sh:748` |
| `PUT /api/matches/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:92`; request `repo/API_tests/run_api_tests.sh:760` |
| `PUT /api/matches/:id/status` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:93`; request `repo/API_tests/run_api_tests.sh:372`, `repo/API_tests/run_api_tests.sh:377`, `repo/API_tests/run_api_tests.sh:381` |
| `POST /api/matches/generate` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:89`; request `repo/API_tests/run_api_tests.sh:489`, `repo/API_tests/run_api_tests.sh:511` |
| `POST /api/matches/import` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:88`; request `repo/API_tests/run_api_tests.sh:765` |
| `POST /api/moderation/check` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:157`; request `repo/API_tests/run_api_tests.sh:535`, `repo/API_tests/run_api_tests.sh:540` |
| `GET /api/moderation/dictionaries` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:145`; request `repo/API_tests/run_api_tests.sh:919` |
| `POST /api/moderation/dictionaries` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:144`; request `repo/API_tests/run_api_tests.sh:526`, `repo/API_tests/run_api_tests.sh:545`, `repo/API_tests/run_api_tests.sh:949` |
| `GET /api/moderation/dictionaries/:dict_id/words` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:153`; request `repo/API_tests/run_api_tests.sh:938` |
| `POST /api/moderation/dictionaries/:dict_id/words` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:151`; request `repo/API_tests/run_api_tests.sh:531` |
| `POST /api/moderation/dictionaries/:dict_id/words/bulk` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:152`; request `repo/API_tests/run_api_tests.sh:930` |
| `GET /api/moderation/dictionaries/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:146`; request `repo/API_tests/run_api_tests.sh:922` |
| `PUT /api/moderation/dictionaries/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:147`; request `repo/API_tests/run_api_tests.sh:925` |
| `DELETE /api/moderation/dictionaries/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:148`; request `repo/API_tests/run_api_tests.sh:953` |
| `GET /api/moderation/reviews` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:162`; request `repo/API_tests/run_api_tests.sh:963` |
| `POST /api/moderation/reviews` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:161`; request `repo/API_tests/run_api_tests.sh:956` |
| `GET /api/moderation/reviews/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:163`; request `repo/API_tests/run_api_tests.sh:966` |
| `PUT /api/moderation/reviews/:id/decide` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:164`; request `repo/API_tests/run_api_tests.sh:969` |
| `DELETE /api/moderation/words/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:154`; request `repo/API_tests/run_api_tests.sh:943` |
| `POST /api/outline-nodes` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:113`; request `repo/API_tests/run_api_tests.sh:399`, `repo/API_tests/run_api_tests.sh:407`, `repo/API_tests/run_api_tests.sh:826` |
| `PUT /api/outline-nodes/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:115`; request `repo/API_tests/run_api_tests.sh:833` |
| `DELETE /api/outline-nodes/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:116`; request `repo/API_tests/run_api_tests.sh:838` |
| `GET /api/outline-nodes/course/:course_id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:114`; request `repo/API_tests/run_api_tests.sh:414`, `repo/API_tests/run_api_tests.sh:446` |
| `GET /api/payments` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:218`; request `repo/API_tests/run_api_tests.sh:1117` |
| `POST /api/payments` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:217`; request `repo/API_tests/run_api_tests.sh:622`, `repo/API_tests/run_api_tests.sh:632`, `repo/API_tests/run_api_tests.sh:640` |
| `GET /api/payments/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:220`; request `repo/API_tests/run_api_tests.sh:1120`, `repo/API_tests/run_api_tests.sh:1123` |
| `PUT /api/payments/:id/fail` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:223`; request `repo/API_tests/run_api_tests.sh:662` |
| `PUT /api/payments/:id/retry` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:224`; request `repo/API_tests/run_api_tests.sh:666` |
| `PUT /api/payments/:id/sign` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:222`; request `repo/API_tests/run_api_tests.sh:647`, `repo/API_tests/run_api_tests.sh:652` |
| `GET /api/payments/account/:account_id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:221`; request `repo/API_tests/run_api_tests.sh:1126` |
| `GET /api/payments/failed-retriable` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:219`; request `repo/API_tests/run_api_tests.sh:1120` |
| `GET /api/reconciliation/reports` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:231`; request `repo/API_tests/run_api_tests.sh:1139` |
| `POST /api/reconciliation/reports` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:230`; request `repo/API_tests/run_api_tests.sh:677` |
| `GET /api/reconciliation/reports/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:232`; request `repo/API_tests/run_api_tests.sh:1142` |
| `GET /api/reconciliation/reports/:id/csv` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:233`; request `repo/API_tests/run_api_tests.sh:682` |
| `GET /api/reconciliation/summary` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:228`; request `repo/API_tests/run_api_tests.sh:673` |
| `GET /api/reconciliation/summary/range` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:229`; request `repo/API_tests/run_api_tests.sh:1136` |
| `GET /api/reports` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:169`; request `repo/API_tests/run_api_tests.sh:569` |
| `POST /api/reports` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:167`; request `repo/API_tests/run_api_tests.sh:554`, `repo/API_tests/run_api_tests.sh:562` |
| `GET /api/reports/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:170`; request `repo/API_tests/run_api_tests.sh:981` |
| `PUT /api/reports/:id/assign` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:172`; request `repo/API_tests/run_api_tests.sh:989` |
| `GET /api/reports/:id/evidence` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:176`; request `repo/API_tests/run_api_tests.sh:1002` |
| `POST /api/reports/:id/evidence` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:175`; request `repo/API_tests/run_api_tests.sh:998`, `repo/API_tests/run_api_tests.sh:1002` |
| `GET /api/reports/:id/notes` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:179`; request `repo/API_tests/run_api_tests.sh:1020` |
| `POST /api/reports/:id/notes` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:178`; request `repo/API_tests/run_api_tests.sh:1015` |
| `PUT /api/reports/:id/status` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:171`; request `repo/API_tests/run_api_tests.sh:984` |
| `GET /api/reports/evidence/:evidence_id/download` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:177`; request `repo/API_tests/run_api_tests.sh:1008` |
| `GET /api/resources` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:127`; request `repo/API_tests/run_api_tests.sh:454`, `repo/API_tests/run_api_tests.sh:866` |
| `POST /api/resources` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:126`; request `repo/API_tests/run_api_tests.sh:418`, `repo/API_tests/run_api_tests.sh:428`, `repo/API_tests/run_api_tests.sh:881` |
| `GET /api/resources/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:129`; request `repo/API_tests/run_api_tests.sh:458`, `repo/API_tests/run_api_tests.sh:462`, `repo/API_tests/run_api_tests.sh:869` |
| `PUT /api/resources/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:130`; request `repo/API_tests/run_api_tests.sh:875` |
| `GET /api/resources/:id/versions` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:134`; request `repo/API_tests/run_api_tests.sh:897` |
| `POST /api/resources/:id/versions` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:133`; request `repo/API_tests/run_api_tests.sh:893`, `repo/API_tests/run_api_tests.sh:897` |
| `GET /api/resources/search` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:128`; request `repo/API_tests/run_api_tests.sh:458`, `repo/API_tests/run_api_tests.sh:869` |
| `GET /api/resources/versions/:version_id/download` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:135`; request `repo/API_tests/run_api_tests.sh:903` |
| `GET /api/resources/versions/:version_id/preview` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:136`; request `repo/API_tests/run_api_tests.sh:906` |
| `GET /api/reviews/configs` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:185`; request `repo/API_tests/run_api_tests.sh:1029` |
| `POST /api/reviews/configs` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:184`; request `repo/API_tests/run_api_tests.sh:579`, `repo/API_tests/run_api_tests.sh:583`, `repo/API_tests/run_api_tests.sh:1043` |
| `GET /api/reviews/configs/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:186`; request `repo/API_tests/run_api_tests.sh:1034` |
| `PUT /api/reviews/configs/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:187`; request `repo/API_tests/run_api_tests.sh:1037` |
| `DELETE /api/reviews/configs/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:188`; request `repo/API_tests/run_api_tests.sh:1047` |
| `PUT /api/reviews/levels/:id/assign` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:205`; request `repo/API_tests/run_api_tests.sh:1075` |
| `PUT /api/reviews/levels/:id/decide` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:206`; request `repo/API_tests/run_api_tests.sh:601`, `repo/API_tests/run_api_tests.sh:611`, `repo/API_tests/run_api_tests.sh:1080` |
| `GET /api/reviews/levels/request/:request_id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:204`; request `repo/API_tests/run_api_tests.sh:1059` |
| `GET /api/reviews/my-assignments` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:200`; request `repo/API_tests/run_api_tests.sh:1056` |
| `GET /api/reviews/requests` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:193`; request `repo/API_tests/run_api_tests.sh:1050` |
| `POST /api/reviews/requests` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:191`; request `repo/API_tests/run_api_tests.sh:587`, `repo/API_tests/run_api_tests.sh:1066`, `repo/API_tests/run_api_tests.sh:1093` |
| `GET /api/reviews/requests/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:195`; request `repo/API_tests/run_api_tests.sh:596`, `repo/API_tests/run_api_tests.sh:607`, `repo/API_tests/run_api_tests.sh:1053` |
| `GET /api/reviews/requests/:id/follow-up-requests` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:196`; request `repo/API_tests/run_api_tests.sh:1100` |
| `GET /api/reviews/requests/:id/follow-ups` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:210`; request `repo/API_tests/run_api_tests.sh:1108` |
| `POST /api/reviews/requests/:id/follow-ups` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:209`; request `repo/API_tests/run_api_tests.sh:1103` |
| `POST /api/reviews/requests/:id/resubmit` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:197`; request `repo/API_tests/run_api_tests.sh:1086` |
| `GET /api/reviews/requests/by-entity` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:194`; request `repo/API_tests/run_api_tests.sh:1053` |
| `GET /api/seasons` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:72`; request `repo/API_tests/run_api_tests.sh:319` |
| `POST /api/seasons` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:71`; request `repo/API_tests/run_api_tests.sh:298`, `repo/API_tests/run_api_tests.sh:311`, `repo/API_tests/run_api_tests.sh:316` |
| `GET /api/seasons/:id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:73`; request `repo/API_tests/run_api_tests.sh:732` |
| `POST /api/teams` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:77`; request `repo/API_tests/run_api_tests.sh:323`, `repo/API_tests/run_api_tests.sh:327`, `repo/API_tests/run_api_tests.sh:476` |
| `GET /api/teams/season/:season_id` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:78`; request `repo/API_tests/run_api_tests.sh:331` |
| `GET /api/venues` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:83`; request `repo/API_tests/run_api_tests.sh:736` |
| `POST /api/venues` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:82`; request `repo/API_tests/run_api_tests.sh:335`, `repo/API_tests/run_api_tests.sh:485` |
| `POST /auth/login` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:39`; request `repo/API_tests/run_api_tests.sh:107`, `repo/API_tests/run_api_tests.sh:111`, `repo/API_tests/run_api_tests.sh:174` |
| `POST /auth/refresh` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:40`; request `repo/API_tests/run_api_tests.sh:120`, `repo/API_tests/run_api_tests.sh:193` |
| `GET /health` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `cmd/server/main.go:146`; request `repo/API_tests/run_api_tests.sh:89` |
| `GET /health/detailed` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:33`; request `repo/API_tests/run_api_tests.sh:93` |
| `GET /metrics` | yes | true no-mock HTTP | `repo/API_tests/run_api_tests.sh` | route `internal/router/router.go:34`; request `repo/API_tests/run_api_tests.sh:97` |

## Coverage Summary

- Total endpoints: **114**
- Endpoints with HTTP tests: **114**
- Endpoints with TRUE no-mock tests: **114**
- HTTP coverage %: **100.00%**
- True API coverage %: **100.00%**

## Unit Test Summary

### Backend Unit Tests

- Unit test files detected in `repo/unit_tests`: **20**
- Core coverage present for token/password/role/status/transition/idempotency/audit helper logic (e.g., `repo/unit_tests/token_service_test.go:21`, `repo/unit_tests/password_validation_test.go:10`).
- Important backend modules not directly unit-tested: handlers (`repo/internal/handler/*.go`), repositories (`repo/internal/repository/*.go`), middleware (`repo/internal/middleware/*.go`).

### Frontend Unit Tests (STRICT REQUIREMENT)

- frontend test files: **NONE**
- frameworks/tools detected: **NONE**
- components/modules covered: **NONE**
- important frontend modules not tested: N/A (backend inferred)

**Frontend unit tests: MISSING**

CRITICAL GAP rule: not triggered (project inferred backend, not fullstack/web).

## Tests Check

- API observability is mostly clear (method/path + body + status assertions in `repo/API_tests/run_api_tests.sh`).
- Weakness: many assertions are status-only; response contract assertions are inconsistent.
- `run_tests.sh` has Docker path, but also local/no-docker modes (`repo/run_tests.sh:25`, `repo/run_tests.sh:27`) so strict Docker-only discipline is not enforced by script design.

## Test Coverage Score (0–100)

**81/100**

## Score Rationale

- High endpoint coverage via HTTP flow tests.
- No explicit mocking signatures detected in audited test paths.
- Gaps remain in deep unit coverage for handler/repository/middleware behavior and rich response assertions.

## Key Gaps

- Add direct tests for middleware authorization and limiter behavior.
- Add repository behavior tests for DB query/constraint branches.
- Strengthen API assertions beyond status codes.

## Confidence & Assumptions

- Confidence: high for static route-to-test mapping.
- Assumption: dynamic/conditional route registration not present beyond audited files.

# README Audit

## High Priority Issues

- Strict literal `docker-compose up` requirement still fails if only `docker compose up` is documented.
- Any non-Docker runtime/install path in README fails strict environment rule.
- Missing explicit top token for project type fails strict declaration rule.

## Medium Priority Issues

- Test/run sections include optional local modes that weaken reproducibility expectations under strict policy.

## Low Priority Issues

- Dense endpoint listing reduces readability and verification speed.

## Hard Gate Failures

- Startup command must include `docker-compose up` literal (strict gate).
- Environment rules disallow local runtime install/dependency execution paths.
- Top-level project type strict token missing.

## README Verdict (PASS / PARTIAL PASS / FAIL)

**FAIL**
