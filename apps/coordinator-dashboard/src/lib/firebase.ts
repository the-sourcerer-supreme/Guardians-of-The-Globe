import { initializeApp, getApps, type FirebaseApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

function parseEnvCandidates(rawValue: string | undefined) {
  return (rawValue ?? "")
    .split(",")
    .map((value) => value.trim())
    .filter((value) => value.length > 0);
}

function pickFirstValue(rawValue: string | undefined) {
  return parseEnvCandidates(rawValue)[0] ?? "";
}

function pickAuthDomain(rawValue: string | undefined) {
  const candidates = parseEnvCandidates(rawValue);
  return (
    candidates.find((value) => value.endsWith(".firebaseapp.com")) ??
    candidates.find((value) => value.endsWith(".web.app")) ??
    candidates[0] ??
    ""
  );
}

function pickWebAppId(rawValue: string | undefined) {
  return parseEnvCandidates(rawValue).find((value) => value.includes(":web:")) ?? "";
}

const config = {
  apiKey: pickFirstValue(import.meta.env.VITE_FIREBASE_API_KEY),
  authDomain: pickAuthDomain(import.meta.env.VITE_FIREBASE_AUTH_DOMAIN),
  projectId: pickFirstValue(import.meta.env.VITE_FIREBASE_PROJECT_ID),
  storageBucket: pickFirstValue(import.meta.env.VITE_FIREBASE_STORAGE_BUCKET),
  messagingSenderId: pickFirstValue(import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID),
  ...(pickWebAppId(import.meta.env.VITE_FIREBASE_APP_ID)
    ? { appId: pickWebAppId(import.meta.env.VITE_FIREBASE_APP_ID) }
    : {})
};

export const firebaseConfigured = [config.apiKey, config.authDomain, config.projectId].every(
  (value) => typeof value === "string" && value.trim().length > 0
);

let firebaseApp: FirebaseApp | null = null;

export function getFirebaseApp() {
  if (!firebaseConfigured) {
    return null;
  }

  if (!firebaseApp) {
    firebaseApp = getApps()[0] ?? initializeApp(config);
  }

  return firebaseApp;
}

export function getFirebaseAuth() {
  const app = getFirebaseApp();
  return app ? getAuth(app) : null;
}

export function getFirebaseFirestore() {
  const app = getFirebaseApp();
  return app ? getFirestore(app) : null;
}
