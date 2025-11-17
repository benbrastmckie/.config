# Current Command Architecture Standards

**Research Date**: 2025-11-17
**Researcher**: Research Specialist Agent
**Scope**: Command architecture requirements, implementation standards, testing protocols, and documentation requirements from .claude/docs/
**Overview Report**: [OVERVIEW.md](OVERVIEW.md) - Command Compliance Assessment Research Overview

---

## Executive Summary

The .claude/docs/ directory establishes comprehensive architectural standards for command and agent development through 16 standards, multiple patterns, and detailed testing protocols. These standards address the unique nature of commands as "AI execution scripts" rather than traditional software, emphasizing execution clarity, behavioral enforcement, and context optimization.

**Key Findings:**
- 16 architectural standards spanning execution enforcement, file separation, library sourcing, and return code verification
- 9 documented architectural patterns including behavioral injection, executable/documentation separation, and parallel execution
- Comprehensive testing protocols including behavioral compliance, test isolation, and 80%+ coverage requirements
- Template-driven development approach with validated executable and guide templates
- Performance metrics showing 70% reduction in executable size, 90% context reduction, and 100% execution success rates

---

## 1. Core Architectural Standards

The command architecture is defined through the **Command and Agent Architecture Standards** document which establishes 16 numbered standards:

### Standard 0: Execution Enforcement

**Purpose**: Distinguish between descriptive documentation and mandatory execution directives.

**Key Requirements:**
- Use imperative language (YOU MUST, EXECUTE NOW, MANDATORY) for critical operations
- Include explicit verification checkpoints with fallback mechanisms
- Mark agent templates with "THIS EXACT TEMPLATE (No modifications)"
- Require checkpoint reporting for major steps
- Use language strength hierarchy (Critical → Mandatory → Strong → Standard → Optional)

**Enforcement Patterns:**
1. **Direct Execution Blocks**: EXECUTE NOW markers for critical operations
2. **Mandatory Verification Checkpoints**: Explicit verification that must execute
3. **Non-Negotiable Agent Prompts**: THIS EXACT TEMPLATE enforcement
4. **Checkpoint Reporting**: Explicit completion reporting

**Rationale**: Claude may interpret loosely worded instructions as optional, leading to incomplete execution. Imperative language enforces execution.

**Performance Evidence**:
- File creation rate: 100% (vs 60-80% with weak language)
- Verification ensures zero silent failures

### Standard 0.5: Subagent Prompt Enforcement

