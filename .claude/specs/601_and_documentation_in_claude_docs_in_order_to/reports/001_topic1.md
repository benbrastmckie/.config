# Claude Code Best Practices for Orchestrator Commands and Agent Delegation

## Metadata
- **Date**: 2025-11-07
- **Agent**: research-specialist
- **Topic**: Orchestrator command patterns and agent delegation best practices
- **Report Type**: Best practices synthesis
- **Complexity Level**: 4

## Executive Summary

Claude Code's orchestration architecture achieves 92-97% context reduction and 40-60% time savings through five core patterns: Phase 0 path pre-calculation (85% token reduction), behavioral injection (100% file creation reliability), metadata-only passing (95-99% context reduction per artifact), wave-based parallel execution, and fail-fast error handling. The recommended pattern separates orchestrator commands (coordinate workflow, pre-calculate paths) from executor agents (perform tasks, create artifacts), with /coordinate serving as the stable, production-ready orchestration command. Common anti-patterns include documentation-only YAML blocks (0% delegation rate), command-to-command invocation (context bloat), and bootstrap fallbacks (hide configuration errors).

## Findings

### 1. Orchestrator vs Executor Role Separation

**Core Principle**: Commands orchestrate; agents execute.

The hierarchical agent architecture distinguishes between two fundamental roles:

**Orchestrator Role** (coordinates workflow):
- Pre-calculates all artifact paths using topic-based organization
- Invokes specialized subagents via Task tool (NOT SlashCommand)
- Injects complete context into subagents (behavioral injection pattern)
- Verifies artifacts created at expected locations
- Extracts metadata only (95% context reduction)
- Examples: /orchestrate, /coordinate, /plan (when coordinating research agents)

**Executor Role** (performs atomic operations):
- Receives pre-calculated paths from orchestrator
- Executes specific task using Read/Write/Edit/Bash tools
- Creates artifacts at exact paths provided
- Returns metadata only (not full content)
- Examples: research-specialist agent, plan-architect agent, implementation-executor agent

**Source**: `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md:308-418`

**Why This Matters**: Prevents command-to-command invocation that causes context bloat and breaks metadata extraction. When orchestrators invoke other commands via SlashCommand, they nest full prompts, preventing the 95% context reduction achievable with metadata-only passing.

### 2. Phase 0: Path Pre-Calculation (MANDATORY)

**Performance Metrics**:
- Token Reduction: 85% (75,600 → 11,000 tokens)
- Speed Improvement: 25x faster (25.2s → <1s)
- Directory Creation: Lazy (only create when agents produce output)

**Implementation Pattern** using unified-location-detection.sh:

```bash
# Source unified location detection library
source "${CLAUDE_CONFIG}/.claude/lib/unified-location-detection.sh"

# Perform location detection
LOCATION_JSON=$(perform_location_detection "<workflow_description>")

# Extract paths
TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')
PLANS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.plans')

# MANDATORY VERIFICATION
if [ ! -d "$TOPIC_PATH" ]; then
  echo "ERROR: Location detection failed - topic directory not created"
  exit 1
fi
```

**Anti-Pattern**: Agent-based location detection costs 75,600 tokens and 25 seconds, eliminating the possibility of path pre-calculation for behavioral injection.

**Source**: `/home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md:172-260`

### 3. Behavioral Injection Pattern

**Definition**: Commands inject execution context, artifact paths, and role clarifications into agent prompts through file content rather than tool invocations.

**Core Components**:

1. **Role Clarification** (explicit orchestrator identity):
```markdown
## YOUR ROLE

You are the ORCHESTRATOR for this workflow. Your responsibilities:
1. Calculate artifact paths and workspace structure
2. Invoke specialized subagents via Task tool
3. Aggregate and forward subagent results
4. DO NOT execute implementation work yourself using Read/Grep/Write/Edit tools
```

2. **Path Pre-Calculation** (before any agent invocation):
```bash
TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW_DESC" "specs")
REPORT_PATH="${TOPIC_DIR}/reports/001_patterns.md"
PLAN_PATH="${TOPIC_DIR}/plans/001_implementation.md"
```

3. **Context Injection** (structured data in agent prompt):
```yaml
research_context:
  topic: "OAuth 2.0 authentication patterns"
  output_path: "specs/027_authentication/reports/001_oauth_patterns.md"
  output_format:
    sections:
      - "OAuth 2.0 Flow Overview"
      - "Implementation Patterns"
```

