import type { PropsWithChildren } from "react";
import { useAppState } from "../state/AppStateContext";

const links = [
  { to: "/dashboard", label: "Dashboard" },
  { to: "/capture", label: "Field Intake" },
  { to: "/tasks", label: "Tasks" },
  { to: "/volunteers", label: "Volunteers" },
  { to: "/map", label: "Map" },
  { to: "/account", label: "Account" }
] as const;

interface LayoutProps extends PropsWithChildren {
  currentRoute: (typeof links)[number]["to"];
  navigate(route: (typeof links)[number]["to"]): void;
}

export function Layout({ children, currentRoute, navigate }: LayoutProps) {
  const { logout, session, theme } = useAppState();

  return (
    <div className={`app-shell app-shell-${theme}`}>
      <aside className="sidebar">
        <div>
          <div className="brand-mark">GG</div>
          <h1>Guardians of the Globe</h1>
          <p className="muted-text">Secure live response control room</p>
        </div>

        <nav className="nav-list">
          {links.map((link) => (
            <button
              key={link.to}
              className={currentRoute === link.to ? "nav-link active" : "nav-link"}
              onClick={() => navigate(link.to)}
              type="button"
            >
              {link.label}
            </button>
          ))}
        </nav>

        <div className="mode-card mode-live">
          <span className="status-dot status-ok" />
          <div>
            <strong>Shared Firebase live mode</strong>
            <p>Web and mobile apps now read the same Auth and Firestore data.</p>
          </div>
        </div>
      </aside>

      <main className="main-content">
        <header className="topbar">
          <div>
            <p className="eyebrow">Operations</p>
            <h2>Coordinator Console</h2>
          </div>

          <div className="topbar-actions">
            <div className="user-chip">
              <strong>{session?.displayName}</strong>
              <span>{session?.email}</span>
            </div>
            <button className="secondary-button" onClick={() => void logout()} type="button">
              Sign out
            </button>
          </div>
        </header>

        {children}
      </main>
    </div>
  );
}
