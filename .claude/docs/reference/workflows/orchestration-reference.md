# Orchestration Reference

Comprehensive reference for all orchestration commands, patterns, and best practices. This consolidated guide combines command syntax, invocation patterns, performance metrics, and troubleshooting guidance.

**Quick Navigation**:
- [Section 1: Command Quick Reference](#section-1-command-quick-reference) - Syntax and common usage
- [Section 2: Command Comparison](#section-2-command-comparison) - When to use each command
- [Section 3: Pattern Library](#section-3-pattern-library) - Reusable templates
- [Section 4: Performance Metrics](#section-4-performance-metrics) - Benchmarks and optimization
- [Section 5: Alternative Patterns](#section-5-alternative-patterns) - Sequential vs parallel approaches

---

## Section 1: Command Quick Reference

### Commands Overview

| Command | Purpose | Phases | Delegation Rate | Use Case |
|---------|---------|--------|-----------------|----------|
| `/build` | Wave-based implementation | 4 | >90% | Execute implementation plans with parallel phases |
| `/plan` | Research-driven planning | 3 | >90% | Create implementation plans with research |
| `/research` | Hierarchical research | 2 | >90% | Deep topic investigation with automatic decomposition |
| `/debug` | Issue investigation | 3 | >90% | Root cause analysis and bug fixing |

**Note**: `/coordinate`, `/orchestrate`, and `/supervise` have been archived. Use `/build` for implementation workflows.

**Common Features**:
- Parallel research (2-4 agents)
- Automated complexity evaluation
- Conditional debugging
- <30% context usage
- 100% file creation reliability

### Basic Usage

```bash
# Research a topic
/research "API authentication patterns and best practices"

# Create implementation plan
/plan "implement OAuth 2.0 authentication"

# Build from plan
/build specs/plans/NNN_oauth_implementation.md

# Debug an issue
/debug "authentication tokens expiring prematurely"
```

### Common Options

```bash
# Dry run (validate without execution)
/coordinate "test workflow" --dry-run

# Specify output location
/research "topic" --output-dir specs/custom_location

# Resume from checkpoint
/coordinate "workflow" --resume

# Create PR after completion
/orchestrate "feature" --create-pr

# Enable dashboard tracking
/orchestrate "feature" --dashboard
```

### Workflow Phases

All orchestration commands follow this 7-phase structure:

```
Phase 0: Location Detection (85% reduction, 25x speedup)
  ↓
Phase 1: Research (2-4 parallel agents, metadata extraction)
  ↓
Phase 2: Planning (complexity evaluation, forward message pattern)
  ↓
Phase 3: Implementation (wave-based parallel, 40-60% savings)
  ↓
Phase 4: Testing (per Testing Protocols, conditional)
  ↓
Phase 5: Debugging (conditional, parallel investigations)
  ↓
Phase 6: Documentation (summary + cross-references)
  ↓
Phase 7: Summary (artifact lifecycle tracking)
```

### Agent Invocation Pattern

#### Correct Pattern (Imperative)

```markdown
**EXECUTE NOW**: USE the Bash tool to calculate paths:

```bash
source .claude/lib/core/unified-location-detection.sh
topic_dir=$(create_topic_structure "topic_name")
report_path="$topic_dir/reports/001_subtopic.md"
echo "REPORT_PATH: $report_path"
```

**EXECUTE NOW**: USE the Task tool with these parameters:

- subagent_type: "general-purpose"
- description: "Research authentication patterns"
- prompt: |
    Read and follow: .claude/agents/research-specialist.md

    Research topic: Authentication patterns for REST APIs
    Output file: [insert $report_path from above]

**MANDATORY VERIFICATION**: After agent returns:

```bash
ls -la "$report_path"
[ -f "$report_path" ] || echo "ERROR: File missing"
```

**WAIT FOR**: Agent to return REPORT_CREATED: $report_path
```

#### Anti-Pattern (Documentation-Only)

```markdown
❌ INCORRECT - Do not use this pattern:

The research phase invokes agents:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC}"
  prompt: "..."
}
```
```

**Problem**: Code fence wrapper prevents execution (0% delegation rate).

**Fix**: Remove code fences, add `**EXECUTE NOW**` directives. See [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md).

### Troubleshooting Quick Checks

#### 1. Command Starts?

```bash
/command-name "test" 2>&1 | head -20
```

**Look for**: Library sourcing errors, function verification failures

**Fix**: Check `.claude/lib/` exists, verify SCRIPT_DIR

#### 2. Agents Delegating?

```bash
/command-name "test" 2>&1 | grep "PROGRESS:"
```

**Look for**: PROGRESS: markers (indicates agent execution)

**Fix**: Run `.claude/lib/util/validate-agent-invocation-pattern.sh`

#### 3. Files Created?

```bash
find .claude/specs -name "*.md" -mmin -5
ls .claude/TODO*.md 2>/dev/null
```

**Look for**: Files in `specs/NNN_topic/`, NO TODO files

**Fix**: Add MANDATORY VERIFICATION checkpoints

#### 4. Validation Passing?

```bash
./.claude/tests/test_orchestration_commands.sh
```

**Look for**: All 12 tests passing (0 failures)

**Fix**: See error messages for specific issues

### Common Problems & Solutions

#### Problem: 0% Delegation Rate

**Symptoms**:
- No PROGRESS: markers
- Output in TODO1.md files
- No reports created

**Diagnosis**:
```bash
./.claude/lib/util/validate-agent-invocation-pattern.sh .claude/commands/command-name.md
```

**Solution**: Remove code fences around Task invocations, add `**EXECUTE NOW**` directives

**Details**: See [Agent Delegation Troubleshooting](../troubleshooting/agent-delegation-troubleshooting.md)

#### Problem: Bootstrap Failure

**Symptoms**:
- Command exits immediately
- "Failed to source" errors

**Diagnosis**:
```bash
ls -la .claude/lib/
source .claude/lib/library-name.sh
```

**Solution**: Verify library files exist and are readable

---

## Section 2: Command Comparison

**For detailed command selection guidance with maturity status, see [Command Selection Guide](../guides/orchestration/orchestration-best-practices.md#command-selection)**

**Quick Recommendation**: Use **/build** for implementation workflows and **/plan** for planning. The former `/coordinate` command has been archived - its functionality is now available through `/build` and `/plan`.

### Decision Matrix

Use this matrix to choose the right orchestration command for your workflow:

| Criteria | /research | /coordinate | /supervise | /orchestrate |
|----------|-----------|-------------|------------|--------------|
| **Primary Use** | Investigation | Parallel workflow | Sequential workflow | Full automation (experimental) |
| **Maturity** | Production | **Production-Ready** | In Development | In Development |
| **Phases** | 4 (research-focused) | 7 (all phases) | 7 (all phases) | 7 (all phases) |
| **Parallelization** | Research only | Wave-based | Sequential | Wave-based |
| **Time Savings** | N/A | 40-60% | Baseline | 40-60% (when stable) |
| **PR Automation** | No | No | No | Yes (experimental) |
| **Dashboard** | No | No | No | Yes (experimental) |
| **Complexity** | Simple | Medium | Medium | High |
| **Best For** | Deep research | **Production workflows (recommended)** | Learning/reference | Experimenting with PR features |

### When to Use Each Command

#### /research

**Use When**:
- Need deep investigation before planning
- Exploring unfamiliar domain or technology
- Gathering evidence for architectural decisions
- Research outputs will inform future work

**Don't Use When**:
- You already know what to implement
- Implementation is straightforward
- Time-sensitive delivery

**Output**: 2-4 research reports + overview in `specs/NNN_topic/reports/`

#### /coordinate (Production-Ready ✓)

**Status**: Stable, tested, production-ready. **Recommended for all workflows.**

**Use When**:
- Any production workflow (default choice)
- Fast delivery is priority
- Implementation has independent phases
- Want wave-based parallelization
- Standard workflow sufficient

**Don't Use When**:
- Need experimental PR automation features (try /orchestrate, expect instability)
- Need experimental dashboard tracking (try /orchestrate, expect instability)

**Output**: Full 7-phase workflow with 40-60% time savings via parallel execution

#### /supervise (In Development ⚠️)

**Status**: Being stabilized, not yet production-ready. Use /coordinate instead for reliable workflows.

**Use When**:
- Studying minimal reference implementation
- Learning orchestration patterns
- Architectural reference needed

**Don't Use When**:
- Production implementation workflows (use /build)
- Speed is critical (use /build for parallel execution)

**Output**: Full 7-phase workflow with reports, plan, implementation, tests, docs

#### /orchestrate (In Development ⚠️)

**Status**: Experimental features may have inconsistent behavior. Not recommended for production use until stabilized.

**Use When**:
- Experimenting with PR automation features
- Testing dashboard progress tracking
- Evaluating comprehensive metrics collection

**Don't Use When**:
- Production implementation workflows (use /build)
- Reliable delivery required (use /build)
- Simple workflows (use /plan or /research)

**Output**: Full workflow + PR (experimental) + dashboard (experimental) + metrics (experimental)

### Feature Comparison

| Feature | /research | /supervise | /coordinate | /orchestrate |
|---------|-----------|------------|-------------|--------------|
| **Phase 0 Optimization** | ✓ | ✓ | ✓ | ✓ |
| **Parallel Research** | ✓ (2-4 agents) | ✓ (2-4 agents) | ✓ (2-4 agents) | ✓ (2-4 agents) |
| **Metadata Extraction** | ✓ | ✓ | ✓ | ✓ |
| **Forward Message Pattern** | ✓ | ✓ | ✓ | ✓ |
| **Wave-Based Implementation** | ✗ | ✗ | ✓ | ✓ |
| **Dependency Analysis** | ✗ | ✗ | ✓ | ✓ |
| **Checkpoint Recovery** | ✗ | ✓ | ✓ | ✓ |
| **Adaptive Planning** | ✗ | ✓ | ✓ | ✓ |
| **PR Automation** | ✗ | ✗ | Optional (--create-pr) | ✓ (default) |
| **Dashboard Tracking** | ✗ | ✗ | ✗ | ✓ |
| **Scope Detection** | ✓ | ✓ | ✓ | ✓ |
| **Context Budget** | <30% | <30% | <30% | <30% |
| **Delegation Rate** | >90% | >90% | >90% | >90% |

---

## Section 3: Pattern Library

### Research Agent Prompt Template

Use this template for each research-specialist agent invocation. Substitute placeholders before invoking.

**Placeholders**:
- `[THINKING_MODE]`: Value from complexity analysis (think, think hard, think harder, or empty)
- `[TOPIC_TITLE]`: Research topic title (e.g., "Authentication Patterns in Codebase")
- `[USER_WORKFLOW]`: Original user workflow description (1 line)
- `[PROJECT_NAME]`: Generated project name slug
- `[TOPIC_SLUG]`: Generated topic slug
- `[SPECS_DIR]`: Path to specs directory
- `[ABSOLUTE_REPORT_PATH]`: ABSOLUTE path for report file (CRITICAL - must be absolute)
- `[COMPLEXITY_LEVEL]`: Simple|Medium|Complex|Critical
- `[SPECIFIC_REQUIREMENTS]`: What this agent should investigate

**Template**:

```markdown
**Thinking Mode**: [THINKING_MODE]

# Research Task: [TOPIC_TITLE]

## Context
- **Workflow**: [USER_WORKFLOW]
- **Project Name**: [PROJECT_NAME]
- **Topic Slug**: [TOPIC_SLUG]
- **Research Focus**: [SPECIFIC_REQUIREMENTS]
- **Project Standards**: /home/benjamin/.config/CLAUDE.md
- **Complexity Level**: [COMPLEXITY_LEVEL]

## Objective
Investigate [SPECIFIC_REQUIREMENTS] to inform planning and implementation phases.

## Specs Directory Context
- **Specs Directory Detection**:
  1. Check .claude/SPECS.md for registered specs directories
  2. If no SPECS.md, use Glob to find existing specs/ directories
  3. Default to project root specs/ if none found
- **Report Location**: Create report in [SPECS_DIR]/reports/[TOPIC_SLUG]/NNN_report_name.md
- **Include in Metadata**: Add "Specs Directory" field to report metadata

## Research Requirements

[SPECIFIC_REQUIREMENTS - Agent should investigate these areas:]

### For "existing_patterns" Topics:
- Search codebase for related implementations using Grep/Glob
- Read relevant source files to understand current patterns
- Identify architectural decisions and design patterns used
- Document file locations with line number references
- Note any inconsistencies or technical debt

### For "best_practices" Topics:
- Use WebSearch to find 2025-current best practices
- Focus on authoritative sources (official docs, security guides)
- Compare industry standards with current implementation
- Identify gaps between best practices and current state
- Recommend specific improvements

### For "alternatives" Topics:
- Research 2-3 alternative implementation approaches
- Document pros/cons of each alternative
- Consider trade-offs (performance, complexity, maintainability)
- Recommend which alternative best fits this project
- Provide concrete examples from similar projects

### For "constraints" Topics:
- Identify technical limitations (platform, dependencies, performance)
- Document security considerations and requirements
- Note compatibility requirements (backwards compatibility, API contracts)
- Consider resource constraints (time, team expertise, infrastructure)
- Flag high-risk areas requiring careful design

## Report File Creation

You MUST create a research report file using the Write tool. Do NOT return only a summary.

**CRITICAL: Use the Provided Absolute Path**:

The orchestrator has calculated an ABSOLUTE report file path for you. You MUST use this exact path when creating the report file:

**Report Path**: [ABSOLUTE_REPORT_PATH]

Example: `/home/benjamin/.config/.claude/specs/reports/orchestrate_improvements/001_existing_patterns.md`

Do NOT calculate your own path. Use the exact path provided above.

## Metadata

Include this metadata at the top of your report:

```markdown
# [TOPIC_TITLE]

## Metadata
- **Date**: [Current date YYYY-MM-DD]
- **Research Focus**: [SPECIFIC_REQUIREMENTS]
- **Complexity**: [COMPLEXITY_LEVEL]
- **Specs Directory**: [SPECS_DIR]
- **Workflow**: [USER_WORKFLOW]
```

## Return Format

After creating the report file, return:

```
REPORT_CREATED: [ABSOLUTE_REPORT_PATH]
```
```

### Plan Architect Prompt Template

Use this template for plan-architect agent invocation.

**Placeholders**:
- `[THINKING_MODE]`: Complexity-based thinking mode
- `[FEATURE_DESCRIPTION]`: User's feature description
- `[PROJECT_NAME]`: Generated project name
- `[TOPIC_SLUG]`: Generated topic slug
- `[ABSOLUTE_PLAN_PATH]`: Pre-calculated plan file path
- `[REPORT_PATHS]`: Array of research report paths (if any)
- `[COMPLEXITY_LEVEL]`: Overall workflow complexity
- `[STANDARDS_FILE]`: Path to CLAUDE.md

**Template**:

```markdown
**Thinking Mode**: [THINKING_MODE]

# Planning Task: [FEATURE_DESCRIPTION]

## Context
- **Feature**: [FEATURE_DESCRIPTION]
- **Project**: [PROJECT_NAME]
- **Topic**: [TOPIC_SLUG]
- **Complexity**: [COMPLEXITY_LEVEL]
- **Standards**: [STANDARDS_FILE]

## Research Integration

[If reports exist:]
The following research reports were created in Phase 1. Read these reports to inform your plan:

[For each report:]
- **Report [N]**: [ABSOLUTE_PATH]
  - Focus: [Brief description]
  - Key findings: [To be extracted from metadata]

Use these research findings to:
1. Identify implementation approach
2. Understand constraints and requirements
3. Choose appropriate design patterns
4. Plan risk mitigation strategies

[If no reports:]
No research phase was conducted. Create plan based on feature description and project standards.

## Plan File Creation

You MUST create an implementation plan file using the Write tool.

**CRITICAL: Use the Provided Absolute Path**:

**Plan Path**: [ABSOLUTE_PLAN_PATH]

Example: `/home/benjamin/.config/.claude/specs/plans/auth_implementation/001_implementation_plan.md`

Do NOT calculate your own path. Use the exact path provided above.

## Plan Structure

Follow the standard implementation plan structure:

```markdown
# [FEATURE_DESCRIPTION] Implementation Plan

## Metadata
- **Date**: [YYYY-MM-DD]
- **Feature**: [FEATURE_DESCRIPTION]
- **Complexity Score**: [Calculated score]
- **Estimated Hours**: [Estimate]
- **Structure Level**: 0 (inline phases)
- **Standards File**: [STANDARDS_FILE]
- **Research Reports**:
  [List of report paths]

## Overview

[1-2 paragraphs describing the feature and approach]

## Research Summary

[If reports exist: 1 paragraph per report summarizing key findings]
[If no reports: "No research phase conducted"]

## Success Criteria

- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

## Technical Design

[Architecture decisions, design patterns, key components]

## Implementation Phases

### Phase 1: [Phase Name]
dependencies: []

**Objective**: [What this phase accomplishes]

**Complexity**: [Low|Medium|High]

**Tasks**:
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

**Testing**:
```bash
# Verification commands
```

**Expected Duration**: [N hours]

### Phase 2: [Phase Name]
dependencies: [1]

[Similar structure...]

## Testing Strategy

[How to verify implementation]

## Documentation Requirements

[What documentation needs to be created/updated]

## Dependencies

[Internal and external dependencies]

## Risk Mitigation

[Potential risks and mitigation strategies]
```

## Return Format

After creating the plan file, return:

```
PLAN_CREATED: [ABSOLUTE_PLAN_PATH]
PHASES: [N]
COMPLEXITY: [Score]
```
```

### Implementation Agent Prompt Template

Use this template for code-writer/implementer agent invocation.

**Placeholders**:
- `[THINKING_MODE]`: Complexity-based thinking mode
- `[PHASE_NUMBER]`: Current phase number
- `[PHASE_NAME]`: Phase name
- `[PHASE_OBJECTIVE]`: What this phase accomplishes
- `[PHASE_TASKS]`: Bulleted list of tasks
- `[PLAN_PATH]`: Path to implementation plan
- `[STANDARDS_FILE]`: Path to CLAUDE.md
- `[TEST_COMMANDS]`: Test commands from phase

**Template**:

```markdown
**Thinking Mode**: [THINKING_MODE]

# Implementation Task: Phase [PHASE_NUMBER] - [PHASE_NAME]

## Context
- **Plan**: [PLAN_PATH]
- **Phase**: [PHASE_NUMBER] of [TOTAL_PHASES]
- **Objective**: [PHASE_OBJECTIVE]
- **Standards**: [STANDARDS_FILE]

## Phase Tasks

[PHASE_TASKS - Bulleted list]

## Implementation Requirements

1. **Follow Standards**: Apply coding standards from [STANDARDS_FILE]
2. **Test As You Go**: Run tests after each significant change
3. **Document Changes**: Add comments for complex logic
4. **Verify Success**: Ensure all phase tasks are completed

## Testing

After completing implementation, run these tests:

```bash
[TEST_COMMANDS from phase]
```

All tests must pass before marking phase complete.

## Standards Compliance

Before completing, verify:
- [ ] Code style matches project standards (indentation, naming)
- [ ] Error handling follows project patterns
- [ ] Documentation meets policy requirements
- [ ] Tests added for new functionality

## Return Format

After completing all tasks and verifying tests pass:

```
PHASE_COMPLETE: [PHASE_NUMBER]
FILES_MODIFIED: [List of modified files]
TESTS_PASSED: true
```
```

### Verification Checkpoint Pattern

Use this pattern after every agent invocation to ensure artifacts were created.

**Template**:

```markdown
**MANDATORY VERIFICATION**: Verify artifact creation

```bash
# Check if artifact exists
if [ ! -f "[ARTIFACT_PATH]" ]; then
  echo "ERROR: Artifact not found at expected path: [ARTIFACT_PATH]"
  echo "Searching for artifact..."

  # Search for artifact by name pattern
  FOUND_PATH=$(find specs -name "[ARTIFACT_NAME_PATTERN]" -type f -mmin -5 | head -1)

  if [ -n "$FOUND_PATH" ]; then
    echo "RECOVERED: Found artifact at: $FOUND_PATH"
    echo "Moving to expected location..."
    mkdir -p "$(dirname '[ARTIFACT_PATH]')"
    mv "$FOUND_PATH" "[ARTIFACT_PATH]"
    echo "VERIFICATION: Artifact recovered and relocated"
  else
    echo "FATAL: Artifact not found anywhere. Agent may have failed."
    exit 1
  fi
else
  echo "VERIFICATION: Artifact found at expected path"
  ls -lh "[ARTIFACT_PATH]"
fi
```
```

---

## Section 4: Performance Metrics

### Context Budget Management

All orchestration commands target <30% total context usage through aggressive optimization:

| Phase | Before Optimization | After Optimization | Reduction |
|-------|---------------------|-------------------|-----------|
| Phase 0: Location Detection | ~12,000 tokens | ~1,800 tokens | 85% |
| Phase 1: Research | ~20,000 tokens | ~2,000 tokens | 90% |
| Phase 2: Planning | ~15,000 tokens | ~1,500 tokens | 90% |
| Phase 3: Implementation | ~25,000 tokens | ~8,000 tokens | 68% |
| Phase 4: Testing | ~5,000 tokens | ~1,000 tokens | 80% |
| Phase 5: Debugging | ~10,000 tokens | ~2,000 tokens | 80% |
| Phase 6: Documentation | ~8,000 tokens | ~1,500 tokens | 81% |
| **Total** | **~95,000 tokens** | **~17,800 tokens** | **81%** |

**Target**: 21% context usage (42k/200k tokens) for complete 7-phase workflow

**Achieved**: Consistently <30% across all commands

### Time Savings

#### Sequential vs Parallel Execution

| Workflow Type | Sequential (/supervise) | Parallel (/coordinate) | Time Savings |
|---------------|------------------------|------------------------|--------------|
| 3 research topics | 12 minutes | 5 minutes | 58% |
| 5-phase plan | 25 minutes | 12 minutes | 52% |
| 8-phase implementation | 45 minutes | 20 minutes | 56% |
| Full workflow (7 phases) | 60 minutes | 25 minutes | 58% |

**Average Savings**: 40-60% with wave-based parallel execution

#### Phase 0 Optimization Impact

**Before** (agent-based location detection):
- Time: 180 seconds per workflow
- Tokens: ~12,000 tokens
- Reliability: 90% (fallback to TODO files)

**After** (unified library detection):
- Time: 7 seconds per workflow
- Tokens: ~1,800 tokens
- Reliability: 100% (fail-fast)

**Improvement**: 25x faster, 85% token reduction, 100% reliability

### Delegation Metrics

All orchestration commands achieve >90% delegation rate through [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md):

| Command | Delegation Rate | File Creation | Context Usage |
|---------|----------------|---------------|---------------|
| /research | 95% | 100% | <25% |
| /supervise | 92% | 100% | <28% |
| /coordinate | 93% | 100% | <27% |
| /orchestrate | 91% | 100% | <30% |

**Validation**: Run `.claude/tests/test_orchestration_commands.sh` for automated metrics verification

### Complexity Thresholds

Orchestration commands use these thresholds for adaptive planning:

| Metric | Threshold | Action |
|--------|-----------|--------|
| Phase Complexity Score | >8.0 | Auto-expand to separate file |
| Task Count | >10 | Auto-expand regardless of score |
| File References | >10 | Increase complexity score |
| Replan Limit | 2 | Maximum replans per phase |

**Configuration**: See [Adaptive Planning Configuration](../../../CLAUDE.md#adaptive_planning_config)

### Benchmark Results

Measured on Spec 508 (Coordinate Command Improvements):

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Total Time | 28 minutes | <60 min | ✓ PASS |
| Context Peak | 58k tokens | <100k | ✓ PASS |
| Context Average | 42k tokens | <60k | ✓ PASS |
| Delegation Rate | 94% | >90% | ✓ PASS |
| File Creation | 12/12 (100%) | 100% | ✓ PASS |
| Test Pass Rate | 100% | 100% | ✓ PASS |

---

## Section 5: Alternative Patterns

### Sequential vs Parallel Research

#### Sequential Pattern (/supervise)

**When to Use**:
- Research topics have dependencies
- Learning orchestration system
- Debugging research issues

**Pattern**:
```bash
# Topic 1
Task { research existing_patterns }
WAIT for completion
Extract metadata from report_1

# Topic 2 (depends on Topic 1)
Task { research best_practices }
WAIT for completion
Extract metadata from report_2

# Topic 3 (depends on Topic 2)
Task { research implementation_approach }
WAIT for completion
Extract metadata from report_3
```

**Time**: ~12 minutes for 3 topics (4 min each)

#### Parallel Pattern (/coordinate, /orchestrate)

**When to Use**:
- Research topics are independent
- Speed is priority
- Production workflows

**Pattern**:
```bash
# Calculate all paths first
REPORT_PATH_1=$(create_topic_artifact "$topic" "reports" "existing_patterns")
REPORT_PATH_2=$(create_topic_artifact "$topic" "reports" "best_practices")
REPORT_PATH_3=$(create_topic_artifact "$topic" "reports" "implementation")

# Invoke all agents in parallel
Task { research existing_patterns } &
Task { research best_practices } &
Task { research implementation_approach } &

# Wait for all to complete
WAIT for all agents

# Extract metadata from all reports
extract_report_metadata "$REPORT_PATH_1"
extract_report_metadata "$REPORT_PATH_2"
extract_report_metadata "$REPORT_PATH_3"
```

**Time**: ~5 minutes for 3 topics (worst case 4 min + overhead)

**Savings**: 58% time reduction

### Wave-Based Implementation

#### Traditional Sequential

**Pattern**:
```bash
for phase in {1..8}; do
  implement_phase $phase
  run_tests
  commit_changes
done
```

**Problem**: No parallelization, even for independent phases

**Time**: 8 phases × 5 min = 40 minutes

#### Wave-Based Parallel

**Pattern**:
```bash
# Analyze dependencies
parse_dependencies plan.md > dependency_graph.json

# Group into waves
# Wave 1: Phases with no dependencies [1, 2, 3]
# Wave 2: Phases depending only on Wave 1 [4, 5]
# Wave 3: Phases depending on Wave 2 [6, 7, 8]

# Execute waves
for wave in {1..3}; do
  for phase in $(get_wave_phases $wave); do
    Task { implement_phase $phase } &
  done
  wait  # Wait for all phases in wave to complete
done
```

**Benefit**: 40-60% time savings for plans with independent phases

**Time**: 3 waves × 7 min = 21 minutes (48% savings)

### Agent-Based vs Library-Based Location Detection

#### Agent-Based (Deprecated)

**Pattern**:
```bash
Task {
  prompt: "Detect specs directory location using filesystem search"
  subagent_type: "general-purpose"
}
WAIT for agent
SPECS_DIR=$(extract from agent output)
```

**Problems**:
- 180 seconds execution time
- 12,000 tokens consumed
- 10% fallback rate to TODO files
- Difficult to debug

**Status**: Deprecated in Spec 508

#### Library-Based (Current)

**Pattern**:
```bash
source .claude/lib/core/unified-location-detection.sh
detect_workflow_scope "$USER_WORKFLOW"
SPECS_DIR="$WORKFLOW_SPECS_DIR"
```

**Benefits**:
- 7 seconds execution time (25x faster)
- 1,800 tokens consumed (85% reduction)
- 100% reliability (fail-fast on errors)
- Easy to debug bash functions

**Status**: Current standard (Spec 508+)

### Metadata Extraction vs Full Content Loading

#### Full Content Loading (Anti-Pattern)

```bash
# ❌ INCORRECT
REPORT_CONTENT=$(cat "$REPORT_PATH")  # 5,000 tokens
PLAN_CONTENT=$(cat "$PLAN_PATH")      # 8,000 tokens

# Pass full content to next phase
Task {
  prompt: "
    Report: $REPORT_CONTENT
    Plan: $PLAN_CONTENT
    Implement...
  "
}
```

**Problem**: Massive context consumption (13,000 tokens for 2 files)

#### Metadata Extraction (Best Practice)

```bash
# ✓ CORRECT
source .claude/lib/workflow/metadata-extraction.sh

REPORT_META=$(extract_report_metadata "$REPORT_PATH")  # 250 tokens
PLAN_META=$(extract_plan_metadata "$PLAN_PATH")        # 300 tokens

# Pass metadata only
Task {
  prompt: "
    Report: $(echo "$REPORT_META" | jq -r '.summary')
    Plan: $(echo "$PLAN_META" | jq -r '.summary')
    Full content available at: $REPORT_PATH, $PLAN_PATH
    Implement...
  "
}
```

**Benefit**: 96% context reduction (13,000 → 550 tokens)

---

## Related Documentation

- [Agent Delegation Troubleshooting](../troubleshooting/agent-delegation-troubleshooting.md) - Diagnose and fix delegation issues
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Correct agent invocation pattern
- [Hierarchical Agent Architecture](../concepts/hierarchical-agents.md) - System overview and metadata extraction
- [Command Development Guide](../guides/development/command-development/command-development-fundamentals.md) - Creating new orchestration commands
- [Workflow Phases Reference](./workflow-phases.md) - Detailed phase documentation
- [Library API Reference](./library-api.md) - Unified location detection and utilities

---

## Validation

Verify orchestration command compliance:

```bash
# Test all orchestration commands
.claude/tests/test_orchestration_commands.sh

# Validate agent invocation pattern
.claude/lib/util/validate-agent-invocation-pattern.sh .claude/commands/*.md

# Check delegation rate
.claude/tests/test_supervise_agent_delegation.sh

# Verify file creation reliability
.claude/tests/validate_topic_based_artifacts.sh
```

**Expected**: All tests passing, >90% delegation rate, 100% file creation, <30% context usage
