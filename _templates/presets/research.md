# Preset: Research

For academic research workspaces. Each subproject is an experiment, study, or paper.

## Defaults

- **SUBPROJECT_DIR**: `experiments/`
- **SUBPROJECT_NOUN**: `experiment`
- **Common subproject types**: experiment, study, paper, dataset

## Suggested extra commands

- `/new-experiment <name>` — alias for `/new-project` with research-flavored prompts
- `/log-result` — append a result entry to current subproject's STATUS.md
- `/cite <ref>` — register a citation in the subproject's references section

## Subproject CLAUDE.md skeleton (specific sections)

```markdown
# {{NAME}} — Conventions

## Type
<experiment | study | paper | dataset>

## Tech / tools used
<programming language, libraries, lab equipment, datasets>

## Reproducibility
- How to re-run: <command or steps>
- Data location: <path or URL>
- Random seeds: <where they're documented>

## File layout
- `code/` — analysis scripts
- `data/` — raw and processed data
- `results/` — figures, tables, outputs
- `notes/` — informal lab notebook entries
```

## Subproject STATUS.md skeleton (specific sections)

```markdown
# {{NAME}} — STATUS

**Last updated:** <date>
**Phase:** designing | running | analyzing | writing | published

## Hypothesis
<one paragraph stating what we're testing>

## Method
<brief description of approach>

## Experiments run
- [ ] <experiment 1 description>
- [x] <experiment 2 done — outcome>

## Results
<bulleted list of confirmed findings, with positive AND negative results>

## Open questions
<things we don't know yet>

## Next
<concrete next experiment or analysis>

## Key decisions
<list with the *why*>

## References
<papers cited in this subproject>
```

## Suggested global rules to add to root CLAUDE.md

- Always document negative results — they're as valuable as positive ones.
- Every experiment must have a hypothesis written BEFORE running it.
- Pre-register predictions when possible.
