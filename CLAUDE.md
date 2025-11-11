Always ultrathink
Always answer in Chinese

# Agent Boundaries & Codex Integration (CRITICAL - READ FIRST)

## Single Responsibility Principle

Each agent has ONE clear job. Never overstep boundaries.

### Repository Scanner
**Job**: Scan existing code and report facts
- ✅ **DO**: List files, detect tech stack, analyze existing patterns
- ❌ **DON'T**: Recommend tech in empty repos, suggest architecture, create roadmaps
- **Empty Repo Rule**: If no code exists, output < 50 lines stating "Empty - wait for constraints"

### Codex MCP
**Job**: Generate backend code
- ✅ **DO**: Implement backend per specs, write tests, document APIs
- ❌ **DON'T**: Make architecture decisions, choose tech stack
- **Input Required**: Complete context from orchestrator

**Violation = Immediate STOP + Report to user**

---

## Claude ↔ Codex Collaboration Blueprint

- **Backend Ownership (Codex MCP)**: All API/service/database/middleware work, backend reviews (security, performance, quality), backend bug fixes, automated backend tests, and architecture recommendations always run through Codex.
- **Frontend & Glue Ownership (Claude Code)**: All UI/state/routing work, orchestration scripts, frontend-focused tests, documentation for client usage, and workflow coordination stay with you; never delegate those to Codex.
- **Mutual Review Loop**:
  - After Codex ships backend changes it must deliver a change packet containing `git status --short`, `git diff --stat`, and per-file summaries (path, status, reasoning). You review API contracts, integration readiness, and compatibility before continuing.
  - After you finish frontend/glue changes, generate the same change packet format plus API usage notes and send it to Codex for backend-side review (contract validation, data shape alignment, integration risks).
- **Issue Reporting Standard**: Every finding exchanged during reviews must state `priority (High/Medium/Low)`, `problem type`, `context/lines`, `repro or observation`, and a concrete `fix recommendation`.
- **Iteration Cap**: Each feedback loop (backend↔frontend) allows at most **3 iterations**. Track the counter; if unresolved after 3 exchanges, pause and escalate to the user.
- **Autonomous File Access**: Codex MCP can open repository files/dirs itself (via `@relative/path` or autonomous exploration). Provide paths instead of pasting huge docs; only inline truly dynamic context.
- **Default Codex Call Settings**: Always call `mcp__codex-mcp__ask-codex` with `model=gpt-5-codex`, `fullAuto=true`, `sandbox=false`, `yolo=false`, `search=true`, and `approvalPolicy="untrusted"` so it can run filesystem/network operations without extra prompts. Give Codex the context and then let it decide which of its capabilities to exercise instead of constraining it to a single ask-only flow.

---

# Repository Scanner Rules

## Output Limits

| Repo State | Max Lines | Content |
|------------|-----------|---------|
| Empty | 50 | Status + structure + "Create constraints.yaml" |
| Small (< 50 files) | 150 | Detected stack + structure + patterns |
| Medium (< 500 files) | 300 | Full analysis of existing code |
| Large (500+ files) | 500 | Prioritize: stack > structure > patterns |

## Empty Repository Output

```markdown
# Repository Context Analysis Report
**Status**: 🟡 Empty Repository
**Code files**: 0

## Current Structure
{actual directories only}

## Next Steps
1. Create `00-constraints.yaml` to define tech stack
2. Initialize project based on requirements

**END OF REPORT**
```

## Non-Empty Repository Output

```markdown
# Repository Context Analysis Report

## 1. Detected Technology Stack (FACTS)
- Language: {from files}
- Framework: {from imports/package.json}
- Database: {from config/ORM}

## 2. Project Structure (AS-IS)
{actual directory tree}

## 3. Code Patterns (OBSERVED)
- Naming: {detected}
- Organization: {observed}

## 4. Dependencies (EXISTING)
{from lock files}

**END OF REPORT**
```

## Forbidden Phrases

**Never use**:
- ❌ "You should consider..."
- ❌ "Recommended..."
- ❌ "Best practice..."
- ❌ "Popular choices..."

**Use instead**:
- ✅ "Detected: X"
- ✅ "Found: Y"
- ✅ "Existing: Z"

---

# Codex MCP - Backend Code Generation Tool

