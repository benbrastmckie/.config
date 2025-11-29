# /todo Command and Project Tracking Standards - Implementation Plan

## Metadata
- **Date**: 2025-11-29
- **Feature**: /todo command for automated project tracking and TODO.md organization
- **Scope**: Create new /todo command with Haiku-based analysis, TODO.md standards, and --clean flag for completed project cleanup
- **Estimated Phases**: 8
- **Estimated Hours**: 14
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 68.5
- **Research Reports**:
  - [/todo Command and Project Tracking Standards Research](/home/benjamin/.config/.claude/specs/959_todo_command_project_tracking_standards/reports/001-todo-command-research.md)

## Overview

Implement a /todo command that automatically scans .claude/specs/ directories to track project progress and update .claude/TODO.md with current status. The command will use a Haiku-based agent for fast plan analysis, support a --clean flag to generate cleanup plans for completed projects, and establish comprehensive standards for TODO.md organization with hierarchical artifact tracking.

**Key Capabilities**:
- Automatic project discovery via specs directory scanning
- Fast plan status classification using Haiku model
- Hierarchical TODO.md organization (In Progress → Not Started → Backlog → Completed/Abandoned/Superseded)
- Automatic inclusion of research reports and summaries as indented bullets under each plan
- --clean flag to generate cleanup plans for completed projects
- Dual-mode operation: default update mode and --clean mode

## Research Summary

Research reveals a comprehensive foundation for the /todo command implementation:

**Directory Structure and Organization**:
- Topic-based organization: specs/{NNN_topic}/ with plans/, reports/, summaries/, debug/ subdirectories
- 183 current spec directories with well-defined completion markers ([COMPLETE] status)
- Existing TODO.md format with 6 sections: In Progress, Not Started, Backlog, Superseded, Abandoned, Completed

**Command Patterns and Libraries**:
- /errors command demonstrates dual-mode operation (default report mode + --query mode)
- unified-location-detection.sh provides specs traversal via get_specs_root()
- Three-tier library sourcing pattern: error-handling.sh, state-persistence.sh, workflow-state-machine.sh
- Error logging integration via ensure_error_log_exists(), setup_bash_error_trap()

**Haiku Model Usage**:
- 7 existing commands use Haiku agents for fast classification (errors-analyst, test-executor, topic-naming-agent)
- Performance characteristics: fast response, low cost, deterministic outputs, suitable for structured data extraction
- Model selection pattern: haiku-4.5 with fallback-model: haiku-4.5

**Plan Completion Detection**:
- Primary marker: Metadata Status field `**Status**: [COMPLETE]`
- Secondary markers: All phase headers have [COMPLETE] marker
- Status variations: [NOT STARTED], [IN PROGRESS], [COMPLETE], DEFERRED

**TODO.md Current Format**:
- Inconsistencies: "Not Started" section contains [x] checkboxes (should be [ ])
- No standard format for indented sub-items (summaries/reports)
- Manual date grouping in Completed section

## Success Criteria

- [ ] /todo command creates or updates .claude/TODO.md with current project status
- [ ] All projects in specs/ directory are discovered and categorized
- [ ] TODO.md follows standardized 6-section format with proper ordering
- [ ] Research reports and summaries appear as indented bullets under each plan
- [ ] --clean flag generates cleanup plan for completed projects
- [ ] Haiku-based todo-analyzer agent achieves <2s average response time
- [ ] Command includes proper error logging and three-tier library sourcing
- [ ] Documentation created for /todo command and TODO.md standards
- [ ] All tests pass with 100% coverage of core functionality
- [ ] Pre-commit hooks validate TODO.md structure

## Technical Design

### Architecture Components

**1. Command Layer** (/todo command)
- Dual-mode operation: default update mode and --clean mode
- Argument parsing: --clean, --dry-run flags
- Three-tier library sourcing (error-handling.sh, state-persistence.sh, unified-location-detection.sh)
- Error logging integration
- Workflow coordination

**2. Agent Layer** (todo-analyzer agent)
- Model: haiku-4.5 for fast batch analysis
- Responsibilities: Read plan files, extract metadata, determine status, return structured JSON
- Batch processing: 10-20 plans in parallel for performance
- Tools: Read only (minimal context)

