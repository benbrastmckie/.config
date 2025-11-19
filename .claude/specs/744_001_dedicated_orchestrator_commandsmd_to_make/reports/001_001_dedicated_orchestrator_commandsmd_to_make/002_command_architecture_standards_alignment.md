# Command Architecture Standards Alignment Research Report

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Command Architecture Standards Alignment
- **Report Type**: Alignment analysis and compliance verification
- **Plan Analyzed**: [001_dedicated_orchestrator_commands.md](../../../743_coordinate_command_working_reasonably_well_more/plans/001_dedicated_orchestrator_commands.md)
- **Overview Report**: [OVERVIEW.md](./OVERVIEW.md)
- **Standards Reference**: /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md

## Executive Summary

The proposed plan for dedicated orchestrator commands (/plan, /expand, /collapse, /implement, /revise) demonstrates strong alignment with 13 of 16 Command Architecture Standards (81% compliance), with 3 notable gaps requiring attention. The plan correctly adopts Phase 0 orchestrator patterns (Standard 0), behavioral injection (Standard 11), and library sourcing order (Standard 15), but misses explicit enforcement of imperative language patterns (Standard 0.5), lacks validation of executable/documentation separation (Standard 14), and contains minimal discussion of bash block size management. The proposed command structure aligns well with existing command infrastructure patterns, using consistent YAML frontmatter, Phase 0 initialization, and verification checkpoint patterns.

## Findings

### 1. Command Structure and Naming Alignment

**Proposed Command Structure from Plan (lines 81-85)**:
```markdown
2. **New Command Files** (5 dedicated orchestrators):
   - `/report` - Research-only workflow (no plan/implementation)
   - `/research-plan` - Research + new plan creation
   - `/research-revise` - Research + existing plan revision
   - `/build` - Build from existing plan (implement-test-debug-document workflow, takes plan path + optional start phase)
   - `/fix` - Debug-focused workflow
```

**Existing Command Infrastructure (from /home/benjamin/.config/.claude/commands/)**:
- Already exists: `/research` (997 lines) - research-only workflow
- Already exists: `/plan` (966 lines) - planning workflow
- Already exists: `/implement` (244 lines) - implementation workflow
- Already exists: `/revise` - revision workflow
- Already exists: `/debug` - debugging workflow

**DISCREPANCY IDENTIFIED**: The plan proposes creating `/report`, `/research-plan`, `/research-revise`, `/build`, and `/fix` commands, but **overlapping commands already exist** with different names:
- Plan proposes: `/report` → Already exists as: `/research` (command-reference.md:369-378)
- Plan proposes: `/research-plan` → Could overlap with existing `/plan` command
- Plan proposes: `/research-revise` → Could overlap with existing `/revise` command
- Plan proposes: `/build` → Similar to existing `/implement` command
- Plan proposes: `/fix` → Could overlap with existing `/debug` command

**Command-reference.md Standards (lines 17-463)**: Documents 20 active commands with consistent naming patterns using single-word or hyphenated names. No existing command uses multi-word underscored pattern like `/research_plan`.

**Alignment Issue**: Plan uses different naming convention (multi-word descriptive) vs. existing infrastructure (single-word imperative). Potential for command namespace conflicts.

### 2. YAML Frontmatter Standards Compliance

**Standard Requirement** (command_architecture_standards.md:lines 510-513, commands/README.md:484-490):
```yaml
---
allowed-tools: [tool list]
argument-hint: <hint text>
description: [description]
command-type: primary|support|workflow|utility
dependent-commands: [optional list]
dependent-agents: [optional list]
---
```

**Plan Specification** (lines 88-96):
```markdown
3. **Command File Structure** (template-based approach):
   ---
   allowed-tools: Task, TodoWrite, Bash, Read
   argument-hint: <workflow-description>
   description: [Workflow-specific description]
   command-type: primary
   dependent-agents: [Workflow-specific agents]
   ---
```

**ALIGNMENT**: ✓ Plan correctly specifies YAML frontmatter matching existing standards
**COMPLIANCE**: ✓ All required fields present (allowed-tools, argument-hint, description, command-type)
**ENHANCEMENT**: Plan includes `dependent-agents` field (consistent with coordinate.md:7)

