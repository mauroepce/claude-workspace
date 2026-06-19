# Templates — Mauricio's senior starter pack

Curated templates that bake in my conventions and good practices, ready to copy-paste during live coding or use as scaffolding base. Each one is a working file — drop it in, compiles, runs.

Templates are installed to `~/.claude/templates/` by `bin/install-personal.sh`. The slash command `/scaffold <type> [name]` lists them and inserts the chosen one.

## Index

### Backend

| Template | What it is | Use when |
|---|---|---|
| `backend/express-endpoint.ts` | REST endpoint with Zod validation, typed handler, error class hierarchy | Quick Node + Express service |
| `backend/nest-controller.ts` | NestJS controller + service + DTO with class-validator | NestJS-based backend (e.g., Carvuk) |
| `backend/next-api-route.ts` | Next.js App Router route handler with Zod validation | Next.js fullstack |

### Frontend

| Template | What it is | Use when |
|---|---|---|
| `frontend/next-page.tsx` | Next.js page (App Router) with Server Component + data fetching | Next.js page |
| `frontend/react-form.tsx` | React form with react-hook-form + Zod resolver + error display | Any form that needs validation |

### Utilities

| Template | What it is | Use when |
|---|---|---|
| `utils/async-retry.ts` | Exponential backoff retry with jitter, AbortSignal support | Any flaky external call |
| `utils/result-type.ts` | Result\<T, E\> pattern + helpers | Want explicit error handling without exceptions |
| `utils/zod-helpers.ts` | Common Zod schemas (email, UUID, timestamp, pagination) | Avoid re-writing the same schemas |

### Tests

| Template | What it is | Use when |
|---|---|---|
| `tests/vitest-setup.ts` | Vitest config + example test + fixture pattern | Starting tests in a new project |

## Conventions baked in

All templates follow:

- **TypeScript strict** — no `any` unless explicitly typed; prefer `unknown` + narrowing
- **ESM imports** — `import X from 'y'`, named exports preferred
- **Async/await** — no `.then()` chains
- **Validation at boundaries** — Zod for runtime input validation; types alone don't protect you from bad data
- **Error classes** — extends `Error`, with a custom name, structured for catch-and-narrow
- **No premature abstraction** — Rule of three before DRY-ing
- **Comments only for WHY** — code explains WHAT; comments explain WHY

## How to use

### In an interview

When you need a pattern:

1. Invoke `/scaffold` to see the list
2. Pick the one you need
3. Copy the output, paste, adjust to context
4. Tell the interviewer in voice over: *"Tengo un template propio para este patrón — incluye [Zod validation, error class, etc]. Lo voy a pegar y adaptar a este caso."*

That voice-over does two things:
- Shows the interviewer you have your own toolkit (senior signal)
- Explains WHY this pattern (not just "claude wrote it")

### In real work

- Read the template once, understand it
- Copy + adapt
- If you find yourself adapting the same way 3 times, the template should be updated

### About the teaching comments

Templates include extensive `// Why X: ...` style comments that explain reasoning. These are intentional — they encode the WHY behind each pattern.

**In an interview**: keep them. They demonstrate that the code reflects deliberate decisions, not "claude wrote it."

**In production code shipping to a team**: strip them after your first read. The pattern is now in your head; the comments are noise for everyone else.

A quick way to strip:

```bash
# Remove single-line comments starting with "// "
sed -i.bak '/^[[:space:]]*\/\/ /d' src/path/to/file.ts

# Remove block comments matching teaching style (// ─── ... ───)
# Open in editor and search-replace: ^// ─.*$ → (empty)
```

Don't strip the multi-line block comments at the top of files that document dependencies and usage — those are useful long after.

### To update a template

The source of truth is `claude-workspace/templates/`. Edit there, commit, re-run `install-personal.sh` on any machine.

## What's NOT here (yet)

- Drizzle / Prisma schema (deferred — too project-specific)
- React Native screen (deferred — Expo conventions vary by Expo version)
- WebSocket handler (deferred — rarely needed in interviews)
- gRPC service (deferred — niche)

Add them when you hit the pattern 3 times.