**Extension**: Apply Standard 0 patterns specifically to agent definition files (.claude/agents/*.md).

**Agent-Specific Patterns:**
- **Pattern A**: Role Declaration Transformation (YOU MUST vs "I am")
- **Pattern B**: Sequential Step Dependencies (STEP N REQUIRED BEFORE STEP N+1)
- **Pattern C**: File Creation as Primary Obligation
- **Pattern D**: Elimination of Passive Voice (never should/may/can)
- **Pattern E**: Template-Based Output Enforcement

**Quality Metrics**: Target 95+/100 on enforcement rubric (10 categories × 10 points)

**Integration**: Two-layer enforcement (command-level fallback + agent-level enforcement)

### Standard 1: Executable Instructions Must Be Inline

**Required Inline Content:**
- Step-by-step execution procedures with numbered steps
- Tool invocation examples with actual parameter values
- Decision logic flowcharts with conditions and branches
- JSON/YAML structure specifications
- Bash command examples with paths and flags
- Agent prompt templates (complete, not truncated)
- Critical warnings
- Error recovery procedures
- Checkpoint structure definitions
- Regex patterns for parsing results

**Allowed as External References:**
- Extended background context and rationale
- Additional examples beyond core patterns
- Alternative approaches for advanced users
- Troubleshooting guides for edge cases
- Historical context and design decisions
- Related reading and deeper dives

**Rationale**: Commands are AI execution scripts that Claude reads during execution. External references break execution flow and lose state.

### Standard 11: Imperative Agent Invocation Pattern

**Requirement**: All Task invocations MUST use imperative instructions signaling immediate execution.

**Required Elements:**
1. **Imperative Instruction**: "EXECUTE NOW", "USE the Task tool", "INVOKE AGENT"
2. **Agent Behavioral File Reference**: "Read and follow: .claude/agents/[agent-name].md"
3. **No Code Block Wrappers**: Task invocations NOT fenced in ```yaml blocks
4. **No "Example" Prefixes**: Remove documentation context
5. **Completion Signal Requirement**: Agent returns explicit confirmation

**Problem Statement**: Documentation-only YAML blocks create 0% agent delegation rate because they appear as syntax examples rather than executable instructions.

**Anti-Pattern Detection:**
```bash
# Find YAML blocks not preceded by imperative instructions
awk '/```yaml/{
  found=0
  for(i=NR-5; i<NR; i++) {
    if(lines[i] ~ /EXECUTE NOW|USE the Task tool|INVOKE AGENT/) found=1
  }
  if(!found) print FILENAME":"NR": Documentation-only YAML block"
} {lines[NR]=$0}' .claude/commands/*.md
```

**Historical Context**:
- Spec 438 (2025-10-24): /supervise 0% → >90% delegation rate
- Spec 495 (2025-10-27): /coordinate and /research 0% → >90% delegation rate
- Spec 497: Unified validation and test suite

### Standard 12: Structural vs Behavioral Content Separation

**Requirement**: Commands MUST distinguish between structural templates (inline) and behavioral content (referenced).

**Structural Templates (MUST Be Inline):**
1. Task Invocation Syntax: `Task { subagent_type, description, prompt }` structure
2. Bash Execution Blocks: `**EXECUTE NOW**: bash commands`
3. JSON Schemas: Data structure definitions
4. Verification Checkpoints: `**MANDATORY VERIFICATION**: file checks`
5. Critical Warnings: `**CRITICAL**: error conditions`

**Behavioral Content (MUST NOT Be Duplicated):**
1. Agent STEP Sequences: Procedural instructions
2. File Creation Workflows: PRIMARY OBLIGATION blocks
3. Agent Verification Steps: Agent-internal quality checks
4. Output Format Specifications: Templates for agent responses

**Rationale**:
- Single source of truth: Agent guidelines exist in one location
- 50-67% maintenance burden reduction
- 90% code reduction per agent invocation (150 lines → 15 lines)
- Zero synchronization burden

**Enforcement**:
- STEP instruction count in commands: <5
- Agent invocation size: <50 lines per Task block
- PRIMARY OBLIGATION presence: Zero occurrences in command files
- Behavioral file references: All agent invocations reference behavioral files

**Relationship to Standard 14**: Standard 12 determines WHAT content (structural vs behavioral), Standard 14 determines WHERE content goes (executable vs guide).

### Standard 13: Project Directory Detection

**Pattern**: Commands MUST use CLAUDE_PROJECT_DIR for project-relative paths.

**Implementation:**
```bash
# Detect project directory if not already set
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    CLAUDE_PROJECT_DIR="$(pwd)"
  fi
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
```

**Rationale**:
- ${BASH_SOURCE[0]} unavailable in SlashCommand execution context
- Git-based detection handles worktrees correctly
- Consistent with library implementation patterns
- Eliminates AI-driven recovery from library sourcing failures

**Context Awareness**: Different execution contexts require different patterns:
- SlashCommand: CLAUDE_PROJECT_DIR (git/pwd) - 100% reliable
- Standalone Script: ${BASH_SOURCE[0]} - 100% reliable
- Sourced Library: ${BASH_SOURCE[0]} - 100% reliable

### Standard 14: Executable/Documentation File Separation

**Requirement**: Commands MUST separate executable logic from comprehensive documentation.

**Two-File Architecture:**
1. **Executable Command File** (.claude/commands/command-name.md)
   - Target: <250 lines (simple), max 1,200 lines (orchestrators)
   - Content: Bash blocks, phase markers, minimal inline comments (WHAT not WHY)
   - Documentation: Single-line reference to guide file only
   - Audience: AI executor (Claude during command execution)

2. **Command Guide File** (.claude/docs/guides/command-name-command-guide.md)
   - Size: Unlimited (typically 500-5,000 lines)
   - Content: Architecture, examples, troubleshooting, design decisions
   - Cross-reference: Links back to executable file
   - Audience: Human developers, maintainers, contributors

**Rationale**: Mixed-purpose files cause meta-confusion loops, recursive invocation bugs, permission denied errors, and context bloat.

**Evidence**:
- Pre-migration meta-confusion rate: 75% (15/20 test runs)
- Post-migration: 0% (0/100 test runs)
- Average reduction: 70% in executable file size
- Reliability: 100% execution success rate (vs 25% pre-migration)

**Migration Results** (7 commands, 2025-11-07):

| Command | Original | New | Reduction | Guide | Status |
|---------|----------|-----|-----------|-------|--------|
| /coordinate | 2,334 | 1,084 | 54% | 1,250 | ✓ |
| /orchestrate | 5,439 | 557 | 90% | 4,882 | ✓ |
| /implement | 2,076 | 220 | 89% | 921 | ✓ |
| /plan | 1,447 | 229 | 84% | 460 | ✓ |
| /debug | 810 | 202 | 75% | 375 | ✓ |
| /document | 563 | 168 | 70% | 669 | ✓ |
| /test | 200 | 149 | 26% | 666 | ✓ |

**Validation**: Automated via `.claude/tests/validate_executable_doc_separation.sh`

### Standard 15: Library Sourcing Order

**Requirement**: Orchestration commands MUST source libraries in dependency order before calling functions.

**Standard Sourcing Pattern:**
```bash
# 1. State machine foundation (FIRST)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# 2. Error handling and verification (BEFORE any verification checkpoints)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# 3. Additional libraries as needed (AFTER core libraries)
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/unified-logger.sh"
```

**Dependency Justification:**
1. State machine → State persistence (state machine defines workflow states)
2. State persistence → Error/Verification (error functions depend on append_workflow_state())
3. Error/Verification → Checkpoints (checkpoints call verify_state_variable())
4. Other libraries AFTER (load after foundations established)

**Rationale**: Bash block execution model enforces subprocess isolation. Functions only available AFTER sourcing. Premature function calls result in "command not found" errors.

**Anti-Pattern**: Calling functions before sourcing libraries
```bash
# ❌ WRONG
verify_state_variable "WORKFLOW_SCOPE" || exit 1
# ... many lines later ...
source "${LIB_DIR}/verification-helpers.sh"
```

**Historical Context**: Spec 675 (2025-11-11) - Library sourcing order fix prevented "command not found" errors in /coordinate initialization.

### Standard 16: Critical Function Return Code Verification

**Requirement**: All critical initialization functions MUST have return codes checked.

**Rationale**: Bash `set -euo pipefail` does not exit on function failures, only simple command failures. Silent function failures lead to incomplete state initialization.

**Critical Functions:**
- sm_init() - State machine initialization
- initialize_workflow_paths() - Path allocation
- source_required_libraries() - Library loading
- classify_workflow_comprehensive() - Workflow classification

**Required Pattern:**
```bash
# Inline error handling (RECOMMENDED for orchestration commands)
if ! critical_function arg1 arg2 2>&1; then
  handle_state_error "critical_function failed: description" 1
fi

# Compound operator (ACCEPTABLE for simple commands)
critical_function arg1 arg2 || exit 1
```

**Prohibited Patterns:**
```bash
# ✗ WRONG: No return code check
critical_function arg1 arg2

# ✗ WRONG: Output redirection hides errors
critical_function arg1 arg2 >/dev/null
```

**Verification Checkpoints**: After successful critical function, verify exported variables:
```bash
if ! sm_init "$WORKFLOW_DESC" "coordinate" 2>&1; then
  handle_state_error "State machine initialization failed" 1
fi

# VERIFICATION: Ensure critical variables exported
if [ -z "${WORKFLOW_SCOPE:-}" ]; then
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not exported" 1
fi
```

**Historical Context**: Spec 698 - Missing return code check allowed sm_init() failures to silently proceed, causing unbound variable errors 78 lines later.

---

## 2. Architectural Patterns

### 2.1 Behavioral Injection Pattern

**Definition**: Commands inject execution context, artifact paths, and role clarifications into agent prompts through file reads rather than tool invocations.

**Purpose**: Separates orchestrator role (command) from executor role (agent).

**Key Elements:**
1. **Role Clarification**: Explicit "YOU ARE THE ORCHESTRATOR" declarations
2. **Path Pre-Calculation**: Calculate all paths before agent invocation
3. **Context Injection via File Content**: Structured data in agent prompts
4. **Reference Behavioral Files**: "Read and follow: .claude/agents/[agent].md"

**Problems Solved:**
- 100% file creation rate through explicit path injection
- <30% context usage by avoiding nested command prompts
- Hierarchical multi-agent coordination through clear role separation
- Parallel execution through independent context injection

**Benefits:**
- 90% reduction in code per invocation (150 lines → 15 lines)
- Single source of truth for agent guidelines
- Zero synchronization burden
- <30% context window usage throughout workflows

### 2.2 Executable/Documentation Separation Pattern

**Definition**: Separate lean executable logic from comprehensive documentation to eliminate meta-confusion and enable independent evolution.

**Implementation**:
- Executable: <250 lines, bash blocks, minimal comments
- Guide: Unlimited length, architecture, examples, troubleshooting

**Benefits:**
- Eliminates meta-confusion loops (0% incident rate vs 75% pre-migration)
- 70% average reduction in executable file size
- Independent evolution (logic changes don't touch docs)
- Unlimited documentation growth without bloat
- Fail-fast execution (lean files obviously executable)

**Validation**: `.claude/tests/validate_executable_doc_separation.sh`

### 2.3 Additional Patterns

The documentation references 9 total architectural patterns in `.claude/docs/concepts/patterns/`:

1. **Behavioral Injection**: Reference agent files, inject context
2. **Hierarchical Supervision**: Multi-level agent coordination
3. **Forward Message**: Direct subagent response passing
4. **Metadata Extraction**: 95-99% context reduction via summaries
5. **Context Management**: <30% context usage techniques
6. **Verification Fallback**: 100% file creation via checkpoints
7. **Checkpoint Recovery**: State preservation and restoration
8. **Parallel Execution**: Wave-based concurrent execution
9. **Workflow Scope Detection**: Conditional phase execution by scope

---

## 3. Command Development Requirements

### 3.1 Command Definition Format

**Metadata Fields:**
```yaml
allowed-tools: Read, Edit, Write, Bash, Grep, Glob, TodoWrite, Task
argument-hint: <required-arg> [optional-arg]
description: Brief one-line description (≤80 characters)
command-type: primary | support | workflow | utility
dependent-commands: cmd1, cmd2, cmd3
```

**Structure Sections:**
1. Overview: Brief description
2. Usage: Syntax and arguments
3. Standards Discovery and Application: CLAUDE.md integration
4. Workflow: Step-by-step execution process
5. Output: What the command produces
6. Testing: Validation procedures

### 3.2 Tool Selection Guidelines

**Security Levels:**
- Read: Low (safe, read-only)
- Edit: Medium (changes tracked)
- Write: Medium (cannot overwrite)
- Bash: High (can execute anything)
- Task: High (complex operations)

**Best Practice**: Start with minimal tools, add as needed (least-privilege principle)

### 3.3 Development Process (8 Steps)

1. **Define Purpose and Scope**: Problem statement, success criteria
2. **Design Command Structure**: Type, arguments, tools, dependencies
3. **Implement Behavioral Guidelines**: Workflow, error handling, examples
4. **Add Standards Discovery Section**: CLAUDE.md usage, fallbacks
5. **Integrate with Agents**: Behavioral injection, context passing
6. **Add Testing and Validation**: Test commands, validation criteria
7. **Document Usage and Examples**: Complete examples, edge cases
8. **Add to Commands README**: Navigation, discoverability

### 3.4 Quality Checklist

**Structure:**
- [ ] Frontmatter metadata complete and valid
- [ ] All metadata fields present
- [ ] Command type appropriate
- [ ] Tool selection justified

**Content:**
- [ ] Purpose clearly stated
- [ ] Usage syntax documented
- [ ] Workflow section with steps
- [ ] Output description present
- [ ] Examples included

**Standards Integration:**
- [ ] Standards Discovery section present
- [ ] Documents which CLAUDE.md sections used
- [ ] Shows how standards influence behavior
- [ ] Fallback behavior documented

**Agent Integration:**
- [ ] Agents clearly identified
- [ ] Invocation patterns use behavioral injection
- [ ] Context passing explained (metadata-only)
- [ ] Result handling specified

**Testing:**
- [ ] Test procedures documented
- [ ] Validation criteria specified
- [ ] Command tested manually
- [ ] Works with and without CLAUDE.md

---

## 4. Testing Protocols

### 4.1 Test Discovery

**Priority Order:**
1. Project root CLAUDE.md for test commands
2. Subdirectory-specific CLAUDE.md files
3. Language-specific test patterns

### 4.2 Claude Code Testing

**Test Location**: `.claude/tests/`
**Test Runner**: `./run_all_tests.sh`
**Test Pattern**: `test_*.sh` (Bash test scripts)

**Coverage Requirements:**
- ≥80% for modified code
- ≥60% baseline
- All public APIs must have tests
- Critical paths require integration tests
- Regression tests for all bug fixes

**Test Categories:**
- test_parsing_utilities.sh - Plan parsing functions
- test_command_integration.sh - Command workflows
- test_progressive_*.sh - Expansion/collapse operations
- test_state_management.sh - Checkpoint operations
- test_shared_utilities.sh - Utility library functions
- test_adaptive_planning.sh - Adaptive planning (16 tests)
- test_revise_automode.sh - /revise auto-mode (18 tests)

**Validation Scripts:**
- validate_executable_doc_separation.sh - Verifies Standard 14 compliance

### 4.3 Agent Behavioral Compliance Testing

**Required Test Types:**
1. **File Creation Compliance**: Verify agent creates files at injected paths
2. **Completion Signal Format**: Validate return format
3. **STEP Structure Validation**: Confirm STEP sequences
4. **Imperative Language**: Check MUST/WILL/SHALL usage
5. **Verification Checkpoints**: Ensure self-verification
6. **File Size Limits**: Validate output meets constraints

**Example Test Pattern:**
```bash
test_agent_creates_file() {
  local test_dir="/tmp/test_agent_$$"
  mkdir -p "$test_dir"

  REPORT_PATH="$test_dir/research_report.md"
  invoke_research_agent "$REPORT_PATH"

  if [ ! -f "$REPORT_PATH" ]; then
    echo "FAIL: Agent did not create file at injected path"
    return 1
  fi

  echo "PASS: Agent created file with content"
  rm -rf "$test_dir"
}
```

**Reference Test Suite**: `.claude/tests/test_optimize_claude_agents.sh` (320-line behavioral validation suite)

### 4.4 Test Isolation Standards

**Key Requirements:**
- **Environment Overrides**: Set CLAUDE_SPECS_ROOT="/tmp/test_specs_$$"
- **Temporary Directories**: Use mktemp for unique test directories
- **Cleanup Traps**: Register trap cleanup EXIT
- **Validation**: Test runner detects production directory pollution

**Detection Point**: unified-location-detection.sh checks CLAUDE_SPECS_ROOT first

**Manual Testing Pattern:**
```bash
export CLAUDE_SPECS_ROOT="/tmp/manual_test_$$"
export CLAUDE_PROJECT_DIR="/tmp/manual_test_$$"
mkdir -p "$CLAUDE_SPECS_ROOT"

/command-to-test "arguments"

rm -rf "/tmp/manual_test_$$"
unset CLAUDE_SPECS_ROOT CLAUDE_PROJECT_DIR
```

---

## 5. Documentation Requirements

### 5.1 Documentation Policy

**README Requirements** (Every subdirectory):
- **Purpose**: Clear explanation of directory role
- **Module Documentation**: Documentation for each file/module
- **Usage Examples**: Code examples where applicable
- **Navigation Links**: Links to parent and subdirectory READMEs

**Documentation Format:**
- Clear, concise language
- Code examples with syntax highlighting
- Unicode box-drawing for diagrams
- No emojis in file content (UTF-8 encoding issues)
- Follow CommonMark specification
- No historical commentary (timeless writing)

**Documentation Updates:**
- Update documentation with code changes
- Keep examples current with implementation
- Document breaking changes prominently
- Remove historical markers when updating

### 5.2 Diataxis Framework Organization

Documentation organized by user need:

**Reference** (Information-oriented):
- Command catalog
- Agent catalog
- Schemas and syntax
- Quick lookup materials

**Guides** (Task-focused):
- How-to guides for specific goals
- Command development
- Agent creation
- Standards integration

**Concepts** (Understanding-oriented):
- Architecture explanations
- Design patterns
- "Why" and "how it works"
- Hierarchical agents

**Workflows** (Learning-oriented):
- Step-by-step tutorials
- Orchestration guide
- Adaptive planning
- Checkpoint system

### 5.3 Link Conventions

**Standard**: All internal markdown links use relative paths from current file location.

**Format:**
- Same directory: `[File](file.md)`
- Parent directory: `[File](../file.md)`
- Subdirectory: `[File](subdir/file.md)`
- With anchor: `[Section](file.md#section-name)`

**Prohibited:**
- Absolute filesystem paths: `/home/user/.config/file.md`
- Repository-relative without base: `.claude/docs/file.md` (from outside .claude/)

**Validation:**
- Quick: `.claude/scripts/validate-links-quick.sh`
- Full: `.claude/scripts/validate-links.sh`

---

## 6. Template-Driven Development

### 6.1 Available Templates

**Executable Templates:**
- `.claude/docs/guides/_template-executable-command.md` (56 lines)
  - Standard 13 CLAUDE_PROJECT_DIR detection
  - Phase-based structure with bash blocks
  - Minimal inline comments (WHAT only)
  - Single-line documentation reference
  - Role statement: "YOU ARE EXECUTING AS the [command] command"

**Guide Templates:**
- `.claude/docs/guides/_template-command-guide.md` (171 lines)
  - Table of Contents for navigation
  - Overview (Purpose, When to Use, When NOT to Use)
  - Architecture (Design Principles, Workflow Phases, Integration Points)
  - Usage Examples (Basic, Advanced, Edge Cases)
  - Advanced Topics (Performance, Customization, Patterns)
  - Troubleshooting (Common Issues with symptoms → causes → solutions)
  - References (Cross-references to standards, patterns, related commands)

**Bash Block Template:**
- `.claude/docs/guides/_template-bash-block.md`
  - Standardized bash block structure
  - Error handling patterns
  - Verification checkpoints

### 6.2 Template Benefits

**Consistency**: All commands follow same structure
**Efficiency**: 60-80% faster new command creation
**Quality**: Templates embody best practices
**Validation**: Automated checks against template patterns

---

## 7. Performance Metrics

### 7.1 Context Optimization

**Metadata Extraction:**
- Report metadata: 5000 tokens → 250 tokens (95% reduction)
- Plan metadata: 8000 tokens → 350 tokens (96% reduction)
- Target: <30% context usage throughout workflows

**Behavioral Injection:**
- Traditional invocation: 11,500 tokens
- Layered invocation: 700 tokens
- Reduction: 94% (90-95% typical)

**Executable/Documentation Separation:**
- Average reduction: 70% in executable file size
- Guide growth: Average 1,300 lines (6.5x more than was inline)
- Context freed for execution state

### 7.2 Execution Reliability

**Agent Delegation Rate:**
- Pre-Standard 11: 0% (documentation-only patterns)
- Post-Standard 11: >90% (imperative patterns)

**File Creation Rate:**
- Pre-Standard 0: 60-80%
- Post-Standard 0: 100% (verification checkpoints)

**Meta-Confusion Rate:**
- Pre-Standard 14: 75% (15/20 test runs)
- Post-Standard 14: 0% (0/100 test runs)

**Bootstrap Reliability:**
- Fail-fast error handling: 100% (exposes configuration errors immediately)

### 7.3 Time Savings

**Parallelization:**
- Research phase: 40-60% faster
- Implementation phase: 40-60% faster
- Overall workflows: 35-50% faster vs sequential

**Library Sourcing Order (Spec 675):**
- /coordinate timeout: >120s → <90s
- Improvement: 25% faster

---

## 8. Cross-References and Integration

### 8.1 Key Documentation Files

**Standards:**
- Command Architecture Standards: `.claude/docs/reference/command_architecture_standards.md` (2,572 lines)
- Testing Protocols: `.claude/docs/reference/testing-protocols.md`
- Code Standards: `.claude/docs/reference/code-standards.md`
- Test Isolation Standards: `.claude/docs/reference/test-isolation-standards.md`

**Guides:**
- Command Development Fundamentals: `.claude/docs/guides/command-development-fundamentals.md`
- Command Development Standards Integration: `.claude/docs/guides/command-development-standards-integration.md`
- Agent Development Guide: `.claude/docs/guides/agent-development-guide.md`
- Imperative Language Guide: `.claude/docs/guides/imperative-language-guide.md`

**Patterns:**
- Behavioral Injection: `.claude/docs/concepts/patterns/behavioral-injection.md`
- Executable/Documentation Separation: `.claude/docs/concepts/patterns/executable-documentation-separation.md`
- Defensive Programming: `.claude/docs/concepts/patterns/defensive-programming.md`
- Verification Fallback: `.claude/docs/concepts/patterns/verification-fallback.md`

**Concepts:**
- Hierarchical Agents: `.claude/docs/concepts/hierarchical_agents.md`
- Bash Block Execution Model: `.claude/docs/concepts/bash-block-execution-model.md`
- Robustness Framework: `.claude/docs/concepts/robustness-framework.md`
- Directory Protocols: `.claude/docs/concepts/directory-protocols.md`

### 8.2 Standards Discovery

**Discovery Method:**
1. Search upward from current directory for CLAUDE.md
2. Check for subdirectory-specific CLAUDE.md files
3. Merge/override: subdirectory standards extend parent standards

**Fallback Behavior:**
- Use sensible language-specific defaults
- Suggest creating/updating CLAUDE.md with /setup
- Continue with graceful degradation

### 8.3 Used By Metadata

Commands that reference specific standards sections:

**Testing Protocols**: /test, /test-all, /implement
**Code Standards**: /implement, /refactor, /plan
**Command Architecture Standards**: All slash commands and agent development
**Documentation Policy**: /document, /plan

---

## 9. Anti-Patterns to Avoid

### 9.1 Reference-Only Sections

**❌ BAD**: Section with only external reference, no inline instructions

**✅ GOOD**: Complete inline instructions FIRST, reference AFTER for supplemental context

### 9.2 Truncated Templates

**❌ BAD**: `prompt: "See agent definition file for complete prompt structure"`

**✅ GOOD**: Complete agent prompt with all required sections inline

### 9.3 Vague Quick References

**❌ BAD**: "Discover plan → Execute phases → Generate summary"

**✅ GOOD**: Specific numbered steps with tools and commands

### 9.4 Missing Critical Warnings

**❌ BAD**: "Invoke multiple agents for parallel research"

**✅ GOOD**: "CRITICAL: Send ALL Task tool invocations in SINGLE message block"

### 9.5 Premature Function Calls

**❌ BAD**: Call verification functions before sourcing verification-helpers.sh

**✅ GOOD**: Source all libraries in dependency order before calling functions

---

## 10. Implementation Guidance

### 10.1 Creating a New Command

**Process:**
1. Copy `.claude/docs/guides/_template-executable-command.md`
2. Define metadata (tools, arguments, type)
3. Implement phases with bash blocks
4. Add verification checkpoints
5. Create companion guide from template
6. Add cross-references (bidirectional)
7. Test execution (verify no meta-confusion)
8. Validate with automated scripts

### 10.2 Migrating Existing Commands

**Checklist:**
- [ ] Backup original file
- [ ] Identify executable vs documentation sections
- [ ] Create lean executable (<250 lines)
- [ ] Extract documentation to guide file
- [ ] Add cross-references (both directions)
- [ ] Update CLAUDE.md with guide link
- [ ] Test execution
- [ ] Verify all phases execute correctly
- [ ] Delete backup (clean-break approach)

### 10.3 Validation Tools

**Automated Validation:**
- `.claude/tests/validate_executable_doc_separation.sh` - Standard 14 compliance
- `.claude/lib/validate-agent-invocation-pattern.sh` - Standard 11 compliance
- `.claude/tests/test_orchestration_commands.sh` - Unified orchestration tests
- `.claude/scripts/validate-links-quick.sh` - Link validation

**Manual Testing:**
- Execute command with test arguments
- Verify no meta-confusion loops
- Check all phases execute correctly
- Validate artifacts created at expected paths

---

## 11. Recommendations

### 11.1 For Command Developers

1. **Start with Templates**: Use validated executable and guide templates
2. **Apply Standard 0**: Use imperative language for all critical operations
3. **Enforce Standard 11**: No code-fenced Task invocations, always imperative
4. **Implement Standard 12**: Reference behavioral files, inject context only
5. **Follow Standard 14**: Separate executable (<250 lines) from guide (unlimited)
6. **Source Libraries Correctly**: Follow Standard 15 dependency order
7. **Verify Return Codes**: Apply Standard 16 to all critical functions
8. **Test Thoroughly**: Use behavioral compliance tests, test isolation
9. **Validate Continuously**: Run automated validation scripts

### 11.2 For Agent Developers

1. **Apply Standard 0.5**: Use imperative language in agent behavioral files
2. **Sequential Dependencies**: Mark steps as "REQUIRED BEFORE STEP N+1"
3. **File Creation Priority**: Mark as "PRIMARY OBLIGATION" or "ABSOLUTE REQUIREMENT"
4. **Eliminate Passive Voice**: Never use should/may/can in critical sections
5. **Template Enforcement**: Mark output formats as "THIS EXACT TEMPLATE"
6. **Verification Checkpoints**: Include "MANDATORY VERIFICATION" blocks
7. **Target Quality**: Score 95+/100 on enforcement rubric
8. **Test Behavioral Compliance**: Use test patterns from section 4.3

### 11.3 For Project Maintainers

1. **Enforce Standards**: Run validation scripts in CI/CD pipeline
2. **Review Checklists**: Use comprehensive review checklist from Standard 0
3. **Monitor Metrics**: Track delegation rates, file creation rates, context usage
4. **Update Templates**: Keep templates synchronized with latest best practices
5. **Document Patterns**: Add new patterns to .claude/docs/concepts/patterns/
6. **Maintain Cross-References**: Update "Used by" metadata in CLAUDE.md sections
7. **Test Isolation**: Ensure all tests use CLAUDE_SPECS_ROOT overrides
8. **Link Validation**: Run link validators before merging documentation changes

---

## 12. Future Considerations

### 12.1 Emerging Patterns

Several patterns are in active development:

1. **State-Based Orchestration**: Architecture for state machine-based workflow coordination
2. **Hierarchical Supervisor Coordination**: Advanced multi-level agent patterns
3. **Workflow State Machine**: Formal state transition architecture
4. **LLM Classification Pattern**: Using AI for workflow scope detection

### 12.2 Potential Improvements

1. **Automated Compliance Checking**: Expand validation scripts to cover all 16 standards
2. **Template Library Expansion**: Create templates for common agent types
3. **Performance Monitoring**: Automated tracking of context usage and execution times
4. **Pattern Catalog Expansion**: Document emerging patterns from real-world usage
5. **Testing Framework Enhancement**: More comprehensive behavioral compliance tests

### 12.3 Documentation Gaps

Areas that could benefit from additional documentation:

1. **Migration Guides**: Detailed guides for migrating legacy commands
2. **Troubleshooting Catalog**: Common issues with diagnostic steps
3. **Performance Tuning**: Optimization techniques for specific scenarios
4. **Integration Examples**: Real-world multi-command workflow examples
5. **Error Recovery Patterns**: Standardized error handling approaches

---

## Appendix A: Standards Quick Reference

| Standard | Focus | Key Requirement | Validation |
|----------|-------|----------------|------------|
| 0 | Execution Enforcement | Imperative language, verification checkpoints | Manual review, behavioral tests |
| 0.5 | Subagent Enforcement | Agent behavioral file patterns | 95+/100 rubric score |
| 1 | Inline Instructions | Executable content inline, not external | Test execution without shared/ |
| 11 | Agent Invocation | Imperative instructions, no code fences | validate-agent-invocation-pattern.sh |
| 12 | Structural/Behavioral | Templates inline, behavior referenced | Line count, duplication check |
| 13 | Directory Detection | CLAUDE_PROJECT_DIR usage | Code review |
| 14 | Executable/Doc Separation | <250 lines executable, unlimited guide | validate_executable_doc_separation.sh |
| 15 | Library Sourcing | Dependency order | test_library_sourcing_order.sh |
| 16 | Return Code Verification | Check critical function returns | Unit tests for failure paths |

---

## Appendix B: Metric Targets

| Metric | Target | Current | Validation Method |
|--------|--------|---------|-------------------|
| Agent Delegation Rate | >90% | >90% | test_orchestration_commands.sh |
| File Creation Rate | 100% | 100% | Verification checkpoints |
| Context Usage | <30% | 21-30% | Context monitoring |
| Meta-Confusion Rate | 0% | 0% | Execution testing |
| Test Coverage | ≥80% modified, ≥60% baseline | Varies | Coverage tools |
| Executable File Size | <250 lines (simple), <1,200 (orchestrator) | Compliant | validate_executable_doc_separation.sh |
| Agent Enforcement Score | 95+/100 | Varies | Behavioral rubric |

---

## Conclusion

The .claude/docs/ standards provide a comprehensive, battle-tested framework for developing reliable, maintainable, and performant commands and agents. The 16 architectural standards address the unique challenges of AI-driven command execution, emphasizing execution clarity, behavioral enforcement, and context optimization.

Key achievements:
- **70% reduction** in executable file size through Standard 14
- **90% context reduction** through behavioral injection (Standard 12)
- **100% reliability** in file creation, agent delegation, and execution
- **Template-driven development** enabling 60-80% faster command creation
- **Comprehensive testing** with behavioral compliance, test isolation, and 80%+ coverage

The standards are actively maintained, validated through automated testing, and continuously improved based on real-world usage patterns. New command developers should start with the provided templates and follow the quality checklists to ensure compliance with all architectural requirements.

**Primary Reference**: `.claude/docs/reference/command_architecture_standards.md` (2,572 lines, 16 standards)

---

**REPORT_CREATED**: /home/benjamin/.config/.claude/specs/746_command_compliance_assessment/reports/001_command_compliance_assessment/003_current_command_architecture_standards.md