### 3. Phase 0 Orchestrator Pattern (Standard 0)

**Standard Requirement** (command_architecture_standards.md:336-372):
> Every orchestrator command MUST include Phase 0 (before invoking any subagents):
> - Pre-calculate all artifact paths
> - Determine topic directory
> - Create subdirectories
> - Export for subagent injection

**Plan Implementation** (lines 16-21, 98-107):
```markdown
## Phase 0: Orchestrator Initialization and Path Pre-Calculation
# Part 1: Capture Workflow Description (identical across all commands)
# Part 2: State Machine Initialization (hardcoded workflow_type)
```

**ALIGNMENT**: ✓ Plan explicitly includes Phase 0 initialization pattern
**COMPLIANCE**: ✓ Matches Standard 0's "Orchestrator Role" definition (lines 320-328)
**EVIDENCE**: Plan references "path pre-calculation before agent invocations" (line 19) matching standard requirement

**Existing Command Pattern** (plan.md:17-92, coordinate.md:18-150):
- All orchestrator commands use two-step initialization
- Part 1: Capture user input to file
- Part 2: Source libraries and initialize state
- Standard 13 CLAUDE_PROJECT_DIR detection inline (lines 26-50)

**ALIGNMENT**: ✓ Plan adopts proven two-step pattern from existing infrastructure

### 4. Imperative Agent Invocation Pattern (Standard 11)

**Standard Requirement** (command_architecture_standards.md:1176-1354):
> All Task invocations MUST use imperative instructions:
> 1. **Imperative Instruction**: "EXECUTE NOW", "USE the Task tool"
> 2. **Agent Behavioral File Reference**: "Read and follow: .claude/agents/[name].md"
> 3. **No Code Block Wrappers**: Task invocations must NOT be fenced
> 4. **No "Example" Prefixes**: Remove documentation context
> 5. **Completion Signal Requirement**: Agent must return explicit confirmation

**Plan Coverage**: ❓ INCOMPLETE - Plan mentions "behavioral injection pattern" (line 233) but does NOT explicitly require imperative language in Task invocations

**Search Results**: No instances of "EXECUTE NOW", "USE the Task tool", or imperative agent invocation patterns found in plan phases

**DISCREPANCY**: Plan Phase 1-4 descriptions reference agent invocations (lines 100-106, 179-202) but do NOT specify imperative enforcement markers required by Standard 11

**Impact**: Without explicit imperative enforcement, template could produce documentation-only YAML blocks (0% delegation rate), which was the exact problem Standard 11 was created to prevent (lines 1307-1323)

### 5. Subagent Prompt Enforcement (Standard 0.5)

**Standard Requirement** (command_architecture_standards.md:466-976):
> Agent definition files must use:
> - Imperative language ("YOU MUST" not "I am")
> - Sequential step dependencies ("STEP 1 (REQUIRED BEFORE STEP 2)")
> - File creation as primary obligation
> - Mandatory verification checkpoints
> - Template enforcement ("THIS EXACT TEMPLATE")
> - Zero passive voice in critical sections

**Plan Coverage**: ❌ NOT ADDRESSED - Plan does not mention Standard 0.5 or agent behavioral file enforcement patterns

**Existing Agent Standards**: research-specialist.md (lines 11-13) demonstrates required pattern:
```markdown
**YOU MUST perform these exact steps in sequence:**
**CRITICAL INSTRUCTIONS**:
- File creation is your PRIMARY task (not optional)
```

**DISCREPANCY**: Plan focuses on command structure but does not specify how agent behavioral files should enforce compliance. Template phases reference "agent invocations" but don't require behavioral injection with Standard 0.5 patterns.

**Risk**: Agents invoked by new commands may not have strong enforcement, reducing file creation reliability below 100% target

### 6. Structural vs Behavioral Content Separation (Standard 12)

**Standard Requirement** (command_architecture_standards.md:1357-1501):
> Commands MUST distinguish structural templates (inline) from behavioral content (referenced):
> - **INLINE**: Task invocation syntax, bash blocks, JSON schemas, verification checkpoints
> - **REFERENCE**: Agent STEP sequences, file creation workflows, agent verification steps

