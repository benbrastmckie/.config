# Minimal Orchestration Patterns and Best Practices Research Report

## Metadata
- **Date**: 2025-11-02
- **Agent**: research-specialist
- **Topic**: Minimal orchestration patterns and best practices
- **Report Type**: codebase analysis | best practices | pattern recognition
- **Complexity Level**: 4

## Executive Summary

This research identifies design principles and best practices for maintaining minimal orchestration commands by analyzing the existing orchestration command ecosystem (/supervise: 1,938 lines, /coordinate: 1,930 lines, /orchestrate: 5,439 lines). The key finding is that /supervise and /coordinate achieve nearly identical line counts (~1,930-1,940 lines) despite different feature sets, while /orchestrate's 5,439-line implementation demonstrates feature bloat through experimental PR automation and dashboard tracking. The research reveals that minimal orchestration requires: (1) **Sequential execution only** - eliminating wave-based parallelization saves ~500 lines, (2) **Concise verification patterns** - single-character success indicators reduce 50+ lines to 1-2 lines per checkpoint achieving 90% token reduction, (3) **Fail-fast without fallbacks** - immediate termination on errors eliminates recovery infrastructure overhead, (4) **Library consolidation** - unified sourcing via workflow-initialization.sh reduces Phase 0 from 225 lines to ~10 lines, and (5) **External documentation** - moving usage guides and phase references out of command files prevents inline bloat. The /coordinate refactoring demonstrates the "integrate, not build" principle achieving 40-50% time savings by leveraging existing infrastructure rather than creating new libraries.

## Findings

### 1. Command Size Metrics and Comparison

