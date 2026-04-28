import { formatTime } from "../lib/format";
import { useAppState } from "../state/AppStateContext";

export function TasksPage() {
  const { tasks, completeTask } = useAppState();

  return (
    <div className="page-stack">
      <section className="panel wide-panel">
        <div className="panel-header">
          <h3>Task Board</h3>
          <span className="panel-meta">{tasks.length} tasks</span>
        </div>

        <div className="table-shell">
          <table>
            <thead>
              <tr>
                <th>Need</th>
                <th>Volunteer</th>
                <th>Status</th>
                <th>Created</th>
                <th>Progress</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {tasks.map((task) => (
                <tr key={task.id}>
                  <td>{task.needTitle}</td>
                  <td>{task.volunteerName}</td>
                  <td className="text-capitalize">{task.status}</td>
                  <td>{formatTime(task.createdAt)}</td>
                  <td>
                    {task.completedAt
                      ? `Completed ${formatTime(task.completedAt)}`
                      : task.acceptedAt
                        ? `Accepted ${formatTime(task.acceptedAt)}`
                        : "Awaiting response"}
                  </td>
                  <td>
                    {task.status === "offered" ||
                    task.status === "accepted" ||
                    task.status === "in_progress" ? (
                      <button
                        className="secondary-button"
                        onClick={() => void completeTask(task.id)}
                        type="button"
                      >
                        Mark complete
                      </button>
                    ) : (
                      <span className="panel-meta">
                        {task.status === "completed" ? "Closed" : "Reassignment needed"}
                      </span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
