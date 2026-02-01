# ProofChecker Development System

Task management and agent orchestration for Lean 4 theorem proving. For comprehensive documentation, see @.claude/README.md.

## Quick Reference

- **Task List**: @specs/TODO.md
- **Machine State**: @specs/state.json
- **Error Tracking**: @specs/errors.json
- **Architecture**: @.claude/README.md

## Project Structure

```
Theories/                 # Lean 4 source code
├── Bimodal/             # Modal logic theories
├── PropositionalLogic/  # Classical propositional logic
└── Shared/              # Common definitions
docs/                    # Project documentation
specs/                   # Task management artifacts
.claude/                 # Claude Code configuration
```

## Task Management

### Status Markers
- `[NOT STARTED]` - Initial state
- `[RESEARCHING]` -> `[RESEARCHED]` - Research phase
- `[PLANNING]` -> `[PLANNED]` - Planning phase
- `[IMPLEMENTING]` -> `[COMPLETED]` - Implementation phase
- `[BLOCKED]`, `[ABANDONED]`, `[PARTIAL]`, `[EXPANDED]` - Terminal/exception states

### Artifact Paths
```
specs/{N}_{SLUG}/
├── reports/research-{NNN}.md
├── plans/implementation-{NNN}.md
└── summaries/implementation-summary-{DATE}.md
```
`{N}` = unpadded task number, `{NNN}` = 3-digit padded version, `{DATE}` = YYYYMMDD.

### Language-Based Routing

| Language | Research Tools | Implementation Tools |
|----------|----------------|---------------------|
| `lean` | lean_leansearch, lean_loogle, lean_leanfinder | lean_goal, lean_hover_info, lean_multi_attempt |
| `latex` | WebSearch, WebFetch, Read | Read, Write, Edit, Bash (pdflatex) |
| `typst` | WebSearch, WebFetch, Read | Read, Write, Edit, Bash (typst compile) |
| `general` | WebSearch, WebFetch, Read | Read, Write, Edit, Bash |
| `meta` | Read, Grep, Glob | Write, Edit |

## Command Reference

All commands use checkpoint-based execution: GATE IN (preflight) -> DELEGATE (skill/agent) -> GATE OUT (postflight) -> COMMIT.

| Command | Usage | Description |
|---------|-------|-------------|
| `/task` | `/task "Description"` | Create task |
| `/task` | `/task --recover N`, `--expand N`, `--sync`, `--abandon N` | Manage tasks |
| `/research` | `/research N [focus]` | Research task, route by language |
| `/plan` | `/plan N` | Create implementation plan |
| `/implement` | `/implement N` | Execute plan, resume from incomplete phase |
| `/revise` | `/revise N` | Create new plan version |
| `/review` | `/review` | Analyze codebase |
| `/todo` | `/todo` | Archive completed/abandoned tasks, sync repository metrics |
| `/errors` | `/errors` | Analyze error patterns, create fix plans |
| `/meta` | `/meta` | System builder for .claude/ changes |
| `/learn` | `/learn [PATH...]` | Scan for FIX:/NOTE:/TODO: tags |
| `/lake` | `/lake [--clean] [--max-retries N]` | Build with automatic error repair |
| `/refresh` | `/refresh [--dry-run] [--force]` | Clean orphaned processes and old files |

### Utility Scripts

- `.claude/scripts/export-to-markdown.sh` - Export .claude/ directory to consolidated markdown file

## State Synchronization

TODO.md and state.json must stay synchronized. Update state.json first (machine state), then TODO.md (user-facing).

### state.json Structure
```json
{
  "next_project_number": 346,
  "active_projects": [{
    "project_number": 334,
    "project_name": "task_slug",
    "status": "planned",
    "language": "lean",
    "completion_summary": "Required when status=completed",
    "roadmap_items": ["Optional explicit roadmap items"]
  }],
  "repository_health": {
    "last_assessed": "ISO8601 timestamp",
    "sorry_count": 295,
    "axiom_count": 10,
    "build_errors": 0,
    "status": "manageable"
  }
}
```

### Completion Workflow
- Non-meta tasks: `completion_summary` + optional `roadmap_items` -> /todo annotates ROAD_MAP.md
- Meta tasks: `completion_summary` + `claudemd_suggestions` -> /todo displays for user review

## Git Commit Conventions

