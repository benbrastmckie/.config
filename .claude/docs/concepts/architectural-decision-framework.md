# Architectural Decision Framework

**Path**: docs → concepts → architectural-decision-framework.md

[Used by: /plan, /implement, /coordinate, all command and agent development]

Decision frameworks for fundamental architectural choices in command and agent system design: subprocess models, supervision patterns, and template selection.

## Purpose

This framework provides explicit decision criteria for three recurring architectural choices that significantly impact context usage, maintenance burden, and workflow complexity. Each decision includes when-to-use criteria, trade-offs, and case studies.

## Decision 1: Bash Blocks vs Standalone Scripts

**Question**: Should this functionality be implemented as inline bash blocks in command files or as standalone scripts?

### Decision Criteria

**Use Bash Blocks (Inline)** when:
- Command must execute operations directly (orchestration responsibility)
- Logic is command-specific and won't be reused
- Execution-critical and must be immediately visible to Claude
- Simple operations (<20 lines of bash)
- Part of phase progression or verification checkpoints

**Use Standalone Scripts** when:
- Logic is shared across multiple commands
- Complex operations (>50 lines of bash)
- Requires dedicated testing and validation
- Benefits from version control separation
- Can be sourced and reused by multiple commands

### Trade-Offs

| Aspect | Bash Blocks (Inline) | Standalone Scripts |
|--------|----------------------|-------------------|
| **Context Usage** | Low (already in command) | Higher (must source) |
| **Reusability** | None (duplicated if needed) | High (sourced by multiple commands) |
| **Testability** | Difficult (requires command execution) | Easy (standalone test suite) |
| **Maintenance** | Localized (in command file) | Centralized (in scripts/) |
| **Visibility** | Immediate (Claude sees it) | Deferred (must be sourced) |

### Examples

**Bash Block (Inline) - Path Calculation**:
```markdown
**EXECUTE NOW - Calculate Artifact Paths**

bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact/artifact-creation.sh"
TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW_DESCRIPTION" ".claude/specs")
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "$topic" "")
echo "Pre-calculated path: $REPORT_PATH"
```

**Why inline**: Command-specific orchestration, execution-critical, simple operation.

**Standalone Script - Complex Validation**:
```bash
# .claude/scripts/validate-links.sh
# Validates markdown links across the codebase
# Used by: /implement, /document, /refactor
# 100+ lines of link validation logic
```

**Why standalone**: Shared by multiple commands, complex logic, requires dedicated testing.

### Case Study: State-Based Orchestration

**Problem**: Coordinate command needed complex state machine logic (80+ lines).

**Decision**: Extracted to `.claude/lib/state-machine-core.sh` (standalone).

**Rationale**:
- Shared by multiple coordinate workflows
- Complex logic requiring dedicated tests
- Benefits from separation of concerns
- Enables independent evolution

**Result**: 60% context reduction, 100% test coverage, reused by 3+ workflows.

## Decision 2: Flat vs Hierarchical Supervision

**Question**: Should this workflow use flat supervision (orchestrator + agents) or hierarchical supervision (orchestrator + supervisors + agents)?

### Decision Criteria

**Use Flat Supervision** when:
- Total agents ≤4
- Agents are independent (no inter-agent dependencies)
- Simple orchestration (sequential or parallel execution)
- Context usage <30% with flat structure
- No need for specialized supervision logic

**Use Hierarchical Supervision** when:
- Total agents >4
- Agents have complex dependencies
- Need specialized supervision (phase coordination, result synthesis)
- Flat structure would exceed 30% context usage
- Benefits from supervision domain separation

### Trade-Offs

| Aspect | Flat Supervision | Hierarchical Supervision |
|--------|------------------|-------------------------|
| **Complexity** | Low (1 orchestrator) | Higher (orchestrator + supervisors) |
| **Context Usage** | Low for ≤4 agents | Lower for >4 agents (via context pruning) |
| **Maintenance** | Simple (single file) | Moderate (multiple files) |
| **Scalability** | Poor (>4 agents) | Excellent (>10 agents) |
| **Supervision Logic** | In orchestrator | Separated by domain |

### Scalability Threshold

**Maximum 4 Agents for Flat Supervision**:
- Each agent invocation: ~5-10KB context
- 4 agents × 10KB = 40KB overhead
- Orchestration logic: ~10KB
- Total: ~50KB ≈ 25% context usage ✓

**5+ Agents Require Hierarchical**:
- 5 agents × 10KB = 50KB agent overhead
- Orchestration logic: ~15KB (more complex)
- Total: ~65KB ≈ 33% context usage ✗ (exceeds <30% target)

### Examples

**Flat Supervision - Research Workflow**:
```markdown
# /research command
Orchestrator invokes:
1. Topic analyzer agent
2. Codebase researcher agent
3. Best practices researcher agent
4. Integration strategist agent

Total: 4 agents, <30% context usage, simple parallel execution
```

**Hierarchical Supervision - Complex Implementation**:
```markdown
# /coordinate command
Orchestrator invokes:
1. Planning supervisor (coordinates 3 planning agents)
2. Implementation supervisor (coordinates 5 implementation agents)
3. Validation supervisor (coordinates 2 validation agents)

Total: 10 agents via 3 supervisors, <25% context usage via context pruning
```

### Case Study: Coordinate Command Maintenance

**Problem**: Coordinate command had 12 agents with flat supervision.

**Symptoms**:
- 45% context usage (exceeds 30% target)
- Complex orchestration logic (200+ lines)
- Difficult to maintain and extend

**Decision**: Migrated to hierarchical supervision with 3 supervisors.

