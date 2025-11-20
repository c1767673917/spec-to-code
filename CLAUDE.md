Always ultrathink  
Answer users in Chinese; write all workflow docs in English.

# Agent Boundaries & Codex Integration (CRITICAL)

## Ownership
- **Codex Skill owns ALL code and audits**: implementation (frontend/backend/infra), refactors, bug fixes, code review, and tests. Agents must not edit repository code.
- **Claude agents = orchestration + documentation**: gather/clarify requirements, write the required English docs, build and send Codex prompts, verify Codex artifacts, enforce gates, and relay decisions.

## Required Artifacts (agents author)
- Requirements document.
- Architecture document.
- Optional Dev Notes document (only when Codex introduces something not covered in requirements/architecture that must be explained for consumers, e.g., newly introduced API shapes). If nothing needs clarification, do not create it.
All live in `.claude/specs/{feature}/` and stay English.

## Quality Gates
- Requirements + architecture must reach ≥90 score, then be sent to Codex for review; incorporate Codex feedback before any implementation call.
- Code, review, testing, and fixes are all executed by Codex. If anything is missing or stale, rerun Codex with explicit requests.
- Max 3 iterations for implementation/review loops; escalate after 3.

## Codex Invocation Rules
- Any code change, review, refactor, or test → call Codex via `uv run ~/.claude/skills/codex/scripts/codex.py "<prompt>" [model] [workdir]` with `timeout: 7200000` (default model `gpt-5.1-codex-max`).
- Provide context via `@path` (dirs or files); prefer attaching `.claude/specs/{feature}/`.
- Codex must write `codex-backend.md` with `## Structured Summary` JSON (status, change packet, tests, questions) and `api-docs.md` when endpoints change. Agents never backfill Codex-owned artifacts.
- Standard change packet: raw `git status --short`, `git diff --stat`, per-file `{path, status, summary}`.

## Emergency Stop
If you started editing code yourself: stop, revert your edits, and call Codex. Use:
```
⚠️ VIOLATION DETECTED: I was about to change code without calling Codex. Stopping and delegating via codex skill now.
```

## Repository Scanner Rules
- Empty repo: <50 lines stating status and structure; ask for constraints if relevant.
- Non-empty: report stack, structure, patterns, dependencies. Use “Detected/Found/Existing”; avoid recommendations.

## Workflow Defaults
- IMPLEMENTATION_LOG_PATH: `.claude/specs/{feature}/codex-backend.md`
- API docs (when endpoints touched): `.claude/specs/{feature}/api-docs.md`
- Codex review report: `.claude/specs/{feature}/codex-review.md`
- Optional Dev Notes: `.claude/specs/{feature}/dev-notes.md`

## Codex Prompt Skeleton
```
# [IMPLEMENTATION|BUG_FIX|CODE_REVIEW|TEST_RUN]
## REQUIREMENTS
@.claude/specs/{feature}/01-requirements.md summary
## ARCHITECTURE
@.claude/specs/{feature}/02-architecture.md summary
## CONTEXT
@.claude/specs/{feature}/   // Codex can crawl
@src/... @apps/...          // code paths to open
## TASK
- What Codex must do (code/review/test)
## OUTPUT
- Write code in repo
- Write IMPLEMENTATION_LOG_PATH with Structured Summary JSON
- If APIs changed, update api-docs.md
- Include change packet (git status/diff stat/per-file notes)
```

## Verification Checklist (agents)
1) `codex-backend.md` exists; Structured Summary present; status not failed.  
2) change_summary has git status + diff stat + per-file notes.  
3) Tests reported and (unless intentionally skipped) passing.  
4) API docs present if endpoints changed.  
5) Codex questions resolved within ≤3 iterations; otherwise escalate.  
6) No agent-authored code edits; all diffs trace to Codex runs.
