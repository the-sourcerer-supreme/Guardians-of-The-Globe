# Cloud Functions

Serverless backend for Guardians of the Globe.

Responsibilities:

- bot and webhook ingestion
- AI parsing
- priority scoring
- volunteer matching
- notifications
- scheduled jobs
- analytics sync triggers

Recommended structure:

- `src/http`
- `src/firestore`
- `src/pubsub`
- `src/scheduler`
- `src/shared`

Use idempotency keys for any handler that can be retried.

Current implementation:

- `src/http/ingestNeed.ts` accepts inbound need payloads.
- `src/firestore/onNeedCreated.ts` computes priority and initial volunteer matches.
- `src/scheduler/recomputePriority.ts` refreshes open-need ranking every 10 minutes.
- `src/shared/scoring.ts` centralizes priority and matching formulas.

Deployment note:

- This backend shape is aligned to Firebase Functions 2nd gen and is the strongest match to the original roadmap.
- Real deployment of these functions requires Firebase Blaze, even if day-one usage stays very low.