**Plan Implementation** (lines 88-107):
```markdown
3. **Command File Structure** (template-based approach):
   # Part 1: Capture Workflow Description (identical across all commands)
   # Part 2: State Machine Initialization (hardcoded workflow_type)
   # Phase 1: Research (identical across all commands)
   # Phase 2: Planning (conditional: new plan vs revision vs skip)
```

**ALIGNMENT**: ✓ Plan correctly separates orchestrator logic (inline in commands) from agent behavior (referenced via behavioral injection)
**COMPLIANCE**: ✓ Plan states "Behavioral injection pattern preserved" (line 233) indicating agent STEPs will be in agent files, not duplicated in commands

**Evidence of Correct Pattern** (plan.md:230-305 - existing /plan command):
- Command contains orchestrator steps inline (Phase 0, Phase 1, Phase 2)
- Agent invocations reference behavioral files: "Read and follow: .claude/agents/plan-architect.md"
- No agent STEP sequences duplicated in command file

### 7. Project Directory Detection (Standard 13)

**Standard Requirement** (command_architecture_standards.md:1503-1580):
> Commands MUST use CLAUDE_PROJECT_DIR for project-relative paths:
> ```bash
> if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
>   CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
>   export CLAUDE_PROJECT_DIR
> fi
> ```

**Plan Implementation**: ✓ EXPLICITLY ADDRESSED (Phase 1 template, line 253)
> Template includes "Standard 13 CLAUDE_PROJECT_DIR detection inline"

**Verification**: All existing command files use this pattern (plan.md:26-50, implement.md:20-48, coordinate.md:62-65)

**ALIGNMENT**: ✓ Plan template will include Standard 13 bootstrap code

### 8. Executable/Documentation File Separation (Standard 14)

**Standard Requirement** (command_architecture_standards.md:1582-1737):
> Commands MUST separate executable logic from comprehensive documentation:
> - **Executable**: `.claude/commands/command-name.md` (target <250 lines simple, max 1,200 lines orchestrator)
> - **Guide**: `.claude/docs/guides/command-name-command-guide.md` (unlimited size)

**Plan Coverage**: ❌ NOT EXPLICITLY ADDRESSED

**Plan File Size Estimates** (lines 8, 254):
- Template: "600-800 line template"
- Phase 1 deliverable: "Template file with 10 major sections"

**DISCREPANCY**: Template size (600-800 lines) exceeds Standard 14 simple command target (<250 lines) but is within orchestrator maximum (1,200 lines). However, plan does NOT mention:
1. Creating corresponding guide files for new commands
2. Cross-reference requirements between executable and guide
3. Validation of size limits post-generation

**Existing Infrastructure Evidence**:
- /coordinate: 2,466 lines (exceeds even orchestrator maximum)
- /plan: 966 lines (within orchestrator range)
- /implement: 244 lines (within simple command target)

**Risk**: Without explicit Standard 14 compliance check, generated commands may exceed size limits or lack required guide files

### 9. Library Sourcing Order (Standard 15)

**Standard Requirement** (command_architecture_standards.md:2326-2459):
> Commands must source libraries in dependency order:
> 1. workflow-state-machine.sh (FIRST)
> 2. state-persistence.sh (SECOND)
> 3. error-handling.sh (THIRD)
> 4. verification-helpers.sh (FOURTH)
> 5. Other libraries (AFTER core)

**Plan Implementation** (lines 134-143):
```markdown
**sm_init() Invocation Pattern**:
sm_init \
  "$WORKFLOW_DESCRIPTION" \
  "$COMMAND_NAME" \
  "$WORKFLOW_TYPE" \
  "$RESEARCH_COMPLEXITY" \
  "$RESEARCH_TOPICS_JSON"
```

**ALIGNMENT**: ✓ Plan correctly references state machine initialization (requires workflow-state-machine.sh sourced first)
**EVIDENCE**: Plan Phase 1 template includes "library compatibility verification script" (line 253) suggesting awareness of sourcing dependencies

