# Audit: SuperClaude Framework vs claude-workspace

Date: 2026-08-21. Method: three parallel agents read (1) all 30 SuperClaude commands, (2) its 20 agents + 7 modes + hooks + core + MCP configs + the internal `DELETION_RATIONALE.md` and `QUALITY_COMPARISON.md` documents, and (3) the 16 claude-workspace skills with a critical eye. This document is the synthesis. The v2.2.0 changes to this repo (spec persistence, confidence gate, lifecycle hooks, `/debug` lesson archive, plus three bug fixes) came out of it.

## Executive verdict

SuperClaude is roughly 30% good ideas and 70% mass-generated volume with invented metrics. Its safety gates are decorative prose; this repo's are mechanisms (a hook that hashes the staged diff). Its real value sits in four concrete patterns this toolkit lacked: a session lifecycle over external memory, numeric confidence gates, a knowledge base that files failures, and lifecycle hooks. Its own history also validates this repo's philosophy: in October 2025 SuperClaude deleted 27 of its 30 commands, declaring that "minimal + orchestration" wins ("89% footprint reduction", "avoid reinventing the wheel") — and today the repo ships 30 commands again. They learned the lesson and un-learned it.

The audit also found 3 real bugs in claude-workspace, worth fixing regardless of everything else (all fixed in v2.2.0).

## What is real in SuperClaude (worth studying or stealing)

### 1. Session lifecycle over external memory (`/sc:load`, `/sc:save`, `pm.md`)

Symmetric session open/close commands over a memory store (Serena MCP), with automatic checkpoints every 30 minutes and a namespaced key schema (`session/`, `plan/[feature]/`, `learning/solutions/[error]`) modeled on git refs. It solves the same problem as a STATUS.md convention, but as a mechanism rather than a discipline that depends on remembering.

Relevance: this toolkit persisted artifacts (conventions, architecture, decisions, todos) but NOT the state of an in-flight task. If a session died mid-`/work`, there was no resume. **Adopted in v2.2.0** as `.claude/specs/` persistence.

### 2. Numeric confidence gates (`agent.md`, `confidence-check` skill)

"Do not implement below confidence 0.90; if confidence stalls, escalate to the user." It turns "be careful" into a number the model must report and cannot cross. The threshold is arbitrary, but the effect is real: it forces the model to state explicitly whether it understood before writing code, and gives the user a legible signal.

Relevance: `/work` Phase 1 asked 5 spec questions but had no explicit go/no-go. **Adopted in v2.2.0** as the confidence gate closing Phase 1.

### 3. Outcome-routed knowledge base (`pm.md`)

Every work cycle gets filed by how it ended: success → formalized `docs/patterns/*.md`; failure → `docs/mistakes/*.md` with date, root cause and a prevention checklist. Plus the rule "never retry the same approach without a hypothesis for why it failed". The repo learns from its own mistakes.

Relevance: `/decision` captured decisions but nothing equivalent existed for failures. **Adopted in v2.2.0** as `/debug`'s "Archive the lesson" phase.

### 4. Lifecycle hooks (`hooks/hooks.json`)

- **Stop hook** (prompt): "before ending, check for uncommitted changes or incomplete tasks and say so". Cheap and real.
- **PostToolUse on Write|Edit** (prompt): "verify the edit has no syntax errors, missing imports or broken logic; if it does, fix it now". A near-zero-cost quality net.

Relevance: this repo had ONE hook (the commit gate, which is better than anything SuperClaude ships). These two are natural complements. **Adopted in v2.2.0.**

### 5. Repo index as context replacement (`index-repo.md`)

Generates `PROJECT_INDEX.md` with a hard size budget (<5KB) and positions it as "read this instead of scanning the repo". The numbers they cite (58K → 3K tokens, 94% reduction) have no measurement behind them, but the pattern is the legitimate kind of token saving: reduce what enters the context, don't compress the output style.

Relevance: `/architecture` already generates architecture-map.md but without a size budget or a "load me first" role. Pending (Tier 3).

### 6. Minor rules that hold up

- Explicit rule precedence on conflict: "Safety > Scope > Quality > Speed" (`core/RULES.md`).
- "Infra changes (Dockerfile, nginx, terraform) MUST consult official documentation via WebFetch before recommending; block assumption-based configuration" (`MODE_Orchestration.md`). Blunt and sensible.
- Style prohibitions: "never 'blazingly fast', '100% secure', no sycophantic behavior".

## What is theater (avoid)

### The "token savings" mode — confirmed as smoke

`MODE_Token_Efficiency.md` is output-style compression: symbol tables (`→`, `∴`, `»`), domain emoji, abbreviations (`cfg`, `impl`, `sec`). Their own worked example: "The authentication system has a security vulnerability in the user validation function" → `auth.js:45 → 🛡️ sec risk in user val()`.

Problems: (a) the claim "30-50% reduction, ≥95% information quality" has no measurement method anywhere; (b) emoji and glyphs like `∴` are multi-token in most tokenizers, so per-glyph savings are not self-evident; (c) it compresses the communication, not the context — real token savings come from not feeding garbage into the context (repo indexes, filtered command output), not from the model speaking in hieroglyphs; (d) their own business-panel budgets "15-30K tokens per analysis", eating the savings elsewhere.

### The 20 personas — interchangeable boilerplate

17 of 20 share the same skeleton (a "mindset" paragraph + 5 focus areas + Will/Will Not) with no procedures, no restricted tools, no examples. `security-engineer.md` contains not a single concrete technique. The 3 exceptions with real operational content: `deep-research-agent.md` (routing with numeric thresholds), `self-review.md` (a 4-question post-implementation checklist), `pm-agent.md`.