**Results**:
- Context usage: 45% → 23% (49% reduction)
- Orchestration logic: 200 → 80 lines (60% reduction)
- Maintenance burden: 67% reduction
- Enabled parallel wave execution (40% time savings)

**Reference**: `.claude/docs/architecture/state-based-orchestration-overview.md`

## Decision 3: Template vs Uniform Plans

**Question**: Should this implementation use template-based plans (with placeholders) or uniform plans (specific values)?

### Decision Criteria

**Use Template Plans** when:
- Pattern repeats across multiple features (>3 instances)
- Significant structural similarity (>70% shared content)
- Benefits from standardization (testing, validation, structure)
- Placeholder substitution is straightforward
- Want to enforce consistent approach

**Use Uniform Plans** when:
- One-off implementation (no pattern repetition)
- High variability (>50% unique content)
- Specific context crucial (not abstractable)
- Template would require >10 placeholders
- Unique constraints or requirements

### Trade-Offs

| Aspect | Template Plans | Uniform Plans |
|--------|----------------|---------------|
| **Reusability** | High (multiple instances) | None (one-off) |
| **Flexibility** | Lower (standardized) | High (customized) |
| **Maintenance** | Centralized (update template) | Distributed (update each) |
| **Learning Curve** | Higher (understand template) | Lower (specific plan) |
| **Consistency** | Enforced (via template) | Manual (developer choice) |

### Template Selection Criteria

**Good Template Candidates**:
- Phase expansion plans (consistent structure across phases)
- Agent creation plans (consistent behavioral pattern)
- Testing plan templates (consistent validation approach)
- Refactoring plan templates (consistent transformation pattern)

**Poor Template Candidates**:
- Unique architectural changes (no repetition)
- Exploratory implementations (high variability)
- One-time migrations (won't repeat)
- Context-specific integrations (not abstractable)

### Examples

**Template Plan - Phase Expansion**:
```markdown
# Template: Expand Phase {PHASE_NUMBER} into {STAGE_COUNT} Stages

## Metadata
- Phase: {PHASE_NAME}
- Stages: {STAGE_COUNT}
- Complexity: {COMPLEXITY_SCORE}

## Stage Breakdown
{foreach STAGE in STAGES}
### Stage {STAGE_NUMBER}: {STAGE_NAME}
- Tasks: {STAGE_TASKS}
- Duration: {STAGE_DURATION}
{end foreach}
```

**Why template**: Repeats for every phase expansion, consistent structure, standardized approach.

**Uniform Plan - Unique Migration**:
```markdown
# Migrate from Event-Based to State-Based Orchestration

## Metadata
- Scope: .claude/lib/orchestration/
- Impact: 8 command files, 3 library modules
- Estimated: 12 hours

## Phase 1: Extract State Machine Core
[Specific steps for this unique migration]
```

**Why uniform**: One-time migration, high specificity, unique constraints, won't repeat.

### Case Study: Phase Expansion Template

**Problem**: Creating expansion plans for 40+ phases was repetitive (3 hours per plan).

**Decision**: Created phase expansion template with 8 placeholders.

**Template Structure**:
- Metadata section (phase number, name, complexity)
- Stage breakdown (tasks, duration, dependencies)
- Testing strategy (validation approach)
- Success criteria (completion requirements)

**Results**:
- Plan creation time: 3 hours → 30 minutes (83% reduction)
- Consistency: 100% (all plans follow template)
- Maintenance: Centralized (update template, not 40 plans)

**Reference**: `.claude/docs/guides/templates/_template-phase-expansion-plan.md`

## Decision Framework Summary

**Subprocess Model** (Bash Blocks vs Scripts):
- ≤20 lines, command-specific → Bash blocks (inline)
- >50 lines, shared logic → Standalone scripts
- Trade-off: Context usage vs reusability

**Supervision Pattern** (Flat vs Hierarchical):
- ≤4 agents, independent → Flat supervision
- >4 agents, complex dependencies → Hierarchical supervision
- Trade-off: Simplicity vs scalability

**Plan Template** (Template vs Uniform):
- >3 instances, >70% similarity → Template plans
- One-off, >50% unique → Uniform plans
- Trade-off: Consistency vs flexibility

## Validation

**Bash Block Size Check**:
```bash
# Verify bash blocks within size limits
grep -zoP '```bash.*?```' command.md | wc -c
# If >2000 bytes, consider extracting to script
```

**Supervision Complexity Check**:
```bash
# Count agent invocations in command
agent_count=$(grep -c "Task tool" command.md)
if [ "$agent_count" -gt 4 ]; then
  echo "WARNING: Consider hierarchical supervision"
fi
```

**Template Applicability Check**:
```bash
# Identify similar plans for template candidates
find .claude/specs/*/plans -name "*.md" -exec grep -l "pattern keyword" {} \; | wc -l
# If ≥3 matches, consider creating template
```

## Related Documentation

**Patterns**:
- [Robustness Framework](robustness-framework.md) → Complete pattern index
- [Behavioral Injection Pattern](patterns/behavioral-injection.md) → Context injection techniques
- [State-Based Orchestration](../architecture/state-based-orchestration-overview.md) → Hierarchical supervision architecture

**Standards**:
- [Command Architecture Standards](../reference/architecture/overview.md) → Complete command standards
- [Code Standards](../reference/standards/code-standards.md) → General coding standards

**Guides**:
- [Command Development Guide](../guides/development/command-development/command-development-fundamentals.md) → Command creation patterns
- [Agent Development Guide](../guides/development/agent-development/agent-development-fundamentals.md) → Agent creation patterns
- [Adaptive Planning Guide](../workflows/adaptive-planning-guide.md) → Plan template usage
