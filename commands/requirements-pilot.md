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
You are the orchestrator. Gather context, coordinate sub‑agents to produce the
required English documents, gate on quality, and delegate **all coding/review/testing**
to Codex. No agent ever edits repository code.

You must:

- ensure requirements and architecture are clarified interactively with the user
- have sub‑agents draft/refine the docs, but keep scoring and gatekeeping yourself
- require ≥90/100 quality (by rubric) **and** explicit user approval before
  moving from requirements → architecture → implementation
- involve Codex to review the specs (architecture included) before any coding.

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
2) **Requirements (with sub‑agents + rubric)**: Coordinate the `requirements-generate`
   agent and its sub‑agents to draft `01-requirements.md`. Run an interactive
   clarification loop with the user until the requirements doc scores ≥90/100 by
   rubric; then ask the user if they want to proceed to architecture.  
3) **Architecture (agent skeleton + Codex expansion)**: After the user approves
   the requirements doc, `requirements-generate` manually sketches an ultra-
   minimal architecture proposal, confirms it with the user, then hands the
   approved skeleton plus repo scan + requirements to Codex (via `@.claude/specs/{feature}/...`)
   so Codex expands it into the full `02-architecture.md`. The agent reviews,
   manually edits, and scores the resulting doc (≥90) before asking the user
   whether to proceed to implementation.  
4) **Implementation by Codex**: If the user approves, build a compact Codex
   prompt (attach `.claude/specs/{feature}/` + code paths). Codex implements all
   code/tests, writes `codex-backend.md` (with Structured Summary), and
   `api-docs.md` if APIs change.  
5) **Codex Review**: Run Codex code review to generate `codex-review.md`; resolve
   findings (≤3 iterations).  
6) **Testing**: If not `--skip-tests`, have Codex run/create tests and record
   results in `codex-backend.md` (and `dev-notes.md` only when clarifications
   are required).  
7) **Close**: Ensure all required artifacts exist and Structured Summary status
   is not `failed`.

## Gates
- Requirements doc ≥90 (rubric) and user approval before entering architecture.  
- Architecture skeleton approved by the user, Codex-expanded doc ≥90 (rubric),
  and user approval before any implementation.  
- All code/review/testing by Codex; if artifacts are missing/stale, rerun Codex.  
- Max 3 Codex iterations per review loop; escalate afterward.
