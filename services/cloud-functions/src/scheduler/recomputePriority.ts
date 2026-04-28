import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import { db } from "../shared/firebase.js";
import type { NeedDocument } from "../shared/models.js";
import { computePriorityScore } from "../shared/scoring.js";

export const recomputePriority = onSchedule("every 10 minutes", async () => {
  const openNeeds = await db
    .collection("needs")
    .where("status", "in", ["open", "triaged", "assigned", "in_progress"])
    .get();

  const batch = db.batch();
  const now = Date.now();

  for (const doc of openNeeds.docs) {
    const need = doc.data() as NeedDocument;
    const unmetHours = Math.max(
      (now - new Date(need.created_at).getTime()) / 3_600_000,
      0
    );

    batch.update(doc.ref, {
      priority_score: computePriorityScore(need, unmetHours),
      updated_at: new Date().toISOString(),
    });
  }

  await batch.commit();
  logger.info("Priority recompute completed", { count: openNeeds.size });
});