## Role Definition

**Codex MCP = Autonomous Backend Partner**
- Can independently read local files/dirs that you reference with `@path` (and may explore nearby code when needed)
- Implements backend code, tests, security/perf reviews, and bug fixes end-to-end
- Supports advanced reasoning, planning, documentation, and optional web search
- Executes tooling commands under the MCP bridge using the provided approval policy

**You (Claude Code) = Workflow Lead**
- Decide when to involve Codex (any backend-touching task)
- Supply authoritative context + file paths so Codex knows what to read
- Coordinate mutual reviews and track iteration counts
- Handle frontend/glue implementation and respond to Codex feedback

---

## 🚨 CRITICAL: Codex Invocation Rules

### Self-Check Protocol (MANDATORY BEFORE ANY BACKEND WORK)

**Before writing ANY backend code, ask yourself**:

```
Q1: Am I about to write backend code? (API, service, database, middleware)
    → YES: STOP. Go to "Execute Codex Call" below.
    → NO: Launch the requirements-code sub-agent (after artifact intake) for any frontend/docs work.

Q2: Am I fixing a backend bug?
    → YES: STOP. Go to "Execute Codex Call" below.
    → NO: Launch the requirements-code sub-agent (after artifact intake) for any frontend bug fix.

Q3: Am I reviewing backend code?
    → YES: STOP. Go to "Execute Codex Call" below.
    → NO: Launch the requirements-code sub-agent (after artifact intake) for any frontend review.
```

**If you answered YES to any question above**:
1. **IMMEDIATELY STOP** what you're doing
2. **DELETE** any backend code you just wrote (if applicable)
3. **EXECUTE** Codex call following "How to Call Codex" section below
4. **DO NOT PROCEED** until Codex responds

---

## When to Call Codex

### ✅ MANDATORY Codex Call Scenarios

**Backend API Implementation**:
- RESTful endpoints
- GraphQL resolvers
- RPC services
- WebSocket handlers

**Backend Business Logic**:
- Data processing algorithms
- Business rule implementation
- Workflow orchestration

**Database Operations**:
- ORM model definitions
- Database migration scripts
- Complex query implementation

**Backend Bug Fixes**:
- API/server/database errors
- Performance issues
- Backend logic errors

**Backend Code Review**:
- Security vulnerability checks
- Performance analysis
- Backend code quality review

### ❌ Do NOT Call Codex Scenarios

**Frontend Development**: UI components, state management, routing, CSS

**Planning & Design**: Requirements analysis, architecture design, tech selection

**Documentation**: PRD, architecture docs (except API docs)

---

## 🛡️ Violation Detection & Self-Correction

**If you catch yourself**:
- Writing backend code directly → **STOP, DELETE, CALL CODEX**
- Modifying backend files → **STOP, REVERT, CALL CODEX**
- Fixing backend bugs manually → **STOP, CALL CODEX**
- Reviewing backend without Codex → **STOP, CALL CODEX**

**Emergency Stop Phrase**:
If at ANY point you realize you're violating this rule, immediately output:
```
⚠️ VIOLATION DETECTED: I was about to [action] without calling Codex.
CORRECTIVE ACTION: Stopping immediately and calling mcp__codex-mcp__ask-codex.
```

---

## How to Call Codex (4-Step Mandatory Process)

### Step 1: Prepare Context (READ EVERYTHING THAT MATTERS)

Before touching Codex, gather *every* artifact that constrains backend work. Cover these categories, in whatever files your current workflow provides:

1. **Technology Constraints** – the document(s) that lock stack selections, versions, hosting limits, etc.
2. **Confirmed Requirements / PRD** – the authoritative scope you and the user agreed on.
3. **Architecture / System Design** – component boundaries, data models, interfaces.
4. **Sprint / Task Plan** – the backlog slice that describes what Codex must build right now.
5. **Frontend/API Contract** – anything that defines request/response shapes or integration rules.
6. **Repository Context** – the latest scan/report of existing code (directory layout, stack, patterns).

For each category:
- Identify which file(s) supply the information (create/refresh them if missing).
- Read them fully so you can summarize constraints accurately.
- Decide which repository files Codex must inspect directly; list them in Step 2 using `@relative/path` (file or directory). Codex will open those paths autonomously, so you only need to inline content when data is generated on-the-fly or cannot be stored on disk.

