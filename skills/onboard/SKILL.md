---
description: Joining an unfamiliar codebase. Runs /conventions + /architecture + /journeys in sequence and produces an onboarding package — three persistent files plus a 5-minute "where to start reading" summary. Use on day one of a new project, a client handoff, or returning to your own code after long absence. Workspace folders with multiple repos get a root INDEX.md plus per-repo packages; team repos with committed .claude/ get *.local.md artifacts kept out of git status.
---

# /onboard — Codebase onboarding package

You are Claude. The user just opened an unfamiliar codebase and wants the full context dump fast: how it looks, what it is, and how it behaves. Your job is to orchestrate three commands and produce a unified onboarding summary.

This is the meta-command that ties `/conventions`, `/architecture`, and `/journeys` together. Used by senior devs in their first 30 minutes in a new repo.

**Argument (optional):** `$ARGUMENTS` may be a brief context note (e.g., "joining as full-stack hire, focus on backend"). Used to bias the prioritization in step 5.

## Phase 0 — Detect the terrain

Two checks BEFORE the sanity check, because they change where everything gets written:

Run all three. The third is not optional: a repo and a workspace are not exclusive, and skipping it is how a workspace hidden one level down gets missed.

```bash
# A. Is THIS directory a repo? `test -e .git`, not `git rev-parse`: rev-parse
# answers about the whole work tree, so it says yes in every subdirectory of a
# parent repo. `-e` not `-d` because a worktree's .git is a FILE.
test -e .git && echo "this dir is a repo" || echo "not a repo"

# B. Are its direct children repos? (worktrees count here; the join skips them)
ls -d */.git 2>/dev/null | wc -l | tr -d ' '

# C. Is the workspace one level down? ALWAYS run this, whatever A and B said.
for c in */; do
  n=$(ls -d "$c"*/.git 2>/dev/null | wc -l | tr -d ' ')
  [ "$n" -ge 2 ] && echo "workspace candidate: $c ($n repos)"
done

# D. Team-owned tooling? (the repo commits .claude/ content or a CLAUDE.md)
git ls-files .claude CLAUDE.md 2>/dev/null | head -5
```

Note for `zsh` users: an unmatched glob aborts the command instead of returning nothing. Run these in `bash`, or `setopt NULL_GLOB` first.

**Case A — no `.git` in THIS directory but 2+ child directories are git repos** → this is a workspace folder, not a codebase. Jump to "Workspace mode" below. Do NOT stop with "not a git repo".

A workspace often lives *inside* a repo — a parent repo holding docs and skills, with the projects cloned into `repos/`. That is why check C runs unconditionally: in that layout A says "this dir is a repo", D says "team-owned", and an agent reading the cases in order would settle on single-repo onboarding and never look down.

If C names a folder, say so and run workspace mode **there**. The outer repo is then a sibling of the workspace, not a member: the join walks the workspace's direct children only, so the outer repo stays outside the graph. Say that out loud rather than letting the user assume it was scanned.

**Case B — tracked `.claude/` files or a CLAUDE.md exist** → this repo belongs to a team, and your onboarding artifacts are personal notes, not team deliverables. Announce it:

> "This repo has team-owned Claude tooling (committed `.claude/` or CLAUDE.md). I'll write the onboarding package as `*.local.md` files and keep them out of `git status` so nothing personal shows up in the team's diff."

Then for this entire run: use the `.local.md` variant of every output (`conventions.local.md`, `architecture-map.local.md`, `journeys-diagram.local.md`, `onboarding.local.md`) and offer to exclude them locally:

```bash
# `**/` matches zero or more directories, so this one line covers both
# .claude/conventions.local.md and .claude/lessons/mistakes/*.local.md.
grep -qF '.claude/**/*.local.md' .git/info/exclude 2>/dev/null || \
  printf '# personal claude-workspace artifacts\n.claude/**/*.local.md\n' >> .git/info/exclude
```