**Benefits**:
- 100% file creation rate through explicit path injection
- <30% context usage by avoiding nested command prompts
- Hierarchical multi-agent coordination through clear role separation
- Parallel execution through independent context injection per agent

**Source**: `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md:1-174`

### 4. Imperative Agent Invocation Pattern (Standard 11)

**Problem**: Documentation-only YAML blocks create 0% agent delegation rate because they appear as code examples rather than executable instructions.

**Required Elements**:

1. **Imperative Instruction**: Use explicit execution markers
   - `**EXECUTE NOW**: USE the Task tool to invoke...`
   - `**INVOKE AGENT**: Use the Task tool with...`
   - `**CRITICAL**: Immediately invoke...`

2. **Agent Behavioral File Reference**: Direct reference to agent guidelines
   - Pattern: `Read and follow: .claude/agents/[agent-name].md`

3. **No Code Block Wrappers**: Task invocations must NOT be fenced
   - ❌ WRONG: ` ```yaml` ... `Task {` ... `}` ... ` ``` `
   - ✅ CORRECT: `Task {` ... `}` (no fence)

4. **Completion Signal Requirement**: Agent must return explicit confirmation
   - Pattern: `Return: REPORT_CREATED: ${REPORT_PATH}`

**Correct Pattern**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: OAuth 2.0 authentication
    - Output Path: /absolute/path/to/report.md

    Return: REPORT_CREATED: /absolute/path/to/report.md
  "
}
```

**Historical Context**:
- Spec 438: /supervise delegation fix (0% → >90% delegation rate)
- Spec 495: /coordinate and /research fixes (9 invocations corrected)
- Spec 057: /supervise error handling improvements

**Source**: `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md:1128-1307`

### 5. Metadata-Only Passing and Forward Message Pattern

**Metadata Extraction**:

Extract concise metadata instead of passing full content:

```bash
source .claude/lib/metadata-extraction.sh

metadata=$(extract_report_metadata "specs/042_auth/reports/001_patterns.md")
title=$(echo "$metadata" | jq -r '.title')
summary=$(echo "$metadata" | jq -r '.summary')  # ≤50 words
```

**Report Metadata Structure**:
```json
{
  "title": "Authentication Patterns Research",
  "summary": "JWT vs sessions comparison. JWT recommended for APIs...",
  "file_paths": ["lib/auth/jwt.lua", "lib/auth/sessions.lua"],
  "recommendations": [
    "Use JWT for API authentication",
    "Use sessions for web application"
  ],
  "path": "specs/042_auth/reports/001_patterns.md",
  "size": 4235
}
```

**Context Reduction**: 99% (5000 chars → 250 chars per artifact)

**Forward Message Pattern**: Pass subagent responses directly without re-summarization, eliminating 200-300 token overhead per subagent.

**Source**: `/home/benjamin/.config/.claude/docs/concepts/hierarchical_agents.md:31-175`

### 6. Wave-Based Parallel Execution

**Performance**: 40-60% time savings through parallel execution of independent phases.

**Dependency Analysis**:
```bash
source "${CLAUDE_CONFIG}/.claude/lib/dependency-analyzer.sh"
WAVES=$(analyze_dependencies_kahn "$PLAN_PATH")

# Expected output:
# Wave 1: [1, 2] (phases 1 and 2 can run in parallel)
# Wave 2: [3] (phase 3 depends on 1, 2)
# Wave 3: [4, 5] (phases 4 and 5 can run in parallel)
```

**Example**:
- Sequential: Phase 1 (5min) → Phase 2 (5min) → Phase 3 (5min) → Phase 4 (5min) → Phase 5 (5min) = **25 minutes**
- Wave-Based: Wave 1 [1] (5min) → Wave 2 [2,3] (5min parallel) → Wave 3 [4,5] (5min parallel) = **15 minutes** (40% savings)

**Source**: `/home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md:502-616`

### 7. Verification and Fallback Pattern

**Purpose**: Achieve 100% file creation rate through mandatory verification checkpoints with fallback mechanisms.

**Three Components**:

1. **Path Pre-Calculation**: Calculate all file paths before execution
2. **Verification Checkpoints**: MANDATORY VERIFICATION after each file creation
3. **Fallback Mechanisms**: Create missing files if verification fails

**Implementation**:

```markdown
## MANDATORY VERIFICATION - Report Creation

EXECUTE NOW (REQUIRED BEFORE NEXT STEP):

