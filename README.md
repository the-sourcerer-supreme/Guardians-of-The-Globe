# Guardians of the Globe

Guardians of the Globe is a field-response platform for capturing needs in low-connectivity environments, ranking urgency, matching volunteers, and coordinating response in real time.

This repo now includes a free-tier-first working starter centered on one shared Firebase Spark project for the dashboard and mobile apps.

## Free-tier-first build choices

To keep the first build genuinely free to run:

- Use `React + Vite` for the first working app because Flutter is not installed in this environment.
- Use `OpenStreetMap + Leaflet` instead of Google Maps because Google Maps Platform requires billing to be enabled.
- Use one Firebase Spark project for Auth, Firestore, Storage, and Hosting.
- Do not rely on `Cloud Functions`, `Pub/Sub`, `Vertex AI`, `BigQuery`, `Firebase Extensions`, or `phone auth` for the first deployable MVP.

## What changed from the original roadmap

The core idea is strong, but a few pieces needed correction or tightening:

- Keep `Flutter + Firestore` for the mobile apps, but use Firestore offline persistence for synced records and a local outbox for guaranteed uploads. Hive can still be used for draft forms, media upload state, and retry metadata.
- Keep `Cloud Functions for Firebase (2nd gen)` in the future architecture, but not in the free-only MVP because production deployment requires Blaze.
- Keep `Gemini` for parsing, but move from `Gemini 1.5 Flash` to `Gemini 2.0 Flash` because 1.5 Flash is now a legacy model.
- Keep `Firestore GeoPoint`, but add a stored `geohash` field because radius queries require geohash bounds logic.
- Replace `Google Cloud Communication Services` for SMS with a third-party SMS provider integrated through a later backend. Google does not offer a simple general-purpose SMS stack for this use case in the same way the current roadmap suggests.
- Prefer `OpenStreetMap` in the first build and reserve Google Maps only for a later paid rollout if needed.
- Prefer manual or export-based reporting in the free-only MVP instead of Firebase BigQuery extensions, since extensions require Blaze.

## Product shape

There are four user-facing surfaces:

1. `Field agent app` for capturing needs with offline-first behavior.
2. `Volunteer app` for receiving, accepting, and completing tasks.
3. `Coordinator dashboard` for triage, dispatch, maps, and oversight.
4. `Messaging fallback` via Telegram bot and optional SMS ingress.

The backend is event-driven:

- Firestore is the operational database.
- Cloud Functions handles ingestion, parsing, matching, notifications, and scheduled scoring.
- Pub/Sub decouples long-running or fan-out work.
- BigQuery + Looker Studio power reporting.

## Repo layout

- [docs/architecture.md](C:/Users/LappySingh/Documents/New%20project%202/docs/architecture.md)
- [docs/data-model.md](C:/Users/LappySingh/Documents/New%20project%202/docs/data-model.md)
- [docs/deployment-setup.md](C:/Users/LappySingh/Documents/New%20project%202/docs/deployment-setup.md)
- [docs/free-tier-gap-analysis.md](C:/Users/LappySingh/Documents/New%20project%202/docs/free-tier-gap-analysis.md)
- [docs/implementation-plan.md](C:/Users/LappySingh/Documents/New%20project%202/docs/implementation-plan.md)
- [docs/ngo-operations-requirements.md](C:/Users/LappySingh/Documents/New%20project%202/docs/ngo-operations-requirements.md)
- [docs/ui-system.md](C:/Users/LappySingh/Documents/New%20project%202/docs/ui-system.md)
- [docs/user-actions.md](C:/Users/LappySingh/Documents/New%20project%202/docs/user-actions.md)
- [apps/coordinator-app/README.md](C:/Users/LappySingh/Documents/New%20project%202/apps/coordinator-app/README.md)
- [apps/field-agent-app/README.md](C:/Users/LappySingh/Documents/New%20project%202/apps/field-agent-app/README.md)
- [apps/volunteer-app/README.md](C:/Users/LappySingh/Documents/New%20project%202/apps/volunteer-app/README.md)
- [apps/coordinator-dashboard/README.md](C:/Users/LappySingh/Documents/New%20project%202/apps/coordinator-dashboard/README.md)
- [services/cloud-functions/README.md](C:/Users/LappySingh/Documents/New%20project%202/services/cloud-functions/README.md)
- [infra/firebase/README.md](C:/Users/LappySingh/Documents/New%20project%202/infra/firebase/README.md)

## Recommended delivery order

1. Ship the shared Firebase Spark baseline for Auth, Firestore, and Hosting.
2. Validate all four apps against the same live project and security rules.
3. Add volunteer dispatch inside the same web workspace.
4. Add later mobile clients and richer automation.
5. Add paid-tier services only if you explicitly choose that step.

## Non-negotiables

- Multi-tenant organization scoping in every document and security rule.
- Idempotent Cloud Functions for every retryable workflow.
- Audit events for every status change and assignment.
- Consent and disclosure for phone auth, location, voice notes, and OCR.
- Secure access only: no demo sign-in, no local auth bypass, and no self-assigned coordinator roles.