Why `.git/info/exclude` and not `.gitignore`: `.gitignore` is a committed, shared file — editing it puts YOUR tooling in THEIR diff, which is exactly what this mode avoids. `.git/info/exclude` behaves identically but never leaves your machine.

If neither case applies, continue to Phase 1 — the classic single-repo flow.

## Phase 1 — Sanity check

Confirm the user is in a git-tracked codebase that's NOT trivially empty:

```bash
test -d .git || echo "Not a git repo"
test -f package.json || test -f Cargo.toml || test -f pyproject.toml || test -f go.mod || echo "Unknown project type"
find . -type f -name "*.ts" -o -name "*.tsx" -o -name "*.py" -o -name "*.go" -o -name "*.rs" 2>/dev/null | grep -v node_modules | head -1
```

If it's not a real codebase (and Phase 0 didn't route to Workspace mode), stop: *"I don't see a recognizable project structure here. Run `/onboard` inside a project root (where package.json / Cargo.toml / etc. lives), or in a workspace folder containing your repos."*

## Phase 1.5 — First-run preference: commit attribution

Only on the FIRST onboard of a repo (no `.claude/onboarding.md` or `.local` variant exists yet). Skip entirely on re-runs. Runs AFTER the sanity check on purpose: never interrogate the user in a folder that Phase 1 is about to reject.

First check whether the repo already legislates this (CLAUDE.md only — a `GIT ETIQUETTE` line in the conventions file is a recorded preference, not repo law, and must not short-circuit this check):

```bash
grep -i "co-authored-by" CLAUDE.md 2>/dev/null | head -3
```

If a rule exists, announce it — *"This repo's CLAUDE.md already states a commit-attribution rule; respecting it"* — and move on without asking. Otherwise ask, once:

