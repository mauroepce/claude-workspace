---
description: Scan a codebase and produce a structured architecture-map.md — stack, directory structure, database schema, API routes, auth flow, external integrations, and the 5-10 most critical files. Use when joining an unfamiliar repo or when re-loading context on your own project after months of absence (e.g., interview prep).
---

# /architecture-map — Codebase architecture cheat sheet

You are Claude. The user wants a structured map of an entire codebase so they can re-load context fast or hand it to someone else (interviewer, new team member).

This is the "30,000-foot view" deliverable, complementing `/conventions` (which captures style patterns) — together they give you both **what the code looks like** (conventions) and **what the code does** (architecture).

**Argument (optional):** `$ARGUMENTS` may be an output path like `.claude/architecture-map.md`. If empty, default to `.claude/architecture-map.md`.

## Phase 1 — Detect project shape

Run, in parallel where possible:

```bash
# Project root identification
test -f package.json && echo "node project"
test -f Cargo.toml && echo "rust project"
test -f pyproject.toml && echo "python project"
test -f go.mod && echo "go project"

# Directory tree (depth 3, skip noise)
tree -L 3 -I 'node_modules|.next|.git|.swc|dist|build|target|__pycache__|.venv' . 2>/dev/null | head -60

# Stack signal
test -f package.json && cat package.json | jq '{name, version, dependencies: (.dependencies // {}), scripts: (.scripts // {})}'
test -f tsconfig.json && cat tsconfig.json | jq '.compilerOptions | {target, module, strict, paths}'
```

## Phase 2 — Detect tech stack details

Based on what's in the dependencies (or equivalent), enrich:

| Signal in deps | Infer |
|---|---|
| `next` | Framework: Next.js + likely TypeScript |
| `@supabase/supabase-js` | DB: Supabase (Postgres + Auth + Storage) |
| `prisma`, `@prisma/client` | ORM: Prisma + likely Postgres |
| `drizzle-orm` | ORM: Drizzle |
| `@nestjs/common` | Framework: NestJS |
| `express`, `fastify`, `hono` | Backend framework |
| `react-native`, `expo` | Mobile: React Native |
| `react-hook-form` + `zod` | Forms with validation |
| `posthog-js`, `@posthog/node` | Analytics: PostHog |
| `@lemonsqueezy/lemonsqueezy.js` | Payments: Lemon Squeezy |
| `resend` | Email: Resend |
| `bullmq` | Queues: BullMQ + Redis |
| `vitest`, `jest` | Testing |

Be honest about uncertainty: if you can't tell from deps alone, mark it as "TBD — verify by reading [file]".

## Phase 3 — Detect database schema

In order, check for:

1. **Prisma**: `schema.prisma` → read models
2. **Drizzle**: `**/schema.ts` with `pgTable` / `mysqlTable` → read tables
3. **Supabase migrations**: `supabase/migrations/*.sql` → read all in chronological order
4. **Raw SQL migrations**: `migrations/*.sql`, `db/migrations/`, etc.
5. **ORM-less**: skip and mark "no schema definition found"

For each table/model, capture:
- Name
- Columns (primary key, FKs, important columns only — not exhaustive)
- Foreign key relationships
- RLS policies (if Supabase)
- Indexes (composite ones especially)

## Phase 4 — Detect API surface

Find HTTP route definitions:

```bash
# Next.js App Router
find src/app -name "route.ts" -o -name "route.tsx" 2>/dev/null | head -20

# Express/Fastify
grep -rn "app\.\(get\|post\|put\|delete\|patch\)" src/ 2>/dev/null | head -20

# NestJS controllers
grep -rln "@Controller(" src/ 2>/dev/null | head -10
```

For each route found, capture the HTTP verb, path, and a 1-line description of what it does (from comments, function name, or inferring from code).

## Phase 5 — Detect auth pattern

Look for:

```bash
grep -rn "createServerClient\|createBrowserClient\|signInWithPassword\|signInWithOAuth" src/ 2>/dev/null | head -10
grep -rn "JsonWebToken\|jsonwebtoken\|jwt\." src/ 2>/dev/null | head -10
grep -rn "passport\|@nestjs/passport" src/ 2>/dev/null | head -10
```

