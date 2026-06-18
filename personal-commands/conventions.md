---
description: Scan an unfamiliar codebase and produce a structured conventions report — import style, naming, file organization, error handling, test patterns. Use when joining a new codebase (interview, new team, new client) before generating any code.
---

# /conventions — Codebase convention detection

You are Claude. The user just landed in an unfamiliar codebase. Before they generate a single line of code, you produce a structured conventions report so that everything generated afterward matches the project's style.

This is the **fastest way to look senior** in an unfamiliar repo. Most devs (and most AI agents) skip this step and produce code that drifts from existing patterns.

## Phase 1 — Detect project shape

Run, in this order:

```bash
# Project type and base config
ls -la
test -f package.json && cat package.json | jq '{name, type, dependencies: (.dependencies // {}), scripts: (.scripts // {})}'
test -f tsconfig.json && cat tsconfig.json | jq '.compilerOptions | {target, module, moduleResolution, paths, strict}'
test -f .eslintrc.json && head -20 .eslintrc.json
test -f .eslintrc.js && head -20 .eslintrc.js
test -f .prettierrc && cat .prettierrc
test -f .editorconfig && cat .editorconfig
```

Capture:
- Language/runtime (TypeScript? JavaScript? Bun? Node version?)
- Module system (ESM vs CommonJS)
- Strict mode? Path aliases?
- Lint and format tools configured

## Phase 2 — Sample source files

Pick 3–5 representative source files (not test, not config). Prefer:
- One from `src/` or main code dir
- One component or controller
- One service or business-logic file
- One test file

For each, capture:
- Import statements (the first 10 lines)
- A typical function/class definition
- Error handling pattern
- Async pattern

Use the file system: `find src -name "*.ts" -not -path "*/node_modules/*" | head -10` then read the most representative ones.

## Phase 3 — Detect patterns

For each category, report what you actually observed (not what you'd recommend):

### Import style
- Module style: ESM (`import X from`) or CommonJS (`require`)?
- Default vs named exports?
- Path alias used? (e.g., `@/components`, `~/lib`)? Or relative paths?
- Side-effect imports? (`import 'reflect-metadata'`)
- Import ordering convention? (third-party first, then local? grouped?)

### Quoting and formatting
- Single quotes or double?
- Semicolons or no?
- Trailing commas?
- Indentation (tabs / 2 spaces / 4 spaces)?

### Naming conventions
- File naming: `kebab-case.ts`, `camelCase.ts`, `PascalCase.tsx`?
- Component files vs utility files — same or different?
- Constant names: `UPPER_SNAKE` or `camelCase`?
- Class/Interface names: `PascalCase`? `IInterface` prefix or not?

### File organization
- Where do types live? (`types.ts`, `types/`, inline, separate `.d.ts`?)
- Where do tests live? (`__tests__/`, `*.test.ts` next to source, `tests/`?)
- Where does business logic vs presentation split?
- Are there reference modules (a folder explicitly used as "the canonical pattern")?

### Error handling
- Throw exceptions, return `Result` type, use `Either`, return null/undefined?
- Custom error classes?
- Are errors logged AND thrown, or one or the other?

### Async patterns
- `async/await` or chained `.then()`?
- Top-level await used?
- Cancellation patterns (AbortController, custom)?

### Test patterns
- Test runner (Jest / Vitest / Bun / Mocha)?
- Mock style (manual, lib like sinon, MSW for HTTP)?
- Integration tests against real DB or mocked?
- Test naming: `describe/it`, `test()`, or `it()`?

### Documentation
- JSDoc on public functions? Sparse comments? README-driven?

## Phase 4 — Output

Produce a structured report in this format. Save it to a temporary working memory the user can reference — and offer to write it to `CONVENTIONS.md` if the project has one or wants one.

```
═══════════════════════════════════════════════════════════
CODEBASE CONVENTIONS — <project name>
═══════════════════════════════════════════════════════════

LANGUAGE/RUNTIME
- <observation>

IMPORT STYLE
- Module system: <ESM/CJS>
- Path aliases: <yes (which) / no, relative>
- Default vs named: <observation>
- Sample import block from <file>:
  <quoted lines>

QUOTING & FORMATTING
- Quotes: <single / double / mixed (which file uses which)>
- Semicolons: <yes / no>
- Indentation: <tabs / 2 spaces / 4 spaces>
- Trailing commas: <yes / no>

NAMING
- Files: <kebab-case / camelCase / PascalCase>
- Components: <observation>
- Constants: <observation>

FILE ORGANIZATION
- Types live in: <observation>
- Tests live in: <observation>
- Reference module pattern: <yes (where) / no>

ERROR HANDLING
- Pattern: <throw / Result / null>
- Custom error classes: <yes (where) / no>

ASYNC
- Pattern: <observation>

TESTS
- Runner: <observation>
- Style: <observation>
- DB strategy: <observation>

DOCUMENTATION
- Style: <observation>

═══════════════════════════════════════════════════════════
ANTI-PATTERN AUDIT (things to AVOID in this codebase)
═══════════════════════════════════════════════════════════

- If user adds <X> they'd violate <pattern> — example: <file:line>
- ...

═══════════════════════════════════════════════════════════
WHAT YOU CAN'T TELL FROM 5 FILES (honest gaps)
═══════════════════════════════════════════════════════════

- <gap 1> — would need to read more files OR ask the team
- ...
```

## Phase 5 — Persist (critical) + hand off

The report MUST be saved to disk so subsequent `/work` invocations can read it. Chat-only is useless after the conversation ends.

Ask the user where to save:

> "I'll save this report so `/work` can pick it up automatically next time. Where?
>
> 1. `.claude/conventions.md` — committed to repo (default, team benefits)
> 2. `CONVENTIONS.md` at root — committed, more visible to anyone browsing the repo
> 3. `.claude/conventions.local.md` — gitignored, personal-only (for interview prep, client repos you don't own, etc.)
> 4. Chat only — discard (only choose if you're exploring and won't act on it)
>
> Default is **1**. Which?"

Wait for an answer. If user picks 1, 2, or 3, write the file using the EXACT same structured format from Phase 4 (the whole block including LANGUAGE/RUNTIME, IMPORT STYLE, ANTI-PATTERN AUDIT, HONEST GAPS).

If user picks 4, just leave it in chat.

For option 3 (`.claude/conventions.local.md`), also check that `.gitignore` covers it. Run:

```bash
grep -q 'conventions.local.md\|.claude/\*\.local\.\*' .gitignore 2>/dev/null
```

If the pattern isn't there, suggest:

> "I noticed `.gitignore` doesn't cover `.claude/*.local.md`. Want me to add it? (recommended for the gitignored option)"

Add this line to `.gitignore` if user agrees:
```
.claude/*.local.md
```

Then output:

> "Saved to `<path>`. When you invoke `/work` next, the Context phase will automatically pick it up — no need to re-paste. If anything in the report is wrong (you know better than 5 files can show), edit the file directly or run `/conventions` again to overwrite."

## What NOT to do

- Don't recommend "best practices" abstractly. Describe what the codebase ACTUALLY uses, even if it's unconventional.
- Don't suggest changing conventions. Your job is to detect, not opinionate.
- Don't hallucinate patterns. If you didn't observe it in the sampled files, mark it under "honest gaps".
- Don't add Co-Authored-By: Claude to any file you write.
- Don't run this on a codebase you've already worked in. It's wasted time.
