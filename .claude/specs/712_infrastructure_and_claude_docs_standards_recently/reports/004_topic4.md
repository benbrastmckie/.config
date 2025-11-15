# Integration Standards and Infrastructure Research Report

## Metadata
- **Date**: 2025-11-14
- **Agent**: research-specialist
- **Topic**: Integration Standards and Infrastructure
- **Report Type**: Codebase analysis and architectural standards review
- **Research Focus**: Agent templates, library functions, documentation patterns, and architectural compliance requirements

## Executive Summary

The .claude/ infrastructure provides a comprehensive standards-based framework for subagent integration with clear architectural boundaries, reusable templates, and extensive library utilities. Integration follows the behavioral injection pattern with strict separation of concerns: commands orchestrate workflows and pre-calculate artifact paths, while agents execute tasks using Write/Edit/Bash tools. Key architectural standards (Standards 0-16 in command_architecture_standards.md) enforce imperative language, verification checkpoints, and fail-fast error handling. The system achieves 95% context reduction through metadata extraction and supports hierarchical supervision for complex workflows.

## Current State Analysis

### Agent Integration Architecture

**Behavioral Injection Pattern** (.claude/docs/concepts/patterns/behavioral-injection.md):
- Commands invoke agents via Task tool with `Read and follow: .claude/agents/[name].md` directive
- Agents read behavioral files directly (0 tokens passed inline)
- Context injected separately (paths, parameters, requirements) - typically 200-500 tokens
- Prevents command-to-command recursion and enables hierarchical coordination
- Achieves 90% code reduction per invocation (150 lines → 15 lines)

**Agent Responsibilities** (agent-development-guide.md:1433-1506):
- ✅ Create artifacts directly using Write tool at provided ARTIFACT_PATH
- ✅ Use Read/Edit tools for analysis and modification
- ✅ Use Grep/Glob for codebase discovery
- ✅ Return structured metadata (path + summary + key findings)
- ❌ NEVER invoke slash commands (prevents recursion)
- ❌ NEVER assume artifact paths (command provides exact locations)
- ❌ NEVER return full content (metadata only for 95% context reduction)

**Tool Selection Decision Tree** (agent-development-guide.md:1482-1506):
- Create artifact → Write tool with exact ARTIFACT_PATH
- Modify file → Edit tool with old_string/new_string
- Search content → Grep tool
- Search files → Glob tool
- Execute commands → Bash tool (file operations only)
- Slash commands → NEVER (except explicit behavioral file permission)

### Agent Templates

**Sub-Supervisor Template** (.claude/agents/templates/sub-supervisor-template.md):
- Template for hierarchical supervisors coordinating 4+ worker agents
- 8 sequential steps: Load state → Parse inputs → Invoke workers → Extract metadata → Aggregate → Save checkpoint → Handle failures → Return metadata
- Performance: 95% context reduction (10,000 → 500 tokens), 73% time savings through parallel execution
- Threshold: Use when ≥4 workers and worker output >2,000 tokens each
- Template variables: SUPERVISOR_TYPE, WORKER_TYPE, WORKER_COUNT, TASK_DESCRIPTION, OUTPUT_TYPE, METADATA_FIELDS

**Template Structure** (agents/templates/README.md):
1. Metadata: Agent name, purpose, complexity
2. Context: Input information
3. Behavioral Instructions: Operational procedures
4. Subagent Delegation: Worker invocation patterns
5. Output Format: Return structure

**Template Customization Examples**:
- Research Supervisor: metadata_field=key_findings, aggregation=merge top 2 per worker (max 12)
- Implementation Supervisor: metadata_field=files_modified, aggregation=count total files/lines/tests
- Testing Supervisor: metadata_field=test_results, aggregation=sum passed/failed, calculate coverage %

### Library Functions

**Core Libraries** (.claude/lib/):

**Metadata Extraction** (metadata-extraction.sh):
- `extract_report_metadata()` - Extract title, summary (50 words), file paths, recommendations
- `extract_plan_metadata()` - Extract complexity, phases, time estimates
- `load_metadata_on_demand()` - Generic metadata loader with caching
- Enables 95-99% context reduction by passing summaries instead of full content

**Plan Parsing** (plan-core-bundle.sh):
- `parse_plan_file()` - Parse plan structure and phases
- `extract_phase_info()` - Extract phase details and tasks
- `get_plan_metadata()` - Get plan-level metadata