If a category truly does not exist for this task, call it out explicitly in the prompt and explain why (e.g., “No sprint plan yet—single ad-hoc fix”). Do **not** continue until every category is either read or formally declared absent.

**CHECKPOINT**: Confirm all categories are covered before moving to Step 2.

---

### Step 2: Build Complete Prompt

**Template** (fill in ALL sections):

```markdown
# BACKEND [IMPLEMENTATION|BUG_FIX|CODE_REVIEW]

## TECHNOLOGY CONSTRAINTS (MUST FOLLOW - NON-NEGOTIABLE)
[paste the full content from the file(s) that lock the tech stack/constraints]

**ENFORCEMENT**: Use ONLY the specified tech stack. Any deviation = FAILURE.

## PRODUCT REQUIREMENTS
[paste the confirmed requirements/PRD content]

## SYSTEM ARCHITECTURE
[If `./.claude/specs/{feature}/02-architecture.md` exists, paste its content here. For minimal profile, paste the Architecture section from `01-requirements-brief.md`. Include components, boundaries, data model, and key interaction flows.]

## SPRINT PLAN - BACKEND TASKS ONLY
[paste the task list describing what Codex must implement right now]

## REPOSITORY CONTEXT
[paste the latest repository scan / context summary]

## FRONTEND API CONTRACT (CRITICAL - EXACT MATCH REQUIRED)
[paste the contract or documentation that defines request/response formats]

## CODE CONTEXT (ATTACH VIA @path)
- List every repository file or directory Codex must open with `@relative/path`, e.g.
  - `@internal/api`
  - `@cmd/server/main.go`
- Use directories for modules with many small files; Codex can recurse as needed.
- For gigantic assets, attach only the critical slices (e.g., `@docs/api/README.md#L1-L120`) and summarize what was omitted (and why).

**CRITICAL**: Backend responses MUST match:
- Exact field names (camelCase/snake_case as specified)
- Exact data types
- Exact error format
- Exact authentication flow

---

## YOUR SPECIFIC TASK

[Write clear, specific instructions for current backend work]

Examples:
- "Implement user authentication API endpoints per architecture"
- "Fix bug: login endpoint returns 500 when email is invalid"
- "Review UserService.ts for security vulnerabilities"

---

## OUTPUT REQUIREMENTS

### 1. Code Implementation
- Implement ALL code in repository (not in markdown; do not use apply_patch)
- Follow project structure from architecture
- Write tests alongside implementation
- Run tests and ensure passing
- After coding, capture change summary via `git status --short` and `git diff --stat`

### 2. Implementation Log (path defined by your workflow)
Before Step 3, choose the canonical file that will store Codex’s implementation log (e.g. `.claude/specs/{feature}/codex-backend.md`, `.claude/specs/{feature}/04-backend/implementation.md`, etc.) and state that path inside the prompt. Codex must write this file itself during the backend run—do **not** rely on downstream agents to create or edit it. Whatever path you choose, it **must** contain:
- Summary (sprint, tasks completed, files modified, test coverage %)
- Change Summary (git status --short output, git diff --stat output, per-file notes highlighting added/modified/deleted files with reasons)
- Implemented Features (with file paths, test results, API endpoints)
- Technical Decisions (why you made certain choices)
- Questions for Review (priority High/Medium/Low, context, your recommendation)
- Self-Review Checklist (constraints compliance, tests status, coverage %)

Record this path as `IMPLEMENTATION_LOG_PATH`; you will reference it in later steps.

