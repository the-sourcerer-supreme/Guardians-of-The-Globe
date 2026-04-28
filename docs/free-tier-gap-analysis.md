# Free-Tier Gap Analysis

## Current repo reality

The repo already has three meaningful foundations:

- `apps/coordinator-dashboard` is a working local-first React dashboard.
- `apps/field-agent-app` is a working Flutter prototype for offline need capture.
- `services/cloud-functions` and `infra/firebase` define the future Firebase backend shape.

The repo does **not** yet have a complete end-to-end MVP. The biggest gaps are product gaps, not styling gaps.

## What is built vs. what is missing

| Area | Status | Notes |
| --- | --- | --- |
| Coordinator dashboard | Partial | Local mode works, but review queue, audit timeline, duplicate detection, and richer dispatch rationale are still missing. |
| Field agent app | Partial | Offline queue works locally, but GPS autofill, attachments, sync transport, and shared backend wiring are still missing. |
| Volunteer app | Partial | Local-first Flutter starter now exists, but Firebase sync, notifications, and media proof are still missing. |
| Firebase rules and indexes | Partial | Good starter rules and indexes exist, but they are not wired into a deployed Spark workflow yet. |
| Cloud Functions | Partial but blocked for free-only rollout | Source exists, but deployment requires Blaze, so these cannot be part of the zero-spend MVP. |
| Telegram ingestion | Missing | Not started in code and would require backend hosting. |
| AI parsing and scoring automation | Missing for zero-spend MVP | Current code includes future backend stubs, but production Gemini and scheduled automation should stay out of the zero-cost path. |
| Reporting | Missing | No export or reporting workflow exists yet. |

## Zero-cost decisions

These are the safest choices if the rule is truly "spend nothing until the challenge submission":

- Keep `React + Vite` for the coordinator dashboard.
- Keep `Flutter` for the field and volunteer apps.
- Keep the apps `local-first` for demos and judging.
- Keep `Firebase Spark` as the only optional cloud target for later hookup.
- Keep `Cloud Firestore` only within Spark-friendly free quota usage.
- Use `OpenStreetMap + Leaflet` for web maps.
- Do **not** depend on `Cloud Functions`, `Pub/Sub`, `Vertex AI`, `BigQuery`, `Looker Studio`, `Google Maps Platform`, or `phone auth` for the first judged build.

## Why the stack needs this adjustment

As of April 27, 2026, the repo should assume:

- `Cloud Firestore` still offers free quota, but only within daily and monthly limits and only for one free database per project.
- `Cloud Functions for Firebase` usage and deployment are tied to the Blaze plan, so they should not be part of a guaranteed zero-cost MVP.
- `Google Maps Platform` uses billing-linked pricing, even though some SKUs include free usage caps.
- `Vertex AI / Gemini via Vertex AI` is usage-priced, so it should be treated as a later upgrade, not an MVP dependency.

## Recommended zero-cost MVP scope

The strongest submission path is:

1. `Field capture`
   Flutter app with offline queue, manual location entry, and draft recovery.
2. `Coordinator dashboard`
   Local triage board, map, need detail, manual assignment, and task status updates.
3. `Volunteer dispatch`
   Flutter app with local offer inbox, availability toggle, accept/decline, and completion notes.
4. `Simple reporting`
   JSON/CSV export from local or Spark-backed data instead of BigQuery/Looker.

## Remaining work in priority order

### Priority 1: close the volunteer loop

Without the volunteer client, the system does not demonstrate the full response workflow.

Needed:

- volunteer sign-in placeholder
- availability toggle
- task inbox
- accept / decline / complete flow
- local persistence

### Priority 2: strengthen coordinator operations

The dashboard should show the control story more clearly.

Needed:

- assignment rationale
- audit timeline
- review-required flag
- duplicate-warning workflow
- task and need filters

### Priority 3: improve field capture credibility

The field app needs stronger evidence that it is built for unstable connectivity.

Needed:

- explicit draft save state
- simulated sync retry states
- attachment placeholders
- clearer outbox states such as `queued`, `syncing`, `failed`, `synced`

### Priority 4: add Spark-ready integration

Only after the local workflow is clean.

Needed:

- Firebase config wiring
- Auth using low-risk free methods first
- Firestore document adapters
- online/offline data repository abstraction

## What should wait until after the free MVP

- Telegram bot ingestion
- SMS fallback
- Cloud Functions deployment
- automated priority recompute
- Gemini parsing
- BigQuery export
- Looker Studio
- push notifications
- OCR

## Immediate implementation choice

The next best use of effort is to build the missing `volunteer app` starter now, because it completes the visible product loop without introducing any paid infrastructure dependency.
