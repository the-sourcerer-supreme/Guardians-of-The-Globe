# What You Need To Do

## Accounts and billing

You need to create or confirm:

1. A Google Cloud project with billing enabled.
2. A Firebase project linked to that Google Cloud project.
3. A Telegram bot token from BotFather.
4. An SMS provider account if you want feature-phone support.
5. Apple Developer access if you want to ship iOS builds.

## Firebase and Google Cloud setup

Enable these products:

- Firebase Auth
- Firestore
- Firebase Storage
- Firebase Hosting
- Firebase Cloud Messaging
- Cloud Functions
- Cloud Pub/Sub
- Cloud Scheduler
- Vertex AI
- Speech-to-Text
- BigQuery
- Maps SDK for Android
- Maps SDK for iOS
- Maps JavaScript API

## Decisions only you can make

These are product and compliance decisions, not coding details:

1. Which organizations share one environment, and whether each organization needs hard isolation.
2. Which countries you will operate in, because phone auth, SMS rules, and data handling vary.
3. Whether voice notes and photos may contain sensitive personal or medical information.
4. Whether volunteers can see beneficiary phone numbers directly or only coordinators can.
5. How long raw voice notes, images, and transcripts should be retained.

## Credentials you will need later

- Firebase project config for web and Flutter
- Service account access for backend deployment
- Telegram bot token and webhook secret
- SMS provider webhook secret and API key
- Maps API keys with platform restrictions
- Vertex AI enabled in the correct project

## Recommended launch order

1. Approve the architecture and collection model in this repo.
2. Create the Firebase project and enable the listed services.
3. Decide whether SMS is required for MVP or later.
4. Start implementation with the field app and dashboard only.

## Practical advice

- Keep MVP to one organization first.
- Keep one supported language in the UI at launch, even if Gemini can parse more.
- Keep a human review step for every non-app ingestion channel.
- Test in poor connectivity conditions before adding AI polish.