1. Verify report file exists:
   ls -la specs/027_authentication/reports/001_oauth_patterns.md

2. Verify file size > 0:
   [ -s specs/027_authentication/reports/001_oauth_patterns.md ] && echo "✓ File created"

3. If verification fails, proceed to FALLBACK MECHANISM.
```

**Fallback**:
```bash
if [ ! -f "$REPORT_PATH" ]; then
  echo "FALLBACK: Creating report from agent output"
  cat > "$REPORT_PATH" <<EOF
# Report Content
$AGENT_OUTPUT
EOF
fi
```

**Performance Impact**:
- Before pattern: 70% file creation success rate (7/10)
- After pattern: 100% file creation success rate (10/10)
- Improvement: +43%

**Source**: `/home/benjamin/.config/.claude/docs/concepts/patterns/verification-fallback.md:1-406`

### 8. Fail-Fast Error Handling

**Principle**: Configuration errors should terminate immediately with diagnostic context, not continue with degraded functionality.

**Distinction**:

| Situation | Approach | Rationale |
|-----------|----------|-----------|
| **Bootstrap Library Loading** | Fail-Fast | Configuration error - cannot proceed |
| **File Creation (Agent Output)** | Verification + Fallback | Transient error - can retry |
| **Directory Creation** | Verification + Fallback | Transient error - can create manually |
| **Function Availability** | Fail-Fast | Configuration error - library not sourced |

**5-Component Error Message Standard**:

1. **What Failed**: Specific operation
2. **Expected State**: What should have happened
3. **Diagnostic Commands**: Exact commands to investigate
4. **Context**: Why this is required
5. **Action**: Steps to resolve

**Example**:
```bash
if ! source "${CLAUDE_CONFIG}/.claude/lib/unified-location-detection.sh" 2>/dev/null; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "ERROR: Failed to load unified-location-detection.sh library"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "**What failed**: Library sourcing"
  echo "**Expected**: Library should exist at ${CLAUDE_CONFIG}/.claude/lib/unified-location-detection.sh"
  echo "**Diagnostic**: Run: ls -la ${CLAUDE_CONFIG}/.claude/lib/"
  echo "**Context**: Required for Phase 0 path pre-calculation"
  echo "**Action**: Verify installation: git status .claude/lib/"
  echo ""
  exit 1
fi
```

**Source**: `/home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md:1147-1218`

### 9. Context Management and Pruning

**Target**: <30% context usage throughout 7-phase workflow

**Context Budget**:
- Phase 0: 500-1,000 tokens (4%)
- Phase 1: 600-1,200 tokens (6% - 2-4 agents × 200-300 tokens each)
- Phase 2: 800-1,200 tokens (5%)
- Phase 3: 1,500-2,000 tokens (8%)
- Phase 4-7: 200-500 tokens each (2% each)
- **Total**: 3,100-6,200 tokens (21%)

**Pruning Policies**:

**Aggressive** (orchestration workflows):
- Prune full agent outputs immediately after metadata extraction
- Keep only metadata (title + 50-word summary)
- Prune completed wave context before starting next wave
- Retain only phase completion status

**When to Prune**:
1. After metadata extraction (most critical)
2. Between workflow phases
3. Before checkpoint saves

**Source**: `/home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md:1220-1265`

### 10. Command Selection: /coordinate is Production-Ready

**Maturity Status**:

| Command | Status | Recommendation |
|---------|--------|----------------|
| **/coordinate** | **Production-Ready** | Stable, tested, recommended for all workflows |
| **/orchestrate** | **In Development** | Experimental PR automation, inconsistent behavior |
| **/supervise** | **In Development** | Minimal reference, being stabilized |

**Unique Features of /coordinate**:
- Wave-based parallel implementation (40-60% time savings)
- Workflow scope auto-detection (4 workflow types)
- Concise verification formatting (90% token reduction)
- Pure orchestration architecture (no command chaining)

**Use Case**: All production workflows - research + planning, full implementation, debug-only, documentation generation.

**Source**: `/home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md:27-138`

## Recommendations

### Recommendation 1: Always Use Phase 0 Path Pre-Calculation

Before invoking any agents, calculate all artifact paths using unified-location-detection.sh. This enables:
- 85% token reduction (75,600 → 11,000 tokens)
- 25x speed improvement
- Explicit path injection into agents (behavioral injection)
- MANDATORY VERIFICATION checkpoints
- Lazy directory creation (only when agents succeed)

**Implementation**: Source `.claude/lib/unified-location-detection.sh` and call `perform_location_detection()` before Phase 1.

### Recommendation 2: Use Imperative Instructions for All Agent Invocations

Never wrap Task invocations in markdown code fences. Always precede with imperative directives:
- `**EXECUTE NOW**: USE the Task tool to invoke...`
- Include agent behavioral file reference: `Read and follow: .claude/agents/[name].md`
- Require completion signals: `Return: REPORT_CREATED: ${PATH}`

This prevents documentation-only patterns that cause 0% delegation rates.

**Validation**: Run `.claude/lib/validate-agent-invocation-pattern.sh` to detect anti-patterns.

### Recommendation 3: Extract Metadata Only, Never Pass Full Artifacts

After agents create artifacts, extract metadata using `extract_report_metadata()` or `extract_plan_metadata()`. Pass only metadata (title + 50-word summary + key references) between phases, achieving 95-99% context reduction per artifact.

**Never** read full artifacts into orchestrator context. Load full content only on-demand when absolutely necessary.

### Recommendation 4: Implement MANDATORY VERIFICATION Checkpoints

After every file creation operation, add MANDATORY VERIFICATION:
```bash
if [ ! -f "$EXPECTED_PATH" ]; then
  echo "CRITICAL: File missing at $EXPECTED_PATH"
  echo "Executing fallback creation..."
  # Fallback code
