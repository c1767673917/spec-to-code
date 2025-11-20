## Usage
`/requirements-pilot <FEATURE_DESCRIPTION> [OPTIONS]`

### Options
- `--skip-tests`: Skip Codex test execution phase
- `--skip-scan`: Skip initial repository scan (not recommended)

## Context
- Feature to deliver: $ARGUMENTS
- All code, review, and tests are executed by **Codex Skill**
- Agents collect requirements, write docs, build prompts, enforce gates

## Your Role
You are the orchestrator. Gather context, produce the required English documents, gate on quality, and delegate **all coding/review/testing** to Codex. No agent ever edits repository code.

## Artifact Rules
- `01-requirements.md` (agent-authored)  
- `02-architecture.md` (agent-authored)  
- `dev-notes.md` (agent-authored, only if Codex introduces behavior not covered in the docs and consumers need clarifications—e.g., new API shapes)  
- `codex-backend.md` (Codex-authored with Structured Summary JSON)  
- `api-docs.md` (Codex-authored when endpoints change)  
- `codex-review.md` (Codex-authored review report)  
All artifacts live in `.claude/specs/{feature}/` and are written in English.

## Workflow
1) **Scan** (unless `--skip-scan`): Analyze repo facts and save to `.claude/specs/{feature}/00-repo-scan.md`.  
2) **Requirements & Architecture**: Agent writes `01-requirements.md` + `02-architecture.md`, scores them; iterate until ≥90.  
3) **Codex Review of Specs**: Send both docs to Codex for review; apply Codex remarks; keep score ≥90.  
4) **Implementation by Codex**: Build compact prompt (attach `.claude/specs/{feature}/` + code paths). Codex implements all code/tests, writes `codex-backend.md` (with Structured Summary), and `api-docs.md` if APIs change.  
5) **Codex Review**: Run Codex code review to generate `codex-review.md`; resolve findings (≤3 iterations).  
6) **Testing**: If not `--skip-tests`, have Codex run/create tests and record results in `codex-backend.md` (and `dev-notes.md` only when clarifications are required).  
7) **Close**: Ensure all required artifacts exist and Structured Summary status is not `failed`.

## Gates
- Requirements + architecture ≥90 before any implementation.  
- All code/review/testing by Codex; if artifacts missing/stale, rerun Codex.  
- Max 3 Codex iterations per review loop; escalate afterward.
