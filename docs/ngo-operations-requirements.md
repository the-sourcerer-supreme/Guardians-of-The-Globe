# NGO Operations Requirements

This file captures operational requirements that came out of humanitarian coordination and volunteer safety guidance, and translates them into product requirements for Guardians of the Globe.

## Assessment and intake

The intake layer should support:

- coordinated needs assessment
- evidence-based prioritization
- reduction of duplicate case creation
- beneficiary language preference
- beneficiary consent capture
- vulnerability tagging

That is why the current mobile data model includes:

- `preferred_language`
- `consent_captured`
- `review_required`
- `verification_status`
- `vulnerability_tags`

## Coordinator workflow

Coordinators need:

- a live queue of open needs
- clear severity and review indicators
- visible volunteer availability
- manual assignment override
- audit visibility

That is why the coordinator app now includes:

- live needs stream
- volunteer assignment suggestions
- status metrics
- audit timeline

## Volunteer workflow

Volunteer management should not stop at assignment. The workflow must support:

- clear accept or decline decision
- one active task at a time where appropriate
- completion notes
- availability management
- volunteer safety and workload visibility

That is why the volunteer app now includes:

- offer inbox
- active task screen
- completion logging
- availability controls

## Safeguarding and accountability

The platform should preserve:

- human review for ambiguous or sensitive cases
- audit events for status changes
- limited role-based access
- clear ownership by organization

The current repository and security rules now reflect that direction, but production hardening still needs:

- custom claims for stronger storage controls
- admin-only role assignment
- abuse handling
- retention policy decisions

## What still needs deeper implementation

- duplicate-detection workflow
- coordinator review queue for sensitive or low-confidence cases
- volunteer incident and safety reporting
- richer beneficiary protection controls
- media upload moderation and retention rules
- organization onboarding and approval flows
