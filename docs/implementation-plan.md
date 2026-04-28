# Guardians of the Globe Implementation Plan

## Phase 0: Foundation

Goal: establish the shared platform safely.

Deliverables:

- Firebase project structure
- Firestore schema and security rules
- Role model and custom claims flow
- Cloud Functions workspace
- Basic React dashboard shell
- Shared design tokens and UI rules

Exit criteria:

- Users can sign in
- Roles resolve correctly
- Organization scoping is enforced

## Phase 1: Field capture MVP

Goal: capture needs reliably from the field.

Deliverables:

- Flutter field agent app
- Need form with GPS autofill
- Photo attachment support
- Offline drafts and retry queue
- Direct Firestore write path
- Dashboard list for incoming needs

Exit criteria:

- Field agent can create needs offline
- Needs sync when connectivity returns
- Coordinator can see and update needs live

## Phase 2: Coordinator operations

Goal: make the command center useful.

Deliverables:

- Real-time task board
- Map view
- Need detail panel
- Manual assignment workflow
- Audit timeline
- Escalation and merge actions

Exit criteria:

- Coordinator can triage and dispatch without admin intervention

## Phase 3: Volunteer dispatch

Goal: close the loop from need to action.

Deliverables:

- Flutter volunteer app
- Volunteer availability controls
- FCM push notifications
- Accept or decline flow
- Completion proof upload

Exit criteria:

- Volunteer receives offers
- Acceptances sync in real time
- Completed tasks update need state

## Phase 4: Messaging ingestion

Goal: bring in non-app reports.

Deliverables:

- Telegram bot webhook
- Raw ingestion event store
- Voice note upload and transcription
- Coordinator review queue

Exit criteria:

- Telegram messages become reviewable candidate needs

## Phase 5: AI enrichment

Goal: speed up triage without removing human control.

Deliverables:

- Gemini structured parser
- Confidence scoring
- Review-required workflow
- Priority scoring job
- Matching engine suggestions

Exit criteria:

- Coordinators see ranked needs and ranked volunteer candidates

## Phase 6: Reporting and hardening

Goal: make the system operationally credible.

Deliverables:

- BigQuery sync
- Looker Studio dashboards
- Backup/export jobs
- Error alerting
- Rate limits and abuse controls
- Data retention settings

Exit criteria:

- Leadership and funders can view stable metrics
- Critical workflows are observable and recoverable

## Recommended team order

If you are building this with limited time, do it in this sequence:

1. Field app
2. Dashboard
3. Firestore rules and functions
4. Volunteer app
5. Telegram ingestion
6. AI parser
7. Analytics

## MVP definition

The first real MVP should exclude:

- SMS ingestion
- fully automated assignment
- advanced OCR extraction workflows
- automatic PDF reporting

The MVP should include:

- smartphone field logging
- dashboard triage
- volunteer dispatch
- reporting via Looker Studio
