## Usage
`/project:bugfix <ERROR_DESCRIPTION> [OPTIONS]`

### Options
- `--skip-scan`: Skip repository scan (not recommended)
- `--skip-tests`: Skip Codex test execution

## Context
- Error description: $ARGUMENTS
- All code, review, and tests are executed by **Codex Skill**
- Agents collect context, build prompts, and gate quality; they do not edit code

## Workflow
1) **Scan** (unless `--skip-scan`): Save facts to `.claude/specs/{issue}/00-repo-scan.md`.  
2) **Confirm scope**: Collect logs/repro info; ensure constraints are clear.  
3) **Codex Fix**: Prompt Codex with repo context + issue; Codex implements fix, writes `codex-backend.md` (Structured Summary) and `api-docs.md` if endpoints change.  
4) **Codex Verification**: Run Codex review to produce `codex-review.md` and resolve findings (≤3 iterations).  
5) **Testing**: If not `--skip-tests`, have Codex run/create tests; record results in `codex-backend.md` (and `dev-notes.md` only if clarifications are required).  
6) **Close**: Ensure Structured Summary status not `failed`, change packet present, and blocker questions resolved.

## Gates
- All coding/review/testing by Codex.  
- Max 3 Codex iterations in review loops; escalate afterward.  
- Artifacts (codex-backend, codex-review, api-docs when needed) must exist; rerun Codex if missing/stale.