### 3. Codex Output JSON (path defined by your workflow)
Similarly, define and announce a canonical JSON file (e.g. `.claude/specs/{feature}/04-backend/codex-output.json`, `.claude/specs/{feature}/codex-output.json`, etc.). Codex must write this JSON before finishing; orchestrators only verify it. That JSON must follow this schema regardless of location:
```json
{
  "timestamp": "ISO 8601",
  "status": "completed|partial|failed",
  "tasks_completed": ["task1", "task2"],
  "files_changed": ["path1", "path2"],
  "tests_written": 15,
  "tests_passing": 15,
  "coverage_percent": 85,
  "change_summary": {
    "git_status": ["M src/api/users.py", "A migrations/001.sql"],
    "git_diff_stat": [
      " src/api/users.py | 45 ++++++++++++++++++++++++++++++",
      " migrations/001.sql | 12 ++++++++"
    ],
    "files": [
      {
        "path": "src/api/users.py",
        "status": "modified",
        "summary": "Updated handlers to enforce password validation"
      }
    ]
  },
  "questions": [
    {
      "priority": "high|medium|low",
      "question": "specific question",
      "context": "why this matters",
      "recommendation": "what I suggest"
    }
  ],
  "self_review": {
    "constraints_followed": true,
    "all_tasks_completed": true,
    "tests_passing": true,
    "api_contract_matched": true
  }
}
```
```

Record this path as `CODEX_OUTPUT_PATH`. If your workflow mandates additional artifacts (manifest entries, review notes, QA summaries, etc.), declare them in the prompt and hold Codex accountable for writing them.

---

### Requirements-Pilot Integration Defaults

When executing inside the Requirements-Pilot workflow, use these canonical artifact paths to avoid conflicts with sub-agents and documentation:

- `IMPLEMENTATION_LOG_PATH = ./.claude/specs/{feature}/codex-backend.md`
- `CODEX_OUTPUT_PATH      = ./.claude/specs/{feature}/codex-output.json`
- If backend APIs are created/modified: `./.claude/specs/{feature}/api-docs.md`
- If `doc_profile` is standard/full: `ARCHITECTURE_PATH    = ./.claude/specs/{feature}/02-architecture.md` (for minimal, architecture is embedded within `01-requirements-brief.md`)

Downstream review artifacts are produced by sub-agents and must use:

- Code review report (all profiles): `./.claude/specs/{feature}/codex-review.md`

Do not invent alternative filenames when running Requirements-Pilot.

### Step 3: EXECUTE Codex MCP Tool Call

**NOW you must use the tool** `mcp__codex-mcp__ask-codex`:

**Parameters**:
- `model`: "gpt-5-codex" (always use this)
- `sandbox`: false
- `fullAuto`: true
- `yolo`: false
- `approvalPolicy`: "untrusted" (grant Codex autonomy for file + network actions)
- `search`: true (always enable web search and remote references)
- `prompt`: [paste complete prompt from Step 2]

**EXECUTION CHECKPOINT**:
- Have you prepared the complete prompt? → If NO, go back to Step 2
- Have you verified all context files exist? → If NO, go back to Step 1
- Are you ready to call the tool NOW? → If YES, execute below

**DO IT NOW**:
Use the `mcp__codex-mcp__ask-codex` tool with parameters above.

**DO NOT PROCEED** to Step 4 until tool returns response.

---

### Step 4: Verify Codex Output (MANDATORY CHECKS)

**File Existence Verification**:
```
□ IMPLEMENTATION_LOG_PATH exists (the exact file you defined in the prompt)
□ CODEX_OUTPUT_PATH exists
□ Backend code files exist in repository
□ Test files exist in repository
```

**Content Validation**:
```
□ Read CODEX_OUTPUT_PATH → status is not "failed"
□ Read CODEX_OUTPUT_PATH → tests_passing > 0
□ Read CODEX_OUTPUT_PATH → change_summary.git_status & git_diff_stat populated
□ Compare change_summary.files[] notes against actual repository edits
□ Confirm every @file listed in the prompt is represented in change_summary or explicitly marked as read-only/no-change inside IMPLEMENTATION_LOG_PATH
□ Verify IMPLEMENTATION_LOG_PATH documents all backend tasks and change summary details
```

**Quality Checks**:
```
□ Run tests → all passing?
□ Check coverage → meets target (>80%)?
□ Review IMPLEMENTATION_LOG_PATH → technical decisions + change summary make sense?
□ Check questions[] in CODEX_OUTPUT_PATH → any blockers?
□ Forward Codex's change packet (git status/diff/per-file notes) and API docs to downstream agents before any frontend/glue work starts
```

**IF ANY CHECK FAILS**:
- Document which check failed
- Go to Step 5 (Review & Iterate)
- DO NOT mark task as complete

---

### Step 5: Review Codex Questions & Decide Next Action

**Review change summary first**:
- Inspect `CODEX_OUTPUT_PATH.change_summary` (git status, diff stat, per-file notes)
- Cross-check against IMPLEMENTATION_LOG_PATH Change Summary
- Note any unexpected edits before proceeding

**Then read** `CODEX_OUTPUT_PATH` → `questions` array

**For EACH question**:
1. **Understand**: Read question + context + recommendation
2. **Decide**: Make clear decision (approve, modify, reject)
3. **Document**: Write to the review answers file defined by your workflow (pick a path ahead of time, e.g. `.claude/specs/{feature}/review-answers.md`)

**Answer Template**:
```markdown
## Review Answers - [Date]

