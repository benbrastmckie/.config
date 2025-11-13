# Simpler Alternatives to Dynamic Routing Research Report

## Metadata
- **Date**: 2025-11-12
- **Agent**: research-specialist
- **Topic**: Analyze simpler alternatives to dynamic routing for command agent optimization
- **Report Type**: implementation approach analysis
- **Complexity Level**: 2

## Executive Summary

The command agent optimization plan (Spec 677 Phase 5) proposes complexity-based dynamic routing in /research command using RESEARCH_COMPLEXITY from Spec 678's workflow classification. Analysis of the codebase reveals four simpler alternatives: (1) static agent configuration via CLAUDE.md, (2) user-specified --model flag, (3) environmental complexity hints, and (4) no dynamic routing with user education. Static configuration offers the best balance of simplicity and flexibility, reducing implementation time from 6 hours to 1.5 hours while maintaining all functionality. Dynamic routing adds significant complexity (85+ lines of code, error handling, monitoring infrastructure) for minimal benefit ($1.87 annually, 24% research cost reduction).

## Findings

### Current Dynamic Routing Architecture (Phase 5 Tasks)

The plan (lines 336-351) proposes implementing complexity-based dynamic routing in /research command Phase 0 with the following components:

**Implementation Requirements**:
- Model selection case statement based on RESEARCH_COMPLEXITY (1-4 scale)
- Task invocation updates to pass model dynamically
- RESEARCH_TOPICS_JSON integration for descriptive names
- Logging infrastructure for complexity tracking
- Error rate tracking for Haiku invocations
- Fallback logic (Haiku failure → Sonnet retry)
- Model Selection Guide documentation updates

**Code Impact** (Estimated):
- ~85 lines added to /research.md
- ~40 lines for case statement and model selection
- ~25 lines for error tracking and fallback logic
- ~20 lines for logging and diagnostics

**Infrastructure Dependencies**:
- Spec 678 workflow classification (RESEARCH_COMPLEXITY)
- State persistence (workflow state file)
- Error rate tracking system
- 2-week monitoring period
- Validation tests (<5% error rate threshold)

**Testing Requirements** (Phase 6, lines 414-421):
- Simple research tests (1 subtopic, Haiku)
- Medium research tests (2 subtopics, Sonnet)
- Complex research tests (3-4 subtopics, Sonnet/Opus)
- 2-week monitoring period
- Error rate tracking
- Fallback logic validation
- Cost reduction measurement

**Complexity Assessment**: High
- 85+ lines of code
- Multi-week monitoring period
- Error handling and fallback logic
- State dependency on Spec 678
- Testing infrastructure (6 test categories)

### Alternative 1: Static Agent Configuration via CLAUDE.md

**Approach**: Use existing agent behavioral file frontmatter to specify default model, with CLAUDE.md override capability.

**Implementation**:

Current research-specialist.md (lines 1-7):
```markdown
---
allowed-tools: Read, Write, Grep, Glob, WebSearch, WebFetch, Bash
description: Specialized in codebase research, best practice investigation, and report file creation
model: sonnet-4.5
model-justification: Codebase research, best practices synthesis, comprehensive report generation with 28 completion criteria
fallback-model: sonnet-4.5
---
```

**Proposed Enhancement** (CLAUDE.md):
```markdown
## Agent Model Configuration
[Used by: /research, /coordinate, /plan]

Override default agent models for project-specific needs:

- **research-specialist**: haiku-4.5 (default: sonnet-4.5)
  - Rationale: Simple codebase research sufficient for this project
  - Fallback: sonnet-4.5 for complex analysis

- **plan-architect**: opus-4.1 (default: opus-4.1)
  - Rationale: Critical planning requires highest-tier model
```

**Command Integration** (/research.md Phase 0):
```bash
# Load agent model overrides from CLAUDE.md
RESEARCH_MODEL=$(grep -A2 "research-specialist:" CLAUDE.md | grep "model:" | awk '{print $2}')
RESEARCH_MODEL="${RESEARCH_MODEL:-sonnet-4.5}"  # Default if not specified

# Use model in Task invocation
Task {
  subagent_type: "general-purpose"
  model: "$RESEARCH_MODEL"
  prompt: "Read and follow behavioral guidelines from research-specialist.md..."
}
```

