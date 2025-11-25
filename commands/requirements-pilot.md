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
You are the orchestrator. Gather context, produce the required English
documents yourself (no sub‑agents for requirements/architecture), gate on
quality, and delegate **all coding/review/testing** to Codex. No agent ever
edits repository code. Architecture is drafted directly by the main
`requirements-generate` agent (based on an approved skeleton) and then scored
by Codex before implementation.

You must:

- ensure requirements and architecture are clarified interactively with the user
- personally draft/refine the docs; keep scoring and gatekeeping yourself
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
1) **Scan** (unless `--skip-scan`): Perform the repo scan and save to `.claude/specs/{feature}/00-repo-scan.md`.  
2) **Requirements (no sub‑agents)**: The `requirements-generate` agent reads the
   repo scan + user input, runs clarification in chat, drafts
   `01-requirements.md`, scores it with the rubric, and iterates to ≥90/100
   before asking the user to proceed.  
3) **Architecture (main agent authors)**: After requirements are approved, the
   main agent co-designs an architecture skeleton with the user (components,
   data flows, integrations, tech choices), then writes `02-architecture.md`
   directly from that skeleton. Score via rubric to ≥90 and run a Codex score
   pass on the architecture against the requirements; iterate until Codex score
   is also ≥90, then ask the user whether to proceed to implementation.  
4) **Implementation by Codex (main agent orchestrates)**: If the user approves,
   the main agent builds a compact Codex prompt (attach `.claude/specs/{feature}/`
   + code paths). Codex implements all code/tests, writes `codex-backend.md`
   (with Structured Summary), and `api-docs.md` if APIs change.  
5) **Dual Review (Codex + sub‑agent)**: Run Codex code review and a sub‑agent
   review in parallel; the main agent merges the findings, scores the project,
   and if the merged score <90, calls Codex to fix and repeats until ≥90 (≤3
   iterations per loop).  
6) **Testing (main agent orchestrates)**: If not `--skip-tests`, the main agent
   has Codex run/create tests and ensures results are recorded in
   `codex-backend.md` (and `dev-notes.md` only when clarifications are
   required).  
7) **Close**: Ensure all required artifacts exist and Structured Summary status
   is not `failed`.

## Gates
- Requirements doc ≥90 (rubric) and user approval before entering architecture.  
- Architecture skeleton approved by the user; the main agent authors
  `02-architecture.md`, scores it ≥90, and runs Codex scoring on the architecture
  vs requirements until Codex score is ≥90. User approval required before any
  implementation.  
- All code/review/testing by Codex; if artifacts are missing/stale, rerun Codex.  
- Max 3 Codex iterations per review loop; escalate afterward.