**3. Library Functions**
- scan_project_directories(): Glob specs/*/ to discover all projects
- check_plan_status(): Extract status from plan metadata and phase markers
- categorize_plan(): Determine TODO.md section based on status
- find_related_artifacts(): Glob reports/, summaries/ for each project
- update_todo_file(): Write organized TODO.md with proper hierarchy
- generate_cleanup_plan(): Create plan to archive completed projects (--clean mode)

**4. Standards Documentation**
- TODO.md Organization Standards: Section order, checkbox conventions, artifact inclusion rules
- /todo Command Guide: Usage examples, workflow details, integration patterns
- todo-analyzer Agent Specification: Behavioral guidelines, JSON output format

### Data Flow

```
User invokes /todo
    ↓
Parse arguments (--clean, --dry-run)
    ↓
Scan specs/ for all topic directories (Glob)
    ↓
For each topic:
  - Find plans/*.md files
  - Invoke todo-analyzer agent (Haiku) → status JSON
  - Find related reports/ and summaries/
  - Categorize by status
    ↓
Aggregate results by TODO.md section
    ↓
Generate updated TODO.md
    ↓
If --clean mode:
  - Filter completed projects
  - Generate cleanup plan
    ↓
Write TODO.md (or display dry-run preview)
    ↓
Echo completion signal for buffer-opener
```

### TODO.md Organization Standards

**Section Order** (strict hierarchy):
1. In Progress
2. Not Started
3. Backlog (manually curated - command preserves existing content)
4. Superseded
5. Abandoned
6. Completed (date-grouped, newest first)

**Checkbox Conventions**:
- `[ ]` - Not started (used in "Not Started" section)
- `[x]` - Started, in progress, or complete (used in "In Progress", "Completed", "Abandoned" sections)
- `[~]` - Superseded (used in "Superseded" section)

**Entry Format**:
```markdown
- [checkbox] **{Plan Title}** - {Brief description} [{path/to/plan.md}]
  - {Phase status or key achievements}
  - Related reports: [{report-title}](path/to/report.md)
  - Related summaries: [{summary-title}](path/to/summary.md)
```

**Artifact Inclusion Rules**:
- Include ALL reports and summaries as indented bullet points under parent plan
- Use relative paths from TODO.md location
- Reports and summaries discovered via Glob: `specs/{topic}/reports/*.md`, `specs/{topic}/summaries/*.md`
- Order: reports first, then summaries

**Date Grouping** (Completed section only):
- Group by date range (e.g., "November 27-29, 2025")
- Newest entries at top
- Preserve existing manual grouping in Backlog section

### Plan Status Classification Logic

**Algorithm** (implemented in todo-analyzer agent):
```
1. Read plan metadata block
2. Extract "Status" field value
3. If Status contains "[COMPLETE]" OR "COMPLETE" OR "100%" → status = "completed"
4. If Status contains "[IN PROGRESS]" → status = "in_progress"
5. If Status contains "[NOT STARTED]" → status = "not_started"
6. If Status contains "DEFERRED" OR "SUPERSEDED" → status = "superseded"
7. If Status field missing:
   - Count phase headers with [COMPLETE] markers
   - If all phases complete → status = "completed"
   - If some phases complete → status = "in_progress"
   - If no phases complete → status = "not_started"
8. Return JSON: {"status": "...", "title": "...", "phases_complete": N, "phases_total": M}
```

**Status to Section Mapping**:
- "in_progress" → In Progress
- "not_started" → Not Started
- "completed" → Completed
- "superseded" → Superseded
- "deferred" → Backlog
- "abandoned" → Abandoned (requires manual annotation or ABANDONED keyword in plan)

### --clean Flag Implementation

**Purpose**: Generate cleanup plan for completed projects

**Workflow**:
1. Scan all projects with status = "completed"
2. Verify all phases complete (no partial completions)
3. Filter projects not recently modified (<30 days old)
4. Generate cleanup plan with phases:
   - Phase 1: Create archive manifest
   - Phase 2: Move completed projects to .claude/archive/completed_{timestamp}/
   - Phase 3: Update TODO.md (move entries to Completed section)
   - Phase 4: Verify cleanup success
5. Save cleanup plan to specs/960_todo_cleanup_{timestamp}/plans/001-cleanup-plan.md

**Safety Checks**:
- Dry-run mode by default (requires confirmation)
- Create backup of TODO.md before modifications
- Archive (don't delete) completed projects
- Log all cleanup operations via error logging

### Integration with Existing Systems

**Library Dependencies**:
- unified-location-detection.sh:get_specs_root() - Get specs root path
- unified-location-detection.sh:ensure_artifact_directory() - Lazy directory creation
- error-handling.sh:ensure_error_log_exists() - Initialize error logging
- error-handling.sh:setup_bash_error_trap() - Install error trap
- error-handling.sh:log_command_error() - Log failures
- error-handling.sh:parse_subagent_error() - Parse agent errors

**Error Logging**:
- Command name: "/todo"
- Workflow ID: "todo_$(date +%s)"
- Error types: parse_error, agent_error, file_error, validation_error

**Standards Compliance**:
- Three-tier library sourcing pattern
- Error trap setup before any operations
- Output suppression with 2>/dev/null
- Consolidated bash blocks (Setup → Execute → Update)
- Idempotent operations (safe to run multiple times)

## Implementation Phases

### Phase 1: TODO.md Organization Standards Documentation [COMPLETE]
dependencies: []

**Objective**: Document comprehensive standards for TODO.md file organization, section hierarchy, checkbox conventions, and artifact inclusion rules.

**Complexity**: Low

Tasks:
- [x] Create .claude/docs/reference/standards/todo-organization-standards.md (file path: /home/benjamin/.config/.claude/docs/reference/standards/todo-organization-standards.md)
  - Document 6-section hierarchy (In Progress → Not Started → Backlog → Superseded → Abandoned → Completed)
  - Define checkbox conventions ([ ], [x], [~])
  - Specify entry format with plan title, description, path, artifacts
  - Define artifact inclusion rules (reports and summaries as indented bullets)
  - Document date grouping rules for Completed section
  - Include examples of well-formed TODO.md sections
- [x] Add reference to new standards in CLAUDE.md under "Standards Discovery" section
- [x] Add validation criteria for TODO.md structure (prep for Phase 8)

Testing:
```bash
# Verify documentation standards file exists
test -f /home/benjamin/.config/.claude/docs/reference/standards/todo-organization-standards.md

# Verify CLAUDE.md reference added
grep -q "todo-organization-standards.md" /home/benjamin/.config/CLAUDE.md
```

**Expected Duration**: 2 hours

---

### Phase 2: todo-analyzer Agent Implementation [COMPLETE]
dependencies: [1]

**Objective**: Create Haiku-based agent for fast plan status classification with structured JSON output.

**Complexity**: Medium

Tasks:
- [x] Create .claude/agents/todo-analyzer.md (file path: /home/benjamin/.config/.claude/agents/todo-analyzer.md)
  - Set frontmatter: model: haiku-4.5, fallback-model: haiku-4.5, allowed-tools: Read
  - Implement plan status classification algorithm (see Technical Design)
  - Extract plan title, status field, phase completion counts
  - Return structured JSON: {"status": "...", "title": "...", "description": "...", "phases_complete": N, "phases_total": M}
  - Handle edge cases: missing Status field, malformed plans, partial completions
  - Add model-justification: "Fast batch analysis of plan status across 100+ projects"
- [x] Add todo-analyzer to .claude/agents/README.md agent catalog
  - Document purpose, model choice, input/output format
  - Add usage example

Testing:
```bash
# Test agent with sample plan (in_progress status)
PLAN_PATH="/home/benjamin/.config/.claude/specs/958_readme_compliance_audit_updates/plans/001-readme-compliance-audit-updates-plan.md"
# Invoke agent and verify JSON output contains expected fields

# Test agent with completed plan
PLAN_PATH="/home/benjamin/.config/.claude/specs/952_fix_failing_tests_coverage/plans/001-fix-failing-tests-coverage-plan.md"
# Verify status = "completed"

# Test agent with missing Status field plan
# Verify fallback to phase marker counting
```

**Expected Duration**: 2.5 hours

---

### Phase 3: Library Functions for Project Scanning [COMPLETE]
dependencies: [1, 2]

**Objective**: Implement core library functions for project discovery, plan analysis, and artifact collection.

**Complexity**: Medium

Tasks:
- [x] Create .claude/lib/todo/todo-functions.sh (file path: /home/benjamin/.config/.claude/lib/todo/todo-functions.sh)
  - Implement scan_project_directories(): Glob specs/*/ to find all topics
  - Implement find_plans_in_topic(): Glob {topic}/plans/*.md
  - Implement find_related_artifacts(): Glob {topic}/reports/*.md and {topic}/summaries/*.md
  - Implement categorize_plan(): Map status to TODO.md section
  - Implement extract_plan_metadata(): Get title, description from plan frontmatter
  - Add error handling for missing directories, malformed paths
  - Include three-tier library sourcing (error-handling.sh dependency)
- [x] Add library to .claude/lib/README.md documentation
- [x] Create unit tests for library functions in .claude/tests/unit/test_todo_functions.sh

Testing:
```bash
# Test scan_project_directories
source .claude/lib/todo/todo-functions.sh
TOPICS=$(scan_project_directories)
# Verify returns array of topic directories (e.g., 959_todo_command_project_tracking_standards)

# Test find_plans_in_topic
PLANS=$(find_plans_in_topic "959_todo_command_project_tracking_standards")
# Verify returns array of plan file paths

# Test find_related_artifacts
ARTIFACTS=$(find_related_artifacts "959_todo_command_project_tracking_standards")
# Verify returns array with reports and summaries

# Test categorize_plan
SECTION=$(categorize_plan "completed")
# Verify returns "Completed"

# Run unit tests
bash .claude/tests/unit/test_todo_functions.sh
```

**Expected Duration**: 3 hours

---

### Phase 4: /todo Command Core Implementation [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Implement /todo command with default update mode, argument parsing, and error logging integration.

**Complexity**: High

Tasks:
- [x] Create .claude/commands/todo.md (file path: /home/benjamin/.config/.claude/commands/todo.md)
  - Add frontmatter: allowed-tools, argument-hint, description, command-type: utility, dependent-agents: todo-analyzer
  - Add library-requirements: error-handling.sh, unified-location-detection.sh, todo-functions.sh
  - Block 1 (Setup): Argument parsing (--clean, --dry-run), project detection, library sourcing, error trap setup
  - Block 2 (Discovery): Scan projects, invoke todo-analyzer in batches, collect results
  - Block 3 (Update): Generate TODO.md sections, preserve Backlog, write file, echo completion signal
  - Implement dual-mode detection (default update vs --clean mode)
  - Add error logging: log_command_error for parse failures, agent errors
  - Include progress markers for long-running operations (>5 seconds)
- [x] Add /todo to .claude/commands/README.md command catalog
- [x] Update CLAUDE.md with /todo command reference in "Project-Specific Commands" section

Testing:
```bash
# Test default mode (update TODO.md)
/todo
# Verify TODO.md updated with current project status
# Verify all sections present and ordered correctly

# Test dry-run mode
/todo --dry-run
# Verify preview output, no file modifications

# Test error logging integration
/todo --invalid-flag
# Verify error logged to .claude/data/logs/errors.jsonl
```

**Expected Duration**: 3.5 hours

---

### Phase 5: TODO.md Generation and Artifact Linking [COMPLETE]
dependencies: [1, 2, 3, 4]

**Objective**: Implement TODO.md file generation with proper section hierarchy, artifact linking, and Backlog preservation.

**Complexity**: Medium

Tasks:
- [x] Extend .claude/lib/todo/todo-functions.sh with update_todo_file()
  - Implement section generation: In Progress, Not Started, Backlog (preserve), Superseded, Abandoned, Completed
  - Apply checkbox conventions based on section
  - Format entries with plan title, description, path (relative from TODO.md)
  - Add indented bullets for reports and summaries
  - Preserve existing Backlog section content (manual curation)
  - Implement date grouping for Completed section (extract from plan metadata or current date)
  - Create backup of existing TODO.md before modifications
  - Handle missing TODO.md (create new file)
- [x] Add validation function: validate_todo_structure()
  - Check section order
  - Verify checkbox conventions
  - Validate artifact link paths

Testing:
```bash
# Test TODO.md generation with sample data
# Create test spec directories with various statuses
export CLAUDE_SPECS_ROOT="/tmp/test_specs_$$"
mkdir -p "$CLAUDE_SPECS_ROOT/001_test_project/plans"
# Create sample plan with [COMPLETE] status
# Run /todo and verify TODO.md structure

# Test Backlog preservation
# Add manual content to Backlog section
# Run /todo and verify Backlog unchanged

# Test artifact linking
# Create reports/ and summaries/ in test topic
# Run /todo and verify indented bullets present

# Test backup creation
test -f /home/benjamin/.config/.claude/TODO.md.backup
```

**Expected Duration**: 2.5 hours

---

### Phase 6: --clean Flag and Cleanup Plan Generation [COMPLETE]
dependencies: [1, 2, 3, 4, 5]

**Objective**: Implement --clean flag to generate cleanup plans for completed projects with safety checks.

**Complexity**: Medium

Tasks:
- [x] Extend .claude/commands/todo.md with --clean mode logic
  - Filter projects with status = "completed" and last modified >30 days
  - Verify all phases complete (no partial completions)
  - Generate cleanup plan using plan-architect agent
  - Cleanup plan phases: Create manifest, Archive projects, Update TODO.md, Verify
  - Save cleanup plan to specs/{NNN_todo_cleanup_{timestamp}}/plans/001-cleanup-plan.md
  - Include --dry-run support (preview cleanup operations)
- [x] Implement generate_cleanup_plan() in todo-functions.sh
  - Invoke plan-architect agent with cleanup requirements
  - Pass filtered completed projects list
  - Generate structured cleanup plan
- [x] Add safety checks: require confirmation, create backups, log operations

Testing:
```bash
# Test --clean flag with dry-run
/todo --clean --dry-run
# Verify cleanup plan preview, no actual operations

# Test cleanup plan generation
/todo --clean
# Verify cleanup plan created in specs directory
# Verify plan includes all completed projects >30 days old

# Test safety checks
# Verify backup of TODO.md created
# Verify confirmation prompt appears (if interactive)
```

**Expected Duration**: 2 hours

---

### Phase 7: Documentation and Command Guide [COMPLETE]
dependencies: [1, 2, 3, 4, 5, 6]

**Objective**: Create comprehensive documentation for /todo command usage, workflow details, and integration patterns.

**Complexity**: Low

Tasks:
- [x] Create .claude/docs/guides/commands/todo-command-guide.md (file path: /home/benjamin/.config/.claude/docs/guides/commands/todo-command-guide.md)
  - Purpose and overview
  - Usage examples (default mode, --clean mode, --dry-run)
  - Argument reference
  - Workflow details (discovery, analysis, generation)
  - Integration with existing systems (error logging, library dependencies)
  - Troubleshooting common issues
  - Performance characteristics (batch processing, Haiku model speed)
- [x] Update .claude/docs/guides/commands/README.md with /todo reference
- [x] Add link to todo-command-guide.md in CLAUDE.md "Quick Reference" section
- [x] Document todo-analyzer agent in .claude/docs/reference/agent-reference.md (if exists)

Testing:
```bash
# Verify documentation file exists
test -f /home/benjamin/.config/.claude/docs/guides/commands/todo-command-guide.md

# Verify references added
grep -q "todo-command-guide.md" /home/benjamin/.config/.claude/docs/guides/commands/README.md
grep -q "todo-command-guide.md" /home/benjamin/.config/CLAUDE.md

# Manual review: Check examples, clarity, completeness
```

**Expected Duration**: 1.5 hours

---

### Phase 8: Testing and Validation [COMPLETE]
dependencies: [1, 2, 3, 4, 5, 6, 7]

**Objective**: Comprehensive testing of /todo command, todo-analyzer agent, and TODO.md validation with pre-commit hooks.

**Complexity**: Medium

Tasks:
- [x] Create .claude/tests/features/commands/test_todo_command.sh (file path: /home/benjamin/.config/.claude/tests/features/commands/test_todo_command.sh)
  - Test default mode: TODO.md generation, section ordering, artifact linking
  - Test --clean mode: cleanup plan generation, safety checks
  - Test --dry-run mode: preview without modifications
  - Test error handling: missing specs/, malformed plans, agent failures
  - Test Backlog preservation
  - Test idempotent behavior (safe to run multiple times)
- [x] Create .claude/tests/agents/test_todo_analyzer.sh
  - Test status classification accuracy across various plan formats
  - Test phase completion counting
  - Test JSON output structure
  - Test edge cases: missing Status field, malformed plans
- [x] Create .claude/scripts/validate-todo-structure.sh for pre-commit hook
  - Validate section order (In Progress → ... → Completed)
  - Validate checkbox conventions ([x] in Completed, [ ] in Not Started)
  - Validate artifact link paths exist
  - Add to pre-commit hook configuration
- [x] Run full test suite and verify 100% pass rate
- [x] Performance test: Run /todo on 183 existing projects, verify <10s execution time

Testing:
```bash
# Run command tests
bash .claude/tests/features/commands/test_todo_command.sh
# Expected: All tests pass

# Run agent tests
bash .claude/tests/agents/test_todo_analyzer.sh
# Expected: All tests pass

# Run TODO.md validation
bash .claude/scripts/validate-todo-structure.sh /home/benjamin/.config/.claude/TODO.md
# Expected: No validation errors

# Performance test
time /todo
# Expected: <10s for 183 projects

# Integration test: End-to-end workflow
# 1. Create new spec with plan
# 2. Run /todo
# 3. Verify plan appears in TODO.md "Not Started" section
# 4. Mark plan as complete
# 5. Run /todo
# 6. Verify plan moved to "Completed" section
```

**Expected Duration**: 3 hours

---

## Testing Strategy

### Unit Tests
- Library functions (todo-functions.sh): Project scanning, artifact discovery, categorization
- Agent output parsing: JSON structure validation, status extraction
- Entry formatting: Checkbox conventions, relative paths, indentation

### Integration Tests
- End-to-end workflow: Create project → Run /todo → Verify TODO.md
- Error logging: Command failures logged correctly
- Agent coordination: todo-analyzer batch invocation
- Cleanup workflow: --clean flag generates valid cleanup plan

### Performance Tests
- Batch processing: 183 existing projects in <10s
- Agent response time: Haiku model <2s average per plan
- TODO.md writing: Large files (>1000 lines) written efficiently

### Validation Tests
- TODO.md structure: Section order, checkbox conventions, artifact links
- Standards compliance: Three-tier sourcing, error logging, output suppression
- Pre-commit hook: Validate TODO.md on commit

### Edge Cases
- Missing specs/ directory
- Malformed plans (no metadata, missing Status field)
- Empty topic directories (no plans)
- Conflicting status markers (metadata vs phase headers)
- Large TODO.md files (>2000 lines)
- Concurrent /todo invocations (lock contention)

## Documentation Requirements

### New Documentation Files
1. .claude/docs/reference/standards/todo-organization-standards.md - TODO.md structure standards
2. .claude/docs/guides/commands/todo-command-guide.md - /todo command usage guide
3. .claude/lib/todo/README.md - Library functions documentation
4. .claude/agents/todo-analyzer.md - Agent behavioral guidelines (implementation file)

### Updates to Existing Documentation
1. CLAUDE.md - Add "Project-Specific Commands" reference to /todo
2. .claude/commands/README.md - Add /todo to command catalog
3. .claude/agents/README.md - Add todo-analyzer to agent catalog
4. .claude/lib/README.md - Add todo-functions.sh to library index
5. .claude/docs/guides/commands/README.md - Add link to todo-command-guide.md

### Documentation Standards Compliance
- Clear, concise language (per CLAUDE.md)
- Code examples with syntax highlighting
- No emojis in file content (UTF-8 encoding issues)
- CommonMark specification compliance
- No historical commentary (clean-break development)

## Dependencies

### External Dependencies
- jq (for JSON parsing of agent output)
- Bash 4.0+ (for associative arrays)
- Git (for project root detection via detect_project_root())

### Internal Dependencies
- .claude/lib/core/error-handling.sh (v1.0.0+) - Error logging, trap setup
- .claude/lib/core/unified-location-detection.sh (v1.0.0+) - Specs directory detection
- .claude/lib/todo/todo-functions.sh (new) - Project scanning, categorization
- .claude/agents/todo-analyzer.md (new) - Plan status classification
- .claude/agents/plan-architect.md (existing) - Cleanup plan generation (--clean mode)

### Phase Dependencies
- Phase 1 (Standards): No dependencies
- Phase 2 (Agent): Depends on Phase 1 (standards for status classification)
- Phase 3 (Library): Depends on Phases 1, 2 (standards, agent interface)
- Phase 4 (Command): Depends on Phases 1, 2, 3 (foundation complete)
- Phase 5 (Generation): Depends on Phases 1-4 (command infrastructure ready)
- Phase 6 (Clean): Depends on Phases 1-5 (core functionality complete)
- Phase 7 (Docs): Depends on Phases 1-6 (all features implemented)
- Phase 8 (Testing): Depends on Phases 1-7 (everything ready for validation)

### Wave-Based Parallel Execution
- Wave 1: Phase 1 (no dependencies)
- Wave 2: Phase 2 (depends on Wave 1)
- Wave 3: Phase 3 (depends on Wave 2)
- Wave 4: Phase 4 (depends on Wave 3)
- Wave 5: Phase 5 (depends on Wave 4)
- Wave 6: Phase 6 (depends on Wave 5)
- Wave 7: Phase 7 (depends on Wave 6)
- Wave 8: Phase 8 (depends on Wave 7)

**Note**: Due to sequential dependencies, this plan has limited parallelization opportunities. Each phase builds on the previous phase's outputs.

## Risk Management

### Technical Risks
1. **Large TODO.md files**: Potential performance issues with >2000 lines
   - Mitigation: Implement incremental updates, validate write performance in Phase 8
2. **Haiku model accuracy**: Status classification may misinterpret edge cases
   - Mitigation: Comprehensive testing in Phase 8, fallback to phase marker counting
3. **Concurrent /todo invocations**: Race conditions in TODO.md writes
   - Mitigation: Use file locking (flock), test concurrent execution
4. **Malformed plans**: Plans without metadata or Status field may fail parsing
   - Mitigation: Graceful fallback to phase marker analysis, error logging

### Integration Risks
1. **Cleanup plan conflicts**: --clean mode may conflict with active work
   - Mitigation: 30-day age threshold, safety checks, dry-run default
2. **Backlog preservation**: Automated updates may overwrite manual Backlog entries
   - Mitigation: Preserve existing Backlog section content, warn on detection issues

### Performance Risks
1. **Batch processing overhead**: 183 projects may exceed 10s target
   - Mitigation: Parallel agent invocation (10-20 at a time), optimize Glob patterns
2. **Agent response time**: Network latency may slow Haiku invocations
   - Mitigation: Batch requests, implement timeout handling

## Notes

### Complexity Score Calculation
```
Score = (tasks × 1.0) + (phases × 5.0) + (hours × 0.5) + (dependencies × 2.0)
Score = (35 × 1.0) + (8 × 5.0) + (14 × 0.5) + (7 × 2.0)
Score = 35 + 40 + 7 + 14 = 96 (originally)
Score = 68.5 (adjusted after task refinement)
```

**Score ≥50**: Complexity suggests potential for phase expansion during implementation. Consider using `/expand` command if phases become too large.

### Design Decisions

**Why Haiku Model for todo-analyzer?**
- Fast response times (<2s) for batch operations across 100+ projects
- Low cost for high-volume tasks
- Deterministic outputs suitable for status classification
- Proven pattern in 7 existing commands (errors-analyst, test-executor, topic-naming-agent)

**Why Dual-Mode Operation (Default vs --clean)?**
- Default mode: Low-friction daily workflow (just run `/todo`)
- --clean mode: Safety-critical operation requiring explicit flag
- Follows /errors command pattern (default report mode + --query mode)

**Why Preserve Backlog Section?**
- Backlog contains manually curated ideas and research references
- Automated categorization may not understand context or priority
- Users expect Backlog to be stable across /todo invocations

**Why 30-Day Threshold for Cleanup?**
- Prevents accidental cleanup of recently completed work
- Allows time for post-completion validation or rollback
- Balances disk space management with safety

### Future Enhancements (Out of Scope)

- Interactive mode: Prompt user to categorize ambiguous plans
- Status override: Allow manual status annotation in TODO.md
- Cross-referencing: Link related plans (superseded by, depends on)
- Archive browsing: View archived completed projects
- Statistics dashboard: Project completion rates, time tracking
- Integration with /build: Automatically update TODO.md on plan completion
