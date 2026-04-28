import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";
import { db } from "../shared/firebase.js";
import type { NeedDocument, VolunteerDocument } from "../shared/models.js";
import { computePriorityScore, rankVolunteerMatches } from "../shared/scoring.js";

export const onNeedCreated = onDocumentCreated("needs/{needId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    return;
  }

  const needId = event.params.needId;
  const need = snapshot.data() as NeedDocument;
  const createdAt = new Date(need.created_at);
  const unmetHours = Math.max((Date.now() - createdAt.getTime()) / 3_600_000, 0);
  const priorityScore = computePriorityScore(need, unmetHours);

  const volunteersSnapshot = await db
    .collection("volunteers")
    .where("organization_id", "==", need.organization_id)
    .get();

  const volunteers = volunteersSnapshot.docs.map((doc) => ({
    id: doc.id,
    ...(doc.data() as VolunteerDocument),
  }));

  const matchCandidates = rankVolunteerMatches(need, volunteers);

  await snapshot.ref.update({
    priority_score: priorityScore,
    updated_at: new Date().toISOString(),
    match_candidates: matchCandidates,
  });

  await db.collection("events").add({
    organization_id: need.organization_id,
    entity_type: "need",
    entity_id: needId,
    event_type: "need.created",
    actor_uid: need.created_by,
    actor_role: "field_agent",
    summary: "Need captured and ranked",
    metadata: {
      priority_score: priorityScore,
      match_candidates: matchCandidates,
    },
    created_at: new Date().toISOString(),
  });

  logger.info("Need created and ranked", {
    needId,
    priorityScore,
    candidateCount: matchCandidates.length,
  });
});