Identify the pattern:
- Supabase Auth (PKCE? OAuth providers?)
- NextAuth / Auth.js
- Custom JWT
- Passport (Express/Nest)
- None / public

## Phase 6 — Detect external integrations

Read imports across `src/` to find third-party services:

```bash
grep -rh "^import.*from \"[^@.]" src/ 2>/dev/null | sed 's/.*from "\([^"]*\)".*/\1/' | sort -u | head -30
```

Filter to known service integrations (Lemon Squeezy, Stripe, Resend, PostHog, Telegram, Twilio, AWS, GCP, etc.). For each, note where it's used (which file).

## Phase 7 — Identify 5-10 critical files

These are files the user will reference often when explaining the system. Pick based on:
- Auth handler (most often `lib/auth.ts` or `app/auth/route.ts`)
- Payment webhook handler (often `app/api/webhooks/[provider]/route.ts`)
- Core business logic (often `lib/calculations.ts`, `services/`, or a domain-specific name)
- Database client wrapper (often `lib/db.ts` or `lib/supabase.ts`)
- Email/notification dispatchers
- Main layout / providers tree (`app/layout.tsx`)
- Main config file (next.config, vercel.json, etc.)

For each, provide:
- Path
- 1-sentence description
- Why it's critical (what would break if you got it wrong)

## Phase 8 — Build the output

Write the file in this exact format. Use `<placeholder>` only where info is genuinely uncertain — never fabricate.

```markdown
# Architecture map — <project name>

*Generated by `/architecture-map` on <date>. Re-run when the codebase changes substantially.*

## 1. Elevator pitch (2 sentences)

<inferred from package.json description, README, and code structure — be conservative>

## 2. Tech stack

| Capa | Tecnología | Versión | Source of truth |
|---|---|---|---|
| <as detected> | <as detected> | <from package.json> | <file where it lives> |

## 3. Directory structure

\`\`\`
<tree output>
\`\`\`

### Carpetas clave
- `<dir>` → <what lives here>
- ...

## 4. Database

### Tables
- **`<table>`** — <one-line purpose>
  - Columns: <key cols>
  - FKs: <relationships>
  - Indexes: <composite ones>
  - RLS: <yes/no, brief>

### Schema decisions worth noting
- <inferred patterns>

## 5. API surface

| Method | Path | Purpose |
|---|---|---|
| <as found> | <as found> | <as inferred> |

## 6. Auth

**Pattern:** <detected pattern>
**Flow (high level):** <inferred steps>
**Critical file:** <path>

## 7. External integrations

| Service | Used in | Purpose |
|---|---|---|
| <as detected> | <file path> | <purpose> |

## 8. Los 5-10 archivos críticos

| # | Path | Por qué importa |
|---|---|---|
| 1 | <path> | <reason> |
| ... | ... | ... |

## 9. ⚠️ Cosas que NO pude verificar desde el código

> Estos huecos requieren tu memoria o experiencia con el proyecto. Llenalos manualmente.

- <list items where you marked TBD>
- ...

## 10. Cosas que sugiero releer ANTES de una entrevista o handoff

- <list of files that would benefit from deeper familiarity>
- ...
```

## Phase 9 — Save + hand off

Save to the path provided in `$ARGUMENTS` or default `.claude/architecture-map.md`.

Output:

> "Architecture map saved to `<path>`. Reviewed: <N> files, <M> tables, <K> API routes detected.
>
> Honest gaps (marked in section 9): <X> items where the code didn't tell me enough — you'll need to fill those from memory.
>
> Want me to also run `/conventions` so you have both the architecture (what the code DOES) and the conventions (what it LOOKS LIKE)?"

## What NOT to do

- Don't fabricate. If you couldn't detect something from the code, mark it as TBD.
- Don't write a 30-page wall of text. Keep each section tight — this is a cheat sheet, not documentation.
- Don't overwrite an existing `architecture-map.md` without warning. If it exists, ask "overwrite, or save as architecture-map.v2.md?"
- Don't try to interpret WHY decisions were made — that's `/decision`'s job. This command only captures WHAT exists.
- Don't add `Co-Authored-By: Claude` to the file.
