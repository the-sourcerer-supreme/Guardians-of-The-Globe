# Guardians of the Globe Data Model

## Document conventions

Every primary document should include:

- `organization_id`
- `created_at`
- `updated_at`
- `created_by`
- `updated_by`
- `status`

Use server timestamps from trusted backend writes whenever possible.

## Collections

### `organizations/{organizationId}`

Fields:

- `name`
- `slug`
- `status`
- `service_area`
- `settings`
- `created_at`

### `users/{uid}`

Shared user profile across all roles.

Fields:

- `organization_ids`
- `display_name`
- `phone`
- `email`
- `preferred_language`
- `roles`
- `active_role`
- `status`
- `photo_url`

### `field_agents/{uid}`

Fields:

- `organization_id`
- `base_location` with `lat`, `lng`, `geohash`
- `assigned_regions`
- `device_last_seen_at`
- `app_version`
- `sync_health`

### `volunteers/{uid}`

Fields:

- `organization_id`
- `skills`
- `languages`
- `availability_status`
- `current_task_count`
- `home_location` with `lat`, `lng`, `geohash`
- `service_radius_km`
- `acceptance_rate`
- `last_active_at`

### `needs/{needId}`

This is the operational heart of the system.

Fields:

- `organization_id`
- `source_channel` such as `field_app`, `telegram`, `sms`, `dashboard`
- `source_event_id`
- `title`
- `description`
- `need_type`
- `urgency_input`
- `priority_score`
- `verification_status`
- `review_required`
- `parse_confidence`
- `people_affected`
- `beneficiary_name`
- `beneficiary_phone`
- `location`
  - `lat`
  - `lng`
  - `geohash`
  - `address_text`
  - `location_accuracy_m`
- `status`
  - `open`
  - `triaged`
  - `assigned`
  - `in_progress`
  - `resolved`
  - `closed`
  - `rejected`
- `escalation_flag`
- `unmet_since`
- `assigned_task_id`

### `tasks/{taskId}`

Fields:

- `organization_id`
- `need_id`
- `volunteer_id`
- `assigned_by`
- `match_candidates`
- `status`
  - `offered`
  - `accepted`
  - `declined`
  - `in_progress`
  - `completed`
  - `cancelled`
- `scheduled_for`
- `accepted_at`
- `completed_at`
- `completion_notes`
- `completion_media`

### `ingestion_events/{eventId}`

Raw inbound messages before normalization.

Fields:

- `organization_id`
- `channel`
- `external_sender_id`
- `external_message_id`
- `raw_text`
- `attachment_refs`
- `voice_storage_path`
- `transcript_text`
- `parse_status`
- `parse_result`
- `parse_confidence`
- `needs_candidate_id`

### `events/{eventId}`

Audit stream.

Fields:

- `organization_id`
- `entity_type`
- `entity_id`
- `event_type`
- `actor_uid`
- `actor_role`
- `summary`
- `metadata`
- `created_at`

### `reports/{reportId}`

Optional generated summaries or funding exports.

Fields:

- `organization_id`
- `type`
- `status`
- `requested_by`
- `time_range`
- `storage_path`

## Subcollections

Recommended subcollections:

- `needs/{needId}/notes`
- `needs/{needId}/attachments`
- `needs/{needId}/history`
- `tasks/{taskId}/history`

Use subcollections for high-churn or append-only data so root documents stay small.

## Required indexes

Start with these:

1. `needs`: `organization_id`, `status`, `priority_score desc`
2. `needs`: `organization_id`, `status`, `updated_at desc`
3. `tasks`: `organization_id`, `volunteer_id`, `status`
4. `volunteers`: `organization_id`, `availability_status`, `skills array`
5. `ingestion_events`: `organization_id`, `parse_status`, `created_at desc`

For geo search:

- Store `geohash`, `lat`, and `lng`
- Query by `geohash` ranges, then filter by exact distance

## State transitions

### Need lifecycle

`open -> triaged -> assigned -> in_progress -> resolved -> closed`

Alternative exits:

- `open -> rejected`
- `assigned -> open` if volunteer declines and reassignment is needed

### Task lifecycle

`offered -> accepted -> in_progress -> completed`

Alternative exits:

- `offered -> declined`
- `offered -> cancelled`
- `accepted -> cancelled`

## Ownership boundaries

- Coordinators can triage, assign, escalate, merge, and close.
- Field agents can create and update draft or open needs they originated.
- Volunteers can read assigned tasks and update task execution fields only.
- Admins can manage org settings, users, and reports.
