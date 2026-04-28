import { formatTime } from "../lib/format";
import { useAppState } from "../state/AppStateContext";

export function VolunteersPage() {
  const { fieldAgents, volunteers } = useAppState();

  return (
    <div className="page-stack">
      <section className="panel wide-panel">
        <div className="panel-header">
          <h3>Volunteer Roster</h3>
          <span className="panel-meta">Live availability snapshot</span>
        </div>

        <div className="roster-grid">
          {volunteers.map((volunteer) => (
            <article key={volunteer.id} className="volunteer-card">
              <div className="need-card-top">
                <strong>{volunteer.name}</strong>
                <span className={`status-badge status-${volunteer.status}`}>
                  {volunteer.status}
                </span>
              </div>
              <p>{volunteer.phone}</p>
              <p className="muted-text">{volunteer.skills.join(", ")}</p>
              <div className="need-card-meta">
                <span>{volunteer.currentTaskCount} active tasks</span>
                <span>{volunteer.languages.map((language) => language.toUpperCase()).join(", ")}</span>
              </div>
              <span className="panel-meta">Last active {formatTime(volunteer.lastActiveAt)}</span>
            </article>
          ))}
        </div>
      </section>

      <section className="panel wide-panel">
        <div className="panel-header">
          <h3>Field Agent Links</h3>
          <span className="panel-meta">Field capture app heartbeat</span>
        </div>

        <div className="roster-grid">
          {fieldAgents.length === 0 ? (
            <p className="empty-state">No field-agent profiles have synced into this organization yet.</p>
          ) : (
            fieldAgents.map((agent) => (
              <article key={agent.id} className="volunteer-card">
                <div className="need-card-top">
                  <strong>{agent.displayName}</strong>
                  <span className={`status-badge ${agent.syncHealth === "healthy" ? "status-available" : "status-offline"}`}>
                    {agent.syncHealth}
                  </span>
                </div>
                <p>{agent.phone || "No phone on file"}</p>
                <p className="muted-text">
                  {agent.assignedRegions.length > 0
                    ? agent.assignedRegions.join(", ")
                    : "No assigned regions yet"}
                </p>
                <div className="need-card-meta">
                  <span>{agent.appVersion || "App version unknown"}</span>
                  <span>Seen {formatTime(agent.deviceLastSeenAt)}</span>
                </div>
              </article>
            ))
          )}
        </div>
      </section>
    </div>
  );
}