This repo's single subagent (`code-reviewer`, restricted to read-only tools, clean context) is a better mechanism than their 20 declarative roles. If specialists ever become worth it, write 2-3 procedural ones like self-review, not 20 job descriptions.

### Invented metrics everywhere

"87% success rate from 2,847 projects" (fabricated, in `recommend.md`), "94% hallucination detection", "sub-100ms decisions, >95% accuracy" (latency SLOs inside prompt files, physically impossible to honor), "complexity >0.8" with no defined computation.

Mirror note: this repo's `/quick-work` cited "catches 50% of misunderstandings" and "80% of obvious bugs" — the same sin in miniature. Removed in v2.2.0.

### Internal drift — the maintenance cautionary tale

`sc.md` says v4.1.7 and documents 5 commands; `help.md` lists 24; the README says 30 and v4.3.0. `recommend.md` references commands that do not exist (`/sc:scan`, `/sc:deploy`). `QUALITY_COMPARISON.md` (Oct 21) declares the TypeScript port "production-ready"; `DELETION_RATIONALE.md` (Oct 24, three days later) deletes it as "over-engineering". Both still sit at the repo root.

Direct lesson for claude-workspace: its hardcoded inventories had drifted the same way (the `/commands` scan bug, `/scaffold`'s hardcoded template list). Any inventory written as prose inside a prompt will drift; it needs automated validation against reality (pending, Tier 3).

## Bugs found in claude-workspace (fixed in v2.2.0)

1. **`skills/commands/SKILL.md` scanned the pre-migration directory.** It looked for `~/.claude/commands/*.md`, but the toolkit migrated to `~/.claude/skills/<name>/SKILL.md` and the installer removes the legacy files. On a current install it reported "No personal commands installed". Its category table also omitted `/isolate`.
2. **`skills/isolate/SKILL.md` — infinite loop.** The ancestor walk did `parent="$parent/.."`; the string grew forever and `[ "$parent" != "/" ]` never became true. Fixed with real path resolution (`cd`/`pwd` + `dirname`).
3. **Ghost spec persistence.** `/work` and `/issue` saved the spec to "a temporary working note" with no defined path; the spec evaporated and `/safe-commit` Phase 4 verified "against the spec" from memory. It contradicted principle #3 of this repo's own FRAMEWORK.md (persistent context). Fixed: canonical path under `.claude/specs/`, written by `/work`, read by `/safe-commit`, status-tracked to `done`.

Minor: inconsistent Q5/Phase-2 numbering in `/decision`; Spanish leakage in `/architecture` and `/decision` output templates; hardcoded template inventory in `/scaffold`; Node-only test detection in `/safe-push` (all pending, Tier 3).

## Prioritized improvement plan

### Tier 1 — Fixes (own debt, no SuperClaude needed) — DONE (v2.2.0)

| # | Change | Status |
|---|--------|--------|
| 1 | Fix `/commands` scan dir + add `/isolate` to its table | Done |
| 2 | Fix `/isolate` infinite loop | Done |
| 3 | Persistent specs: `/work` writes `.claude/specs/`, `/safe-commit` reads it, `/issue` too | Done |
| 4 | Remove invented statistics from `/quick-work` | Done |

### Tier 2 — High-benefit, low-effort adoptions — DONE (v2.2.0)

| # | Change | Source | Status |
|---|--------|--------|--------|
| 5 | Stop hook: on session end, surface uncommitted changes / in-progress specs / incomplete tasks | SC hooks.json | Done |
| 6 | PostToolUse Write\|Edit: post-edit self-check | SC hooks.json | Done |
| 7 | Confidence gate in `/work`: report 0-1 after the spec; <0.9 → more questions, not code | SC agent.md | Done |
| 8 | `/debug` closes by offering `docs/mistakes/` archive with prevention checklist; recurring classes promote to conventions or `docs/patterns/` | SC pm.md | Done |

### Tier 3 — Structural improvements (when time allows)

| # | Change | Notes |
|---|--------|-------|
| 9 | Size budget (<5KB) and "load me first" role for architecture-map | The legitimate token saving |
| 10 | Rule precedence in FRAMEWORK.md (Safety > Scope > Quality > Speed) | One table |
| 11 | "Official docs before infra changes" rule | From MODE_Orchestration |
| 12 | Anti-drift script: validate hardcoded inventories (`/scaffold`, `/commands`) against the filesystem in CI | The lesson from SC's drift |
| 13 | Label the Node/Next.js bias honestly or add python/go detection | In `/conventions`, `/safe-push` |

### Not adopting

- Symbol/emoji compression mode (theater; likely quality degradation)
- The 20 declarative personas (boilerplate; the restricted-tools code-reviewer is superior)
- The 25 pseudo-flag system (overhead for a personal toolkit; `$ARGUMENTS` free text + skill auto-invocation scales fine at this size)
- Latency SLOs and unmeasured metrics (the complete anti-pattern)
- The 8-server MCP fleet (evaluate individually if a need arises; not as a bundle)

## Closing note

The best validation of claude-workspace sits in SuperClaude's own `DELETION_RATIONALE.md`: when they had to choose what survived, they chose exactly this repo's philosophy (minimal command count, orchestration, markdown over code, don't duplicate built-in tools) — and then the repo grew back to 30 commands. A small personal toolkit with deterministic gates is more maintainable than a large framework with prose gates. The risk to watch is not missing features; it is inventory drift, which had already started here (bugs 1 and `/scaffold`'s list).
