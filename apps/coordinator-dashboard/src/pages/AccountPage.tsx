import { useEffect, useState } from "react";
import { useAppState } from "../state/AppStateContext";
import type { ProfileFormInput, SupportedLanguage } from "../types";

export function AccountPage() {
  const { logout, saveProfile, session, theme, toggleTheme } = useAppState();
  const [busy, setBusy] = useState(false);
  const [saved, setSaved] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [form, setForm] = useState<ProfileFormInput>(() => ({
    displayName: session?.displayName ?? "",
    phone: session?.phone ?? "",
    preferredLanguage: session?.preferredLanguage ?? "en",
    notificationsEnabled: session?.notificationsEnabled ?? true,
    emergencyAlertsEnabled: session?.emergencyAlertsEnabled ?? true
  }));

  if (!session) {
    return null;
  }

  useEffect(() => {
    setForm({
      displayName: session.displayName,
      phone: session.phone,
      preferredLanguage: session.preferredLanguage,
      notificationsEnabled: session.notificationsEnabled,
      emergencyAlertsEnabled: session.emergencyAlertsEnabled
    });
  }, [
    session.displayName,
    session.emergencyAlertsEnabled,
    session.notificationsEnabled,
    session.phone,
    session.preferredLanguage
  ]);

  async function onSave() {
    setBusy(true);
    setSaved(null);
    setError(null);

    try {
      await saveProfile(form);
      setSaved("Account preferences saved.");
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : "Could not save account details.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="page-stack">
      <section className="panel wide-panel account-panel">
        <div className="panel-header account-header">
          <div>
            <h3>Account</h3>
            <p className="panel-subtitle">
              Secure coordinator identity, language preference, and appearance controls.
            </p>
          </div>

          <div className="settings-toolbar">
            <label className="field compact-field">
              <span>Language</span>
              <select
                value={form.preferredLanguage}
                onChange={(event) =>
                  setForm((current) => ({
                    ...current,
                    preferredLanguage: event.target.value as SupportedLanguage
                  }))
                }
              >
                <option value="en">English</option>
                <option value="hi">Hindi</option>
                <option value="mr">Marathi</option>
              </select>
            </label>

            <button className="secondary-button appearance-button" onClick={toggleTheme} type="button">
              Appearance: {theme === "dark" ? "Dark" : "Light"}
            </button>
          </div>
        </div>

        <div className="account-identity">
          <div className="account-avatar">
            {(session.displayName || "GU")
              .split(" ")
              .filter(Boolean)
              .slice(0, 2)
              .map((part) => part[0]?.toUpperCase() ?? "")
              .join("")}
          </div>
          <div>
            <strong>{session.email}</strong>
            <p className="panel-meta">
              Roles: {session.roles.join(", ")} | Org: {session.organizationIds.join(", ")}
            </p>
          </div>
        </div>

        <div className="form-grid">
          <label className="field">
            <span>Display name</span>
            <input
              value={form.displayName}
              onChange={(event) =>
                setForm((current) => ({ ...current, displayName: event.target.value }))
              }
            />
          </label>

          <label className="field">
            <span>Phone</span>
            <input
              value={form.phone}
              onChange={(event) =>
                setForm((current) => ({ ...current, phone: event.target.value }))
              }
            />
          </label>
        </div>

        <div className="settings-switches">
          <label className="toggle-row">
            <span>Notifications</span>
            <input
              checked={form.notificationsEnabled}
              onChange={(event) =>
                setForm((current) => ({
                  ...current,
                  notificationsEnabled: event.target.checked
                }))
              }
              type="checkbox"
            />
          </label>

          <label className="toggle-row">
            <span>Emergency alerts</span>
            <input
              checked={form.emergencyAlertsEnabled}
              onChange={(event) =>
                setForm((current) => ({
                  ...current,
                  emergencyAlertsEnabled: event.target.checked
                }))
              }
              type="checkbox"
            />
          </label>
        </div>

        {saved ? <p className="success-text">{saved}</p> : null}
        {error ? <p className="error-text">{error}</p> : null}

        <div className="form-actions">
          <button className="primary-button" disabled={busy} onClick={onSave} type="button">
            Save account
          </button>
          <button className="secondary-button" onClick={() => void logout()} type="button">
            Sign out
          </button>
        </div>
      </section>
    </div>
  );
}
