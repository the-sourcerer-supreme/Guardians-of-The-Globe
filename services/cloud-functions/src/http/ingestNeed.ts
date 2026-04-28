import { onRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { db } from "../shared/firebase.js";

export const ingestNeed = onRequest(async (request, response) => {
  if (request.method !== "POST") {
    response.status(405).json({ error: "method_not_allowed" });
    return;
  }

  const body = request.body as Record<string, unknown>;
  const organizationId = typeof body.organization_id === "string" ? body.organization_id : "";
  const title = typeof body.title === "string" ? body.title.trim() : "";
  const description =
    typeof body.description === "string" ? body.description.trim() : "";

  if (!organizationId || title.length < 5 || description.length < 10) {
    response.status(400).json({ error: "invalid_payload" });
    return;
  }

  const eventRef = await db.collection("ingestion_events").add({
    organization_id: organizationId,
    channel: body.channel ?? "field_app",
    raw_payload: body,
    parse_status: "pending",
    created_at: new Date().toISOString(),
  });

  logger.info("Ingestion event accepted", { ingestionEventId: eventRef.id });
  response.status(202).json({ ingestion_event_id: eventRef.id, status: "accepted" });
});