fi
```

This achieves 100% file creation reliability (vs 60-80% without verification).

### Recommendation 5: Use Fail-Fast for Bootstrap, Verification for Agents

**Bootstrap operations** (library loading, function verification): Exit immediately on failure with 5-component diagnostic messages.

**Agent operations** (file creation, artifact generation): Use MANDATORY VERIFICATION + fallback mechanisms to achieve 100% reliability.

Never mask configuration errors with fallback mechanisms - they should terminate immediately.

### Recommendation 6: Prune Context Aggressively

After each phase completion, prune full outputs and retain only metadata:
```bash
source .claude/lib/context-pruning.sh
prune_phase_metadata "research"
```

Target: <30% context usage throughout workflow. Use aggressive pruning policy for orchestration workflows.

### Recommendation 7: Use /coordinate for Production Workflows

For all production orchestration workflows, use `/coordinate` as the stable, tested command. Avoid `/orchestrate` (experimental PR features) and `/supervise` (being stabilized) unless specifically needed.

**Command**: `/coordinate "<workflow-description>"`

### Recommendation 8: Avoid Common Anti-Patterns

**Never**:
- Wrap Task invocations in ` ```yaml ` code fences (0% delegation)
- Invoke slash commands from agents via SlashCommand tool (context bloat)
- Use bootstrap fallback mechanisms (hide configuration errors)
- Pass full artifact content between phases (context explosion)
- Calculate paths during agent execution (inconsistent organization)

**Always**:
- Pre-calculate paths before agent invocation (Phase 0)
- Use imperative directives for Task invocations
- Extract metadata only after agent completion
- Add MANDATORY VERIFICATION checkpoints
- Implement fail-fast error handling for bootstrap

## References

### Primary Documentation
- `/home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md` - Complete unified framework (lines 1-1516)
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` - Architecture standards (lines 1-2111)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md` - Behavioral injection pattern (lines 1-1162)
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical_agents.md` - Hierarchical agent architecture (lines 1-2218)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/verification-fallback.md` - Verification and fallback pattern (lines 1-406)

### Key Libraries
- `.claude/lib/unified-location-detection.sh` - Phase 0 path pre-calculation
- `.claude/lib/metadata-extraction.sh` - Metadata-only passing
- `.claude/lib/dependency-analyzer.sh` - Wave-based parallel execution
- `.claude/lib/context-pruning.sh` - Context management
- `.claude/lib/checkpoint-utils.sh` - Checkpoint recovery

### Validation Tools
- `.claude/lib/validate-agent-invocation-pattern.sh` - Detect documentation-only YAML blocks
- `.claude/tests/test_orchestration_commands.sh` - Comprehensive testing suite

### Performance Metrics
- Phase 0 optimization: 85% token reduction, 25x speedup
- Metadata extraction: 95-99% context reduction per artifact
- Wave-based execution: 40-60% time savings
- File creation reliability: 100% (with verification + fallback)
- Agent delegation rate: >90% (with imperative pattern)