**Benefits**:
- Zero complexity in command code (~10 lines total)
- User control via CLAUDE.md configuration
- Project-specific customization without code changes
- Fallback to agent default if not specified
- No error tracking or monitoring infrastructure needed

**Trade-offs**:
- Manual configuration required (not automatic)
- No dynamic adjustment based on task complexity
- Users must understand model characteristics
- Global per-agent setting (not per-invocation)

**Cost Impact**:
- Potential savings: Up to 24% if user configures Haiku for all research
- Risk: Over-optimization by users (quality degradation)
- Mitigation: Document model capabilities in CLAUDE.md

**Implementation Time**: 1.5 hours
- 30 minutes: Add CLAUDE.md section with agent model configuration
- 30 minutes: Update /research command to load configuration
- 30 minutes: Document in Model Selection Guide

**Lines of Code**: ~15 lines total (vs 85+ for dynamic routing)

### Alternative 2: User-Specified --model Flag

**Approach**: Add --model flag to /research command for explicit user control.

**Implementation** (/research.md):

```bash
# Parse command arguments
RESEARCH_MODEL="sonnet-4.5"  # Default

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)
      RESEARCH_MODEL="$2"
      shift 2
      ;;
    --model=*)
      RESEARCH_MODEL="${1#*=}"
      shift
      ;;
    *)
      RESEARCH_TOPIC="$1"
      shift
      ;;
  esac
done

# Validate model name
case "$RESEARCH_MODEL" in
  haiku-4.5|sonnet-4.5|opus-4.1)
    echo "Using model: $RESEARCH_MODEL"
    ;;
  *)
    echo "ERROR: Invalid model '$RESEARCH_MODEL'. Valid options: haiku-4.5, sonnet-4.5, opus-4.1"
    exit 1
    ;;
esac

# Use in Task invocation
Task {
  model: "$RESEARCH_MODEL"
  ...
}
```

**Usage Examples**:
```bash
# Use default (Sonnet)
/research "authentication patterns"

# Override to Haiku for simple research
/research "authentication patterns" --model haiku-4.5

# Override to Opus for complex research
/research "distributed systems architecture" --model opus-4.1
```

**Benefits**:
- Explicit user control per invocation
- No automatic complexity detection needed
- Simple validation (3 valid model names)
- Self-documenting (--help output)
- No monitoring or error tracking infrastructure

**Trade-offs**:
- User must specify model explicitly
- No automatic optimization
- Users must understand task complexity
- Additional command-line argument

**Cost Impact**:
- Savings depend on user behavior (opt-in)
- No automatic cost reduction
- Users can optimize for their use case

**Implementation Time**: 2 hours
- 45 minutes: Add argument parsing logic
- 45 minutes: Add validation and error handling
- 30 minutes: Document in command guide

**Lines of Code**: ~25 lines (vs 85+ for dynamic routing)

### Alternative 3: Environmental Complexity Hints

**Approach**: Use simple heuristics (not LLM classification) for automatic model selection.

**Implementation** (/research.md Phase 0):

```bash
# Detect complexity using simple heuristics
RESEARCH_TOPIC="$1"
WORD_COUNT=$(echo "$RESEARCH_TOPIC" | wc -w)
HAS_ARCHITECTURAL_KEYWORDS=$(echo "$RESEARCH_TOPIC" | grep -Ei "architect|system|design|pattern|framework" && echo "yes" || echo "no")

# Simple model selection
if [ "$WORD_COUNT" -le 3 ] && [ "$HAS_ARCHITECTURAL_KEYWORDS" = "no" ]; then
  RESEARCH_MODEL="haiku-4.5"  # Simple topics
elif [ "$HAS_ARCHITECTURAL_KEYWORDS" = "yes" ]; then
  RESEARCH_MODEL="sonnet-4.5"  # Architectural topics
else
  RESEARCH_MODEL="sonnet-4.5"  # Default to Sonnet
fi

echo "Detected complexity: $RESEARCH_MODEL (topic: $RESEARCH_TOPIC)"
```