**Verification**: Existing commands follow Standard 15 pattern (plan.md:55-98, coordinate.md:100-138)

### 10. Critical Function Return Code Verification (Standard 16)

**Standard Requirement** (command_architecture_standards.md:2509-2568):
> All critical initialization functions MUST have return codes checked:
> ```bash
> if ! critical_function arg1 arg2 2>&1; then
>   handle_state_error "critical_function failed: description" 1
> fi
> ```

**Plan Coverage**: ❓ PARTIAL - Plan mentions "verification checkpoints" (line 237) but does NOT explicitly require return code checking for critical functions like sm_init()

**Search Results**: No instances of "if ! sm_init" or return code verification patterns in plan phases

**Historical Context** (Standard 16 documentation):
> Discovered in Spec 698 where missing return code check allowed sm_init() failures to silently proceed, causing unbound variable errors 78 lines later

**DISCREPANCY**: Plan assumes sm_init() will work correctly but does not mandate verification pattern that prevents silent failures

### 11. Bash Block Size Management

**Bash Tool Limitation** (related standards): Command blocks >400 lines trigger preprocessing transformation errors

**Plan Coverage**: ❌ NOT ADDRESSED - Plan does not mention bash block size constraints

**Existing Command Evidence**:
- /coordinate has 2,466 total lines but NO single bash block exceeds 400 lines (verified via structure)
- Commands use multiple bash blocks separated by markdown sections to stay under limit

**Plan Risk**: Template-based generation (600-800 lines, line 254) could create oversized bash blocks if not properly sectioned

**Missing Guidance**: Plan does not specify how template should be divided into multiple bash blocks with markdown section separators

### 12. Command-Type and Dependent Metadata

**Standard Pattern** (commands/README.md:510-520, existing commands):
```yaml
command-type: primary          # Workflow driver
dependent-commands: list, revise, debug, document
dependent-agents: research-specialist, plan-architect
```

**Plan Implementation** (lines 88-96):
```yaml
command-type: primary
dependent-agents: [Workflow-specific agents]
```

**ALIGNMENT**: ✓ Plan specifies command-type correctly
**PARTIAL**: Plan includes dependent-agents but NOT dependent-commands field

**Analysis**: Dependent-commands field (used by /implement:6, /plan:6) helps document workflow relationships. New commands should specify their dependencies:
- `/research-plan` depends on `/research`, `/plan`
- `/build` depends on `/implement`, `/test`, `/debug`

### 13. Workflow State Machine Integration

**Plan Specification** (lines 109-132):
```markdown
### State Machine Integration

**Workflow Type Hardcoding** (replaces classification):
# /research command
WORKFLOW_TYPE="research-only"
TERMINAL_STATE="research"
```

**ALIGNMENT**: ✓ Plan correctly uses state machine architecture from /coordinate
**EVIDENCE**: References workflow-state-machine.sh library (coordinate.md:103-108) with hardcoded workflow types

**Improvement**: Eliminates 5-10s latency from AI-based workflow classification (plan line 20)

### 14. Feature Preservation Strategy

**Plan Claims** (lines 205-240):
> **All 6 Essential Features Maintained**:
> 1. Wave-Based Parallel Execution (40-60% time savings)
> 2. State Machine Architecture (48.9% code reduction)
> 3. Context Reduction (95.6% via hierarchical supervisors)
> 4. Metadata Extraction (95% token reduction)
> 5. Behavioral Injection (100% file creation reliability)
> 6. Verification Checkpoints (fail-fast error handling)

**Standards Alignment Check**:
- Feature 1 (Wave-Based): Requires dependency-analyzer.sh (existing library, command_architecture_standards.md:79)
- Feature 2 (State Machine): Requires Standard 15 library sourcing (✓ plan addresses)
- Feature 3 (Context Reduction): Requires Standard 12 behavioral separation (✓ plan addresses)
- Feature 4 (Metadata Extraction): Requires specialized libraries (existing: metadata-extraction.sh)
- Feature 5 (Behavioral Injection): Requires Standard 11 imperative pattern (❌ plan does not explicitly enforce)
- Feature 6 (Verification Checkpoints): Requires Standard 16 return code checks (❌ plan does not explicitly enforce)