**Context Management** (context-pruning.sh):
- `prune_subagent_output()` - Clear full outputs after metadata extraction
- `prune_phase_metadata()` - Remove phase data after completion
- `apply_pruning_policy()` - Automatic pruning by workflow type
- Target: <30% context usage throughout workflows

**Workflow Classification** (workflow-llm-classifier.sh, workflow-scope-detection.sh):
- `classify_workflow_comprehensive()` - Main classification function with 2-mode system
- `classify_workflow_llm()` - LLM-based semantic classification (98%+ accuracy, default)
- `classify_workflow_regex_comprehensive()` - Traditional regex-based classification (offline mode)
- `detect_workflow_scope()` - Backward compatibility wrapper
- Modes: llm-only (online, semantic understanding) vs regex-only (offline, pattern matching)

**State Management** (state-persistence.sh, workflow-state-machine.sh):
- 8 explicit workflow states: initialize, research, plan, implement, test, debug, document, complete
- Selective file-based persistence (7 critical items, 70% analyzed state)
- Atomic state transitions with checkpoint coordination
- 67% performance improvement (6ms → 2ms for CLAUDE_PROJECT_DIR detection)

**Error Handling** (error-handling.sh, verification-helpers.sh):
- `handle_state_error()` - Centralized error handling with diagnostics
- `verify_file_created()` - Mandatory file existence verification
- `verify_state_variable()` - State variable validation
- Fail-fast philosophy: expose errors immediately, never hide with fallbacks

**Artifact Creation** (artifact-creation.sh):
- `get_or_create_topic_dir()` - Topic-based directory structure (specs/NNN_topic/)
- `create_topic_artifact()` - Sequential artifact numbering (001_, 002_, etc.)
- `ensure_artifact_directory()` - Lazy directory creation pattern

### Documentation Patterns

**Executable/Documentation Separation** (Standard 14, command_architecture_standards.md:1535-1689):

**Two-File Pattern for Commands**:
- Executable: .claude/commands/command-name.md (<250 lines simple, <1,200 lines orchestrators)
- Guide: .claude/docs/guides/command-name-command-guide.md (unlimited, comprehensive)
- Validation: .claude/tests/validate_executable_doc_separation.sh
- Benefits: 70% average file size reduction, 0% meta-confusion, independent evolution

**Two-File Pattern for Agents** (agent-development-guide.md:769-932):
- Behavioral: .claude/agents/agent-name.md (<400 lines target)
- Usage Guide: .claude/docs/guides/agent-name-agent-guide.md (unlimited)
- Pattern parallel to commands but adjusted for agent complexity (higher threshold)
- Candidate for migration: research-specialist.md (671 lines, ~200 extractable)

**Cross-Reference Requirements**:
- Executable → Guide: Single-line reference only
- Guide → Executable: Link back with clear distinction
- Bidirectional validation in test suite

**Documentation Structure** (.claude/docs/):
```
docs/
├── concepts/       Core patterns and architectural concepts
├── guides/         Task-focused how-to guides
├── reference/      API references and catalogs
├── workflows/      End-to-end workflow tutorials
└── troubleshooting/ Problem-solving guides
```

### Architectural Compliance Requirements

**Command Architecture Standards** (command_architecture_standards.md):

**Standard 0: Execution Enforcement** (lines 52-463):
- Imperative language patterns: YOU MUST, EXECUTE NOW, MANDATORY (not "should", "may", "can")
- Verification checkpoints: Explicit file existence checks, file size validation
- Fallback mechanisms: Detect errors (verification) not hide errors (bootstrap)
- Strength hierarchy: Critical > Mandatory > Strong > Standard > Optional
- Fail-fast philosophy: Bootstrap fallbacks PROHIBITED, verification fallbacks REQUIRED

**Standard 11: Imperative Agent Invocation** (lines 1173-1352):
- **EXECUTE NOW**: USE the Task tool... (imperative instruction required)
- No code block wrappers around Task invocations (``` yaml ``` prevents execution)
- No "Example" prefixes (documentation context prevents execution)
- Completion signal requirement: REPORT_CREATED: ${PATH} enables verification
- Agent behavioral file reference: Read and follow: .claude/agents/[name].md
- Performance: >90% delegation rate when compliant, 0% when violated

**Standard 12: Structural vs Behavioral Separation** (lines 1356-1453):
- Structural templates (inline): Task invocation syntax, bash blocks, JSON schemas, verification checkpoints
- Behavioral content (referenced): Agent STEP sequences, file creation workflows, verification procedures, output formats
- Benefits: 90% code reduction, single source of truth, zero synchronization burden
- Validation: <5 STEP instructions in commands, <50 lines per Task block, zero PRIMARY OBLIGATION in commands

