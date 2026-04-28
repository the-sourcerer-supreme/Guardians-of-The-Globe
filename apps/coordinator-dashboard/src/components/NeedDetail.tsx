import { formatTime, relativeUrgencyLabel } from "../lib/format";
import { useAppState } from "../state/AppStateContext";

export function NeedDetail() {
  const { selectedNeed, volunteers, assignNeed } = useAppState();

  if (!selectedNeed) {
    return (
      <div className="panel">
        <h3>No need selected</h3>
      </div>
    );
  }

  const assignedVolunteer = selectedNeed.assignedVolunteerId
    ? volunteers.find((volunteer) => volunteer.id === selectedNeed.assignedVolunteerId)
    : null;
  const candidateVolunteers = volunteers
    .filter((volunteer) => volunteer.status === "available")
    .sort((left, right) => volunteerMatchScore(right, selectedNeed) - volunteerMatchScore(left, selectedNeed));

  return (
    <div className="panel">
      <div className="panel-header">
        <h3>Need Detail</h3>
        <span className={`urgency-pill urgency-${selectedNeed.urgency}`}>
          {relativeUrgencyLabel(selectedNeed.urgency)}
        </span>
      </div>

      <div className="detail-grid">
        <div>
          <span className="detail-label">Need</span>
          <strong>{selectedNeed.title}</strong>
        </div>
        <div>
          <span className="detail-label">Status</span>
          <strong className="text-capitalize">{selectedNeed.status.replace("_", " ")}</strong>
        </div>
        <div>
          <span className="detail-label">Location</span>
          <strong>{selectedNeed.locationName}</strong>
        </div>
        <div>
          <span className="detail-label">Reported by</span>
          <strong>{selectedNeed.createdBy}</strong>
        </div>
        <div>
          <span className="detail-label">Source</span>
          <strong className="text-capitalize">{selectedNeed.sourceChannel.replace("_", " ")}</strong>
        </div>
      </div>

      <p className="detail-copy">{selectedNeed.description}</p>

      <div className="detail-grid compact">
        <div>
          <span className="detail-label">People affected</span>
          <strong>{selectedNeed.peopleAffected}</strong>
        </div>
        <div>
          <span className="detail-label">Updated</span>
          <strong>{formatTime(selectedNeed.updatedAt)}</strong>
        </div>
        <div>
          <span className="detail-label">Verification</span>
          <strong className="text-capitalize">{selectedNeed.verificationStatus.replaceAll("_", " ")}</strong>
        </div>
        <div>
          <span className="detail-label">Beneficiary</span>
          <strong>{selectedNeed.beneficiaryName || "Not yet captured"}</strong>
        </div>
      </div>

      {assignedVolunteer ? (
        <>
          <div className="divider" />
          <div className="detail-grid compact">
            <div>
              <span className="detail-label">Assigned volunteer</span>
              <strong>{assignedVolunteer.name}</strong>
            </div>
            <div>
              <span className="detail-label">Dispatch status</span>
              <strong className="text-capitalize">{assignedVolunteer.status}</strong>
            </div>
          </div>
        </>
      ) : null}

      <div className="divider" />

      <div className="panel-header">
        <h4>Suggested volunteers</h4>
        <span className="panel-meta">{candidateVolunteers.length} available</span>
      </div>

      <div className="stack-list">
        {candidateVolunteers.length === 0 ? (
          <p className="empty-state">No available volunteer profiles are online right now.</p>
        ) : (
          candidateVolunteers.map((volunteer) => (
            <div key={volunteer.id} className="volunteer-row">
              <div>
                <strong>{volunteer.name}</strong>
                <p>{describeVolunteerFit(volunteer, selectedNeed)}</p>
                <div className="need-card-meta">
                  <span>{volunteer.skills.length > 0 ? volunteer.skills.join(", ") : "No skills listed yet"}</span>
                  <span>{volunteer.currentTaskCount} active tasks</span>
                  <span>{volunteer.languages.map((language) => language.toUpperCase()).join(", ")}</span>
                </div>
              </div>
              <button
                className="primary-button"
                disabled={selectedNeed.status !== "open" && selectedNeed.status !== "triaged"}
                onClick={() => void assignNeed(selectedNeed.id, volunteer.id)}
                type="button"
              >
                Assign
              </button>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

function volunteerMatchScore(
  volunteer: (typeof useAppState extends () => infer State
    ? State extends { volunteers: Array<infer Volunteer> }
      ? Volunteer
      : never
    : never),
  need: (typeof useAppState extends () => infer State
    ? State extends { selectedNeed: infer Need }
      ? NonNullable<Need>
      : never
    : never)
) {
  const normalizedNeedType = need.needType.trim().toLowerCase();
  const hasExactSkill = volunteer.skills.some(
    (skill: string) => skill.trim().toLowerCase() === normalizedNeedType
  );
  const hasLanguage = volunteer.languages.includes(need.preferredLanguage);
  const lastActiveScore = Date.parse(volunteer.lastActiveAt) || 0;

  return (
    (hasExactSkill ? 100 : 0) +
    (hasLanguage ? 20 : 0) +
    Math.max(10 - volunteer.currentTaskCount, 0) +
    lastActiveScore / 1_000_000_000_000
  );
}

function describeVolunteerFit(
  volunteer: (typeof useAppState extends () => infer State
    ? State extends { volunteers: Array<infer Volunteer> }
      ? Volunteer
      : never
    : never),
  need: (typeof useAppState extends () => infer State
    ? State extends { selectedNeed: infer Need }
      ? NonNullable<Need>
      : never
    : never)
) {
  const normalizedNeedType = need.needType.trim().toLowerCase();
  const hasExactSkill = volunteer.skills.some(
    (skill: string) => skill.trim().toLowerCase() === normalizedNeedType
  );
  const hasLanguage = volunteer.languages.includes(need.preferredLanguage);

  if (hasExactSkill && hasLanguage) {
    return "Exact skill match and speaks the beneficiary's preferred language.";
  }
  if (hasExactSkill) {
    return "Exact skill match and currently available for dispatch.";
  }
  if (hasLanguage) {
    return "Language match and available, even though the skill list is still incomplete.";
  }
  if (volunteer.skills.length > 0) {
    return "Available now with adjacent skills that may still cover this need.";
  }
  return "Available now. This volunteer profile has not listed skills yet.";
}