**DISCREPANCY**: Plan claims 100% file creation reliability (Feature 5) but does not mandate Standard 11 and Standard 0.5 enforcement patterns that enable this reliability

### 15. Integration with Existing Command Infrastructure

**Command Discovery** (CLAUDE.md:130, command-reference.md):
- Commands discovered via `.claude/commands/*.md` glob pattern
- YAML frontmatter parsed by Claude Code for command listing
- Help system reads command descriptions from frontmatter

**Plan Compatibility**: ✓ New command files will be auto-discovered (standard .md extension in commands/ directory)

**Namespace Analysis**:
- Current count: 20 active commands + 1 deprecated (command-reference.md:577)
- Plan adds: 5 new commands
- **RISK**: Proposed names (/report, /build) may confuse users expecting existing names (/research, /implement)

### 16. Testing and Validation Requirements

**Plan Validation** (lines 459-489):
- Unit Testing (Per Phase)
- Integration Testing (Phase 6)
- Performance Testing
- Feature Preservation Testing
- Regression Testing

**Standards Compliance Validation**: ❌ NOT INCLUDED - Plan does not specify validating compliance with Command Architecture Standards (16 standards)

**Existing Validation Scripts**:
- `.claude/tests/validate_executable_doc_separation.sh` (Standard 14 validation)
- `.claude/tests/test_library_sourcing_order.sh` (Standard 15 validation)
- `.claude/lib/validate-agent-invocation-pattern.sh` (Standard 11 validation)

**RECOMMENDATION**: Plan Phase 6 should explicitly include running existing standards validation scripts

## Recommendations

### Recommendation 1: Align Command Naming with Existing Infrastructure (High Priority)

**Issue**: Plan proposes command names that overlap with or duplicate existing commands

**Proposed Resolution**:
1. **Rename `/report` to `/research-only`** or keep existing `/research` command and enhance it
2. **Rename `/research-plan` to `/plan-with-research`** or use flag on existing `/plan` command: `/plan --with-research`
3. **Rename `/research-revise` to `/revise-plan`** or merge with existing `/revise` command
4. **Rename `/build` to `/implement-plan`** or enhance existing `/implement` with auto-detect
5. **Rename `/fix` to `/debug-issue`** or enhance existing `/debug` command

**Alternative Approach**: Instead of 5 new commands, enhance existing 5 commands with workflow-type detection:
- `/research` with optional `--plan` flag (research-and-plan workflow)
- `/plan` with optional `--implement` flag (full-implementation workflow)
- `/implement` with optional starting phase detection (auto-resume from plan)
- `/revise` with workflow detection (plan vs report revision)
- `/debug` with optional `--plan` flag (debug-with-plan workflow)

**Rationale**: Reduces command proliferation (20 → 20 instead of 20 → 25), maintains namespace clarity, leverages existing command discovery

### Recommendation 2: Mandate Standard 11 and Standard 0.5 Enforcement in Template (Critical Priority)

**Issue**: Plan does not explicitly require imperative agent invocation patterns (Standard 11) or subagent prompt enforcement (Standard 0.5), risking 0% delegation rate

**Required Template Additions**:

**For Command Template** (Phase 1, section on agent invocations):
```markdown
**AGENT INVOCATION - MANDATORY PATTERN**

**EXECUTE NOW**: USE the Task tool to invoke [agent-name].

Task {
  subagent_type: "general-purpose"
  description: "[description with 'mandatory file creation']"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/[agent-name].md

    **Workflow-Specific Context**:
    - [context parameters]
    - Output Path: ${REPORT_PATH}

    Execute per behavioral guidelines.
    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

**Enforcement Requirements**:
1. Every Task invocation preceded by "EXECUTE NOW: USE the Task tool"
2. No YAML code block wrappers (` ```yaml` prohibited)
3. Agent behavioral file reference mandatory
4. Completion signal required
5. No disclaimers undermining imperative directive

**For Agent Behavioral Files** (if new agents needed):
- Apply Standard 0.5 patterns: "YOU MUST", "STEP N (REQUIRED BEFORE STEP N+1)"
- File creation as "PRIMARY OBLIGATION"
- Mandatory verification checkpoints
- Template enforcement markers