**Standard 14: Executable/Documentation Separation** (lines 1535-1689):
- Size limits: <250 lines simple commands, <1,200 lines orchestrators
- Cross-reference requirement: Bidirectional links between executable and guide
- Guide existence: All commands >150 lines MUST have guide file
- Migration results: 70% average reduction, 0% meta-confusion, 100% execution success

**Standard 15: Library Sourcing Order** (lines 2277-2412):
- State machine foundation FIRST (workflow-state-machine.sh, state-persistence.sh)
- Error/verification libraries SECOND (error-handling.sh, verification-helpers.sh)
- Additional libraries AFTER core foundations
- Rationale: Functions unavailable until sourced, premature calls cause "command not found"
- Source guards enable safe re-sourcing (zero overhead)

**Standard 16: Critical Function Return Code Verification** (lines 2462-2521):
- All critical initialization functions MUST have return codes checked
- Required pattern: `if ! critical_function; then handle_state_error "failed" 1; fi`
- Critical functions: sm_init(), initialize_workflow_paths(), source_required_libraries(), classify_workflow_comprehensive()
- Bash `set -euo pipefail` does NOT exit on function failures
- Verification checkpoints after success to validate exported variables

### Directory Organization

**Directory Protocols** (CLAUDE.md:46-62, .claude/docs/concepts/directory-protocols.md):
- Topic-based structure: specs/{NNN_topic}/ with artifact subdirectories
- Artifact types: plans/, reports/, summaries/, debug/
- Plan levels: Single file (Level 0) → Phase expansion (Level 1) → Stage expansion (Level 2)
- Phase dependencies: Enable parallel execution (40-60% time savings)
- Artifact lifecycle: Debug reports committed, others gitignored

**Directory Structure Standards** (.claude/docs/guides/command-development-guide.md, CLAUDE.md:288-421):
```
.claude/
├── scripts/        Standalone CLI tools (validate, fix, migrate)
├── lib/            Sourced function libraries (parsing, error handling)
├── commands/       Slash command definitions
│   └── templates/  Plan templates (YAML) for /plan-from-template
├── agents/         Specialized AI assistant definitions
│   └── templates/  Agent behavioral templates (sub-supervisor, etc.)
├── docs/           Integration guides and standards
├── utils/          Specialized helper utilities
└── tests/          Test suites for system validation
```

**File Placement Decision Matrix** (CLAUDE.md:373-387):
| Question | scripts/ | lib/ | commands/ | agents/ |
|----------|----------|------|-----------|---------|
| Standalone executable? | ✓ | ✗ | ✗ | ✗ |
| Needs CLI arguments? | ✓ | ✗ | ✗ | ✗ |
| Sourced by other code? | ✗ | ✓ | ✗ | ✗ |
| Complete workflow? | ✓ | ✗ | ✓ | ✓ |
| User-facing command? | ✗ | ✗ | ✓ | ✗ |
| AI agent behavioral? | ✗ | ✗ | ✗ | ✓ |

## Research Findings

### Integration Pattern Analysis

**1. Behavioral Injection is Standard Pattern**
- ALL orchestration commands use behavioral injection (no command-to-command invocations)
- 35+ agent behavioral files in .claude/agents/
- Consistent invocation structure: Task tool + "Read and follow: .claude/agents/[name].md"
- Context injection separate from behavioral guidelines (90% code reduction)

**2. Metadata-Based Context Reduction is Core Architecture**
- extract_report_metadata(), extract_plan_metadata() used by all orchestrators
- Forward message pattern: Pass subagent responses without re-summarization
- Context pruning: Remove completed phase data, retain references only
- Target achieved: <30% context usage across all multi-phase workflows
- Performance: 95-99% reduction (10,000 → 500 tokens typical)

**3. Template System is Mature**
- Sub-supervisor template validated through 3 production supervisors (research, implementation, testing)
- 11 plan templates in commands/templates/ for /plan-from-template
- Template variables clearly documented with substitution patterns
- Usage guides separate from templates (guides show HOW, templates provide WHAT)

**4. Library Utilities are Comprehensive**
- 60+ library files in .claude/lib/
- Function categories: Parsing, validation, metadata, state management, workflow classification, error handling
- Source guards enable safe re-sourcing (all libraries protected)
- Dependency ordering enforced (Standard 15)
- Performance optimized: 67% improvement through selective persistence

