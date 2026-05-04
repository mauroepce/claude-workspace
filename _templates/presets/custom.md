# Preset: Custom

For workspaces that don't fit research / product / knowledge / consulting cleanly.

## Defaults

- **SUBPROJECT_DIR**: ask the user
- **SUBPROJECT_NOUN**: ask the user

## Extra interview questions (in addition to standard ones)

When user picks Custom, ask:

1. What do you call your subprojects? (a noun: experiment, project, episode, dossier, etc.)
2. What directory should they live under? (e.g., `projects/`, `dossiers/`)
3. What state do you need to track per subproject? (multi-select: progress, decisions, blockers, references, dataset, deliverables, sources, other)
4. Any extra commands you want? (free text or "none")

Use the answers to assemble a STATUS.md skeleton with only the sections they picked. Don't include sections they didn't ask for.

## Subproject CLAUDE.md skeleton (generic fallback)

```markdown
# {{NAME}} — Conventions

## Type
<what kind of subproject this is>

## Tools / stack
<what's used here>

## Conventions
<patterns specific to this subproject>
```

## Subproject STATUS.md skeleton (generic fallback)

```markdown
# {{NAME}} — STATUS

**Last updated:** <date>

## State
<one paragraph capturing current state>

## TODOs
- [ ] ...

## Key decisions
- **<decision>.** Reason: <why>.

## Blockers
<things waiting on user input>
```
