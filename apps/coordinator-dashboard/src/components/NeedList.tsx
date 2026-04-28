import { formatTime, relativeUrgencyLabel } from "../lib/format";
import { useAppState } from "../state/AppStateContext";

export function NeedList() {
  const { needs, selectedNeedId, selectNeed } = useAppState();

  return (
    <div className="panel">
      <div className="panel-header">
        <h3>Live Need Queue</h3>
        <span className="panel-meta">{needs.length} total</span>
      </div>

      <div className="stack-list">
        {needs.map((need) => (
          <button
            key={need.id}
            className={selectedNeedId === need.id ? "need-card selected" : "need-card"}
            onClick={() => selectNeed(need.id)}
            type="button"
          >
            <div className="need-card-top">
              <strong>{need.title}</strong>
              <span className={`urgency-pill urgency-${need.urgency}`}>{relativeUrgencyLabel(need.urgency)}</span>
            </div>
            <p>{need.locationName}</p>
            <div className="need-card-meta">
              <span>{need.needType}</span>
              <span>{need.peopleAffected} affected</span>
              <span>{need.sourceChannel.replace("_", " ")}</span>
              <span>{formatTime(need.updatedAt)}</span>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}
