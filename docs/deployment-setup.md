# Deployment Setup

## What you need to create

To make the apps truly live and connected across devices, you need one Firebase project.

Minimum services:

- Firebase Authentication
- Cloud Firestore
- Firebase Storage

Recommended but optional later:

- Firebase Hosting
- Firebase Cloud Messaging
- Cloud Functions

## Zero-cost live deployment profile

You can stay on Firebase Spark for the first live connected build if you avoid:

- Cloud Functions deployment
- phone authentication
- paid maps usage
- BigQuery export
- Vertex AI

## Authentication providers to enable

Enable these in Firebase Authentication:

- Email/Password
- Google

For Google sign-in on Android, add your SHA-1 and SHA-256 fingerprints in Firebase project settings.

## FlutterFire setup

Run this separately for each Flutter app after installing the Firebase CLI and FlutterFire CLI:

```powershell
flutterfire configure
```

This project currently supports a second path as well:

- provide Firebase values through `--dart-define`
- app runs in live Firebase mode when all required values are present
- app stays locked when they are missing so sign-in cannot be bypassed

Required `dart-define` values:

- `FIREBASE_API_KEY`
- `FIREBASE_AUTH_DOMAIN`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_APP_ID_WEB`
- `FIREBASE_APP_ID_ANDROID`
- `FIREBASE_APP_ID_IOS`

Optional:

- `FIREBASE_IOS_BUNDLE_ID`

## Example run commands

Field app:

```powershell
flutter run `
  --dart-define=FIREBASE_API_KEY=... `
  --dart-define=FIREBASE_AUTH_DOMAIN=... `
  --dart-define=FIREBASE_PROJECT_ID=... `
  --dart-define=FIREBASE_STORAGE_BUCKET=... `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... `
  --dart-define=FIREBASE_APP_ID_ANDROID=... `
  --dart-define=FIREBASE_APP_ID_WEB=... `
  --dart-define=FIREBASE_APP_ID_IOS=...
```

Repeat for:

- `apps/field-agent-app`
- `apps/volunteer-app`
- `apps/coordinator-app`

## Firestore collections you must seed or allow creation for

- `users`
- `field_agents`
- `volunteers`
- `needs`
- `tasks`
- `events`

The current apps now assume:

- `users` is pre-provisioned by an administrator
- `field_agents` and `volunteers` are created by a coordinator or directly in Firebase Console
- `needs`, `tasks`, and `events` are created by the live apps after authentication

## Important manual production steps

### 1. Role assignment

The apps assume users belong to one or more organizations and roles.

For production:

- create admin or bootstrap coordinator accounts first
- assign roles deliberately
- create matching `users/{uid}` documents before granting access
- do not let end users elevate themselves to coordinator or admin
- do not enable public self-registration for coordinator access

### 2. Firestore rules deployment

Deploy:

- `infra/firebase/firestore.rules`
- `infra/firebase/firestore.indexes.json`
- `infra/firebase/storage.rules`

### 3. Storage hardening

For true production-grade storage enforcement, add custom auth claims or a server-mediated upload path.

Why:

- Storage rules cannot use the same rich document lookups as Firestore rules
- strict organization-level media access works best with custom claims or signed upload workflows

### 4. Google OAuth setup

You must manually:

- enable Google provider
- add each authorized Google account to Firebase Auth first or provision it immediately after first sign-in
- add Android SHA fingerprints
- configure iOS bundle identifiers if shipping iOS

### 5. Coordinator dashboard web config

Before `npm run build` in `apps/coordinator-dashboard`, create a `.env` file from `.env.example` and fill:

- `VITE_FIREBASE_API_KEY`
- `VITE_FIREBASE_AUTH_DOMAIN`
- `VITE_FIREBASE_PROJECT_ID`
- `VITE_FIREBASE_STORAGE_BUCKET`
- `VITE_FIREBASE_MESSAGING_SENDER_ID`
- `VITE_FIREBASE_APP_ID`

### 6. Release signing

Before publishing APKs:

- create a release keystore
- replace debug signing in the Android Gradle config

## What is still better handled later

- push notifications
- media upload workflows
- conflict resolution for simultaneous edits
- admin invitation flow
- coordinator-only user management
- audit export and reporting