> "One repo preference, asked only on this first onboard: when I commit here, should commit messages include the `Co-Authored-By: Claude` trailer?
> 1. **Yes** — transparent AI attribution in the git history (what this toolkit's own repo does)
> 2. **No** — clean history, or the team hasn't decided a policy
>
> I'll record the answer in the conventions file so `/safe-commit` and future sessions honor it without re-asking."

Carry the answer into Phase 2: when `/conventions` writes its report, append this section to that same file:

```markdown
## GIT ETIQUETTE

- Co-Authored-By: Claude trailer in commits: <YES|NO> (set on first /onboard, <date>)
```

Precedence downstream: an explicit rule in the repo's own CLAUDE.md always wins over this recorded preference.

## Phase 2 — Run /conventions

Invoke `/conventions` as if the user did. Use the default save location (`.claude/conventions.md`) unless they specify otherwise.

After it completes, capture the result. Note the high-level patterns found (import style, naming, error handling, test framework).

## Phase 3 — Run /architecture

Invoke `/architecture` as if the user did. Default save location is `.claude/architecture-map.md`.

Capture what was found: stack, schema, API surface, auth pattern, integrations.

## Phase 4 — Run /journeys

Invoke `/journeys` as if the user did. Default save location is `.claude/journeys-diagram.md`.

For the journeys selection step, **suggest 3-5 most important ones** automatically (don't make the user pick from 10). Auth flow, payment flow if applicable, and 1-2 main feature flows. Tell the user which you're picking and why.

## Phase 5 — Produce the onboarding summary

Create `.claude/onboarding.md` (or `.claude/onboarding.local.md` if `.gitignore` covers it, or always when Phase 0 flagged team-owned tooling) with this exact format:

```markdown
# Onboarding — <project name>

*Generated by `/onboard` on <date>. The three files referenced below are your cheat sheet.*

## What this is (1 line)

<inferred from package.json description + README + code shape>

## The three persistent artifacts

| File | What it tells you |
|---|---|
| [`conventions.md`](./conventions.md) | How the code looks: import style, naming, error patterns, test framework |
| [`architecture-map.md`](./architecture-map.md) | What the parts are: stack, schema, API routes, auth, integrations |
| [`journeys-diagram.md`](./journeys-diagram.md) | What the code does: visual flow diagrams of <N> main user journeys |

Open them in this order. Read each in 3-5 minutes. Total ramp time: ~15 min.

## Top 5 files to read first

Based on the architecture scan, these are the files that will most often answer "where does this happen?":

1. **`<path>`** — <why important: 1 sentence>
2. **`<path>`** — <why>
3. **`<path>`** — <why>
4. **`<path>`** — <why>
5. **`<path>`** — <why>

If the user passed context in `$ARGUMENTS` (e.g., "focus on backend"), prioritize files matching that focus.

## Mental model for the system

In 3-5 sentences, describe the system's flow at the highest level. Example:

> "This is a Next.js SaaS for X. Users sign up via Supabase Auth (PKCE flow), and a Postgres trigger provisions their profile. The main feature is Y, which lives in `<files>`. Payments flow through Lemon Squeezy webhooks (idempotent via dedup table). Analytics fire to PostHog. Telegram alerts notify the operator on key events."

This is meant to be the kind of explanation you'd give a new hire on day one.

## What to ask the team / read in the wiki

Things the code didn't tell us, that you'd want to know on day one:

- <gap 1, e.g., "What's the deployment process? I see Vercel hooks but no deploy.yml">
- <gap 2, e.g., "Are there staging/test environments? Couldn't find env config for them">
- <gap 3>
- ...

## What's NOT documented (honest gaps from the scan)

- <list anything the three scans marked as TBD>
```

## Phase 6 — Hand off

Output:

> "Onboarding package ready in `.claude/`:
> - `conventions.md` (style)
> - `architecture-map.md` (structure)
> - `journeys-diagram.md` (flows)
> - `onboarding.md` (the summary + suggested reading order)

(Use the `*.local.md` names throughout when Phase 0 Case B applied.)
>
> Total ramp time: ~15 min to read all four. After that, you'll have a working mental model of the system.
>
> When you're ready to make changes, run `/work` — it'll auto-load the conventions file as context. Or `/quick-work` for small edits."

## Workspace mode (parent folder with multiple repos)

The folder is not a codebase — it's a workspace: each child directory with `.git` is its own project, with its own stack, conventions, and team. Onboarding it as ONE codebase would blend incompatible conventions into a muddled report, so don't. Produce two artifacts instead:

### 1. handles.md — what each repo answers to (this is what makes routing possible)

Do this before the INDEX, because the INDEX is derived from it.

The problem it solves, measured on a real workspace: grepping for a repo's **directory name** `tg-oss` finds 6 files. Grepping for the name it publishes under, `@teselagen/ui`, finds 1011. Same dependency, 168x apart. **You can grep for what a repo calls; you cannot grep for what it is called** — so the name is the one thing worth writing to disk.

Write `<repo>/.claude/handles.local.md` in **every** repo, team-owned or not. These are your personal routing notes, never a team deliverable, so they are always the `.local` variant. Add the exclude line in each repo — do not assume it is already there, it usually is not:

```bash
grep -qF '.claude/**/*.local.md' .git/info/exclude 2>/dev/null || \
  printf '# personal claude-workspace artifacts\n.claude/**/*.local.md\n' >> .git/info/exclude
```

Format — two header keys, one block, one date, no nesting:

```
repo: tg-copilot
aka: langgraph | qdrant | copilot

serves:
- @teselagen/tg-tool-client :: client/typescript/
- COPILOTKIT_URL            :: src/copilotkit_runtime_api/

scanned: <date>
```

**The two lines do different jobs, and confusing them is the main way this goes wrong.**

`aka:` is **vocabulary**. Bare product and service names — `langgraph`, `qdrant`, `piston`, `lims` — that let a reader map a task phrase ("the langgraph service is timing out") onto a repo. They feed the INDEX's "Names" section. They are **not** used to derive edges.

Moving bare names here removes them from the edge graph but not from the reader's path: "Names" is the first thing Routing consults, so a bad `aka:` misroutes instead of inventing an edge, and no script will catch it. Three rules, applied by hand:

- **No common English words.** `roadmap`, `dashboard`, `gateway` will match a task phrase that has nothing to do with the repo.
- **Flag collisions explicitly.** If a name also means something else (`gae` is both an image here and Google App Engine; `aiworker` is both a directory here and an uncloned repo), write the qualifier next to it in "Names". An ambiguous alias that looks certain is worse than none.
- **Drop an alias for a subcomponent.** A name that refers to one folder inside the repo, not to the repo, sends whole tasks to the wrong place.

`serves:` is **addresses**. Qualified strings another repo would literally contain if it talked to this one: package names, env vars naming this service, deployable names. Read it as *these are the strings another repo would contain if it talked to me, and here is what implements each one.* Only these feed the join.

Why the split, measured: a run that put bare names in `serves:` produced fourteen new edge rows and **not one new true dependency**. Six were backed by code, six were real pairs whose only evidence was prose, one recorded where code had been copied from, and one was an outright false pair pointing the wrong way — a comment in a gateway repo describing its *consumer* became an edge *to* that consumer. One bare name alone supplied 73% and 81% of the hits on two pairs it did not discover. Word boundaries fix substring noise; they cannot tell a call from a sentence, and prose is where product names live.

**Where handles come from**, in descending order of reliability:

1. **Published package names.** `git ls-files '*package.json' 'pyproject.toml'` — take the `name` field. Skip anything private, and skip vendored upstream code and example/demo packages: a repo that vendors a framework will otherwise claim that framework's name. Check `private` loosely — it appears as both `true` and `"true"` in the wild.
2. **Deployable names in your own manifests.** `git ls-files 'docker-compose*' 'k8s/**/*.yaml' 'Dockerfile*'`. Only count a name if **this repo builds it** — a deploy repo's manifests name everyone's services, and claiming them makes that repo appear to serve half the platform.
3. **Artifact names.** Not every dependency is a call. A repo can depend on another through what it *produces*: its GitHub slug (`Org/repo`), a storage bucket its CI writes, a published report path. These leave clean, greppable traces and belong in `serves:` on the repo that produces the artifact. Skipping this category cost a real edge in a live run — a test-analytics repo that reads another repo's CI reports had no detectable relationship at all, because nothing it referenced was a service address.

4. **The env var peers use to reach you.** This one is backwards by default and needs care: the `*_URL` variables inside a repo are overwhelmingly the ones it **consumes**, not the ones it answers to. `lims` contains `WALLET_API_URL` because it *calls* the wallet, not because it *is* the wallet. Only claim such a variable as a handle if you can see this repo **serving** that address — it appears in this repo's own deploy manifest as its published host, or its value points at this repo's service. When in doubt leave it out; a wrongly claimed variable invents an inbound edge that does not exist.

For the `:: path` on an env-var handle, point at the directory that answers the requests (`server/`, `gateway/`), not at a file that merely mentions the name. If you cannot tell, write `::` with the repo root and say so in the INDEX.

**Which strings belong in `serves:`:**

- At least 3 characters, and **qualified** — it carries a scope, a separator, or a casing that marks it as an address rather than a word: `@scope/name`, `SOME_SERVICE_URL`, `my-service-internal-lb`. A bare lowercase product name belongs in `aka:`.
- **Never** a generic name that half the ecosystem uses. Blocklist, enforced by the join: `API_URL`, `BASE_URL`, `HOST_URL`, `DATABASE_URL`, `DB_HOST`, `REDIS_URL`, `PORT`, `GATEWAY_URL`, `BACKEND_URL`, `FRONTEND_URL`, `SERVICE_URL`, `WEBHOOK_URL`, `API_BASE_URL`, `CLIENT_URL`, `PUBLIC_URL`. Measured: five of these alone carried 693 hits across one workspace and would have connected nearly every pair of repos.
- **Hostnames deserve their own entry.** Word boundaries treat `-` as part of the word, so a handle `tg-gateway` no longer matches `tg-gateway-dev.example.net` — and that hostname is often how peers actually reach the service. If a repo publishes one, list it: twelve real references went uncounted in one run because nobody did.

Two source rules that look right and are not:

- *"Only count a name if this repo builds it"* wrongly excludes a Deployment this repo owns that runs an upstream image (`qdrant`, `redis`, `postgres`). But "who owns the manifest" alone is equally wrong, and the two together leave names nobody may claim: a deploy repo writes the manifest for a service whose code lives elsewhere, so the first rule excludes it from the deploy repo and the second excludes it from the code repo. **The owner is the repo whose code answers the request.** A deploy repo naming someone else's service is a *caller*, which is exactly what the join should detect; it does not get to serve that name.
- *"Skip anything private"* wrongly excludes a private root package whose name is the product itself. Skip private **sub**packages and vendored code; keep the name the repo is known by — in `aka:`, since it will be a bare word.

If a repo has no distinctive address, leave `serves:` empty and say so. An empty block is honest; an invented handle is not.

### 2. INDEX.md — the roll-up, with derived routing

Light scan per child repo for the table. Everything below "Repos" is **generated output**:

```markdown
# <folder name> — workspace index

*Repo table by `/onboard`. Everything below "Routing" is DERIVED — regenerated <date> —
except "Edges ruled out", which is authored. Do not hand-edit the derived sections:
fix the repo's .claude/handles.local.md and re-run the join at the bottom.*

## Routing — read this before opening any repo

1. Look up every proper noun in the task under "Names". That maps task vocabulary
   onto a repo AND a path inside it.
2. Read the "Edges" rows for the repos you hit. One hop. Stop.
3. Open only those repos, starting at the paths "Names" gave you.
4. A name absent from "Names" is not necessarily absent from the workspace —
   check "Unmatched" before concluding anything.
5. If the date above is old, re-run the join at the bottom of this file.

## Repos
| Repo | What it is | Stack | Last activity | Onboarding |
|---|---|---|---|---|

## Names
<every repo's `aka:` vocabulary AND its `serves:` addresses, grouped by repo,
 with paths. This is the section a reader searches; both lines feed it.>

## Edges — derived <date>, counts are matches
| From | To | Matched handle | Hits |
|---|---|---|---|

## Edges ruled out — AUTHORED, not derived
<a row you verified as false, with the reason, so the next regeneration does not
 re-present it as new. The only hand-written thing below "Routing"; label it as
 such. If the join stops producing a row listed here, delete the row.>

## Inbound — inverted from Edges. Never authored.

## Unmatched — references no handle claims
<by category, see below>

## Known blind spots — not detectable by this method

## Join — the command that regenerates the three sections above
<paste the exact script, so the file carries its own instructions>
```

**The join.** Run from the workspace root, in `bash`. It picks its own regex engine, enforces the blocklist, and reports what it threw away:

```bash
BLOCK='^(API_URL|BASE_URL|HOST_URL|DATABASE_URL|DB_HOST|REDIS_URL|PORT|GATEWAY_URL|BACKEND_URL|FRONTEND_URL|SERVICE_URL|WEBHOOK_URL|API_BASE_URL|CLIENT_URL|PUBLIC_URL)$'
REPOS=$(for d in */; do [ -d "$d/.git" ] && echo "${d%/}"; done)
[ -z "$REPOS" ] && { echo "no git repos here" >&2; exit 1; }

ALL=$(for r in $REPOS; do
        awk -F' :: ' '/^serves:/{s=1;next} /^scanned:/{s=0} s&&/^- /{sub(/^- /,"");gsub(/ +$/,"",$1);print $1}' \
          "$r"/.claude/handles*.md 2>/dev/null
      done | sort -u)

SHORT=$(printf '%s\n' "$ALL" | grep -vE '^.{3,}$')
BLOCKED=$(printf '%s\n' "$ALL" | grep -E "$BLOCK")
BARE=$(printf '%s\n' "$ALL" | grep -E '^.{3,}$' | grep -vE "$BLOCK" | grep -vE '[@/_.-]|[A-Z]')
KEEP=$(printf '%s\n' "$ALL" | grep -E '^.{3,}$' | grep -vE "$BLOCK" | grep -E '[@/_.-]|[A-Z]')

report() { echo "== $1 =="; if [ -n "$2" ]; then printf '%s\n' "$2"; else echo "(none)"; fi; echo; }
report "dropped: shorter than 3" "$SHORT"
report "dropped: blocklisted generic" "$BLOCKED"
report "dropped: unqualified, belongs in aka:" "$BARE"

# Longest first: PCRE alternation is leftmost-FIRST, so a handle that prefixes
# another would otherwise swallow every match of the longer one.
# Escape every ERE/PCRE metacharacter, not just a few: one unescaped '+' aborts
# the whole scan with a regex error rather than missing quietly.
HANDLES=$(printf '%s\n' "$KEEP" | awk '{print length"\t"$0}' | sort -rn -k1,1 | cut -f2- \
          | sed 's/[][\\.^$*+?(){}|\/]/\\&/g' | paste -sd'|' -)

FIRST=$(printf '%s\n' "$REPOS" | head -1)
git -C "$FIRST" grep -qP '(?<!\x01)x' -- . >/dev/null 2>&1
[ $? -eq 128 ] && ENGINE=ere || ENGINE=pcre
echo "== engine: $ENGINE =="

scan() {
  if [ "$ENGINE" = pcre ]; then
    git -C "$1" grep -hoIP "(?<![A-Za-z0-9_-])(?:$HANDLES)(?![A-Za-z0-9_-])" \
        -- '*.ts' '*.tsx' '*.js' '*.jsx' '*.py' '*.go' '*.yaml' '*.yml' 'Dockerfile*' 2>/dev/null
  else
    git -C "$1" grep -hoIE "(^|[^A-Za-z0-9_-])($HANDLES)([^A-Za-z0-9_-]|\$)" \
        -- '*.ts' '*.tsx' '*.js' '*.jsx' '*.py' '*.go' '*.yaml' '*.yml' 'Dockerfile*' 2>/dev/null \
      | sed -E 's/^[^A-Za-z0-9_@]//; s/[^A-Za-z0-9_-]$//'
  fi
}

RAW=$(for r in $REPOS; do
  [ -d "$r/.git" ] || { echo "skipped worktree: $r" >&2; continue; }
  scan "$r" | sort | uniq -c | sed "s|^|$r |"
done)
printf '%s\n' "$RAW"
echo
SEEN=$(printf '%s\n' "$RAW" | awk '{print $3}' | sort -u)
report "zero hits anywhere (dead weight)" "$(comm -23 <(printf '%s\n' "$KEEP" | sort) <(printf '%s\n' "$SEEN"))"
```

Drop self-matches and anything under 2 hits. **On the ERE fallback, verify a count of 1 before dropping it:** `grep -o` does not overlap, so a handle whose neighbour was consumed by the previous match loses its boundary and goes uncounted. Measured at 26 missed matches in 6,148 — under half a percent, and it changed exactly one row, but that row sat on the drop threshold. The PCRE path has no such gap because a lookaround consumes nothing.

**Do not add `*.json` to that glob.** In one real repo 15,922 JSON data files carried a handle string against a few hundred source files, tripling the scan time while burying the signal.

**Timing, measured on six repos with 31,000 files in the largest:** about 2 seconds on the PCRE path, about 25 on the ERE fallback. If the fallback is what you get and it becomes annoying, that is the argument for installing a `git` built with PCRE, not for narrowing the glob.

**The reports print even when empty**, showing `(none)`. Otherwise a silent section is ambiguous: it could mean nothing was dropped, or that this copy of the script has no such check. In one real run 26 of 121 handles were dead weight and nothing said so until it was counted by hand.

**Check "Edges ruled out" before treating a row as new.** The join has no memory: a row you investigated and disproved comes back identical on every regeneration. Read that section first and leave the disproved rows out, or you will re-litigate the same false edge every time.

**Unmatched — six categories, not two.** Run the second pass to find what each repo reaches for:

```bash
git -C "$d" grep -hoE '[A-Z][A-Z0-9_]*_(URL|URI|HOST|ENDPOINT)' \
    -- '*.ts' '*.js' '*.py' '*.go' '*.yaml' '*.yml' 2>/dev/null | sort | uniq -c | sort -rn
```

Sort every result that matches no handle into:

- **A repo not cloned here.** The highest-value rows. Name the repo you think it is and quote the value that told you (a deploy manifest usually holds it).
- **A repo that IS here, but no handle covers.** The category most likely to be missed, and the one that shows the method's limit: `GATEWAY_URL` inside a client file is a real edge to the gateway repo, but no handle matches because the variable name does not carry the repo's name. Read the value or the surrounding call to place it.
- **An external vendor.** Stripe, an IdP, a public API. Not routable, but worth listing.
- **Own infrastructure.** Database, cache, queue, tunnel. Not a service dependency.
- **Not a dependency at all.** Test constants, regex fragments, and prefixes the pattern truncated (`ARTIFACT_URI` cut out of `ARTIFACT_URI_SCHEME`). Say so rather than inventing an edge.
- **Undetermined.** You looked and could not place it: no committed value, no catalog entry, read-only usage. Say that, with where you looked. A forced guess in one of the five categories above is worse than an honest sixth.

**A qualified handle is still not proof of a call.** Boundaries remove substring noise and the `aka:` split removes bare-word noise, but a qualified name quoted in a comment or a docstring counts exactly like one in a function call. When an edge's evidence looks thin, read the hits before believing it, and put the ones you disprove in "Edges ruled out".

**Known blind spots.** Record what this method structurally cannot see, so a gap is never read as an absence. The recurring ones: a call made on a relative path against a host held in a shared client object; dispatch through a registry or a slug; a shared URI scheme or route contract that no handle names; and every file type outside the join's glob.

### 3. Full onboarding — per repo, on demand

Don't run three deep scans times N repos unprompted. Ask:

> "Workspace indexed: <N> repos, <M> edges between them. Run the full onboarding (conventions + architecture + journeys) on one of them now? <list, most recently active first>. Each takes a few minutes — the others can be onboarded later by running `/onboard` inside them."

For each chosen repo: `cd` into it and run Phases 0–6 normally. Phase 0 matters here — client repos inside a workspace usually hit Case B (team-owned tooling), so their packages land as `*.local.md` automatically.

After per-repo runs complete, update the INDEX.md "Onboarding" column to link each generated package.

The workspace root usually isn't a git repo, so `INDEX.md` is invisible to every child repo's `git status` — nothing to exclude. If the root IS a repo, apply the Phase 0 Case B rules to it.

## Composition

`/onboard` is the orchestrator. The three commands it runs (`/conventions`, `/architecture`, `/journeys`) are still atomic and invokable independently — you don't NEED to use `/onboard` to get them. But for the day-one experience, this single command is the right entry point.

In workspace mode it also pairs with `/todo`: a workspace root is where a cross-repo `.claude/todos.md` lives (tasks tagged per repo), and the optional session-status hook surfaces the focused task from that same root at session start.

## What NOT to do

- Don't skip any of the three sub-commands if they fail. If `/conventions` couldn't parse the codebase, surface that error — don't pretend success.
- Don't fabricate the mental model section. If the code didn't tell you what the product does, leave it as `<unclear — ask the team>`.
- Don't suggest more than 5 files to read first. Six is too many for "day one".
- Don't add `Co-Authored-By: Claude` to any generated file.
