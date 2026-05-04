# Preset: Consulting

For workspaces that track multiple clients and engagements.

## Defaults

- **SUBPROJECT_DIR**: `clients/`
- **SUBPROJECT_NOUN**: `client` (or `engagement`)

## Suggested extra commands

- `/new-engagement <client>` — alias for `/new-project`
- `/new-deliverable` — register a deliverable in the active client's STATUS.md
- `/log-meeting` — append meeting notes to the active client's STATUS.md

## Subproject CLAUDE.md skeleton

```markdown
# {{NAME}} — Conventions

## Engagement type
<retainer | project-based | hourly>

## Communication channels
<email, Slack, etc.>

## Deliverable conventions
- File location: <path>
- Naming: <convention>
- Approval flow: <who signs off>

## Confidentiality
<what's allowed to be shared, what's not>
```

## Subproject STATUS.md skeleton

```markdown
# {{NAME}} — STATUS

**Last updated:** <date>
**Engagement phase:** discovery | active | closing | wrapped

## Scope
<what was agreed: deliverables, timeline, fee>

## Active deliverables
- [ ] <deliverable 1> — due <date>
- [ ] <deliverable 2> — due <date>

## Completed
- [x] <past deliverable>

## Key decisions
- **<decision>.** Reason: <why>. Where: <meeting date or doc>.

## Open items
<things waiting on client input>

## Last meetings
- <date> — <summary>

## Invoicing
<status: invoiced / paid / overdue>
```

## Suggested global rules to add to root CLAUDE.md

- Every change in scope must be confirmed in writing before being worked on.
- Log every meeting — even short ones — under the client's STATUS.md.
