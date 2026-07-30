---
description: Detect user-facing journeys in a codebase (auth flows, payment flows, main feature actions) and produce Mermaid sequence diagrams for each. Outputs journeys-diagram.md. Use to communicate system behavior visually — interview prep, onboarding new team members, documenting before refactor.
---

# /journeys-diagram — Visual flow documentation

You are Claude. The user wants visual sequence diagrams of the main user journeys in a codebase, rendered as Mermaid (which renders natively in GitHub, VS Code, and most modern markdown viewers).

A journey diagram answers: "When a user does X, what actually happens through the stack?" — frontend → backend → DB → side effects. They're the highest-leverage artifact for explaining behavior to humans.

**Argument (optional):** `$ARGUMENTS` may be an output path. Default: `.claude/journeys-diagram.md`.

## Phase 1 — Identify candidate journeys

Scan the codebase to find journey starting points:

```bash
# Frontend entry points (Next.js App Router)
find src/app -name "page.tsx" -not -path "*/node_modules/*" 2>/dev/null | head -20

# Auth-related files
grep -rln "signIn\|signUp\|signOut\|oauth\|PKCE" src/ 2>/dev/null | head -10

# Payment-related files
grep -rln "checkout\|webhook\|stripe\|lemon\|squeezy\|payment" src/ 2>/dev/null | head -10

# Form submissions (common journey trigger)
grep -rln "handleSubmit\|onSubmit\|Server Action\|use server" src/ 2>/dev/null | head -10

# API routes
find src/app -name "route.ts" 2>/dev/null | head -20
```

From these signals, propose 3-5 candidate journeys to map. Typical for SaaS apps:

| Category | Journey | Trigger |
|---|---|---|
| Auth | Signup with email/password or OAuth | User visits /signup |
| Auth | Login | User visits /login |
| Onboarding | Complete onboarding form | User authenticated for first time |
| Core feature | Main user action (e.g., calculator, create entity) | User submits form |
| Payment | Hit paywall → checkout | User exceeds free tier limit |
| Payment | Webhook processing | External provider sends event |
| Notification | First-event alerts | User triggers a "first time" event |

Present the candidates to the user and ask:

> "Detected these candidate journeys. Which ones do you want to map?
> (Diagramming each takes ~30s of my time, so feel free to pick 3-5 most important.)
>
> 1. [auto-detected journey 1]
> 2. [auto-detected journey 2]
> ...
>
> Pick numbers or say 'all'."

If user says "all" and there are >7 candidates, push back: *"That's a lot. The diagram file gets noisy at >7 journeys. Pick the 5 most important — the others can be added later if needed."*

## Phase 2 — Trace each journey through the code

For each chosen journey, READ the actual code involved. Don't infer from imagination.

Starting from the trigger (page, form, button), trace:

1. **Frontend** — what handler fires, what state changes, what's submitted
2. **API boundary** — which route/Server Action receives, what validation runs
3. **Backend logic** — services called, business rules applied
4. **Database** — queries, inserts, triggers (don't miss DB triggers — they're side effects you might not see in app code)
5. **External services** — webhooks sent, emails dispatched, notifications fired
6. **Response** — what comes back to frontend, what re-renders, what redirects

Each step should be 1 line in the diagram. Don't over-detail — the goal is a 30-second understanding, not a code review.

## Phase 3 — Generate Mermaid diagrams

For each journey, produce a Mermaid `sequenceDiagram`. Use these conventions:

- **Actors (left to right):** User → Browser → Frontend → API → Service/DB → External
- **Arrow types:**
  - `->>` for sync calls
  - `-->>` for responses
  - `-->>+` activated, `-->>-` deactivated for emphasis
  - `--x` for failure paths
- **Notes:** `Note over X: ...` for important context (e.g., transaction boundaries)

Example output format:

\`\`\`markdown
## Journey 1 — Signup with Google OAuth

**Trigger:** User clicks "Sign in with Google" on `/auth/signup`
**Files involved:**
- \`src/app/auth/signup/page.tsx\` (form)
- \`src/lib/supabase.ts\` (client)
- \`src/app/auth/callback/route.ts\` (callback handler)
- \`supabase/migrations/001_schema.sql\` (trigger creating profile)

\`\`\`mermaid
sequenceDiagram
    actor User
    participant Browser
    participant NextJS as Next.js Server
    participant Supabase
    participant Postgres
    participant Google

    User->>Browser: Click "Sign in with Google"
    Browser->>NextJS: GET /auth/signup
    NextJS-->>Browser: Render form with OAuth button
    User->>Browser: Click OAuth button
    Browser->>Supabase: signInWithOAuth({provider: 'google'})
    Supabase-->>Browser: Redirect URL with PKCE challenge
    Browser->>Google: Redirect with challenge
    User->>Google: Approve consent
    Google-->>Browser: Redirect to /auth/callback?code=...
    Browser->>NextJS: GET /auth/callback?code=...
    NextJS->>Supabase: exchangeCodeForSession(code, verifier)
    Supabase->>Postgres: INSERT INTO auth.users
    Note over Postgres: Trigger fires:<br/>INSERT INTO hcl_profiles
    Postgres-->>Supabase: User + Profile created
    Supabase-->>NextJS: Session + tokens
    NextJS-->>Browser: Set HTTP-only cookies, redirect /onboarding
    Browser-->>User: Show onboarding form
\`\`\`

**Key decisions in this flow:**
- PKCE (not implicit) — protects against authorization code interception
- Postgres trigger (not app code) — guarantees profile creation even if app code fails
- HTTP-only cookies (not localStorage) — XSS protection

**Trade-offs / known issues:**
- If the Postgres trigger errors silently, user gets logged in but has no profile (handled by [defensive check in middleware? null check elsewhere?])
\`\`\`

Repeat this format for each journey.

## Phase 4 — Save the file

Save to the path from `$ARGUMENTS` or default `.claude/journeys-diagram.md`. If the file exists, ask:

> "`journeys-diagram.md` exists. Overwrite, or save to `journeys-diagram.v2.md`?"

Add a header to the file:

\`\`\`markdown
# User journeys — <project name>

*Generated by \`/journeys-diagram\` on <date>. Re-run when journeys change substantially.*

Diagrams are Mermaid `sequenceDiagram` — render natively in GitHub, VS Code with Mermaid extension, and most modern markdown viewers.

---
\`\`\`

Then each journey as its own section.

## Phase 5 — Hand off

Output:

> "Journeys diagram saved to `<path>`. Mapped <N> journeys.
>
> To view: open in GitHub (renders Mermaid automatically), or use the Markdown Preview Mermaid Support extension in VS Code.
>
> Want to complement this with `/architecture-map` (static structure) and `/conventions` (style patterns)? Together they cover what the system DOES, what it LOOKS LIKE, and what it's BUILT FROM."

## What NOT to do

- Don't invent steps. If you can't trace a step from the actual code, mark it as "TBD: verify with author" instead of fabricating.
- Don't write a journey that's actually two journeys mashed together. Each diagram should answer one question.
- Don't render walls of code. Each step should be a 1-line action, not a function body.
- Don't include error handling exhaustively. Mermaid gets noisy. Show 1-2 important error paths per journey; mention others in prose.
- Don't add `Co-Authored-By: Claude` to the file.