**5. Documentation Standards are Enforced**
- Executable/documentation separation validated by automated tests
- Cross-reference requirements checked by link validation scripts
- Internal link conventions: Relative paths from current file location
- Validation scripts: validate-links-quick.sh, validate_executable_doc_separation.sh
- Template placeholders allowed: {variable}, NNN_topic, $ENV_VAR

### Architectural Compliance Requirements

**1. Imperative Language is Mandatory** (Standard 0)
- Critical operations use CRITICAL/ABSOLUTE REQUIREMENT
- Essential steps use YOU MUST/REQUIRED/EXECUTE NOW
- Optional features use MAY/CAN/CONSIDER
- Verification checkpoints after all critical operations
- Fallback taxonomy: Bootstrap PROHIBITED, Verification REQUIRED, Optimization ACCEPTABLE

**2. Agent Invocation Pattern is Strictly Defined** (Standard 11)
- Imperative instruction: **EXECUTE NOW**: USE the Task tool...
- No code block wrappers: Task { } not ``` yaml Task { } ```
- Agent behavioral file reference: .claude/agents/[name].md
- Completion signal: REPORT_CREATED: ${PATH}
- Performance evidence: >90% delegation rate when compliant, 0% when violated

**3. Behavioral Content Must Not Be Duplicated** (Standard 12)
- Agent STEP sequences ONLY in .claude/agents/ files
- PRIMARY OBLIGATION blocks ONLY in agent behavioral files
- Commands inject context (parameters) not procedures
- Single source of truth principle
- 90% reduction achieved per compliant invocation

**4. Library Sourcing Order is Critical** (Standard 15)
- State machine FIRST (workflow-state-machine.sh, state-persistence.sh)
- Error handling SECOND (error-handling.sh, verification-helpers.sh)
- Other libraries AFTER foundations
- Premature function calls cause "command not found" errors
- Source guards enable safe re-sourcing across bash blocks

**5. Return Code Verification is Required** (Standard 16)
- All critical functions MUST have return codes checked
- Pattern: if ! func; then handle_state_error "failed" 1; fi
- Bash set -euo pipefail does NOT exit on function failures
- Verification checkpoints validate exported variables after success
- Historical evidence: Silent failures caused unbound variable errors 78 lines later

### Anti-Patterns Documented

**1. Documentation-Only YAML Blocks** (behavioral-injection.md:264-414):
- Code-fenced Task invocations (``` yaml ```) prevent execution
- "Example" prefixes establish documentation interpretation
- Priming effect: Single fenced example causes all subsequent Task blocks to be skipped
- Evidence: Spec 438 (/supervise) - 7 YAML blocks, 0% delegation before fix
- Fix pattern: Remove code fences, add imperative instructions, use HTML comments for clarifications

**2. Inline Template Duplication** (behavioral-injection.md:264-323):
- Duplicating agent STEP sequences in command prompts
- 150+ lines of behavioral guidelines per invocation
- Creates maintenance burden and violates single source of truth
- Evidence: 800+ lines across command files before fix
- Fix pattern: Reference behavioral file, inject context only (150 → 15 lines)

**3. Undermined Imperative Pattern** (behavioral-injection.md:528-617):
- Following **EXECUTE NOW** with disclaimers suggesting template/future generation
- "**Note**: The actual implementation will generate N calls" contradicts imperative
- Template assumption causes 0% delegation rate
- Evidence: Spec 502 (/supervise) research delegation failure
- Fix pattern: Remove disclaimers, use "for each [item]" phrasing, `[insert value]` placeholders

**4. Bootstrap Fallbacks** (behavioral-injection.md:842-1030):
- Silent function definitions when libraries missing
- Automatic directory creation masking agent delegation failures
- Default value substitution for missing required variables
- Evidence: 32 lines removed from /supervise (Spec 057)
- Fix pattern: Fail-fast with diagnostic error messages, remove fallback functions

**5. Command-to-Command Invocation** (behavioral-injection.md:618-676):
- SlashCommand tool invoking /plan, /implement, /debug
- Loss of path control, context bloat, recursion risk
- Prevents hierarchical patterns and metadata extraction
- Evidence: Plan 080 - /orchestrate calling /plan (85% context before fix)
- Fix pattern: Behavioral injection with direct agent invocation

## Recommendations

### For New Subagent Integration

