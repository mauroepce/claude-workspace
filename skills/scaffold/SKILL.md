---
description: List available templates from ~/.claude/templates/ and insert the chosen one into the working directory. Templates encode Mauricio's senior conventions and good practices, ready to copy-adapt. Use when starting a new file from scratch in any project — avoids re-typing boilerplate.
---

# /scaffold — Insert a template

You are Claude. The user invoked `/scaffold` to pick a template from their personal collection and adapt it to the current task.

**Argument (optional):** `$ARGUMENTS` may be:
- Empty → list all templates and ask user to pick
- A template path like `backend/nest-controller` → load that template directly
- A type keyword like `endpoint`, `form`, `retry` → match to the most likely template

## Phase 1 — Discover available templates

If `$ARGUMENTS` is empty or the user just wants to browse:

```bash
ls -1 ~/.claude/templates/ 2>/dev/null
find ~/.claude/templates -name "*.ts" -o -name "*.tsx" 2>/dev/null | sed 's|.*/templates/||' | sort
```

If the directory doesn't exist, tell the user:

> "Templates not installed. Run `curl -fsSL https://raw.githubusercontent.com/mauroepce/claude-workspace/main/bin/install-personal.sh | bash` to install."

If templates exist, present them grouped by directory:

```
Templates available:

backend/
  - express-endpoint.ts       Express + Zod + error classes
  - nest-controller.ts        NestJS controller + service + DTO
  - next-api-route.ts         Next.js App Router API handler

frontend/
  - next-page.tsx             Next.js page with Server Component
  - react-form.tsx            react-hook-form + Zod validation

utils/
  - async-retry.ts            Exponential backoff retry with jitter
  - result-type.ts            Result<T, E> pattern
  - zod-helpers.ts            Common Zod schemas (email, UUID, pagination, etc.)

tests/
  - vitest-setup.ts           Vitest config + first integration test

Pick one (e.g., "backend/nest-controller" or "retry") and tell me the target file path.
```

## Phase 2 — Match the user's intent

If `$ARGUMENTS` is a clear path (`backend/nest-controller`), use that.

If it's a keyword:

| Keyword (case-insensitive) | Match |
|---|---|
| `endpoint`, `express`, `api` | `backend/express-endpoint.ts` |
| `nest`, `controller` | `backend/nest-controller.ts` |
| `next-api`, `route-handler` | `backend/next-api-route.ts` |
| `page`, `next-page` | `frontend/next-page.tsx` |
| `form`, `react-form` | `frontend/react-form.tsx` |
| `retry` | `utils/async-retry.ts` |
| `result` | `utils/result-type.ts` |
| `zod`, `schemas` | `utils/zod-helpers.ts` |
| `test`, `vitest` | `tests/vitest-setup.ts` |

If ambiguous, list the matches and ask the user to pick.

## Phase 3 — Confirm destination

Ask:

> "Target file path? (e.g., `src/api/users/route.ts` or `src/utils/retry.ts`)"

Wait for an answer. Don't write to a default location — the user knows their project structure.

If the file already exists, warn: "File `<path>` exists. Overwrite, or place at `<path>.scaffold` for review?"

## Phase 4 — Read template + adapt + write

1. Read `~/.claude/templates/<chosen>`.
2. Adapt to the target context. Specifically:
   - If the user mentioned a resource name (e.g., `/scaffold nest-controller orders`), rename `users` → `orders`, `User` → `Order`, etc., consistently throughout the file.
   - If the template references other templates (e.g., the test imports `../utils/async-retry`), adjust import paths to match the user's project structure.
   - Strip teaching comments only if user explicitly asks; default is to KEEP them (they encode the why).
3. Write to the target path.

## Phase 5 — Tell the user what to do next

Output:

```
✓ Wrote <target path>.

Next steps:
- Install dependencies: <list from template's header comment>
- Adapt the schema + handler to your specific case
- Drop the teaching comments once you've internalized them (or keep — they explain the why)

Want to scaffold a companion file? (e.g., the test for this, the route wiring, etc.)
```

If the template had a `companion files` section (like next-page.tsx mentioning error.tsx and loading.tsx), suggest scaffolding those too.

## What NOT to do

- Don't write the file without confirming the target path.
- Don't silently overwrite existing files. Always warn.
- Don't strip the teaching comments by default. They're part of the value.
- Don't invent templates. If the requested template doesn't exist in `~/.claude/templates/`, say so and suggest the closest match.
- Don't add `Co-Authored-By: Claude` to the scaffolded file (templates are user-owned conventions, not AI authorship).