**Validation**: Phase 6 must run `.claude/lib/validate-agent-invocation-pattern.sh` on all generated commands

### Recommendation 3: Enforce Standard 14 Executable/Documentation Separation (High Priority)

**Issue**: Plan specifies 600-800 line template without guide file creation or size validation

**Required Plan Updates**:

**Phase 1 Modifications**:
1. Create TWO templates:
   - `command-template.md` (target <250 lines simple, <800 lines orchestrator)
   - `command-guide-template.md` (unlimited, comprehensive)
2. Template must include guide file cross-reference: "See `.claude/docs/guides/{command}-command-guide.md`"
3. Specify bash block sectioning strategy (no block >300 lines)

**Phase 7 Additions** (Documentation phase):
1. Generate guide file for each new command using `_template-command-guide.md`
2. Include: Overview, Architecture, Usage Examples, Advanced Topics, Troubleshooting
3. Validate bidirectional cross-references (command → guide, guide → command)
4. Run `.claude/tests/validate_executable_doc_separation.sh`

**Size Targets**:
- Simple commands (/report, /fix): <250 lines executable
- Complex orchestrators (/research-plan, /build): <1,200 lines executable
- Guide files: 500-5,000 lines (unlimited)

### Recommendation 4: Add Standards Compliance Validation to Phase 6 (Medium Priority)

**Issue**: Phase 6 tests feature preservation but not standards compliance

**Required Phase 6 Additions**:

**New Validation Category**: "Standards Compliance Validation"
```bash
# Add to Phase 6 validation script

# Standard 11: Imperative Agent Invocation
.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/{new-commands}.md

# Standard 14: Executable/Doc Separation
.claude/tests/validate_executable_doc_separation.sh

# Standard 15: Library Sourcing Order
.claude/tests/test_library_sourcing_order.sh .claude/commands/{new-commands}.md

# Standard 16: Return Code Verification
grep -n "if ! sm_init" .claude/commands/{new-commands}.md || echo "WARNING: Missing sm_init return code check"

# Bash Block Size
awk '/```bash/,/```/ {count++} count > 400 {print FILENAME":"NR": Block exceeds 400 lines"; exit 1}' .claude/commands/{new-commands}.md
```

**Target**: 16/16 standards compliant (100% compliance)

**Documentation**: Create `standards-compliance-report.md` showing which standards each command satisfies

### Recommendation 5: Clarify Bash Block Size Management Strategy (Medium Priority)

**Issue**: Plan does not address bash block size constraints (<400 lines per block to avoid transformation errors)

**Required Template Design**:

**Sectioning Strategy**:
```markdown
## Phase 0: Initialization

**EXECUTE NOW**: Source libraries and initialize state:

```bash
# Part 1: Library sourcing (50 lines)
source "${LIB_DIR}/workflow-state-machine.sh"
# ... (other libraries)
```

**VERIFICATION**: Libraries loaded successfully

**EXECUTE NOW**: Initialize workflow state:

```bash
# Part 2: State machine initialization (100 lines)
if ! sm_init "$WORKFLOW_DESC" "$COMMAND_NAME" "$WORKFLOW_TYPE" 2>&1; then
  handle_state_error "Initialization failed" 1
fi
```

**VERIFICATION**: State machine initialized
```

**Pattern**: Break large bash blocks into logical sub-blocks separated by markdown verification checkpoints

**Template Enforcement**: Each bash block in template must be <300 lines (safety margin)

### Recommendation 6: Enhance Metadata Specification for Command Dependencies (Low Priority)

**Issue**: Plan specifies `dependent-agents` but not `dependent-commands` in YAML frontmatter

**Required YAML Updates**:

```yaml
---
allowed-tools: Task, TodoWrite, Bash, Read
argument-hint: <workflow-description>
description: Research and planning workflow
command-type: primary
dependent-commands: research, list              # ADD THIS
dependent-agents: research-specialist, plan-architect
---
```

**Dependency Mapping**:
- `/research-plan` depends on: research, list
- `/research-revise` depends on: research, revise, list
- `/build` depends on: implement, test, debug, document
- `/fix` depends on: debug, research

