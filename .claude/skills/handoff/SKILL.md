---
name: handoff
description: Use when a session of work on Universal Beatdown ends or pauses, when the context runs low, before /clear or /compact, or when the user says "handoff", "save the state", "wrap up", "we'll continue later" or "where are we". Writes vault/Handoff.md (current state, work in progress, plan, problems to fix, decisions, waiting on the user, how to resume) and brings vault/SUMMARY.md, vault/Todo.md and the topic notes up to date, so a new session with no memory can continue the work. Not for release notes or commit messages.
---

# Handoff

A new session remembers nothing. `CLAUDE.md` imports `vault/SUMMARY.md` and `vault/Handoff.md`, so these two files ARE the memory of the project. Write them so that a session that reads only them can take the next step without asking.

## 1. Collect the facts

Run these (read-only) and read the output:

```
git status -sb
git log --oneline -15
git diff --stat
git log -1 --format=%H
gh pr list --state open
gh run list -L 3
```

Then read the current `vault/Handoff.md`, `vault/SUMMARY.md` and `vault/Todo.md`.

From the conversation, list:

- What was asked in this session and what was finished.
- What was started and is not finished: which files, how far, the exact next step.
- Problems found: bugs, failing checks, script errors, things that were tested and failed. Give `file:line` where known.
- Decisions made and the reason for each (also options the user rejected, so they are not proposed again).
- What waits on the user: tests only a human can do, answers, assets (lore, art, recordings).

Use only facts from the conversation, the git output and the files. Do not invent a status. If something was not tested, write "not tested".

## 2. Write `vault/Handoff.md`

Overwrite the whole file each time; it holds only the latest state (git keeps the history). Keep it under about 120 lines. Remove items that are finished or no longer true. Use this shape:

```markdown
---
class: state
validity: current
type: handoff
updated: YYYY-MM-DD
branch: <branch>
last_commit: <short sha> <subject>
---

# Handoff

Back to [Summary](SUMMARY.md).

## Current state
2-5 sentences: what the game can do now, what this session changed, is the work committed / pushed / released.

## Work in progress
- **<item>**: what is done, what is not, the files (`path`), the exact next step.
(Write "None." when nothing is half-done.)

## Plan
1. The next steps in order. The first one is what the next session does first.

## Problems to fix
- **<problem>**: symptom, where (`file:line`), what was tried, the suspected cause.

## Decisions
- <decision>: <reason>. (Rejected: <option>, because <reason>.)

## Waiting on the user
- <what the user must do or give>.

## To-dos
New and changed items are in the [To-do list](Todo.md). Items for the next session only: ...

## How to resume
- First action: <one concrete action>.
- Useful commands: <run / test / build commands for this work>.
- Check first: `git status`; if HEAD is not `last_commit`, read `git log <last_commit>..HEAD` before anything else.
```

## 3. Update the other notes

Follow the rules in `CLAUDE.md` ("Keeping the notes current"):

- `vault/SUMMARY.md`: change the state table and "Next step" only when the main state changed (version, release, what is playable, audio, testing). Set `updated:` to today. Keep details out of it.
- `vault/Todo.md`: remove or check off finished items; add new open items in the right section.
- The topic note of each changed area (`Content.md`, `StoryMode.md`, `Audio.md`, `Performance.md`, `BuildAndRelease.md`, `ThreeD.md`, `ProjectLayout.md`, `Roadmap.md`).
- `vault/Recap.md`: only when the user asks for a recap.

Write the notes in short, plain sentences (Simplified Technical English): active voice, one fact per sentence, the same word for the same thing.

## 4. Save and report

- Commit only the vault files: `git add vault/` then `git commit -m "Vault: handoff YYYY-MM-DD"`. Do not commit other half-done work without asking.
- Push only when the user asks, or when the repo's own push flow (`tools/auto_push.ps1`, the `/push` command) does it.
- Tell the user in 3-5 lines: what the handoff holds, the first step of the next session, and that a new session reads it automatically.