1. **Follow Behavioral Injection Pattern Strictly**
   - Create agent behavioral file in .claude/agents/[name].md
   - Use agent frontmatter (allowed-tools, description, model, model-justification)
   - Structure: System prompt → Core capabilities → Behavioral guidelines → Input/Output specs
   - Invoke via Task tool with "Read and follow: .claude/agents/[name].md"
   - Inject context separately (paths, parameters) - typically 200-500 tokens
   - Never duplicate STEP sequences or PRIMARY OBLIGATION blocks in commands

2. **Use Sub-Supervisor Template for Complex Coordination**
   - Apply when coordinating ≥4 workers with output >2,000 tokens each
   - Copy .claude/agents/templates/sub-supervisor-template.md
   - Replace template variables: SUPERVISOR_TYPE, WORKER_TYPE, WORKER_COUNT, etc.
   - Customize aggregation algorithm for supervisor-specific metadata
   - Test with .claude/tests/test_[supervisor]_supervisor.sh
   - Expected performance: 95% context reduction, 73% time savings

3. **Leverage Library Utilities for Common Operations**
   - Metadata extraction: Use extract_report_metadata(), extract_plan_metadata()
   - Context reduction: Use prune_subagent_output(), apply_pruning_policy()
   - Workflow classification: Use classify_workflow_comprehensive() with llm-only mode
   - State management: Use workflow-state-machine.sh functions (sm_init, sm_transition)
   - Error handling: Use handle_state_error() with diagnostic messages
   - Source libraries in dependency order (Standard 15)

4. **Follow Architectural Standards for Compliance**
   - Use imperative language for critical operations (Standard 0)
   - Add verification checkpoints after file creation (Standard 0)
   - Use imperative agent invocation pattern (Standard 11)
   - Separate structural templates from behavioral content (Standard 12)
   - Create guide file when executable exceeds threshold (Standard 14)
   - Source libraries in correct order (Standard 15)
   - Verify return codes for critical functions (Standard 16)

5. **Apply Documentation Patterns Consistently**
   - Create executable/guide file pair when appropriate
   - Use relative paths for internal markdown links
   - Validate with .claude/tests/validate_executable_doc_separation.sh
   - Validate links with .claude/scripts/validate-links-quick.sh
   - Cross-reference bidirectionally (executable ↔ guide)
   - Use template placeholders for variables ({variable}, NNN_topic, $ENV_VAR)

### For Architecture Improvements

1. **Extend Template System for Common Agent Patterns**
   - Create agent behavioral template (_template-agent-behavioral.md)
   - Create agent usage guide template (_template-agent-usage-guide.md)
   - Document template variables and customization points
   - Validate with comprehensive test suite

2. **Strengthen Validation Infrastructure**
   - Extend validate_executable_doc_separation.sh for agent files
   - Create automated tests for behavioral injection pattern compliance
   - Add delegation rate monitoring to CI/CD pipeline
   - Implement anti-pattern detection (documentation-only YAML, undermined imperatives)
   - Track metrics: File creation rate, context usage, delegation rate

3. **Document Migration Patterns for Legacy Integration**
   - Create migration guide for command-to-command invocations
   - Document bootstrap fallback removal process
   - Provide before/after examples with metrics
   - Include regression test requirements
   - Track migration completion percentage

4. **Optimize Library Performance**
   - Profile library function execution times
   - Identify optimization opportunities (caching, memoization)
   - Measure selective persistence impact (67% improvement baseline)
   - Document performance characteristics per library
   - Create performance benchmarks for critical paths

5. **Expand Hierarchical Supervision Capabilities**
   - Create additional supervisor templates (debugging, documentation, refactoring)
   - Document supervisor coordination patterns
   - Implement supervisor metrics collection
   - Create supervisor performance analysis tools
   - Establish guidelines for when to use hierarchical vs flat coordination

## Implementation Guidance

### Quick Start for New Agent

**Step 1: Create Agent Behavioral File** (.claude/agents/new-agent.md)
```markdown
---
allowed-tools: Read, Write, Edit
description: Brief description of agent purpose
model: sonnet-4.5
model-justification: "Task type and complexity rationale"
---

# New Agent

**YOU MUST perform these exact steps in sequence:**

## STEP 1 (REQUIRED BEFORE STEP 2) - Receive and Verify Inputs
[Input validation procedures]

## STEP 2 (REQUIRED BEFORE STEP 3) - Execute Core Task
[Task execution procedures]

## STEP 3 (ABSOLUTE REQUIREMENT) - Create Output Artifact
[File creation procedures with Write tool]

## STEP 4 (MANDATORY VERIFICATION) - Verify and Return
[Verification procedures and completion signal]
```

