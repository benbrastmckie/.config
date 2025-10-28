# Orchestrator Command Best Practices Research Report

## Metadata
- **Date**: 2025-10-28
- **Agent**: research-specialist
- **Topic**: Best practices for orchestrator commands in Claude Code that call subagents
- **Report Type**: codebase analysis and best practices synthesis
- **Complexity Level**: 2

## Executive Summary

This report synthesizes best practices for orchestrator commands in Claude Code based on extensive codebase analysis, including behavioral injection patterns, context management, verification mechanisms, error handling, performance optimization, and anti-pattern avoidance. The research examines implementations across multiple orchestration commands (/orchestrate, /coordinate, /supervise, /research) and identifies patterns that achieve >90% agent delegation rates, 100% file creation reliability, and <30% context usage throughout complex workflows.

Key findings demonstrate that proper implementation of behavioral injection, metadata extraction, mandatory verification checkpoints, and fail-fast error handling enables orchestrator commands to coordinate 10+ specialized agents across 7-phase workflows while maintaining predictable performance and reliability.

## Findings

### 1. Behavioral Injection Patterns for Agent Invocation

**Pattern Definition**: Behavioral injection is the foundational pattern where orchestrating commands inject execution context, artifact paths, and role clarifications into agent prompts through structured data rather than tool invocations, transforming agents from autonomous executors into orchestrated workers.

**Core Implementation Requirements**:

1. **Role Clarification (Phase 0)**: Every orchestrator MUST explicitly declare its role before any agent invocations:
   - "YOU ARE THE ORCHESTRATOR. DO NOT execute yourself."
   - "YOUR ROLE: Calculate paths, invoke agents, aggregate results"
   - "DO NOT use Read/Grep/Write tools for implementation work"

2. **Path Pre-Calculation**: Calculate ALL artifact paths before agent invocation using unified location detection library:
   ```bash
   source .claude/lib/unified-location-detection.sh
   topic_dir=$(create_topic_structure "$workflow_description")
   report_path="$topic_dir/reports/001_subtopic.md"
   ```

3. **Context Injection Structure**: Pass calculated paths and parameters to agents via structured prompt injection:
   ```yaml
   prompt: |
     Read and follow: .claude/agents/research-specialist.md

     **Workflow-Specific Context**:
     - Research Topic: OAuth 2.0 authentication patterns
     - Output Path: /absolute/path/to/report.md
     - Project Standards: /path/to/CLAUDE.md
   ```

**Anti-Pattern Resolution**: The research identified three critical anti-patterns that cause 0% agent delegation rates:

- **Documentation-Only YAML Blocks**: YAML-style Task blocks wrapped in markdown code fences (` ```yaml`) are interpreted as documentation, not executable instructions. Solution: Remove code fences, add imperative directives like "**EXECUTE NOW**: USE the Task tool".

- **Undermining Disclaimers**: Following imperative directives with disclaimers like "Note: The actual implementation will generate N calls" contradicts the imperative, causing AI to interpret Task blocks as templates. Solution: Use "for each [item]" phrasing with `[insert value]` placeholders, no disclaimers.

- **Template Variables**: Using `${VARIABLE}` syntax in prompts without pre-calculation results in literal strings passed to agents. Solution: Pre-calculate all paths using Bash tool, then inject concrete values.

**Evidence from Codebase**:
- `.claude/docs/concepts/patterns/behavioral-injection.md:1-1160` - Complete pattern documentation with case studies
- `.claude/docs/reference/command_architecture_standards.md:1128-1307` - Standard 11: Imperative Agent Invocation Pattern
- `.claude/specs/497_unified_plan_coordinate_supervise_improvements/` - Unified fixes across all orchestration commands

**Historical Performance**:
- Spec 438 (2025-10-24): /supervise delegation rate 0% → >90% after removing 7 YAML code fences
- Spec 495 (2025-10-27): /coordinate delegation rate 0% → >90% after fixing 9 invocations + ~10 bash blocks
- Spec 495 (2025-10-27): /research delegation rate 0% → >90% after fixing 3 invocations

### 2. Context Management and Metadata Extraction

**Context Management Strategy**: Multi-technique approach achieving <30% context usage across 7-phase workflows:

**Technique 1: Metadata Extraction** (95-99% context reduction):
- Agents return condensed metadata (200-300 tokens) instead of full content (5,000-10,000 tokens)
- Required metadata fields: artifact_path, title, summary (50 words), key_findings (3 items), recommendations (3 items), file_paths
- Implementation: `.claude/lib/metadata-extraction.sh` provides `extract_report_metadata()` and `extract_plan_metadata()`

**Technique 2: Context Pruning** (96% reduction per phase):
- After phase completion, extract metadata and aggressively prune full content
- Utilities: `.claude/lib/context-pruning.sh` - `prune_subagent_output()`, `prune_phase_metadata()`, `apply_pruning_policy()`
- Policy types: aggressive (research-heavy), moderate (balanced), conservative (minimal pruning)

**Technique 3: Forward Message Pattern** (0 additional tokens):
- Pass metadata directly without re-summarization
- Anti-pattern: Supervisor paraphrasing agent metadata adds 500+ redundant tokens
- Correct pattern: `FORWARDING AGENT RESULTS: {metadata}` without interpretation

**Technique 4: Layered Context Architecture**:
```yaml
Layer 1 (Permanent): User request, workflow type, critical errors - 500-1,000 tokens
Layer 2 (Phase-Scoped): Current phase instructions, retained during phase only - 2,000-4,000 tokens
Layer 3 (Metadata): Artifact paths, phase summaries, retained between phases - 200-300 tokens/phase
Layer 4 (Transient): Full agent responses, pruned immediately - 0 tokens retained
```

**Technique 5: Checkpoint-Based State** (external storage):
- Store full state in `.claude/data/checkpoints/workflow_id.json`
- Prune state from active context after saving
- Load on-demand during recovery, extract only needed metadata

**Performance Impact**:
- Research phase (4 agents): 20,000 tokens → 1,000 tokens (95% reduction)
- 7-phase /orchestrate: 40,000 tokens (160% overflow) → 7,000 tokens (28% usage)
- Hierarchical (3 levels): 60,000 tokens (240% overflow) → 4,000 tokens (16% usage)

**Evidence from Codebase**:
- `.claude/docs/concepts/patterns/metadata-extraction.md:1-393` - Complete metadata extraction pattern
- `.claude/docs/concepts/patterns/context-management.md:1-290` - Comprehensive context management techniques
- `.claude/lib/metadata-extraction.sh` - Extraction utilities implementation
- `.claude/lib/context-pruning.sh` - Pruning utilities implementation

### 3. Verification and Fallback Patterns

**MANDATORY VERIFICATION Requirement**: 100% file creation rate achieved through defense-in-depth approach.

**Three-Layer Defense**:

**Layer 1: Agent Prompt Enforcement**:
- Mark file creation as "ABSOLUTE REQUIREMENT" or "PRIMARY OBLIGATION"
- Use sequential dependencies: "STEP 1 (REQUIRED BEFORE STEP 2)"
- Eliminate passive voice: "YOU MUST create" not "should create"
- Template enforcement: "THIS EXACT TEMPLATE (No modifications)"

**Layer 2: Agent Behavioral File Reinforcement**:
- Standard 0.5: Subagent Prompt Enforcement in `.claude/agents/*.md`
- 10-category enforcement rubric (target: 95+/100 score)
- Required completion criteria with explicit checklists
- "Why This Matters" context explaining enforcement rationale

**Layer 3: Command-Level Verification + Fallback**:
```markdown
**MANDATORY VERIFICATION** (EXECUTE AFTER AGENT RETURNS):

1. Verify file exists:
   ls -la "$report_path"
   [ -f "$report_path" ] || echo "ERROR: File missing"

2. Verify file size > 500 bytes:
   file_size=$(wc -c < "$report_path")
   [ "$file_size" -ge 500 ] || echo "WARNING: File too small"

3. IF VERIFICATION FAILS: Execute FALLBACK MECHANISM
   - Extract content from agent response
   - Create file using Write tool directly
   - Re-verify before proceeding
```

**Fallback Philosophy Distinction** (Critical from Spec 057):
- **Bootstrap Fallbacks** (REMOVED): Silent function definitions when libraries missing - Hide configuration errors that MUST be fixed
- **File Creation Verification Fallbacks** (PRESERVED): Detect transient Write tool failures where agent succeeded but file missing - Enable 100% reliability

**Performance Impact**:
- Without verification: 60-80% file creation reliability
- With verification: 100% file creation reliability
- Real metrics (Plan 077): /report 70% → 100%, /plan 60% → 100%, /implement 80% → 100%

**Evidence from Codebase**:
- `.claude/docs/concepts/patterns/verification-fallback.md:1-404` - Complete verification pattern
- `.claude/docs/reference/command_architecture_standards.md:419-929` - Standard 0.5: Subagent Prompt Enforcement
- Spec 057 case study: Bootstrap fallback removal vs file verification preservation

### 4. Error Handling and Recovery Strategies

**Fail-Fast Philosophy**: Configuration errors should fail immediately with diagnostic commands, not be masked by fallbacks.

**5-Component Error Message Standard**:
1. **What failed**: Specific operation that failed
2. **Expected state**: What should have happened (paths, variables)
3. **Diagnostic commands**: Exact commands to investigate (ls, cat, grep)
4. **Context**: Why this operation is required
5. **Action**: Steps to resolve the issue

**Example Enhanced Error Message**:
```bash
if ! source .claude/lib/workflow-detection.sh; then
  echo "ERROR: Failed to source workflow-detection.sh"
  echo "EXPECTED PATH: $SCRIPT_DIR/.claude/lib/workflow-detection.sh"
  echo "DIAGNOSTIC: ls -la $SCRIPT_DIR/.claude/lib/workflow-detection.sh"
  echo ""
  echo "CONTEXT: Library required for workflow scope detection"
  echo "ACTION: Verify library file exists and is readable"
  exit 1
fi
```

**Error Classification and Recovery**:

1. **Bootstrap Failures** (Fail-Fast):
   - Library sourcing failures
   - Function verification failures
   - SCRIPT_DIR validation errors
   - Solution: Exit immediately, no fallbacks

2. **Agent Invocation Failures** (Retry with Backoff):
   - Transient network/API errors
   - Temporary resource constraints
   - Solution: `.claude/lib/error-handling.sh` - `retry_with_backoff()` with exponential backoff (1s, 2s, 4s)

3. **File Creation Failures** (Verification + Fallback):
   - Write tool transient failures
   - Directory permission issues
   - Solution: MANDATORY VERIFICATION + fallback file creation from agent output

4. **Test Failures** (Debugging Loop, NOT Errors):
   - Expected workflow outcome, not error condition
   - Solution: Enter conditional debugging phase (max 3 iterations)

**Utility Integration**:
- `.claude/lib/error-handling.sh` - `retry_with_backoff()`, `classify_error()`, `format_error_report()`, `suggest_recovery()`
- `.claude/lib/checkpoint-utils.sh` - State preservation for recovery
- `.claude/lib/unified-logger.sh` - Structured error logging

**Evidence from Codebase**:
- `.claude/docs/guides/orchestration-troubleshooting.md:1-833` - Complete troubleshooting guide with 5 failure categories
- `.claude/agents/shared/error-handling-guidelines.md` - Error handling patterns
- Spec 057 case study: Removed 32 lines of bootstrap fallbacks, enhanced 7 library error messages

### 5. Performance Optimization Techniques

**Optimization 1: Unified Location Detection** (85% token reduction, 25x speedup):
- **Previous**: location-specialist agent (75.6k tokens, 25.2s)
- **Current**: `.claude/lib/unified-location-detection.sh` library (<11k tokens, <1s)
- **Benefit**: Orchestrator Phase 0 completes in <1s instead of ~25s

**Optimization 2: Parallel Agent Execution** (40-60% time savings):
- **Requirement**: Send ALL Task invocations in SINGLE message block
- **Anti-pattern**: Sending separate messages per agent breaks parallelization
- **Implementation**:
  ```markdown
  **CRITICAL**: Send ALL Task tool invocations in SINGLE message block.

  Task { ... agent 1 ... }
  Task { ... agent 2 ... }
  Task { ... agent 3 ... }
  ```

**Optimization 3: Wave-Based Implementation** (parallel execution with dependencies):
- Parse plan file for phase dependencies
- Group independent phases into waves
- Execute wave members in parallel, waves sequentially
- Result: 40-60% implementation time reduction

**Optimization 4: Metadata-Only Passing** (95% context reduction):
- Already covered in Context Management section
- Critical for scalability: Enables coordination of 10+ agents vs 2-3 without

**Optimization 5: Progress Streaming** (user experience, not performance):
- Emit `PROGRESS:` markers at phase transitions, agent invocations, long operations
- Format: `PROGRESS: [phase] - [action_description]`
- Frequency: Every major operation, every 30s for long operations
- Purpose: User visibility, debugging aid

**Performance Metrics**:
- Context usage: 80-100% → <30% (enabling 7-phase workflows)
- Agent coordination: 2-3 agents → 10+ agents per supervisor
- File creation rate: 60-80% → 100%
- Bootstrap time: ~25s → <1s (Phase 0)
- Implementation time: 40-60% reduction with wave-based parallel execution

**Evidence from Codebase**:
- `.claude/commands/orchestrate.md:419-466` - Unified location detection integration
- `.claude/docs/concepts/patterns/parallel-execution.md` - Wave-based parallel execution (referenced)
- Phase 0 optimization: Feature flag `USE_UNIFIED_LOCATION="${USE_UNIFIED_LOCATION:-true}"`

### 6. Common Anti-Patterns to Avoid

**Anti-Pattern 1: Documentation-Only YAML Blocks** (0% delegation rate):
- **Pattern**: Task invocations wrapped in ` ```yaml ... ``` ` code fences
- **Consequence**: Claude interprets as documentation examples, never executes
- **Detection**: Search for ` ```yaml` blocks without preceding "EXECUTE NOW" within 5 lines
- **Solution**: Remove code fences, add imperative directives
- **Evidence**: Spec 438 (7 blocks), Spec 495 (9 blocks in /coordinate, 3 in /research)

**Anti-Pattern 2: Priming Effect from Code-Fenced Examples** (0% delegation rate):
- **Pattern**: Early code-fenced Task examples establish "documentation interpretation" pattern
- **Consequence**: Subsequent unwrapped Task blocks also treated as non-executable
- **Detection**: Even single ` ```yaml` wrapper around example can establish priming effect
- **Solution**: Use HTML comments for clarifications, move examples to external reference files
- **Evidence**: Spec 469 case study - Lines 62-79 code-fenced example prevented execution of lines 350-400

**Anti-Pattern 3: Undermining Disclaimers** (0% delegation rate):
- **Pattern**: Following "EXECUTE NOW" with "Note: The actual implementation will generate N calls"
- **Consequence**: Disclaimer contradicts imperative, causing template assumption
- **Detection**: Search for "Note:" within 25 lines after "EXECUTE NOW" referencing "generate", "template"
- **Solution**: Use "for each [item]" phrasing, `[insert value]` placeholders, no disclaimers
- **Evidence**: Spec 502 case study - /supervise delegation failure

**Anti-Pattern 4: Reference-Only Sections** (execution failure):
- **Pattern**: Replacing execution steps with "See external file for details"
- **Consequence**: Command cannot execute without reading external files
- **Detection**: Sections with only "See:" references, no inline instructions
- **Solution**: Keep execution-critical content inline, use references for supplemental context only

**Anti-Pattern 5: Bootstrap Fallbacks** (hide configuration errors):
- **Pattern**: Silent fallback function definitions when libraries fail to source
- **Consequence**: Configuration errors hidden, inconsistent behavior across environments
- **Detection**: `if ! source ...; then function_name() { ... }; fi` patterns
- **Solution**: Remove fallbacks, fail-fast with diagnostic error messages
- **Evidence**: Spec 057 - Removed 32 lines of fallbacks, enhanced error messages

**Anti-Pattern 6: No Verification Checkpoints** (70% file creation reliability):
- **Pattern**: Agent invocation without post-execution file existence verification
- **Consequence**: Silent failures, cascading phase failures when files missing
- **Detection**: Agent invocations not followed by `ls -la`, `[ -f "$path" ]` checks
- **Solution**: Add MANDATORY VERIFICATION after every file creation operation

**Validation Tools**:
- `.claude/lib/validate-agent-invocation-pattern.sh` - Detects anti-patterns in command files
- `.claude/tests/test_orchestration_commands.sh` - Comprehensive delegation rate testing
- Automated detection patterns provided in documentation

**Evidence from Codebase**:
- `.claude/docs/concepts/patterns/behavioral-injection.md:322-615` - Complete anti-pattern documentation
- `.claude/docs/guides/orchestration-troubleshooting.md` - Section 2: Agent Delegation Issues

### 7. Directory Protocol Standards

**Topic-Based Directory Structure**: All workflow artifacts organized in single numbered topic directory.

**Standard Structure**:
```
.claude/specs/NNN_topic_name/
├── reports/         # Research reports (001_*.md, 002_*.md, ...)
├── plans/           # Implementation plans (001_*.md)
├── summaries/       # Workflow summaries (001_*.md)
├── debug/           # Debug reports (001_*.md, 002_*.md, ...)
├── scripts/         # Workflow-specific scripts
└── outputs/         # Execution outputs, logs
```

**Numbering Convention**:
- **Topic Number**: Next available NNN (001, 002, 003, ...) in specs/ directory
- **Artifact Numbers**: Sequential within each subdirectory (001, 002, 003, ...)
- **Topic Name**: Snake_case slug derived from workflow description

**Artifact Lifecycle**:
- **Reports**: Created during research phase, gitignored
- **Plans**: Created during planning phase, gitignored
- **Summaries**: Created at workflow completion, gitignored
- **Debug Reports**: Created during debugging phase, committed to git (for audit trail)

**Location Detection**:
- **Library**: `.claude/lib/unified-location-detection.sh`
- **Function**: `perform_location_detection()`
- **Returns**: JSON with topic_path, topic_number, topic_name, artifact_paths
- **Integration**: Phase 0 of all orchestration commands

**Path Pre-Calculation Pattern**:
```bash
source .claude/lib/unified-location-detection.sh
topic_dir=$(create_topic_structure "$workflow_description")

# Pre-calculate all artifact paths
report_path="$topic_dir/reports/001_oauth_patterns.md"
plan_path="$topic_dir/plans/001_implementation.md"
summary_path="$topic_dir/summaries/001_workflow_summary.md"

# Inject into agent prompts
```

**Benefits**:
- **Single source of truth**: All workflow artifacts in one directory
- **Easy navigation**: Numbered topics with descriptive names
- **Gitignore compliance**: Working artifacts excluded, debug reports committed
- **Artifact ownership**: Clear which workflow created each artifact

**Evidence from Codebase**:
- `.claude/docs/concepts/directory-protocols.md` (referenced in CLAUDE.md)
- `.claude/lib/unified-location-detection.sh` - Location detection library
- `.claude/commands/orchestrate.md:390-500` - Phase 0 location determination

## Recommendations

### Recommendation 1: Implement Standard 11 Compliance Across All Orchestration Commands

**Action**: Ensure all orchestration commands (/orchestrate, /coordinate, /supervise, /research, and any future commands) use the imperative agent invocation pattern with no documentation-only YAML blocks.

**Rationale**: Historical data shows 0% → >90% delegation rate improvement across three separate specs (438, 495, 502) when this pattern is properly applied.

**Implementation Steps**:
1. Run validation script: `.claude/lib/validate-agent-invocation-pattern.sh` on all command files
2. Fix any detected anti-patterns using transformation guidelines from behavioral-injection.md
3. Add validation to CI/CD pipeline to prevent regression
4. Include delegation rate tests in pre-commit hooks

**Success Metrics**:
- Delegation rate >90% for all orchestration commands
- Zero TODO*.md files created during execution
- 100% file creation in correct specs/NNN_topic/ directories

### Recommendation 2: Enforce MANDATORY VERIFICATION Checkpoints for All File Creation Operations

**Action**: Implement three-layer defense-in-depth approach (agent prompt enforcement + behavioral file reinforcement + command-level verification + fallback) for all operations that create files.

**Rationale**: Achieves 100% file creation reliability (vs 60-80% without verification) based on Plan 077 metrics.

**Implementation Steps**:
1. Add MANDATORY VERIFICATION blocks after every agent invocation that creates files
2. Enhance agent behavioral files (.claude/agents/*.md) with Standard 0.5 enforcement patterns
3. Implement fallback file creation when verification fails
4. Test file creation reliability across 10 workflow executions (target: 10/10 success)

**Success Metrics**:
- File creation reliability: 100% (10/10 test runs)
- Zero cascading phase failures due to missing files
- Verification checkpoint execution visible in logs

### Recommendation 3: Adopt Context Management Best Practices to Maintain <30% Context Usage

**Action**: Implement layered context architecture with aggressive pruning, metadata extraction, and forward message passing across all multi-phase workflows.

**Rationale**: Enables 7-phase workflows within context limits that would otherwise accommodate only 2-3 phases. Demonstrated 82-95% context reduction in real workflows.

**Implementation Steps**:
1. Update all agents to return metadata-only (200-300 tokens) instead of full content
2. Implement context pruning after each phase completion using `.claude/lib/context-pruning.sh`
3. Use forward message pattern (no re-summarization) when passing metadata between phases
4. Implement layered context architecture (permanent, phase-scoped, metadata, transient)
5. Store full state in checkpoints, load on-demand

**Success Metrics**:
- Context usage <30% across entire 7-phase workflow
- Ability to coordinate 10+ agents per supervisor (vs 2-3 without optimization)
- 100% workflow completion rate (no context overflows)

## References

### Primary Documentation Files
- `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md` - Behavioral injection pattern (1,160 lines)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/verification-fallback.md` - Verification and fallback pattern (404 lines)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/metadata-extraction.md` - Metadata extraction pattern (393 lines)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/context-management.md` - Context management pattern (290 lines)
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` - Command architecture standards (2,032 lines analyzed)
- `/home/benjamin/.config/.claude/docs/guides/orchestration-troubleshooting.md` - Orchestration troubleshooting guide (833 lines)

### Implementation References
- `/home/benjamin/.config/.claude/commands/orchestrate.md` - Reference implementation (lines 1-500 analyzed)
- `/home/benjamin/.config/.claude/agents/research-specialist.md` - Agent behavioral file example (671 lines)
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` - Location detection library
- `/home/benjamin/.config/.claude/lib/metadata-extraction.sh` - Metadata extraction utilities
- `/home/benjamin/.config/.claude/lib/context-pruning.sh` - Context pruning utilities
- `/home/benjamin/.config/.claude/lib/error-handling.sh` - Error handling utilities

### Case Studies and Specifications
- Spec 438 (2025-10-24): /supervise agent delegation fix (0% → >90% delegation rate)
- Spec 495 (2025-10-27): /coordinate and /research delegation failures (9 + 3 invocations fixed)
- Spec 057 (2025-10-27): /supervise robustness improvements (fail-fast philosophy)
- Spec 497 (2025-10-27): Unified orchestration improvements (all commands validated)
- Spec 502: /supervise undermined imperative pattern discovery
- Spec 469: /supervise code-fenced example priming effect

### Validation and Testing Tools
- `/home/benjamin/.config/.claude/lib/validate-agent-invocation-pattern.sh` - Anti-pattern detection
- `/home/benjamin/.config/.claude/tests/test_orchestration_commands.sh` - Comprehensive test suite
- `/home/benjamin/.config/.claude/tests/test_subagent_enforcement.sh` - Agent enforcement validation

### Related Standards
- CLAUDE.md - Project configuration (sections: directory_protocols, testing_protocols, hierarchical_agent_architecture)
- Standard 0: Execution Enforcement (Imperative vs Descriptive Language)
- Standard 0.5: Subagent Prompt Enforcement (10-category enforcement rubric)
- Standard 11: Imperative Agent Invocation Pattern (no documentation-only YAML blocks)
- Standard 12: Structural vs Behavioral Content Separation (inline templates vs referenced behavioral content)