**Line Count Analysis** (/home/benjamin/.config/.claude/commands/*.md):
- **/supervise**: 1,938 lines - Minimal reference implementation
- **/coordinate**: 1,930 lines - Production-ready with wave-based execution
- **/orchestrate**: 5,439 lines - Experimental with PR automation

**Key Observation**: /supervise and /coordinate are nearly identical in size (8-line difference, <0.5%) despite /coordinate including wave-based parallel execution. This demonstrates that wave-based execution adds minimal overhead when properly implemented through library delegation.

**Feature Bloat Sources in /orchestrate**:
- PR automation infrastructure: ~574 lines (github-specialist agent integration)
- Interactive progress dashboard: ~351 lines (ANSI terminal library)
- Comprehensive metrics tracking: Additional ~500+ lines
- **Total bloat**: ~1,425+ lines (26% of total file)

**Source**: Line counts verified via `wc -l` command; feature estimates from orchestration-best-practices.md:80-90

### 2. Design Principles for Minimal Orchestration

#### Principle 1: Sequential Execution Only (No Wave-Based Parallelization)

**Analysis**: /supervise uses sequential phase execution while /coordinate implements wave-based parallel execution via dependency-analyzer.sh. Surprisingly, both commands are ~1,930-1,940 lines, indicating wave-based execution overhead is absorbed by library delegation rather than inline code.

**Recommendation for /supervise**: **DO NOT adopt wave-based execution**. The feature requires:
- Dependency graph analysis (~150 lines when inlined)
- Wave calculation algorithms (Kahn's topological sort)
- Wave-level checkpointing infrastructure
- Parallel agent orchestration coordination

Minimal commands benefit from sequential execution's **simplicity** and **predictability** without the parallelization complexity.

**Evidence**: /supervise Phase 3 (lines 1139-1285) shows simple sequential implementer invocation vs /coordinate's wave calculation (coordinate.md:1240-1282).

#### Principle 2: Concise Verification Patterns

**Pattern**: orchestration-best-practices.md:952-1014 documents the "Concise Verification Pattern"

**Format**:
- **Success**: Single character `✓` (no newline) - Example: `Verifying research reports (3): ✓✓✓ (all passed)`
- **Failure**: Multi-line diagnostic with context (file path, expected vs found, diagnostic commands, root causes)

**Implementation**:
```bash
verify_file_created() {
  if [ -f "$file_path" ]; then
    echo -n "✓"  # Silent success
  else
    # Multi-line diagnostic output
    echo "VERIFICATION FAILED: $item_desc not created"
    # ... (full diagnostic template)
  fi
}
```

**Metrics** (orchestration-best-practices.md:1008-1012):
- Success output: 50+ lines → 1-2 lines per checkpoint (≥90% reduction)
- Token reduction: ≥3,150 tokens saved per workflow
- File creation reliability: >95% through proper agent invocation

**Adoption for /supervise**: **ADOPT FULLY** - /supervise currently uses verbose verification (supervise.md:650-770). Switching to concise pattern would save ~300-400 lines across all verification checkpoints (6 phases × 50-70 lines each).

**Source**: orchestration-best-practices.md:952-1014; coordinate.md:746-815 (verification helper functions)

#### Principle 3: Fail-Fast Without Fallback Mechanisms

**Philosophy** (verification-fallback.md:1-37):
- **NO retries**: Single execution attempt per operation
- **NO fallbacks**: If operation fails, report why and exit immediately
- **Clear diagnostics**: Every error shows exactly what failed and why
- **Debugging guidance**: Every error includes steps to diagnose the issue

**Rationale**:
1. **Predictable behavior**: No hidden retry loops masking root causes
2. **Easier debugging**: Clear failure point with no retry state confusion
3. **Faster feedback**: Immediate failure notification
4. **Simpler code**: Eliminates retry infrastructure and fallback mechanisms

**Current State**: /supervise implements fail-fast correctly (supervise.md:137-148, 163-183). **NO CHANGES NEEDED**.

**Source**: orchestration-best-practices.md:956, verification-fallback.md:1-100

#### Principle 4: Library Consolidation for Phase 0

**Pattern**: workflow-initialization.sh consolidates 225+ lines of path calculation into ~10 lines

**Comparison**:
- **Before consolidation**: Phase 0 STEPS 3-7 = 225+ lines (individual path calculations, directory creation, variable exports)
- **After consolidation**: Single function call `initialize_workflow_paths()` = ~10 lines

**Implementation** (supervise.md:531-562):
```bash
# Source workflow initialization library
if [ -f "$SCRIPT_DIR/../lib/workflow-initialization.sh" ]; then
  source "$SCRIPT_DIR/../lib/workflow-initialization.sh"
else
  echo "ERROR: workflow-initialization.sh not found"
  exit 1
fi

# Call unified initialization function (consolidates STEPS 3-7)
if ! initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE"; then
  echo "ERROR: Workflow initialization failed"
  exit 1
fi
```

**Benefits**:
- **85% token reduction**: 75,600 → 11,000 tokens (orchestration-best-practices.md:176-183)
- **25x speedup**: 25.2s → <1s for path pre-calculation
- **Lazy directory creation**: Only create directories when agents produce output
- **Maintainability**: Single source of truth for path calculation logic

**Adoption for /supervise**: **ALREADY ADOPTED** (supervise.md:531-562). NO CHANGES NEEDED.

**Source**: orchestration-best-practices.md:172-199; supervise.md:531-562; coordinate.md:679-745

#### Principle 5: External Documentation Ecosystem

**/supervise Unique Feature**: Comprehensive external documentation prevents inline bloat

**Documentation Structure**:
- **Usage Guide**: .claude/docs/guides/supervise-guide.md - Examples and common patterns
- **Phase Reference**: .claude/docs/reference/supervise-phases.md - Detailed phase documentation

**Benefits**:
1. **Prevents inline bloat**: Usage examples and detailed phase docs don't inflate command file
2. **Better organization**: Users consult docs for guidance, command file stays focused on execution
3. **Easier maintenance**: Update docs independently without touching command logic

**Evidence** (supervise.md:111-116, 395-402):
```markdown
## Workflow Overview

**DOCUMENTATION**: For complete usage guide, see [/supervise Usage Guide](../docs/guides/supervise-guide.md)
**PHASE REFERENCE**: For detailed phase documentation, see [/supervise Phase Reference](../docs/reference/supervise-phases.md)
```

**Comparison**: /coordinate and /orchestrate embed usage examples inline (coordinate.md:1827-1876, 405-476 example usage tables).

**Adoption for /supervise**: **ALREADY ADOPTED**. This pattern should be **PRESERVED** as it's a key differentiator preventing inline documentation bloat.

**Source**: supervise.md:111-116, 395-402, 1936-1939

### 3. Features /supervise Should Adopt from /coordinate

#### Feature 1: Concise Verification Pattern (HIGH PRIORITY)

**Status**: /coordinate implements (coordinate.md:746-815), /supervise does not

**Implementation Effort**: Medium (300-400 line reduction)

**Benefits**:
- 90% token reduction at verification checkpoints (6 phases × ~50-70 lines = 300-420 lines saved)
- Cleaner output on success (single-line vs multi-line per checkpoint)
- Comprehensive diagnostics on failure (preserved)

**Recommendation**: **ADOPT** - Highest ROI for minimal commands

#### Feature 2: Standardized Progress Markers

**Status**: Both commands implement `emit_progress()` function (supervise.md:192-199, coordinate.md:1016-1051)

**Format**: `PROGRESS: [Phase N] - [description]`

**Adoption for /supervise**: **ALREADY ADOPTED** via unified-logger.sh library. NO CHANGES NEEDED.

**Source**: orchestration-best-practices.md:1016-1056

#### Feature 3: Simplified Completion Summaries

**Pattern** (orchestration-best-practices.md:1059-1099):
- **Previous format**: 53 lines (workflow type, artifacts with sizes, plan overview, key findings, next steps)
- **Simplified format**: 8 lines (workflow scope, artifact counts, next step)
- **Reduction**: 85% reduction (700 tokens saved per workflow)

**Implementation** (supervise.md:240-271):
/supervise already implements simplified summaries via `display_brief_summary()` function. **NO CHANGES NEEDED**.

**Source**: orchestration-best-practices.md:1059-1099; supervise.md:240-271

### 4. Features /supervise Should NOT Adopt

#### Feature 1: Wave-Based Parallel Execution (DO NOT ADOPT)

**Rationale**: Adds complexity without significant size increase only because of library delegation. For minimal commands prioritizing **simplicity** and **predictability**, sequential execution is preferred.

**Complexity Added**:
- Dependency graph parsing and validation
- Wave calculation algorithms (topological sorting)
- Wave-level checkpoint management
- Parallel agent coordination logic
- Error handling across parallel executions

**Trade-off**: 40-60% time savings (coordinate) vs simplicity and debuggability (supervise)

**Recommendation**: **DO NOT ADOPT** - Complexity outweighs benefits for minimal reference implementation

**Source**: coordinate.md:186-243; orchestration-best-practices.md:56-74

#### Feature 2: PR Automation and GitHub Integration (DO NOT ADOPT)

**Rationale**: Experimental feature causing /orchestrate's 5,439-line bloat

**Components**:
- github-specialist agent integration (~574 lines)
- PR creation workflows
- GitHub API interaction logic
- Branch management and commit automation

**Status**: Experimental, may have inconsistent behavior (orchestration-best-practices.md:88-89)

**Recommendation**: **DO NOT ADOPT** - Feature bloat incompatible with minimal command philosophy

**Source**: orchestration-best-practices.md:83-90

#### Feature 3: Interactive Progress Dashboard (DO NOT ADOPT)

**Rationale**: ANSI terminal library adds ~351 lines for visual progress tracking

**Components**:
- Real-time progress dashboard rendering
- ANSI escape sequence handling
- Terminal state management
- Progress bar and spinner animations

**Trade-off**: Visual appeal vs minimal file size

**Recommendation**: **DO NOT ADOPT** - Visual features incompatible with minimal command philosophy. Standard `emit_progress()` markers sufficient for monitoring.

**Source**: orchestration-best-practices.md:59, 85-86

#### Feature 4: Comprehensive Metrics Tracking (DO NOT ADOPT)

**Rationale**: Adds ~500+ lines for workflow performance analysis

**Components**:
- Detailed timing metrics per phase
- Context usage tracking and reporting
- Token consumption analysis
- Performance comparison against baselines

**Trade-off**: Observability vs simplicity

**Recommendation**: **DO NOT ADOPT** - Metrics useful for optimization but unnecessary for minimal reference implementation. Basic checkpoint data sufficient.

**Source**: orchestration-best-practices.md:86-87

### 5. Code Organization Patterns for Minimal Commands

#### Pattern 1: Library-First Architecture

**Principle**: Delegate complex logic to libraries, keep command files focused on orchestration

**Examples from /supervise**:
- **workflow-initialization.sh**: Path calculation and directory creation (225 lines → 10 lines in command)
- **library-sourcing.sh**: Consolidated library loading (supervise.md:213-236)
- **workflow-detection.sh**: Scope detection and phase execution control
- **error-handling.sh**: Error classification and diagnostic generation
- **checkpoint-utils.sh**: Checkpoint save/restore operations

**Benefits**:
1. **Reusability**: Libraries shared across all orchestration commands
2. **Testability**: Library functions can be unit tested independently
3. **Maintainability**: Bug fixes in one place benefit all commands
4. **Readability**: Command files stay focused on workflow logic

**Recommendation**: **PRESERVE** - /supervise's library-first architecture is a best practice for minimal commands

**Source**: supervise.md:201-346 (library sourcing and function documentation)

#### Pattern 2: Inline Critical Templates Only

**Principle**: Keep agent invocation templates inline (execution-critical), extract reference documentation

**What stays inline** (command_architecture_standards.md:931):
- Agent invocation templates (Task tool calls with behavioral injection)
- Verification checkpoint templates
- Error diagnostic templates
- Bash execution blocks for path calculation

**What moves to external files**:
- Usage examples (→ docs/guides/supervise-guide.md)
- Phase documentation (→ docs/reference/supervise-phases.md)
- Best practices (→ docs/guides/orchestration-best-practices.md)
- Pattern explanations (→ docs/concepts/patterns/*.md)

**Current State**: /supervise correctly balances inline vs external content. **NO CHANGES NEEDED**.

**Source**: supervise.md:111-116, 395-402; command_architecture_standards.md:931-976

#### Pattern 3: Fail-Fast Library Sourcing

**Pattern** (supervise.md:213-236):
```bash
# Source library-sourcing utilities first
if [ -f "$SCRIPT_DIR/../lib/library-sourcing.sh" ]; then
  source "$SCRIPT_DIR/../lib/library-sourcing.sh"
else
  echo "ERROR: Required library not found: library-sourcing.sh"
  echo "Expected location: $SCRIPT_DIR/../lib/library-sourcing.sh"
  exit 1
fi

# Source all required libraries using consolidated function
if ! source_required_libraries; then
  # Error already reported by source_required_libraries()
  exit 1
fi
```

**Benefits**:
1. **Immediate failure**: Missing libraries detected before any execution
2. **Clear diagnostics**: Shows exact library file missing and expected location
3. **No silent degradation**: Command won't run with missing dependencies
4. **Consolidated sourcing**: Single function loads all required libraries

**Recommendation**: **PRESERVE** - Fail-fast library sourcing is best practice for minimal commands

**Source**: supervise.md:213-236

### 6. Testing and Verification Approaches for Minimal Commands

#### Approach 1: Integration Tests Over Unit Tests

**Rationale**: Minimal commands prioritize end-to-end workflow validation over granular function testing

**Test Strategy**:
1. **Workflow-level tests**: Verify complete Phase 0-6 execution for each workflow scope (research-only, research-and-plan, full-implementation, debug-only)
2. **File creation validation**: Verify all expected artifacts exist after workflow completion
3. **Checkpoint recovery tests**: Verify resume from each phase boundary
4. **Error handling tests**: Verify fail-fast behavior and diagnostic quality

**Test Location**: .claude/tests/test_orchestration_commands.sh

**Recommendation for /supervise**: **ADOPT** - Focus on integration tests validating complete workflows rather than isolated function tests

**Source**: orchestration-best-practices.md:330-332 (validation tools section)

#### Approach 2: Validation Tools for Architectural Compliance

**Tool**: .claude/lib/validate-agent-invocation-pattern.sh

**Purpose**: Detect anti-patterns in agent invocations (documentation-only YAML blocks, missing imperative instructions)

**Usage**:
```bash
# Validate agent invocations in command file
.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/supervise.md
```

**Validation Checks**:
1. All agent invocations use imperative pattern (`**EXECUTE NOW**: USE the Task tool...`)
2. No code block wrappers around Task invocations
3. Direct reference to agent behavioral files (`.claude/agents/*.md`)
4. Explicit completion signals (e.g., `REPORT_CREATED:`)

**Recommendation for /supervise**: **ADOPT** - Add validation to CI/CD pipeline to prevent architectural regressions

**Source**: CLAUDE.md:329-335 (validation tools section)

#### Approach 3: Fail-Fast Verification Philosophy

**Principle**: >95% success rate through proper agent invocation, no retry infrastructure

**Metrics** (orchestration-best-practices.md:1011-1012):
- File creation reliability: >95% through proper agent invocation
- Fail-fast exposes root causes immediately (no fallback masking)

**Testing Focus**:
1. **Agent invocation correctness**: Verify paths pre-calculated and injected into agent prompts
2. **Verification checkpoint coverage**: Every file creation has mandatory verification
3. **Diagnostic quality**: Error messages include context, expected vs found, diagnostic commands

**Recommendation for /supervise**: **PRESERVE** - Current fail-fast approach is correct, maintain >95% success through proper invocation rather than retry infrastructure

**Source**: orchestration-best-practices.md:956, 1008-1014

### 7. Documentation Standards for Simpler Commands

#### Standard 1: External Documentation Ecosystem (PRESERVE)

**Pattern**: /supervise uses external documentation to prevent inline bloat

**Structure**:
- **Usage Guide**: docs/guides/supervise-guide.md - Common workflows, examples, troubleshooting
- **Phase Reference**: docs/reference/supervise-phases.md - Detailed phase documentation with metrics
- **Command File**: commands/supervise.md - Execution logic only, references external docs

**Benefits**:
1. **Prevents bloat**: Usage examples don't inflate command file size
2. **Better discoverability**: Centralized docs easier to find and navigate
3. **Independent updates**: Docs updated without modifying command logic

**Comparison**: /coordinate embeds usage examples inline (405-476 lines example tables)

**Recommendation for /supervise**: **PRESERVE** - External documentation ecosystem is a best practice for minimal commands

**Source**: supervise.md:111-116, 395-402

#### Standard 2: Reference-OK vs Execution-Critical Comments

**Pattern** (supervise.md line comments):
- `[EXECUTION-CRITICAL: ...]` - Must be inline, cannot be externalized (agent templates, verification logic)
- `[REFERENCE-OK: ...]` - Can be moved to external docs (usage examples, best practices)

**Examples**:
```markdown
## Phase 1: Research
[EXECUTION-CRITICAL: Agent invocation patterns and verification - templates must be inline]

## Available Utility Functions
[REFERENCE-OK: Can be supplemented with external library documentation]
```

**Benefits**:
1. **Clear guidance**: Developers know what can/cannot be extracted
2. **Prevents over-extraction**: Execution-critical templates stay inline
3. **Enables cleanup**: Reference-OK sections can move to docs when needed

**Recommendation for /supervise**: **PRESERVE AND EXPAND** - Add more `[REFERENCE-OK]` markers to identify extractable content

**Source**: supervise.md:201, 348, 564, 884, 1139, 1285, 1402, 1778 (section comments)

#### Standard 3: Minimal Inline Examples

**Principle**: Inline examples limited to critical execution patterns only

**What stays inline**:
- Agent invocation syntax (1-2 examples)
- Verification checkpoint format (1 example)
- Error diagnostic template (1 example)

**What moves to external docs**:
- Multiple workflow examples (→ usage guide)
- Edge case handling examples (→ troubleshooting guide)
- Performance optimization examples (→ best practices guide)

**Current State**: /supervise follows this principle correctly. **NO CHANGES NEEDED**.

**Recommendation**: **PRESERVE** - Minimal inline examples keep command file focused

**Source**: supervise.md structure (execution templates inline, usage examples external)

## Recommendations

### Immediate Adoption (High ROI, Low Effort)

#### 1. Adopt Concise Verification Pattern (HIGH PRIORITY)

**Action**: Replace verbose verification blocks with concise pattern from /coordinate

**Implementation**:
1. Add `verify_file_created()` helper function to Phase 0 (coordinate.md:756-810)
2. Replace all verification blocks in Phases 1-6 with concise calls
3. Preserve multi-line diagnostics on failure (no change to error handling)

**Expected Impact**:
- **Line reduction**: ~300-400 lines (6 phases × 50-70 lines each)
- **Token reduction**: ~3,150 tokens per workflow
- **Readability**: Success output 90% more compact

**Effort**: Medium (2-3 hours to refactor all verification checkpoints)

**Priority**: HIGH - Highest ROI for minimal commands

**Source**: orchestration-best-practices.md:952-1014; coordinate.md:746-815

#### 2. Add Architectural Validation to CI/CD

**Action**: Integrate `.claude/lib/validate-agent-invocation-pattern.sh` into testing pipeline

**Implementation**:
```bash
# Add to .claude/tests/test_orchestration_commands.sh
test_supervise_architectural_compliance() {
  .claude/lib/validate-agent-invocation-pattern.sh .claude/commands/supervise.md
  assertEquals "Architectural validation passed" 0 $?
}
```

**Expected Impact**:
- Prevent anti-pattern regressions
- Enforce imperative agent invocation pattern
- Catch documentation-only YAML blocks

**Effort**: Low (1 hour to add test and CI integration)

**Priority**: MEDIUM - Prevents future architectural drift

**Source**: CLAUDE.md:329-335

### Preserve Current Patterns (No Changes)

#### 3. Preserve Sequential Execution (DO NOT ADD Wave-Based Parallelization)

**Rationale**: Simplicity and predictability outweigh 40-60% time savings for minimal reference implementation

**Action**: **NO CHANGES** - Keep Phase 3 sequential execution

**Trade-off Analysis**:
- **Benefits of parallelization**: 40-60% time savings on multi-phase implementations
- **Costs of parallelization**: Dependency analysis, wave calculation, parallel coordination complexity
- **Decision**: Minimal commands prioritize simplicity over performance

**Source**: orchestration-best-practices.md:56-74; coordinate.md:186-243

#### 4. Preserve External Documentation Ecosystem

**Rationale**: Prevents inline bloat, enables independent doc updates

**Action**: **NO CHANGES** - Maintain usage guide and phase reference as external files

**Benefits**:
- Command file stays focused on execution logic
- Documentation more discoverable and organized
- Updates independent of command changes

**Source**: supervise.md:111-116, 395-402

#### 5. Preserve Library-First Architecture

**Rationale**: Reusability, testability, maintainability

**Action**: **NO CHANGES** - Keep complex logic delegated to libraries

**Libraries Used**:
- workflow-initialization.sh (path calculation)
- library-sourcing.sh (consolidated loading)
- workflow-detection.sh (scope detection)
- error-handling.sh (diagnostics)
- checkpoint-utils.sh (state management)

**Source**: supervise.md:201-346

### Avoid Feature Bloat (Do Not Adopt)

#### 6. Do Not Adopt PR Automation

**Rationale**: Experimental feature causing 574-line bloat in /orchestrate

**Action**: **REJECT** - Do not add github-specialist agent integration

**Complexity**: PR creation workflows, GitHub API interaction, branch management

**Source**: orchestration-best-practices.md:83-90

#### 7. Do Not Adopt Interactive Progress Dashboard

**Rationale**: ANSI terminal library adds 351 lines for visual features

**Action**: **REJECT** - Standard `emit_progress()` markers sufficient

**Trade-off**: Visual appeal vs minimal file size

**Source**: orchestration-best-practices.md:59, 85-86

#### 8. Do Not Adopt Comprehensive Metrics Tracking

**Rationale**: Adds 500+ lines for performance analysis

**Action**: **REJECT** - Basic checkpoint data sufficient for minimal commands

**Trade-off**: Observability vs simplicity

**Source**: orchestration-best-practices.md:86-87

### Refactoring Methodology Lessons

#### 9. Apply "Integrate, Not Build" Principle

**Lesson from /coordinate refactoring** (coordinate.md:478-506):

**Original Plan**: 6 phases, 12-15 days
- Build new libraries for location detection, metadata extraction, context pruning
- Extract agent behavioral templates from scratch
- Create backup files for rollback safety

**Optimized Approach**: 3 phases, 8-11 days (40-50% reduction)
- **Integrate existing libraries** instead of rebuilding
- **Reference existing agent behavioral files** in `.claude/agents/` instead of extracting
- **Git provides version control** - eliminated unnecessary backup file creation

**Key Insights**:
1. **Infrastructure maturity eliminates redundant work**: 100% coverage on location detection, metadata extraction, context pruning
2. **Single-pass editing**: Consolidated 6 phases into 3 by combining related edits
3. **Realistic targets**: Adjusted from 1,600 lines (unrealistic 37% reduction) to 2,000 lines (realistic 21% reduction)

**Recommendation for /supervise refactoring**: **ADOPT** - Survey existing infrastructure before creating new components

**Source**: coordinate.md:478-506

## References

### Command Files
- /home/benjamin/.config/.claude/commands/supervise.md - 1,938 lines (minimal reference implementation)
- /home/benjamin/.config/.claude/commands/coordinate.md - 1,930 lines (production-ready with wave execution)
- /home/benjamin/.config/.claude/commands/orchestrate.md - 5,439 lines (experimental with PR automation)

### Documentation
- /home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md:1-200 - Unified 7-phase framework, Phase 0 optimization, command selection guide
- /home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md:950-1099 - Concise verification pattern, standardized progress markers, simplified completion summaries
- /home/benjamin/.config/.claude/docs/concepts/patterns/verification-fallback.md:1-100 - Fail-fast philosophy, MANDATORY VERIFICATION checkpoints, diagnostic standards
- /home/benjamin/.config/CLAUDE.md:320-335 - Hierarchical agent architecture, validation tools, troubleshooting guide references

### Libraries
- /home/benjamin/.config/.claude/lib/workflow-initialization.sh - Unified path calculation and directory creation (225 lines → 10 lines in command)
- /home/benjamin/.config/.claude/lib/library-sourcing.sh - Consolidated library loading with fail-fast error handling
- /home/benjamin/.config/.claude/lib/validate-agent-invocation-pattern.sh - Architectural compliance validation tool

### Architecture Standards
- /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md:931-976 - Standard 1: Executable instructions must be inline (EXECUTION-CRITICAL vs REFERENCE-OK)
