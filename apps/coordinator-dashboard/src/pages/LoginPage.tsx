import { useState } from "react";
import { useAppState } from "../state/AppStateContext";

export function LoginPage() {
  const {
    authConfigured,
    authError,
    clearAuthError,
    signInWithEmail,
    signUpWithEmail,
    signInWithGoogle
  } = useAppState();
  const [displayName, setDisplayName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);
  const [createMode, setCreateMode] = useState(false);

  async function run(action: () => Promise<void>) {
    setBusy(true);
    setLocalError(null);
    clearAuthError();

    try {
      await action();
    } catch (error) {
      setLocalError(error instanceof Error ? error.message : "Sign-in failed.");
    } finally {
      setBusy(false);
    }
  }

  const formError = localError ?? authError;

  return (
    <div className="login-shell">
      <div className="login-card">
        <div className="brand-mark">GG</div>
        <h1>Guardians of the Globe</h1>
        <p className="muted-text">
          Live coordinator access with Firebase-backed self-service sign-up.
        </p>

        <div className={`mode-card ${authConfigured ? 'mode-live' : 'mode-locked'}`}>
          <span className={`status-dot ${authConfigured ? 'status-ok' : 'status-critical'}`} />
          <div>
            <strong>{authConfigured ? "Firebase live mode" : "Configuration required"}</strong>
            <p>
              {authConfigured
                ? "Users can create their own dashboard account here."
                : "Add Firebase environment variables before deploying this dashboard."}
            </p>
          </div>
        </div>

        {createMode ? (
          <label className="field">
            <span>Display name</span>
            <input
              autoComplete="name"
              value={displayName}
              onChange={(event) => setDisplayName(event.target.value)}
            />
          </label>
        ) : null}

        <label className="field">
          <span>Email</span>
          <input
            autoComplete="email"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
          />
        </label>

        <label className="field">
          <span>Password</span>
          <input
            autoComplete="current-password"
            type="password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
          />
        </label>

        {formError ? <p className="error-text">{formError}</p> : null}

        <button
          className="primary-button full-width"
          disabled={busy || !authConfigured}
          onClick={() =>
            run(async () => {
              const normalizedEmail = email.trim();
              if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(normalizedEmail)) {
                throw new Error("Enter a valid email address.");
              }
              if (createMode && displayName.trim().length < 2) {
                throw new Error("Enter a display name.");
              }
              if (password.trim().length < 8) {
                throw new Error("Password must be at least 8 characters.");
              }
              if (createMode) {
                await signUpWithEmail(normalizedEmail, password.trim(), displayName.trim());
                return;
              }
              await signInWithEmail(normalizedEmail, password.trim());
            })
          }
          type="button"
        >
          {createMode ? "Create account" : "Sign in"}
        </button>

        <button
          className="secondary-button full-width"
          disabled={busy || !authConfigured}
          onClick={() => run(signInWithGoogle)}
          type="button"
        >
          Continue with Google
        </button>

        <button
          className="secondary-button full-width"
          disabled={busy || !authConfigured}
          onClick={() => {
            setCreateMode((current) => !current);
            setLocalError(null);
            clearAuthError();
          }}
          type="button"
        >
          {createMode ? "Use existing account" : "Create account with email"}
        </button>

        <p className="panel-meta">
          First sign-in now auto-creates the matching Firestore profile for this dashboard.
        </p>
      </div>
    </div>
  );
}