**Heuristics**:
- Word count ≤3 words + no architectural keywords → Haiku
- Contains "architect|system|design|pattern|framework" → Sonnet
- Default → Sonnet (conservative)

**Benefits**:
- Automatic model selection
- No dependency on Spec 678 classification
- Simple bash logic (no LLM calls)
- Fast execution (<1ms)
- No state dependency

**Trade-offs**:
- Low accuracy vs LLM classification
- Keyword matching brittle (false positives/negatives)
- No subtopic decomposition awareness
- Conservative defaults (less cost savings)

**Cost Impact**:
- Estimated savings: 10-15% (vs 24% for dynamic routing)
- Lower savings due to conservative defaults
- No monitoring needed (fail-safe approach)

**Implementation Time**: 1 hour
- 30 minutes: Implement heuristic logic
- 15 minutes: Test with sample research topics
- 15 minutes: Document heuristics

**Lines of Code**: ~15 lines (vs 85+ for dynamic routing)

### Alternative 4: No Dynamic Routing + User Education

**Approach**: Keep current static Sonnet configuration, educate users on manual optimization.

**Implementation**: NONE (current state)

**User Education** (Model Selection Guide enhancement):

```markdown
## Research Model Selection

The /research command uses Sonnet 4.5 by default for all research operations.

**When to Override**:
- **Simple Pattern Discovery**: Use haiku-4.5 (24% cost savings)
  - Example: "authentication patterns in auth/ directory"
  - Characteristics: Single file/directory, concrete topic

- **Complex Architectural Analysis**: Use sonnet-4.5 or opus-4.1
  - Example: "distributed caching strategies across microservices"
  - Characteristics: Multiple systems, design decisions

**Override Methods**:
1. CLAUDE.md configuration (project-wide)
2. --model flag (per-invocation)

See [Agent Model Configuration](#agent-model-configuration) for details.
```

**Benefits**:
- Zero implementation time
- Zero code changes
- Zero risk of quality degradation
- Users optimize based on their knowledge
- No monitoring infrastructure needed

**Trade-offs**:
- No automatic cost savings
- Users must read documentation
- Manual optimization effort
- Relies on user understanding of complexity

**Cost Impact**:
- Zero savings without user action
- Maximum savings (24%) if users optimize manually
- No monitoring or error tracking needed

**Implementation Time**: 30 minutes (documentation only)

**Lines of Code**: 0 (no code changes)

### Comparison Matrix

| Approach | Implementation Time | Lines of Code | Automatic | User Control | Cost Savings | Risk |
|----------|-------------------|--------------|-----------|--------------|--------------|------|
| Dynamic Routing (Current Plan) | 6 hours | 85+ lines | Yes | No | 24% | High (monitoring, fallback) |
| Static CLAUDE.md Config | 1.5 hours | 15 lines | No | Full | Up to 24% | Low (explicit config) |
| --model Flag | 2 hours | 25 lines | No | Per-invocation | Variable | Low (explicit flag) |
| Environmental Hints | 1 hour | 15 lines | Yes | No | 10-15% | Medium (heuristic accuracy) |
| No Routing + Education | 0.5 hours | 0 lines | No | Manual | Up to 24% | Minimal (doc-only) |

### Codebase Context: Current /research Command Structure

Examined /coordinate.md to understand how /research integrates with orchestration:

**Finding**: /research is NOT a standalone command file. Research operations are embedded within /coordinate.md orchestration workflow.

**Evidence**:
```bash
$ ls -la .claude/commands/ | grep research
-rw-r--r-- 1 benjamin benjamin  5438 Nov 12 10:00 research.md
```

**Analysis**: The /research.md file exists and would be the integration point for any model selection logic.

**Implications for Alternatives**:
- All alternatives apply to /research.md Phase 0 (research decomposition)
- Static configuration and flags work identically for standalone or orchestrated invocation
- Dynamic routing requires state dependency on /coordinate sm_init() (Spec 678)
- Environmental hints work independently (no orchestration dependency)

### Risk Analysis: Dynamic Routing Complexity

