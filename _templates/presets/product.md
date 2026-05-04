# Preset: Product

For MVP / startup portfolios. Each subproject is a product with its own lifecycle.

## Defaults

- **SUBPROJECT_DIR**: `apps/`
- **SUBPROJECT_NOUN**: `product` (or `MVP`)

## Suggested extra commands

- `/build <name>` — bootstrap a new product subproject from a template
- `/ship <name>` — mark as deployed and start lifecycle clock
- `/kill <name>` — archive a product

## Lifecycle states

```
pending → validating → live | iterating → archived
```

- `pending`: idea approved, not yet built
- `validating`: deployed, in proving window (default: 14 days)
- `iterating`: extra round of validation after a reset (max 1)
- `live`: got signal (≥1 paying customer or ≥10 organic signups)
- `archived`: dead

## Subproject CLAUDE.md skeleton

```markdown
# {{NAME}} — Conventions

## Stack
<framework, DB, payments, hosting>

## DB conventions
<table prefix, naming>

## Deploy
<command or workflow>

## Code patterns
<auth, payments, data fetching conventions>
```

## Subproject STATUS.md skeleton

```markdown
# {{NAME}} — STATUS

**Last updated:** <date>
**Lifecycle:** validating | iterating | live | archived
**Days since deploy:** <N>

## Brief
<one sentence: what this product does and for whom>

## What works ✅
- <feature 1>
- <feature 2>

## TODOs
```
CRITICAL
[ ] ...

CONVERSION
[ ] ...

GROWTH
[ ] ...
```

## Key decisions
- **<decision>.** Reason: <why>. How to apply: <when this kicks in>.

## Blockers
<things waiting on user input>

## Metrics this week
- Visits: N
- Signups: N
- Revenue: $X
```

## Suggested global rules to add to root CLAUDE.md

- Revenue from day 1 — every product must have a clear monetization path BEFORE coding starts.
- Ship in 48h max. If it doesn't fit, reduce scope.
- 14-day validation window. If no signal, archive.
