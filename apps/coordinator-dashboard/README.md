# Coordinator Dashboard

React app hosted locally first, with Firebase Spark as the deployment target.

Core views:

- live needs board
- field intake
- map
- volunteer roster
- assignment drawer
- need and task detail pages

Primary goals:

- real-time situational awareness
- fast triage
- transparent assignment rationale
- audit visibility

Current implementation note:

- The connected dashboard lives in `src/` and reads the same Firebase Auth and Firestore data as the field-agent and volunteer apps.
- `site/` is a legacy offline prototype and should not be used for live operations.

How to run now:

1. Run `npm install`.
2. Run `npm run dev` for local development, or `npm run build` to produce the deployable app in `dist/`.
3. Serve `dist/` locally or deploy through Firebase Hosting, which is already pointed at `apps/coordinator-dashboard/dist`.
