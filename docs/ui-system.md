# Guardians of the Globe UI System

## Design intent

The product should feel dependable, clear, and quiet under pressure.

Use:

- white background
- solid colors only
- low-radius surfaces
- dense but readable layouts
- obvious status coding

Avoid:

- gradients
- glows
- neon colors
- oversized hero sections
- decorative cards inside cards

## Base palette

- `#FFFFFF` page background
- `#111827` primary text
- `#4B5563` secondary text
- `#1D4ED8` primary action
- `#059669` success
- `#D97706` warning
- `#DC2626` critical
- `#E5E7EB` borders
- `#F3F4F6` muted surfaces

## Surface rules

- Cards or panels max radius: `8px`
- Tables and boards should prioritize scan speed
- Maps are full-width working surfaces, not decorative embeds
- Buttons should use icon plus short label when ambiguity is possible

## App-specific guidance

### Coordinator dashboard

- Default to table + map split
- Keep filters visible
- Use urgency color chips and compact metrics
- Put assignment rationale in a side panel

### Field agent app

- One primary action per screen
- Large touch targets
- Sync state always visible
- Offline queue reachable in one tap

### Volunteer app

- One active task emphasized at a time
- Accept and decline actions must be unmistakable
- Show distance, ETA, and skill match plainly

## Typography

- No viewport-based font scaling
- No negative letter spacing
- Compact headings in work surfaces
- Reserve large text for app title or empty-state emphasis only
