# Preset: Knowledge

For personal knowledge management. Each subproject is a topic, a long-running note, or a learning project.

## Defaults

- **SUBPROJECT_DIR**: `notes/`
- **SUBPROJECT_NOUN**: `note` (or `topic`)

## Suggested extra commands

- `/new-note <topic>` — alias for `/new-project` with knowledge-flavored prompts
- `/link <other-note>` — add a cross-reference to another subproject

## Subproject CLAUDE.md skeleton

```markdown
# {{NAME}} — Conventions

## Topic
<what this note is about, in one sentence>

## Format conventions
- Source links go in `## Sources`
- Personal interpretations go in `## My take`
- Open questions go in `## Open questions`

## Related
- <list of related subprojects in this workspace>
```

## Subproject STATUS.md skeleton

```markdown
# {{NAME}} — STATUS

**Last updated:** <date>

## Summary
<a few sentences capturing the current understanding of this topic>

## Sources
- [link or citation 1]
- [link or citation 2]

## My take
<your interpretation, distinct from sources>

## Open questions
- <question 1>
- <question 2>

## Next reading / actions
<what to read or explore next>
```

## Suggested global rules to add to root CLAUDE.md

- Distinguish source content from your own interpretation explicitly.
- Track open questions — they're the most valuable output of a knowledge project.