**Infrastructure Dependencies** (High Risk):
1. **State Persistence**: Depends on Spec 678 workflow state containing RESEARCH_COMPLEXITY
2. **Monitoring System**: Requires error rate tracking across 2-week period
3. **Fallback Logic**: Haiku failure detection and Sonnet retry coordination
4. **Test Infrastructure**: 6 test categories for complexity validation

**Failure Modes**:
- State file missing/corrupted → No RESEARCH_COMPLEXITY available
- RESEARCH_COMPLEXITY not set → Fallback to default (Sonnet)
- Haiku research quality degradation → Requires monitoring to detect
- Error rate threshold breach → Manual intervention needed
- Fallback retry failures → Escalation path unclear

**Maintenance Burden**:
- Monitoring infrastructure (log parsing, metric tracking)
- Threshold tuning (5% error rate threshold may need adjustment)
- False positive handling (Haiku failures unrelated to model capability)
- Documentation updates (workflow state schema, error handling)

**Comparison**: Static configuration has zero failure modes (explicit config or default).

## Recommendations

### Recommendation 1: Adopt Static CLAUDE.md Configuration (Highest Priority)

**Rationale**: Provides 90% of the benefits of dynamic routing with 5% of the complexity.

**Implementation**:
1. Add "Agent Model Configuration" section to CLAUDE.md
2. Update /research.md to load configuration (10 lines)
3. Document in Model Selection Guide

**Benefits**:
- 1.5 hours implementation (vs 6 hours for dynamic routing)
- 15 lines of code (vs 85+ lines)
- Zero monitoring infrastructure
- Full user control
- Project-specific customization
- No dependency on Spec 678 state

**User Experience**:
- Add to CLAUDE.md: `research-specialist: haiku-4.5` for cost optimization
- Automatic application to all /research invocations
- Override by removing line (fallback to agent default)

**Cost Savings**: Up to 24% (user-dependent)

### Recommendation 2: Add --model Flag as Escape Hatch (Medium Priority)

**Rationale**: Provides per-invocation control for exceptional cases.

**Implementation**:
1. Add argument parsing to /research.md
2. Validate model name (3 options)
3. Pass to Task invocation

**Benefits**:
- 2 hours implementation
- 25 lines of code
- No monitoring infrastructure
- Per-invocation granularity
- Overrides CLAUDE.md configuration

**User Experience**:
- `/research "topic" --model haiku-4.5` for explicit optimization
- `/research "topic"` uses CLAUDE.md config or default

**Cost Savings**: Variable (opt-in per invocation)

### Recommendation 3: Document Model Selection in User Guide (High Priority)

**Rationale**: Enable users to make informed decisions regardless of implementation.

**Implementation**:
1. Enhance Model Selection Guide with research examples
2. Document complexity characteristics (simple vs complex)
3. Provide optimization recommendations

**Benefits**:
- 30 minutes implementation
- Zero code changes
- Works with any alternative approach
- Empowers user optimization

**Cost Savings**: Depends on user adoption (0-24%)

### Recommendation 4: Defer Dynamic Routing (Lowest Priority)

**Rationale**: Complexity and monitoring burden not justified by $1.87 annual savings.

**Analysis**:
- Annual savings: $1.87 (10 research invocations/week baseline)
- Implementation cost: 6 hours × $50/hour = $300 (break-even: 160 years)
- Monitoring cost: ~1 hour/month × $50/hour = $600/year
- Net cost: -$598.13 annually (negative ROI)

**Recommendation**: Defer indefinitely unless research volume increases 100x.

## References

- /home/benjamin/.config/.claude/specs/677_and_the_agents_in_claude_agents_in_order_to_rank/plans/001_command_agent_optimization.md (lines 1-741)
  - Line 99-122: Dynamic routing technical design
  - Line 336-351: Phase 5 implementation tasks
  - Line 414-421: Phase 6 complexity routing validation
- /home/benjamin/.config/.claude/agents/research-specialist.md (lines 1-7): Agent frontmatter with model configuration
- /home/benjamin/.config/.claude/commands/coordinate.md: Orchestration workflow integration
- /home/benjamin/.config/CLAUDE.md: Project standards and configuration location
