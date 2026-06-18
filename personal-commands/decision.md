---
description: Capture a technical decision with its alternative, the reasoning, and your confidence level. Appends to decisions-log.md so the rationale persists across sessions. Use during /work when you make a non-trivial choice, or retroactively when documenting decisions in an existing project.
---

# /decision — Capture and persist a technical decision

You are Claude. The user wants to capture a technical decision so it survives the conversation. Decisions made in chat evaporate when the session ends — by writing them to a file, they become part of the codebase's tribal knowledge.

**Argument (optional):** `$ARGUMENTS` may be a short one-line description of the decision (e.g., `"Why Lemon Squeezy over Stripe"`). If empty, ask.

## Phase 1 — Frame the decision

Walk the user through these 4 questions, **one at a time**. Wait for an answer before the next. Don't accept hand-wavy answers — push back kindly until each is sharp.

### Q1 — What's the decision?

> "In one line, what's the decision? Not the reasoning — just the choice."

Example good answers:
- "Use Lemon Squeezy as the primary payment provider"
- "Move from Pages Router to App Router in Next.js"
- "Add a dedup table for webhook idempotency instead of relying on HMAC alone"

Example bad answers (push back):
- "Improve our payment system" → too vague
- "Make better choices" → not a decision

### Q2 — What alternative did you consider and reject?

> "What's the most credible alternative you considered? Why did the other option exist as a candidate?"

Insist on at least one concrete alternative. If the user says "there was no alternative," push: *"There's always an alternative — even 'do nothing'. What was it?"*

### Q3 — Why did this one win?

> "Why this choice over the alternative? Give me the 2-3 most important reasons."

Push for specifics, not buzzwords:
- "Better DX" → "Better DX how? Compared to what?"
- "More scalable" → "What scale? What about the alternative wouldn't scale?"

### Q4 — Confidence level

> "How confident are you in this decision today?
> - 🟢 High — I'd defend this in an interview without hesitation
> - 🟡 Medium — it was the right call at the time, but I'd reconsider if circumstances changed
> - 🔴 Low — I'd revisit if I had time, or I'm not 100% sure why I made it"

**Be honest in your confidence.** A 🔴 documented honestly is worth more than a fabricated 🟢.

## Phase 2 — Optional: trade-off and known costs

After Q1-Q4 are answered, ask one more:

> "Any trade-off worth noting? Something this decision makes harder, or a cost you accepted?"

This is optional — if the user says "none I can think of right now," that's fine.

## Phase 3 — Find or create the decisions log

Check for an existing log:

```bash
test -f .claude/decisions-log.md && echo "found .claude/decisions-log.md"
test -f DECISIONS.md && echo "found DECISIONS.md"
test -f docs/DECISIONS.md && echo "found docs/DECISIONS.md"
```

If one exists, use it. If not, ask:

> "No decisions log found. Where should I create it?
> 1. `.claude/decisions-log.md` (default, committed to repo)
> 2. `DECISIONS.md` at root (committed, more visible)
> 3. `docs/DECISIONS.md` (if you have a docs folder)
> 4. `.claude/decisions-log.local.md` (gitignored, personal-only)
>
> Default: 1. Which?"

If user picks the gitignored option, also suggest adding `.claude/*.local.md` to `.gitignore` if not already there.

## Phase 4 — Append the decision

Generate the entry in this exact format and append to the file. If the file doesn't exist yet, create it with a header first.

**File header (only on first decision):**

```markdown
# Decisions log — <project name>

Captured by `/decision`. Each entry follows: decision → alternative → reason → confidence → trade-off.

---
```

**Entry format (every decision):**

```markdown
## <Decision number> — <One-line decision title>

*Captured: <today's date> | Confidence: <emoji + Alta/Media/Baja>*

**Decision:** <Q1 answer>

**Alternative considered:** <Q2 answer>

**Why this won:**
- <reason 1>
- <reason 2>
- <reason 3>

**Trade-off / known cost:**
<Q5 answer, or "None noted at capture time">

---
```

Number the entry sequentially. If this is the 6th decision in the log, number it `## 6 — ...`.

## Phase 5 — Confirm and offer follow-up

Output:

> "Decision #<N> captured in `<path>`.
>
> Total decisions in log: <count>.
>
> Want to capture another, or move on? You can also invoke `/decision` retroactively for past choices you're documenting from memory."

## Bonus — Using `/decision` during `/work`

When the user is in a `/work` session and they articulate a non-trivial choice in Phase 1 Q3 ("what changes / what doesn't") or Phase 1 Q5 ("failure modes"), suggest:

> "That choice ([the choice]) sounds worth capturing. Want me to invoke `/decision` to log it before we continue?"

Don't force — let the user say yes or no.

## What NOT to do

- Don't capture trivial decisions. "I named the variable `userId` not `id`" is not worth logging.
- Don't accept vague decisions. Push back until the user articulates clearly.
- Don't make up alternatives the user didn't actually consider. Honesty over completeness.
- Don't auto-mark confidence as 🟢. Most decisions in real codebases are 🟡 with brutal honesty.
- Don't overwrite previous entries. Always append.
- Don't add `Co-Authored-By: Claude`.