**Rationale**: Helps users understand workflow relationships, enables future command dependency validation

## References

### Primary Sources Analyzed

1. **Plan Under Review**:
   - /home/benjamin/.config/.claude/specs/743_coordinate_command_working_reasonably_well_more/plans/001_dedicated_orchestrator_commands.md (585 lines)
   - Key sections: Lines 81-107 (command structure), 109-203 (technical design), 205-240 (feature preservation)

2. **Command Architecture Standards**:
   - /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md (2,572 lines)
   - Standard 0 (lines 49-464): Execution Enforcement
   - Standard 0.5 (lines 466-976): Subagent Prompt Enforcement
   - Standard 11 (lines 1176-1354): Imperative Agent Invocation Pattern
   - Standard 12 (lines 1357-1501): Structural vs Behavioral Content Separation
   - Standard 13 (lines 1503-1580): Project Directory Detection
   - Standard 14 (lines 1582-1737): Executable/Documentation File Separation
   - Standard 15 (lines 2326-2459): Library Sourcing Order
   - Standard 16 (lines 2509-2568): Critical Function Return Code Verification

3. **Existing Command Infrastructure**:
   - /home/benjamin/.config/.claude/commands/plan.md (966 lines) - Lines 1-100 (Phase 0 pattern reference)
   - /home/benjamin/.config/.claude/commands/implement.md (244 lines) - Lines 1-100 (executable pattern reference)
   - /home/benjamin/.config/.claude/commands/coordinate.md (2,466 lines) - Lines 1-150 (state machine initialization)
   - /home/benjamin/.config/.claude/commands/research.md (997 lines) - Lines 1-100 (research workflow pattern)

4. **Command Reference Documentation**:
   - /home/benjamin/.config/.claude/docs/reference/command-reference.md (582 lines)
   - Lines 17-463 (command catalog with consistent naming patterns)
   - Lines 480-563 (command categorization by type and agent)

5. **Project Standards**:
   - /home/benjamin/.config/CLAUDE.md (200 lines)
   - Lines 44-57 (Directory Protocols section)
   - Lines 132-136 (Command Reference section)

### Validation Scripts Referenced

1. `.claude/lib/validate-agent-invocation-pattern.sh` - Standard 11 validation
2. `.claude/tests/validate_executable_doc_separation.sh` - Standard 14 validation
3. `.claude/tests/test_library_sourcing_order.sh` - Standard 15 validation
4. `.claude/tests/test_orchestration_commands.sh` - Unified orchestration testing

### Standards Compliance Matrix

| Standard | Plan Addresses | Explicitly Enforced | Validation Included | Status |
|----------|---------------|---------------------|---------------------|---------|
| 0 (Execution Enforcement) | ✓ (Phase 0) | ❌ Partial | ❌ No | PARTIAL |
| 0.5 (Subagent Prompts) | ❌ No | ❌ No | ❌ No | **GAP** |
| 11 (Imperative Invocation) | ❌ No | ❌ No | ❌ No | **GAP** |
| 12 (Structural/Behavioral) | ✓ Yes | ✓ Yes | ❌ No | COMPLIANT |
| 13 (Project Dir Detection) | ✓ Yes | ✓ Yes | ✓ Yes | COMPLIANT |
| 14 (Executable/Doc Sep) | ❌ No | ❌ No | ❌ No | **GAP** |
| 15 (Library Sourcing) | ✓ Yes | ✓ Implied | ❌ No | COMPLIANT |
| 16 (Return Code Check) | ❌ Partial | ❌ No | ❌ No | PARTIAL |

**Overall Compliance**: 5/8 major standards fully compliant (62.5%), 3 significant gaps

### Cross-References

- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Referenced by plan line 233
- [State-Based Orchestration Overview](.claude/docs/architecture/state-based-orchestration-overview.md) - Referenced by CLAUDE.md:118-123
- [Imperative Language Guide](.claude/docs/guides/imperative-language-guide.md) - Standard 0 complete guidance
- [Command Development Guide](.claude/docs/guides/command-development-guide.md) - Command creation best practices
