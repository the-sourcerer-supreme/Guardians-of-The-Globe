import { formatTime } from "../lib/format";
import { MetricCard } from "../components/MetricCard";
import { NeedDetail } from "../components/NeedDetail";
import { NeedList } from "../components/NeedList";
import { useAppState } from "../state/AppStateContext";

export function DashboardPage() {
  const { events, fieldAgents, needs, tasks, volunteers } = useAppState();

  const openNeeds = needs.filter((need) => !["resolved", "closed", "rejected"].includes(need.status)).length;
  const criticalNeeds = needs.filter((need) => need.urgency >= 4 && !["resolved", "closed", "rejected"].includes(need.status)).length;
  const availableVolunteers = volunteers.filter((volunteer) => volunteer.status === "available").length;
  const activeTasks = tasks.filter((task) => !["completed", "declined", "cancelled"].includes(task.status)).length;
  const connectedFieldAgents = fieldAgents.filter((agent) => agent.syncHealth !== "offline").length;

  return (
    <div className="page-stack">
      <section className="metrics-grid">
        <MetricCard label="Open needs" value={String(openNeeds)} />
        <MetricCard label="Critical queue" value={String(criticalNeeds)} tone="critical" />
        <MetricCard label="Available volunteers" value={String(availableVolunteers)} tone="good" />
        <MetricCard label="Active tasks" value={String(activeTasks)} />
        <MetricCard label="Field agents seen" value={String(connectedFieldAgents)} />
      </section>

      <section className="content-grid">
        <NeedList />
        <NeedDetail />
      </section>

      <section className="panel wide-panel">
        <div className="panel-header">
          <div>
            <h3>Live Audit Feed</h3>
            <p className="panel-subtitle">Shared coordinator, volunteer, and field-agent activity from the same Firebase project.</p>
          </div>
          <span className="panel-meta">{events.length} events</span>
        </div>

        <div className="audit-feed">
          {events.length === 0 ? (
            <p className="empty-state">No live activity has reached this workspace yet.</p>
          ) : (
            events.slice(0, 8).map((event) => (
              <article key={event.id} className="audit-row">
                <div>
                  <strong>{event.summary}</strong>
                  <p className="muted-text">
                    {event.eventType.replaceAll(".", " ")} | {event.entityType} | {event.actorRole}
                  </p>
                </div>
                <span className="panel-meta">{formatTime(event.createdAt)}</span>
              </article>
            ))
          )}
        </div>
      </section>
    </div>
  );
}