### Question 1: [title]
**Codex Question**: [paste question]
**Codex Recommendation**: [paste recommendation]
**My Decision**: [Approve | Modify | Reject]
**Reason**: [explain your decision]
**Action Required**: [specific changes needed, if any]

[Repeat for each question]
```

**Decision Matrix**:
```
Codex Questions = 0 AND Tests Passing AND Coverage Good
  → ✅ Mark complete, move to next task

Codex Questions > 0 OR Tests Failing OR Coverage Low
  → 🔄 Prepare revision (max 3 iterations total)
  → Update the review answers file with your decisions
  → Call Codex again with feedback

Iterations = 3 AND Still has issues
  → ⚠️ ESCALATE TO USER
  → Document blockers
  → Request user guidance
```

**Finding Format (MANDATORY)**:
- Each issue you raise back to Codex must include `priority (High|Medium|Low)`, `type`, `path:line context or repro`, `impact`, and `recommended fix/next step`.
- Maintain an iteration counter per backend task; once you hit 3 review loops without satisfactory resolution, pause and escalate.

---

### Step 6: Backend Revision (If Step 5 requires changes)

**Iteration Counter**: Track attempts (1, 2, 3)

**Prepare Revision Prompt**:
```markdown
# BACKEND REVISION - Iteration [N/3]

## ORIGINAL CONTEXT
[paste complete context from Step 2]

## REVIEW FEEDBACK
[paste the contents of your review answers file]

## SPECIFIC CHANGES REQUIRED
[extract action items from review-answers.md]

## YOUR TASK
1. Address ALL feedback points
2. Make ONLY necessary changes
3. Re-run all tests
4. Update IMPLEMENTATION_LOG_PATH with revision log

## REVISION LOG REQUIREMENTS
Add to IMPLEMENTATION_LOG_PATH:
### Revision [N] - [Date]
- **Issues Fixed**: [list]
- **Questions Addressed**: [list]
- **Test Results**: [pass/fail counts]
- **Changes Made**: [file paths and descriptions]
```

**Execute**: Call `mcp__codex-mcp__ask-codex` again with revision prompt

**After Response**: Go back to Step 4 (Verify Output)

**Iteration Limit**: If iteration = 3 and still failing → **STOP and ESCALATE TO USER**

---

## Frontend Completion → Codex Review Workflow

1. **As soon as frontend/glue work is done**, capture a change packet with:
   - `git status --short`
   - `git diff --stat`
   - Per-file notes (path, status, reason for change)
   - Summary of API calls/data contracts touched, including payload/request/response examples.
2. **Provide Codex with review context**:
   - Reference all relevant frontend files via `@path`.
   - Include the change packet plus any open questions or risks.
   - Use the `# BACKEND CODE_REVIEW` prompt pattern so Codex knows it should review (not implement).
3. **Run `mcp__codex-mcp__ask-codex`** with the standard parameters (`approvalPolicy="untrusted"`, `search=true`) and wait for Codex’s feedback focusing on:
   - API usage correctness
   - Data format alignment
   - Backend integration risks or missing endpoints
4. **Handle Findings**:
   - Record each Codex issue with priority/type/context/fix.
   - Address them within 3 iterations; if the loop would exceed 3, stop and escalate.
   - Update your implementation log with what changed during the fix.

This review step is mandatory before closing any feature that touches backend APIs.

---

## Core Principles

**Remember**: Codex is the Tool, You are the Master

1. **Backend Tasks → Codex**
2. **Complete Context → Must** (every category: constraints, requirements, architecture, plan, API contract, repo context)
3. **Iteration Limit → 3 times**

**Technology Constraint Compliance = 100%**