**Step 2: Invoke from Command**
```markdown
**EXECUTE NOW**: USE the Task tool to invoke new-agent.

Task {
  subagent_type: "general-purpose"
  description: "Task description"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/new-agent.md

    **Workflow-Specific Context**:
    - Input parameter 1: ${VALUE1}
    - Output path: ${ARTIFACT_PATH}

    Return: ARTIFACT_CREATED: ${ARTIFACT_PATH}
  "
}
```

**Step 3: Verify Integration**
- Check delegation rate: Agent executes when invoked
- Check file creation: Artifact appears at ARTIFACT_PATH
- Check metadata: extract_[type]_metadata() returns expected structure
- Check context usage: <30% across workflow

### Key Integration Checkpoints

**Before Invoking Agent:**
- ✓ Pre-calculate artifact path using artifact-creation.sh
- ✓ Verify parent directory exists (ensure_artifact_directory)
- ✓ Source required libraries in dependency order
- ✓ Validate state variables (verify_state_variable)

**Agent Invocation:**
- ✓ Use imperative instruction (**EXECUTE NOW**: USE the Task tool...)
- ✓ Reference behavioral file (.claude/agents/[name].md)
- ✓ Inject context (paths, parameters) not procedures
- ✓ No code block wrapper around Task invocation
- ✓ Require completion signal (ARTIFACT_CREATED: ${PATH})

**After Agent Completes:**
- ✓ Verify artifact exists (if [ ! -f "$PATH" ]; then error; fi)
- ✓ Verify artifact size (minimum 500 bytes for reports)
- ✓ Extract metadata (extract_[type]_metadata "$PATH")
- ✓ Prune full content (prune_subagent_output)
- ✓ Save checkpoint with metadata only

## References

**Core Documentation:**
- .claude/docs/concepts/patterns/behavioral-injection.md (Lines 1-1162) - Complete pattern with anti-patterns and case studies
- .claude/docs/guides/agent-development-guide.md (Lines 1-2175) - Comprehensive agent creation guide
- .claude/docs/reference/command_architecture_standards.md (Lines 1-2525) - Standards 0-16 architectural requirements
- .claude/agents/templates/sub-supervisor-template.md (Lines 1-597) - Hierarchical supervisor template
- .claude/agents/templates/README.md (Lines 1-78) - Template system overview

**Library References:**
- .claude/lib/metadata-extraction.sh - extract_report_metadata(), extract_plan_metadata()
- .claude/lib/plan-core-bundle.sh - parse_plan_file(), extract_phase_info()
- .claude/lib/context-pruning.sh - prune_subagent_output(), apply_pruning_policy()
- .claude/lib/workflow-llm-classifier.sh - classify_workflow_comprehensive()
- .claude/lib/workflow-state-machine.sh - sm_init(), sm_transition()
- .claude/lib/state-persistence.sh - save_workflow_state(), load_workflow_state()
- .claude/lib/error-handling.sh - handle_state_error()
- .claude/lib/verification-helpers.sh - verify_file_created(), verify_state_variable()
- .claude/lib/artifact-creation.sh - get_or_create_topic_dir(), create_topic_artifact()

**Pattern Documentation:**
- .claude/docs/concepts/patterns/metadata-extraction.md - 95% context reduction pattern
- .claude/docs/concepts/patterns/forward-message.md - Pass responses without re-summarization
- .claude/docs/concepts/patterns/hierarchical-supervision.md - Recursive coordination
- .claude/docs/concepts/patterns/verification-fallback.md - Fail-fast verification pattern
- .claude/docs/concepts/patterns/executable-documentation-separation.md - Two-file architecture

**Validation Tools:**
- .claude/tests/validate_executable_doc_separation.sh - Executable/guide separation validation
- .claude/scripts/validate-links-quick.sh - Internal link validation
- .claude/lib/validate-agent-invocation-pattern.sh - Agent delegation pattern validation
- .claude/tests/test_orchestration_commands.sh - Delegation rate testing

**Directory Organization:**
- .claude/docs/concepts/directory-protocols.md - Topic-based structure and artifact lifecycle
- .claude/README.md - Complete .claude/ directory structure guide
- CLAUDE.md (Lines 288-421) - Directory organization standards and decision matrix