Format: `task {N}: {action}` with session ID in body.
```
task 334: complete research

Session: sess_1736700000_abc123

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

Standard actions: `create`, `complete research`, `create implementation plan`, `phase {P}: {name}`, `complete implementation`.

## Lean 4 Integration

### CRITICAL: Blocked MCP Tools - NEVER CALL THESE

**DO NOT call these tools under any circumstances.** They have known bugs that cause incorrect behavior.

| Tool | Bug | Alternative |
|------|-----|-------------|
| `lean_diagnostic_messages` | lean-lsp-mcp #118 | `lean_goal` or `lake build` |
| `lean_file_outline` | lean-lsp-mcp #115 | `Read` + `lean_hover_info` |

**Full documentation**: @.claude/context/core/patterns/blocked-mcp-tools.md

### MCP Tools (via lean-lsp server)
`lean_goal`, `lean_hover_info`, `lean_completions`, `lean_leansearch`, `lean_loogle`, `lean_leanfinder`, `lean_multi_attempt`, `lean_local_search`, `lean_state_search`, `lean_hammer_premise`

### Search Decision Tree
1. "Does X exist locally?" -> lean_local_search
2. "I need a lemma that says X" -> lean_leansearch
3. "Find lemma with type pattern" -> lean_loogle
4. "What's the Lean name for concept X?" -> lean_leanfinder
5. "What closes this goal?" -> lean_state_search

### MCP Configuration
Configure lean-lsp in user scope (`~/.claude.json`) for subagent access. Run `.claude/scripts/setup-lean-mcp.sh`.

## Skill-to-Agent Mapping

| Skill | Agent | Purpose |
|-------|-------|---------|
| skill-lean-research | lean-research-agent | Lean 4/Mathlib research |
| skill-lean-implementation | lean-implementation-agent | Lean proof implementation |
| skill-researcher | general-research-agent | General web/codebase research |
| skill-planner | planner-agent | Implementation plan creation |
| skill-implementer | general-implementation-agent | General file implementation |
| skill-latex-implementation | latex-implementation-agent | LaTeX document implementation |
| skill-typst-implementation | typst-implementation-agent | Typst document implementation |
| skill-meta | meta-builder-agent | System building and task creation |
| skill-document-converter | document-converter-agent | Document format conversion |
| skill-status-sync | (direct execution) | Atomic status updates |
| skill-refresh | (direct execution) | Process and file cleanup |
| skill-lake-repair | (direct execution) | Build with error repair |

## Rules References

Core rules (auto-applied by file path):
- @.claude/rules/state-management.md - Task state patterns (specs/**)
- @.claude/rules/git-workflow.md - Commit conventions
- @.claude/rules/lean4.md - Lean development (**/*.lean)
- @.claude/rules/error-handling.md - Error recovery (.claude/**)
- @.claude/rules/artifact-formats.md - Report/plan formats (specs/**)
- @.claude/rules/workflows.md - Command lifecycle (.claude/**)

## Context Imports

Domain knowledge (load as needed):
- @.claude/context/project/lean4/tools/mcp-tools-guide.md
- @.claude/context/project/lean4/patterns/tactic-patterns.md
- @.claude/context/project/logic/domain/kripke-semantics-overview.md
- @.claude/context/project/repo/project-overview.md

## Error Handling

- **On failure**: Keep task in current status, log to errors.json, preserve partial progress
- **On timeout**: Mark phase [PARTIAL], next /implement resumes
- **On MCP error**: Retry once, try alternative tool, continue with available info
- **Git failures**: Non-blocking (logged, not fatal)

## jq Command Safety

Claude Code Issue #1132 causes jq parse errors when using `!=` operator (escaped as `\!=`).

**Safe pattern**: Use `select(.type == "X" | not)` instead of `select(.type != "X")`

```bash
# SAFE - use "| not" pattern
select(.type == "plan" | not)

# UNSAFE - gets escaped as \!=
select(.type != "plan")
```

Full documentation: @.claude/context/core/patterns/jq-escaping-workarounds.md

## Important Notes

- Update status BEFORE starting work (preflight) and AFTER completing (postflight)
- state.json = machine truth, TODO.md = user visibility
- All skills use lazy context loading via @-references
- Session ID format: `sess_{timestamp}_{random}` - generated at GATE IN, included in commits
