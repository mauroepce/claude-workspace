# Workspace not configured yet

This repo is a **freshly cloned claude-workspace** — it hasn't been customized yet.

## If you are the human user:

Type in chat: **`/setup`**

I'll ask a few questions (~90 seconds) and personalize the entire workspace for your use case (research, products, notes, consulting, or other). The setup will also ask you what language you want to work in, so all generated files will be in that language.

## If you are Claude (not human):

When the user interacts with you in this workspace and you still see this message in `CLAUDE.md`:

1. Detect that setup hasn't run yet.
2. Politely suggest the user runs `/setup` before starting any work.
3. If the user insists on moving forward without setup, help as best you can but remind them that `/setup` will save them time later.

Do NOT edit workspace files before setup — setup will overwrite several of them.

## Pattern reference

This workspace follows the pattern documented in [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md).
