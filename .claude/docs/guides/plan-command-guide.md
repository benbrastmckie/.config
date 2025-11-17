# /plan Command - Complete Guide

**Executable**: `.claude/commands/plan.md`

**Quick Start**: Run `/plan "<feature description>" [report-path1] [report-path2]` - creates implementation plans guided by research reports.

---

## Table of Contents

1. [Overview and Purpose](#1-overview-and-purpose)
2. [Quick Start](#2-quick-start)
3. [Usage Examples](#3-usage-examples)
4. [Feature Analysis](#4-feature-analysis)
5. [Research Delegation](#5-research-delegation)
6. [Plan Validation](#6-plan-validation)
7. [Expansion Evaluation](#7-expansion-evaluation)
8. [Standards Compliance](#8-standards-compliance)
9. [Troubleshooting](#9-troubleshooting)
10. [Advanced Topics](#10-advanced-topics)
11. [Agent Integration](#11-agent-integration)
12. [API Reference](#12-api-reference)
13. [Execution Phases](#13-execution-phases)
14. [Plan Structure](#14-plan-structure)
15. [See Also](#15-see-also)

---

## 1. Overview and Purpose

The `/plan` command creates comprehensive implementation plans following project standards, optionally incorporating insights from research reports. It serves as the planning phase of the research → plan → implement → document workflow.

### Key Capabilities

- **Feature complexity pre-analysis**: Estimates complexity using LLM classification with heuristic fallback
- **Automatic research delegation**: Invokes research agents for complex features (complexity ≥7)
- **Standards discovery**: Extracts and applies project standards from CLAUDE.md
- **Report integration**: Incorporates findings from research reports with 95% context reduction
- **Topic-based organization**: Creates organized spec directories with numbered topics
- **Metadata-rich plans**: Includes complexity scores, dependencies, success criteria
- **Plan validation**: Validates against 8 required metadata fields and project standards
- **Expansion evaluation**: Recommends phase expansion for complex plans

### When to Use

Use `/plan` when you need to:

- **Create implementation plans** for new features
- **Plan refactoring** or architecture changes
- **Document complex bug fixes** requiring multiple phases
- **Integrate research findings** into actionable plans
- **Establish project structure** before implementation

Do NOT use `/plan` when:

- You already have a plan and need to execute it → Use `/implement`
- You need to research a topic first → Use `/research`
- You need to expand existing plan phases → Use `/expand`
- You want quick prototyping without planning overhead

### Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│ /plan Command Architecture                                           │
└──────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
        ┌───────────────────────────────────────┐
        │ Phase 0: Initialization               │
        │ → State management                    │
        │ → Path pre-calculation                │
        │ → Library sourcing                    │
        └───────────────────────────────────────┘
                                │
                                ▼
        ┌───────────────────────────────────────┐
        │ Phase 1: Feature Analysis (LLM)       │
        │ → Complexity classification           │
        │ → Heuristic fallback                  │
        │ → Research trigger evaluation         │
        └───────────────────────────────────────┘
                                │
                                ▼
                   ┌────────────────────────┐
                   │ Complexity ≥7?         │
                   └────────────────────────┘
                      │                  │
                 YES  │                  │  NO
                      ▼                  │
        ┌───────────────────────────┐   │
        │ Phase 1.5: Research       │   │
        │ → Topic generation        │   │
        │ → Parallel agents         │   │
        │ → Metadata extraction     │   │
        └───────────────────────────┘   │
                      │                  │
                      └──────┬───────────┘
                             ▼
        ┌───────────────────────────────────────┐
        │ Phase 2: Standards Discovery          │
        │ → Find CLAUDE.md                      │
        │ → Extract standards                   │
        │ → Create minimal if missing           │
        └───────────────────────────────────────┘
                                │
                                ▼
        ┌───────────────────────────────────────┐
        │ Phase 3: Plan Creation (Agent)        │
        │ → Invoke plan-architect               │
        │ → Behavioral injection                │
        │ → Mandatory verification              │
        └───────────────────────────────────────┘
                                │
                                ▼
        ┌───────────────────────────────────────┐
        │ Phase 4: Plan Validation              │
        │ → Metadata validation                 │
        │ → Standards compliance                │
        │ → Dependency checks                   │
        └───────────────────────────────────────┘
                                │
                                ▼
        ┌───────────────────────────────────────┐
        │ Phase 5: Expansion Evaluation         │
        │ → Check complexity ≥8                 │
        │ → Recommend /expand                   │
        └───────────────────────────────────────┘
                                │
                                ▼
        ┌───────────────────────────────────────┐
        │ Phase 6: Plan Presentation            │
        │ → Summary output                      │
        │ → Next steps                          │
        └───────────────────────────────────────┘
```

### Command Flow Overview

1. **Input**: Feature description + optional research reports
2. **Analysis**: LLM classifies complexity, determines research needs
3. **Research** (conditional): Parallel research agents create reports
4. **Standards**: Discover CLAUDE.md, extract project standards
5. **Planning**: plan-architect agent creates implementation plan
6. **Validation**: Validate metadata, standards, dependencies
7. **Output**: Plan file + validation report + next steps

---

## 2. Quick Start

### Installation

The `/plan` command is part of the .claude/ system. No separate installation needed if you have the .claude/ directory structure.

**Verify installation**:
```bash
ls -la .claude/commands/plan.md
ls -la .claude/agents/plan-architect.md
ls -la .claude/lib/
```

### Basic Usage

Create a simple plan:

```bash
/plan "Add dark mode toggle to settings page"
```

### What to Expect

**Terminal Output**:
```
=========================================
PLAN CREATED SUCCESSFULLY
=========================================

Feature: Add dark mode toggle to settings page
Plan location: /home/user/project/specs/001_dark_mode/plans/001_implementation_plan.md
Complexity: 4/10
Phases: 4
Tasks: 12

Validation: ✓ Passed

Next steps:
  1. Review plan: cat specs/001_dark_mode/plans/001_implementation_plan.md
  2. Implement: /implement specs/001_dark_mode/plans/001_implementation_plan.md
```

**Files Created**:
```
specs/
└── 001_dark_mode/
    ├── plans/
    │   └── 001_implementation_plan.md    # Your plan
    └── reports/                           # Empty (no research needed)
```

### Next Steps After Plan Creation

1. **Review the plan**: Read through to understand phases and tasks
2. **Validate assumptions**: Check complexity and time estimates
3. **Expand if needed**: For complex plans (≥8), consider `/expand`
4. **Begin implementation**: Run `/implement <plan-path>`
5. **Track progress**: Use checkboxes in plan to track completion

---

## 3. Usage Examples

### Example 1: Simple Feature (No Research)

**Scenario**: Add a UI button with basic functionality

**Command**:
```bash
/plan "Add export button to dashboard that downloads data as CSV"
```

**Expected Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
COMPLEXITY PRE-ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Estimated complexity: 3/10 (Low)
Recommended structure: single-file
Suggested phases: 3-4
Matching templates: ui-feature

Recommendations:
- Simple feature, no research needed
- Straightforward implementation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Creating plan...

=========================================
PLAN CREATED SUCCESSFULLY
=========================================

Feature: Add export button to dashboard that downloads data as CSV
Plan location: /home/user/project/specs/002_export_button/plans/002_implementation_plan.md
Complexity: 3/10
Phases: 3
Tasks: 9

Validation: ✓ Passed

Next steps:
  1. Review plan: cat specs/002_export_button/plans/002_implementation_plan.md
  2. Implement: /implement specs/002_export_button/plans/002_implementation_plan.md
```

**Generated Plan Preview** (abbreviated):
```markdown
# Implementation Plan: Export Button Feature

## Metadata
- **Plan ID**: 002
- **Complexity**: 3/10
- **Estimated Duration**: 4 hours
- **Structure Level**: 0 (Single-file)

## Implementation Phases

### Phase 1: UI Implementation
- [ ] Add export button to dashboard
- [ ] Style button with existing theme
- [ ] Add click handler

### Phase 2: CSV Export Logic
- [ ] Implement data-to-CSV conversion
- [ ] Handle edge cases (empty data, special chars)
- [ ] Add download trigger

### Phase 3: Testing
- [ ] Unit tests for CSV conversion
- [ ] Integration tests for button click
- [ ] Manual testing across browsers
```

### Example 2: Complex Feature (With Automatic Research)

**Scenario**: Major architectural change triggering automatic research

**Command**:
```bash
/plan "Migrate authentication system from JWT to OAuth2 with support for multiple providers"
```

**Expected Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
COMPLEXITY PRE-ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Estimated complexity: 8/10 (High)
Recommended structure: single-file (expand during implementation)
Suggested phases: 7-9
Matching templates: architecture-migration

Recommendations:
- High complexity detected - delegating research
- Consider phase expansion for complex phases
- Migration requires careful planning and rollback strategy

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Delegating research to specialist agents...

Research topic 1: OAuth2 authentication architecture patterns
  Agent: research-specialist
  Output: specs/003_oauth_migration/reports/001_oauth2_architecture.md
  Status: ✓ Complete (2.3s)

Research topic 2: JWT to OAuth2 migration strategies
  Agent: research-specialist
  Output: specs/003_oauth_migration/reports/002_migration_strategies.md
  Status: ✓ Complete (1.9s)

Research topic 3: Multi-provider OAuth2 implementation
  Agent: research-specialist
  Output: specs/003_oauth_migration/reports/003_provider_support.md
  Status: ✓ Complete (2.1s)

Extracting research metadata...
Context reduction: 6000 tokens → 300 tokens (95% reduction)

Creating plan with research integration...

=========================================
PLAN CREATED SUCCESSFULLY
=========================================

Feature: Migrate authentication system from JWT to OAuth2
Plan location: /home/user/project/specs/003_oauth_migration/plans/003_implementation_plan.md
Complexity: 8/10
Phases: 8
Tasks: 34

Research reports: 3
  - specs/003_oauth_migration/reports/001_oauth2_architecture.md
  - specs/003_oauth_migration/reports/002_migration_strategies.md
  - specs/003_oauth_migration/reports/003_provider_support.md

Validation: ✓ Passed (with 2 warning(s) - review recommended)

RECOMMENDATION: Consider using /expand command for detailed phase breakdown
Command: /expand specs/003_oauth_migration/plans/003_implementation_plan.md

Expansion provides:
  - Detailed task breakdown per phase
  - Granular dependency management
  - Better progress tracking

Next steps:
  1. Review research: ls specs/003_oauth_migration/reports/
  2. Review plan: cat specs/003_oauth_migration/plans/003_implementation_plan.md
  3. Expand phases: /expand specs/003_oauth_migration/plans/003_implementation_plan.md
  4. Implement: /implement specs/003_oauth_migration/plans/003_implementation_plan.md
```

**Generated Plan Preview** (abbreviated):
```markdown
# Implementation Plan: OAuth2 Authentication Migration

## Metadata
- **Plan ID**: 003
- **Complexity**: 8/10
- **Estimated Duration**: 40 hours
- **Research Reports**:
  - reports/001_oauth2_architecture.md
  - reports/002_migration_strategies.md
  - reports/003_provider_support.md

## Research Findings Summary

### OAuth2 Architecture Patterns
- Authorization Code flow recommended for web apps
- PKCE extension required for security
- Token refresh strategy needed

### Migration Strategy
- Parallel run approach: support both JWT and OAuth2 during transition
- Feature flag for gradual rollout
- Data migration for existing sessions

### Provider Support
- Start with Google and GitHub
- Abstract provider interface for easy additions
- Handle provider-specific quirks in adapters

## Implementation Phases

### Phase 1: OAuth2 Infrastructure Setup
Dependencies: None
- [ ] Install OAuth2 libraries
- [ ] Configure provider credentials
- [ ] Set up authorization endpoints

### Phase 2: Provider Abstraction Layer
Dependencies: [1]
- [ ] Define provider interface
- [ ] Implement Google provider adapter
- [ ] Implement GitHub provider adapter
- [ ] Add provider registry

### Phase 3: Token Management
Dependencies: [1]
- [ ] Implement token storage
- [ ] Add token refresh logic
- [ ] Handle token expiration

### Phase 4: Parallel Run Support
Dependencies: [2, 3]
- [ ] Add feature flag for OAuth2
- [ ] Support both JWT and OAuth2 auth
- [ ] Add migration endpoint

### Phase 5: Data Migration
Dependencies: [4]
- [ ] Migrate existing user sessions
- [ ] Update user records
- [ ] Verify migration success

### Phase 6: Testing
Dependencies: [5]
- [ ] Unit tests for all components
- [ ] Integration tests for auth flows
- [ ] Load testing for token refresh
- [ ] Security audit

### Phase 7: Rollout
Dependencies: [6]
- [ ] Enable OAuth2 for 10% of users
- [ ] Monitor metrics and errors
- [ ] Gradually increase to 100%

### Phase 8: Cleanup
Dependencies: [7]
- [ ] Remove JWT code paths
- [ ] Remove feature flags
- [ ] Update documentation
```

### Example 3: With Existing Research Reports

**Scenario**: You've already done research and want to create a plan based on it

**Command**:
```bash
/plan "Refactor plugin system to support lazy loading" \
  specs/004_plugin_refactor/reports/001_lazy_loading_analysis.md \
  specs/004_plugin_refactor/reports/002_performance_impact.md
```

**Expected Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
COMPLEXITY PRE-ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Estimated complexity: 7/10 (Medium-High)
Recommended structure: single-file
Suggested phases: 5-7
Matching templates: refactor

Recommendations:
- Research reports provided - skipping research delegation
- Refactoring requires careful testing
- Performance validation needed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Integrating provided research reports...

Report 1: specs/004_plugin_refactor/reports/001_lazy_loading_analysis.md
  Summary: Analysis of lazy loading patterns for plugin systems
  Key findings: 3 patterns identified, defer-load recommended

Report 2: specs/004_plugin_refactor/reports/002_performance_impact.md
  Summary: Performance benchmarks for lazy loading strategies
  Key findings: 60% startup time reduction, 30% memory savings

Creating plan with research integration...

=========================================
PLAN CREATED SUCCESSFULLY
=========================================

Feature: Refactor plugin system to support lazy loading
Plan location: /home/user/project/specs/004_plugin_refactor/plans/004_implementation_plan.md
Complexity: 7/10
Phases: 6
Tasks: 24

Research reports: 2
  - specs/004_plugin_refactor/reports/001_lazy_loading_analysis.md
  - specs/004_plugin_refactor/reports/002_performance_impact.md

Validation: ✓ Passed

Next steps:
  1. Review research: cat specs/004_plugin_refactor/reports/*.md
  2. Review plan: cat specs/004_plugin_refactor/plans/004_implementation_plan.md
  3. Implement: /implement specs/004_plugin_refactor/plans/004_implementation_plan.md
```

### Example 4: Multi-Word Descriptions and Special Characters

**Scenario**: Complex feature descriptions requiring proper quoting

**Command**:
```bash
# Correct: Use quotes for multi-word descriptions
/plan "Add caching layer with Redis for API responses (GET only)"

# Incorrect: Without quotes - only "Add" will be parsed
/plan Add caching layer with Redis
```

**Special Character Handling**:
```bash
# Parentheses and symbols are fine within quotes
/plan "Implement A/B testing framework (50/50 split)"

# Environment variables work
/plan "Deploy to $ENVIRONMENT with blue-green strategy"

# Paths can be relative or absolute
/plan "feature" specs/reports/001.md
/plan "feature" /home/user/project/specs/reports/001.md
```

**Multi-Line Descriptions** (using heredoc):
```bash
/plan "$(cat <<'EOF'
Implement comprehensive logging system with:
- Structured logging (JSON format)
- Multiple log levels (debug, info, warn, error)
- Log rotation and archival
- Integration with monitoring tools
EOF
)"
```

### Example 5: Batch Planning Workflow

**Scenario**: Planning multiple related features

**Command**:
```bash
# Create plans for related features
/plan "User authentication"
/plan "User profile management"
/plan "User settings page"

# Review all plans
ls specs/*/plans/*.md

# Implement in order
/implement specs/001_authentication/plans/001_implementation_plan.md
/implement specs/002_profile/plans/002_implementation_plan.md
/implement specs/003_settings/plans/003_implementation_plan.md
```

---

## 4. Feature Analysis

The `/plan` command performs complexity pre-analysis before creating plans. This section details the analysis process.

**Implementation**: See `plan.md` Phase 1 (lines 186-299) for complete LLM classification and heuristic fallback algorithm.

### LLM Classification Process

**Primary Method**: Uses Claude Haiku 4 for fast, accurate complexity classification.

**Classification Prompt Structure**:
```
Analyze this feature description for implementation complexity:

"<feature description>"

Provide a complexity score (1-10) considering:
- Technical depth (APIs, databases, authentication, etc.)
- Scope breadth (single component vs. system-wide)
- Integration points (dependencies on other systems)
- Risk factors (breaking changes, data migrations)
- Uncertainty level (clear requirements vs. vague)

Return JSON:
{
  "estimated_complexity": <1-10>,
  "suggested_phases": <3-10>,
  "template_type": "<architecture|feature|bugfix|refactor>",
  "keywords": ["keyword1", "keyword2"],
  "requires_research": <true|false>,
  "reasoning": "Brief explanation"
}
```

**LLM Response Example**:
```json
{
  "estimated_complexity": 7,
  "suggested_phases": 6,
  "template_type": "feature",
  "keywords": ["authentication", "OAuth2", "migrate"],
  "requires_research": true,
  "reasoning": "Migration from JWT to OAuth2 requires architectural changes, provider integration, and data migration. Multiple integration points increase complexity."
}
```

### Heuristic Fallback Algorithm

**Trigger**: Used when LLM unavailable or fails

**Algorithm**:

1. **Keyword Scoring**:
```bash
KEYWORD_SCORE=0

# High complexity keywords (8 points)
if [[ "$DESCRIPTION" =~ (architecture|migrate|redesign) ]]; then
  KEYWORD_SCORE=8

# Medium-high keywords (6 points)
elif [[ "$DESCRIPTION" =~ (refactor|integrate|system) ]]; then
  KEYWORD_SCORE=6

# Medium keywords (4 points)
elif [[ "$DESCRIPTION" =~ (implement|create|build) ]]; then
  KEYWORD_SCORE=4

# Low keywords (2 points)
else
  KEYWORD_SCORE=2
fi
```

2. **Length Scoring**:
```bash
WORD_COUNT=$(echo "$DESCRIPTION" | wc -w)
LENGTH_SCORE=0

if [[ $WORD_COUNT -gt 40 ]]; then
  LENGTH_SCORE=3
elif [[ $WORD_COUNT -gt 20 ]]; then
  LENGTH_SCORE=2
elif [[ $WORD_COUNT -gt 10 ]]; then
  LENGTH_SCORE=1
fi
```

3. **Combined Score**:
```bash
COMPLEXITY_SCORE=$((KEYWORD_SCORE + LENGTH_SCORE))
```

4. **Research Trigger**:
```bash
if [[ $COMPLEXITY_SCORE -ge 7 ]]; then
  REQUIRES_RESEARCH=true
else
  REQUIRES_RESEARCH=false
fi
```

### Complexity Score Interpretation

**Score Ranges**:

- **1-3 (Low)**: Simple feature, straightforward implementation
  - Example: "Add button to UI"
  - Phases: 2-3
  - Duration: 2-8 hours
  - Research: Not needed

- **4-6 (Medium)**: Moderate feature with some integration
  - Example: "Add CSV export functionality"
  - Phases: 3-5
  - Duration: 8-24 hours
  - Research: Optional

- **7-9 (High)**: Complex feature with significant integration
  - Example: "Migrate to OAuth2 authentication"
  - Phases: 6-8
  - Duration: 24-80 hours
  - Research: Recommended (triggered automatically)

- **10+ (Very High)**: Major architectural changes
  - Example: "Redesign entire data layer with event sourcing"
  - Phases: 8-12
  - Duration: 80+ hours
  - Research: Required (triggered automatically)

### Keyword Detection

**High Complexity Keywords** (trigger research):
- architecture, design, redesign
- migrate, migration
- integrate, integration
- refactor (with system scope)
- performance (optimization)

**Medium Complexity Keywords**:
- implement, create, build
- add (with integration)
- update, enhance
- refactor (single component)

**Low Complexity Keywords**:
- add (simple UI)
- fix, patch
- update (content only)
- style, format

### Research Delegation Triggers

Research delegation activates when:

1. **Complexity threshold**: `estimated_complexity >= 7`
2. **Architecture keywords**: Detected in feature description
3. **Manual override**: `--force-research` flag (future)

**Trigger Logic**:
```bash
if [[ $COMPLEXITY -ge 7 ]] || [[ "$KEYWORDS" =~ (architecture|migrate|integrate) ]]; then
  echo "Triggering research delegation..."
  invoke_research_agents
fi
```

### Template Type Determination

Based on complexity analysis, recommends plan template:

- **architecture**: Major design changes (complexity ≥8)
- **feature**: New functionality (complexity 4-7)
- **bugfix**: Issue resolution (complexity 2-4)
- **refactor**: Code improvement (complexity 3-6)

**Template Selection Logic**:
```bash
if [[ "$KEYWORDS" =~ architecture ]]; then
  TEMPLATE="architecture"
elif [[ "$KEYWORDS" =~ (implement|create|build) ]]; then
  TEMPLATE="feature"
elif [[ "$KEYWORDS" =~ (fix|bug|issue) ]]; then
  TEMPLATE="bugfix"
elif [[ "$KEYWORDS" =~ refactor ]]; then
  TEMPLATE="refactor"
else
  TEMPLATE="feature"  # Default
fi
```

---

## 5. Research Delegation

For complex features, the command automatically delegates research to specialized agents.

**Implementation**: See `plan.md` Phase 1.5 (lines 301-547) for complete research delegation logic.

### When Research is Triggered

**Automatic Triggers**:
1. **Complexity ≥7**: From feature analysis
2. **Architecture keywords**: architecture, design, migrate, refactor, integrate, performance
3. **Multiple integration points**: Detected in description

**Manual Triggers** (future):
- `--force-research` flag
- `--research-topics="topic1,topic2"` flag

### Topic Generation Logic

**Topic Count Determination**:
```bash
if [[ $COMPLEXITY -ge 9 ]]; then
  TOPIC_COUNT=4
elif [[ $COMPLEXITY -ge 7 ]]; then
  TOPIC_COUNT=3
else
  TOPIC_COUNT=2
fi
```

**Keyword-Based Topic Selection**:

1. **Extract keywords** from feature description
2. **Map keywords to research topics**:
   - "authentication" → "Authentication patterns and security best practices"
   - "OAuth2" → "OAuth2 implementation strategies"
   - "migrate" → "Migration strategies and rollback planning"
   - "performance" → "Performance optimization techniques"
   - "database" → "Database design patterns"

3. **Generic topics** if insufficient keywords:
   - "Implementation approaches and architectural patterns"
   - "Best practices and common pitfalls"
   - "Testing strategies and quality assurance"

**Topic Generation Example**:
```bash
# Feature: "Migrate authentication from JWT to OAuth2"
# Keywords: migrate, authentication, OAuth2

RESEARCH_TOPICS=(
  "OAuth2 authentication architecture patterns"
  "JWT to OAuth2 migration strategies"
  "Authentication security best practices"
)
```

### Parallel Agent Invocation

**Pre-Calculation** (STANDARD 16):
All report paths calculated BEFORE any agent invocation:

```bash
# Pre-calculate ALL paths
REPORT_PATHS=()
for i in $(seq 1 $TOPIC_COUNT); do
  REPORT_NUM=$(printf "%03d" $i)
  REPORT_PATH="$TOPIC_DIR/reports/${REPORT_NUM}_research.md"
  REPORT_PATHS+=("$REPORT_PATH")
done
```

**Parallel Invocation**:
```bash
# Invoke all agents in parallel
for i in $(seq 0 $((${#RESEARCH_TOPICS[@]} - 1))); do
  TOPIC="${RESEARCH_TOPICS[$i]}"
  OUTPUT_PATH="${REPORT_PATHS[$i]}"

  # Invoke agent (runs in parallel)
  Task {
    subagent_type: "general-purpose"
    description: "Research: $TOPIC"
    prompt: |
      Read and follow behavioral guidelines from:
      ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

      Research Topic: $TOPIC
      Feature Context: $FEATURE_DESCRIPTION
      Output Path: $OUTPUT_PATH

      EXECUTE NOW: Create research report with findings, recommendations, and risks.
  }
done

# Wait for all agents to complete
wait
```

**Time Savings**:
- Sequential: 3 agents × 2s = 6s
- Parallel: max(2s, 2s, 2s) = 2s
- Savings: 66% (4s saved)

### Metadata Extraction and Context Reduction

**Extraction Process**:
```bash
for REPORT_PATH in "${REPORT_PATHS[@]}"; do
  # Extract metadata section (first 250 tokens)
  METADATA=$(head -c 1000 "$REPORT_PATH" | \
    sed -n '/## Summary/,/##/p' | \
    head -c 250)

  # Cache to workflow state
  state_set "research_metadata_$i" "$METADATA"
done
```

**Context Reduction Example**:
```
Before: 2000 tokens (full report)
After: 100 tokens (metadata only)
Reduction: 95%
```

**Metadata Format**:
```json
{
  "report_path": "specs/003/reports/001_research.md",
  "summary": "Analysis of OAuth2 patterns...",
  "key_findings": [
    "Authorization Code flow recommended",
    "PKCE extension required",
    "Token refresh strategy needed"
  ],
  "recommendations": [
    "Use authorization code flow",
    "Implement PKCE",
    "Add token refresh logic"
  ]
}
```

### Graceful Degradation on Failures

**Failure Scenarios**:
1. **Agent unavailable**: Skip research, continue with planning
2. **Report creation failed**: Use partial research from successful agents
3. **Metadata extraction failed**: Use first 250 characters as fallback

**Degradation Logic**:
```bash
# Check if agent succeeded
if [[ ! -f "$REPORT_PATH" ]]; then
  echo "WARNING: Research agent failed for topic: $TOPIC"
  echo "Continuing with available research..."
  continue
fi

# Verify report size
REPORT_SIZE=$(wc -c < "$REPORT_PATH")
if [[ $REPORT_SIZE -lt 500 ]]; then
  echo "WARNING: Research report unusually small: $REPORT_PATH"
  echo "Report may be incomplete - review manually"
fi

# Extract metadata with fallback
METADATA=$(extract_metadata "$REPORT_PATH") || \
  METADATA=$(head -c 250 "$REPORT_PATH")
```

**Partial Research Handling**:
```bash
SUCCESSFUL_REPORTS=0
for REPORT_PATH in "${REPORT_PATHS[@]}"; do
  [[ -f "$REPORT_PATH" ]] && ((SUCCESSFUL_REPORTS++))
done

if [[ $SUCCESSFUL_REPORTS -eq 0 ]]; then
  echo "ERROR: All research agents failed"
  echo "Proceeding without research (may reduce plan quality)"
elif [[ $SUCCESSFUL_REPORTS -lt ${#REPORT_PATHS[@]} ]]; then
  echo "WARNING: Only $SUCCESSFUL_REPORTS/${#REPORT_PATHS[@]} research reports created"
  echo "Plan quality may be reduced"
fi
```

### Research Integration into Plan

**Context Injection**:
```json
{
  "feature_description": "<feature>",
  "output_path": "<plan-path>",
  "complexity": 8,
  "report_paths": [
    "specs/003/reports/001_oauth2_architecture.md",
    "specs/003/reports/002_migration_strategies.md"
  ],
  "research_metadata": [
    {
      "path": "specs/003/reports/001_oauth2_architecture.md",
      "summary": "OAuth2 patterns analysis...",
      "key_findings": [...]
    },
    {
      "path": "specs/003/reports/002_migration_strategies.md",
      "summary": "Migration strategies...",
      "key_findings": [...]
    }
  ]
}
```

**Plan-Architect Usage**:
The plan-architect agent receives research metadata and:
1. Incorporates findings into phase design
2. References reports in plan metadata
3. Uses recommendations for task breakdown
4. Includes risks in risk assessment section

---

## 6. Plan Validation

After plan creation, the command validates the plan against project standards.

**Implementation**: See `plan.md` Phase 4 (lines 770-890) for complete validation logic.

### Validation Library Overview

**Library**: `$UTILS_DIR/validate-plan.sh`

**Sourced in**: Phase 0 (initialization)

**Functions**:
- `validate_plan_metadata()`: Check required metadata fields
- `validate_plan_dependencies()`: Check phase dependencies
- `validate_plan_standards()`: Check standards compliance
- `validate_plan_structure()`: Check plan structure

**Validation Report Format**:
```json
{
  "summary": {
    "errors": 0,
    "warnings": 2,
    "plan_path": "/path/to/plan.md"
  },
  "metadata": {
    "valid": true,
    "missing": []
  },
  "dependencies": {
    "valid": true,
    "issues": []
  },
  "standards": {
    "valid": true,
    "issues": ["Missing test coverage target"]
  },
  "structure": {
    "valid": true,
    "issues": []
  }
}
```

### 8 Required Metadata Fields

**Metadata Section Requirements**:

1. **Date Created**: `YYYY-MM-DD` format
2. **Feature**: Feature description
3. **Scope**: Brief scope description
4. **Phases**: Number of implementation phases
5. **Estimated Duration**: In hours
6. **Structure Level**: 0, 1, or 2
7. **Complexity**: Score 1-10
8. **Standards File**: Path to CLAUDE.md (or "Not found")

**Validation**:
```bash
validate_plan_metadata() {
  local PLAN_PATH="$1"
  local ERRORS=0

  # Check required fields
  REQUIRED_FIELDS=(
    "Date Created"
    "Feature"
    "Scope"
    "Phases"
    "Estimated Duration"
    "Structure Level"
    "Complexity"
    "Standards File"
  )

  for FIELD in "${REQUIRED_FIELDS[@]}"; do
    if ! grep -q "^- \*\*$FIELD\*\*:" "$PLAN_PATH"; then
      echo "ERROR: Missing required metadata field: $FIELD"
      ((ERRORS++))
    fi
  done

  return $ERRORS
}
```

### Standards Compliance Checks

**Code Standards Validation**:
```bash
# Check for code standards reference
if grep -q "Code Standards" "$PLAN_PATH"; then
  # Validate standards are applied in tasks
  if ! grep -q "following Code Standards" "$PLAN_PATH"; then
    echo "WARNING: Code Standards referenced but not applied in tasks"
  fi
fi
```

**Required Elements**:
1. **Code standards** mentioned in at least one phase
2. **Testing protocols** included in test phase
3. **Documentation policy** applied in documentation tasks

**Standards Section Check**:
```bash
# Verify standards section exists in plan
if ! grep -q "## Standards Compliance" "$PLAN_PATH"; then
  echo "WARNING: Plan missing standards compliance section"
fi
```

### Test Phase Requirements

**Test Coverage Validation**:
```bash
# Must have dedicated test phase OR test tasks in each phase
HAS_TEST_PHASE=$(grep -c "## Phase.*Test" "$PLAN_PATH")
TEST_TASK_COUNT=$(grep -c "\[ \].*test" "$PLAN_PATH")

if [[ $HAS_TEST_PHASE -eq 0 ]] && [[ $TEST_TASK_COUNT -lt 3 ]]; then
  echo "ERROR: Plan lacks adequate test coverage"
  echo "  Required: Dedicated test phase OR ≥3 test tasks"
fi
```

**Test Requirements**:
1. **Dedicated test phase** (recommended), OR
2. **Test tasks** in each implementation phase (minimum 3 total)
3. **Test coverage target** specified (e.g., ≥80%)
4. **Test location** specified (e.g., tests/ or .claude/tests/)

### Documentation Task Requirements

**Documentation Validation**:
```bash
# Check for documentation tasks
DOC_TASK_COUNT=$(grep -c "\[ \].*\(documentation\|README\|comment\)" "$PLAN_PATH")

if [[ $DOC_TASK_COUNT -eq 0 ]]; then
  echo "WARNING: Plan lacks documentation tasks"
  echo "  Recommended: Add documentation phase or tasks"
fi
```

**Documentation Requirements**:
1. **README updates** in at least one phase
2. **Inline comments** for complex logic
3. **API documentation** for public interfaces
4. **User-facing docs** for features

### Dependency Validation

**Dependency Check**:
```bash
validate_plan_dependencies() {
  local PLAN_PATH="$1"
  local ERRORS=0

  # Extract all phase dependencies
  DEPENDENCIES=$(grep "^\*\*Dependencies\*\*:" "$PLAN_PATH" | \
    sed 's/.*: \[\([^]]*\)\].*/\1/')

  # Validate each dependency
  for DEP in $DEPENDENCIES; do
    # Check dependency is a valid phase number
    if ! [[ "$DEP" =~ ^[0-9]+$ ]]; then
      echo "ERROR: Invalid dependency format: $DEP"
      ((ERRORS++))
      continue
    fi

    # Check dependency phase exists
    if ! grep -q "^### Phase $DEP:" "$PLAN_PATH"; then
      echo "ERROR: Dependency references non-existent phase: $DEP"
      ((ERRORS++))
    fi
  done

  # Check for circular dependencies
  if has_circular_dependencies "$PLAN_PATH"; then
    echo "ERROR: Circular dependencies detected"
    ((ERRORS++))
  fi

  return $ERRORS
}
```

**Dependency Rules**:
1. **Valid references**: Dependencies must reference existing phases
2. **Acyclic**: No circular dependencies allowed
3. **Forward references**: Phase N can only depend on phases < N
4. **None allowed**: "None" is valid for independent phases

### Error vs. Warning Interpretation

**Errors** (fail-fast):
- Missing required metadata fields
- Invalid phase dependencies
- Circular dependencies
- No test coverage

**Warnings** (continue with note):
- Missing documentation tasks
- Low task count (< 3 per phase)
- Standards not applied consistently
- Complexity mismatch (estimated vs. calculated)

**Exit Behavior**:
```bash
if [[ $ERROR_COUNT -gt 0 ]]; then
  echo "✗ Validation failed with $ERROR_COUNT error(s)"
  echo "Plan not created - fix errors and retry"
  exit 1
fi

if [[ $WARNING_COUNT -gt 0 ]]; then
  echo "✓ Validation passed with $WARNING_COUNT warning(s)"
  echo "Review warnings before proceeding"
fi
```

---

## 7. Expansion Evaluation

After validation, the command evaluates whether phase expansion is recommended.

**Implementation**: See `plan.md` Phase 5 (lines 892-931) for expansion evaluation logic.

### When Expansion is Recommended

**Expansion Triggers**:

1. **High complexity**: `complexity >= 8`
2. **Many phases**: `phase_count >= 7`
3. **Large phases**: Any phase with >15 tasks

**Trigger Logic**:
```bash
SHOULD_EXPAND=false

# Check complexity threshold
if [[ $COMPLEXITY -ge 8 ]]; then
  SHOULD_EXPAND=true
  EXPAND_REASON="High complexity ($COMPLEXITY/10)"
fi

# Check phase count
if [[ $PHASE_COUNT -ge 7 ]]; then
  SHOULD_EXPAND=true
  EXPAND_REASON="Many phases ($PHASE_COUNT)"
fi

# Check task density
MAX_TASKS_PER_PHASE=$(grep -c "^- \[ \]" "$PLAN_PATH" | \
  awk '{max = ($1 > max ? $1 : max)} END {print max}')

if [[ $MAX_TASKS_PER_PHASE -gt 15 ]]; then
  SHOULD_EXPAND=true
  EXPAND_REASON="Dense phases ($MAX_TASKS_PER_PHASE tasks)"
fi
```

### Complexity Thresholds

**Expansion Recommendation Levels**:

- **Complexity 1-5**: No expansion needed
  - Simple features
  - Clear task breakdown

- **Complexity 6-7**: Optional expansion
  - Medium features
  - Consider for clarity

- **Complexity 8-9**: Expansion recommended
  - Complex features
  - Better progress tracking

- **Complexity 10+**: Expansion strongly recommended
  - Very complex features
  - Essential for manageability

### Benefits of Expansion

**Level 1 (Phase Expansion)**:
- **Detailed task breakdown**: Each phase in separate file
- **Better focus**: Work on one phase at a time
- **Granular dependencies**: Phase-level dependency management
- **Progress tracking**: Clear completion status per phase
- **Reduced cognitive load**: Smaller files to review

**Level 2 (Stage Expansion)**:
- **Ultra-granular**: Stages within phases in separate files
- **Team coordination**: Multiple developers per phase
- **Parallel execution**: Stages with dependencies run in parallel
- **Milestone tracking**: Stage-level milestones

### Using /expand Command

**Basic Expansion**:
```bash
# Expand all phases
/expand specs/003/plans/003_implementation_plan.md
```

**Selective Expansion**:
```bash
# Expand specific phase
/expand phase specs/003/plans/003_implementation_plan.md 2
```

**Stage Expansion**:
```bash
# Expand phase 2, stage 1
/expand stage specs/003/plans/003_implementation_plan.md 2 1
```

**Expansion Output**:
```
Expanding plan: specs/003/plans/003_implementation_plan.md
Structure level: 0 → 1

Created phase files:
  - specs/003/plans/003_implementation_plan/phase_1.md
  - specs/003/plans/003_implementation_plan/phase_2.md
  - specs/003/plans/003_implementation_plan/phase_3.md
  - specs/003/plans/003_implementation_plan/phase_4.md
  - specs/003/plans/003_implementation_plan/phase_5.md
  - specs/003/plans/003_implementation_plan/phase_6.md
  - specs/003/plans/003_implementation_plan/phase_7.md
  - specs/003/plans/003_implementation_plan/phase_8.md

Main plan updated with phase references.
Use /implement to execute phases.
```

### Expansion vs. Single-File Trade-offs

**Single-File Advantages**:
- Simple to review (one file)
- Easy to search
- No directory management
- Quick edits

**Expanded Advantages**:
- Focused work (one phase at a time)
- Better for large plans
- Team-friendly (less merge conflicts)
- Clearer progress tracking

**Recommendation**:
- Start with single-file (Level 0)
- Expand during implementation if needed
- Use `/collapse` to merge back if expansion not helpful

---

## 8. Standards Compliance

The `/plan` command implements 6 key project standards. This section details each standard and its implementation.

**Implementation**: Standards are embedded throughout `plan.md` (see Phase 0-6).

### Standard 0: Imperative Language

**Requirement**: All agent invocation prompts use imperative markers.

**Implementation**:
```bash
# Phase 3: Plan creation
Task {
  description: "Create implementation plan"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    EXECUTE NOW: Create implementation plan at: $OUTPUT_PATH
}
```

**Markers Used**:
- EXECUTE NOW
- CREATE
- GENERATE
- PERFORM

**Rationale**: Imperative language reduces ambiguity and increases agent success rate.

### Standard 11: Agent Invocation

**Requirement**: Reference agent behavioral files only, no inline duplication.

**Implementation**:
```bash
# Correct: Reference behavioral file
Task {
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md
}

# Incorrect: Inline behavioral duplication
Task {
  prompt: |
    You are a plan architect agent.
    Your job is to create implementation plans...
}
```

**Benefits**:
- Single source of truth
- Easier to update agent behavior
- Consistent agent invocations

### Standard 12: Behavioral Injection

**Requirement**: Inject workflow-specific context via JSON, keep behavioral logic in agent file.

**Implementation**:
```bash
# Agent file: .claude/agents/plan-architect.md
# Contains: Generic behavioral guidelines

# Command file: .claude/commands/plan.md
# Injects: Workflow-specific context
CONTEXT=$(cat <<EOF
{
  "feature_description": "$FEATURE_DESCRIPTION",
  "output_path": "$OUTPUT_PATH",
  "complexity": $COMPLEXITY,
  "report_paths": $(printf '%s\n' "${REPORT_PATHS[@]}" | jq -R . | jq -s .)
}
EOF
)

Task {
  prompt: |
    Read behavioral guidelines from: .claude/agents/plan-architect.md

    Workflow context:
    $CONTEXT

    EXECUTE NOW: Create plan.
}
```

**Context Structure**:
- **Input data**: Feature description, report paths
- **Output paths**: Pre-calculated absolute paths
- **Configuration**: Complexity, suggested phases
- **References**: Standards path, template type

### Standard 13: Path Handling

**Requirement**: All paths must be absolute, no relative paths.

**Implementation**:
```bash
# Phase 0: Path pre-calculation
TOPIC_DIR="$CLAUDE_PROJECT_DIR/specs/$TOPIC_NUM_$(sanitize_topic_name "$FEATURE_DESCRIPTION")"
PLAN_PATH="$TOPIC_DIR/plans/${TOPIC_NUM}_implementation_plan.md"
REPORT_DIR="$TOPIC_DIR/reports"

# Verify absolute paths
if [[ ! "$TOPIC_DIR" =~ ^/ ]]; then
  echo "ERROR: Topic directory must be absolute path"
  exit 1
fi

# Export for cross-phase access
state_set "topic_dir" "$TOPIC_DIR"
state_set "plan_path" "$PLAN_PATH"
```

**Path Pre-Calculation Benefits**:
- Prevents behavioral injection vulnerabilities
- Ensures consistency across phases
- Simplifies agent invocation

### Standard 15: Library Sourcing

**Requirement**: Source libraries in dependency order at start.

**Implementation**:
```bash
# Phase 0: Library sourcing in dependency order
source "$UTILS_DIR/workflow-state-machine.sh"  # No dependencies
source "$UTILS_DIR/state-persistence.sh"       # Depends on workflow-state-machine
source "$UTILS_DIR/error-handling.sh"          # Depends on state-persistence
source "$UTILS_DIR/verification-helpers.sh"    # Depends on error-handling
source "$UTILS_DIR/validate-plan.sh"           # Depends on verification-helpers
```

**Dependency Order**:
1. workflow-state-machine.sh (base state management)
2. state-persistence.sh (persistent state)
3. error-handling.sh (error utilities)
4. verification-helpers.sh (verification functions)
5. validate-plan.sh (plan validation)

### Standard 16: Return Code Verification

**Requirement**: Verify return codes after every agent invocation.

**Implementation**:
```bash
# Phase 3: Plan creation
Task {
  prompt: "Create plan at: $OUTPUT_PATH"
}

# MANDATORY verification
if [[ $? -ne 0 ]]; then
  echo "✗ ERROR: Agent plan-architect failed"
  exit 1
fi

# Verify output exists
if [[ ! -f "$OUTPUT_PATH" ]]; then
  echo "✗ ERROR: Agent plan-architect failed to create: $OUTPUT_PATH"
  echo "DIAGNOSTIC: Check agent output above for errors"
  exit 1
fi

# Verify output quality
PLAN_SIZE=$(wc -c < "$OUTPUT_PATH")
if [[ $PLAN_SIZE -lt 500 ]]; then
  echo "✗ ERROR: Plan unusually small ($PLAN_SIZE bytes)"
  echo "DIAGNOSTIC: Plan may be incomplete"
  exit 1
fi
```

**Verification Levels**:
1. **Return code**: Check `$?` after agent invocation
2. **File existence**: Verify expected output files created
3. **Content quality**: Check file size, required sections
4. **Metadata validation**: Validate plan structure (Phase 4)

---

## 9. Troubleshooting

This section covers common issues, diagnostic steps, and solutions.

**Implementation**: Diagnostic patterns embedded throughout `plan.md`.

### Issue 1: "File not found" Errors

**Symptom**:
```
ERROR: Report file not found: specs/003/reports/001_research.md
```

**Diagnosis**:
```bash
# Check if file exists
ls -la specs/003/reports/001_research.md

# Check parent directory
ls -la specs/003/reports/

# Check topic directory
ls -la specs/003/
```

**Common Causes**:
1. Research agent failed to create report
2. Wrong path in command
3. Permission issues

**Solutions**:
```bash
# Solution 1: Check research agent output
# Look for agent errors above the file not found error

# Solution 2: Verify path
# Ensure path is absolute or relative to project root
/plan "feature" specs/003/reports/001_research.md  # Relative
/plan "feature" /full/path/specs/003/reports/001_research.md  # Absolute

# Solution 3: Fix permissions
chmod 755 specs/003/reports
chmod 644 specs/003/reports/001_research.md
```

### Issue 2: "Relative path" Errors

**Symptom**:
```
ERROR: Relative path detected: ../specs/plans/001.md
ERROR: All paths must be absolute (start with /)
```

**Diagnosis**:
```bash
# Check how path was provided
echo "Path: ../specs/plans/001.md"
echo "Starts with /: No"

# Get absolute path
realpath ../specs/plans/001.md
```

**Common Causes**:
1. Used `../` or `./` in path
2. Used `~` for home directory
3. Used relative path from current directory

**Solutions**:
```bash
# Solution 1: Use absolute path
/plan "feature" /home/user/project/specs/reports/001.md

# Solution 2: Use $PWD
/plan "feature" $PWD/specs/reports/001.md

# Solution 3: Convert to absolute
REPORT_PATH=$(realpath specs/reports/001.md)
/plan "feature" $REPORT_PATH
```

### Issue 3: "Validation failed" Errors

**Symptom**:
```
✗ Validation failed with 3 error(s)
ERROR: Missing required metadata field: Date Created
ERROR: Missing required metadata field: Complexity
ERROR: Plan lacks adequate test coverage
```

**Diagnosis**:
```bash
# Read validation report
cat "$PLAN_PATH.validation.json" | jq

# Check metadata section
grep "## Metadata" -A 20 "$PLAN_PATH"

# Count test tasks
grep -c "\[ \].*test" "$PLAN_PATH"
```

**Common Causes**:
1. Plan template incomplete
2. Agent failed to fill metadata
3. Missing test phase

**Solutions**:
```bash
# Solution 1: Manually add missing metadata
# Edit plan and add:
# - **Date Created**: 2025-01-15
# - **Complexity**: 7/10

# Solution 2: Add test phase
# Add a dedicated testing phase with tasks

# Solution 3: Re-run plan creation
# Delete incomplete plan and retry
rm "$PLAN_PATH"
/plan "feature" [reports...]
```

### Issue 4: "Research delegation failed" Warnings

**Symptom**:
```
WARNING: Research agent failed for topic: OAuth2 patterns
Continuing with available research...
```

**Diagnosis**:
```bash
# Check agent logs
tail -n 50 .claude/logs/plan.log

# Check research reports
ls -la specs/003/reports/

# Check successful reports
find specs/003/reports/ -name "*.md" -size +1k
```

**Common Causes**:
1. Agent timeout
2. Network issues (if agent needs internet)
3. Insufficient context for research

**Solutions**:
```bash
# Solution 1: Retry with manual research
# Create research reports manually
/research "OAuth2 patterns"
/plan "feature" specs/003/reports/001_oauth2_patterns.md

# Solution 2: Continue without research
# Warning is not fatal - plan will be created with available research

# Solution 3: Simplify research topics
# Reduce complexity by breaking feature into smaller pieces
/plan "Implement OAuth2 authentication"  # Simpler
# vs.
/plan "Migrate entire auth system to OAuth2 with 5 providers"  # Too complex
```

### Issue 5: "Plan too small" Warnings

**Symptom**:
```
WARNING: Plan unusually small (342 bytes)
DIAGNOSTIC: Plan may be incomplete
```

**Diagnosis**:
```bash
# Check plan file size
wc -c "$PLAN_PATH"

# Count phases
grep -c "^### Phase" "$PLAN_PATH"

# Count tasks
grep -c "^- \[ \]" "$PLAN_PATH"

# View plan
cat "$PLAN_PATH"
```

**Common Causes**:
1. Agent failed mid-creation
2. Insufficient context for planning
3. Feature description too vague

**Solutions**:
```bash
# Solution 1: Provide more context
/plan "Add OAuth2 authentication with Google and GitHub providers, including token refresh and session management" \
  specs/reports/001_oauth2_analysis.md \
  specs/reports/002_provider_integration.md

# Solution 2: Review feature description
# Be more specific about requirements

# Solution 3: Delete and retry
rm "$PLAN_PATH"
/plan "<more detailed description>"
```

### Issue 6: Command Not Creating Plan

**Symptom**:
Command runs but no plan file appears.

**Diagnosis**:
```bash
# Check if specs directory exists
ls -la specs/

# Check permissions
ls -ld specs/

# Check disk space
df -h

# Check for errors in output
/plan "feature" 2>&1 | tee plan-debug.log
```

**Solutions**:
```bash
# Solution 1: Create specs directory
mkdir -p specs/plans

# Solution 2: Fix permissions
chmod 755 specs

# Solution 3: Check disk space
# Free up space if needed

# Solution 4: Check command output
cat plan-debug.log
```

### Issue 7: Standards Not Discovered

**Symptom**:
```
WARNING: CLAUDE.md not found
Using default standards
```

**Diagnosis**:
```bash
# Search for CLAUDE.md
find . -name "CLAUDE.md" -type f

# Check project root
ls -la CLAUDE.md

# Check parent directories
ls -la ../CLAUDE.md
```

**Solutions**:
```bash
# Solution 1: Create CLAUDE.md
/setup

# Solution 2: Move CLAUDE.md to project root
mv path/to/CLAUDE.md .

# Solution 3: Continue with defaults
# Not critical - plan will use sensible defaults
```

### Issue 8: Complexity Seems Wrong

**Symptom**:
Complexity score doesn't match expectation.

**Diagnosis**:
```bash
# Check complexity analysis
source .claude/lib/complexity-utils.sh
ANALYSIS=$(analyze_feature_description "your description")
echo "$ANALYSIS" | jq '.estimated_complexity'

# Check keywords
echo "$ANALYSIS" | jq '.keywords'

# Check reasoning
echo "$ANALYSIS" | jq '.reasoning'
```

**Solutions**:
```bash
# Solution 1: Add technical keywords
/plan "Migrate authentication to OAuth2 with database schema changes and API integration"
# Keywords: migrate, authentication, OAuth2, database, API

# Solution 2: Manually override in plan metadata
# Edit plan after creation:
# - **Complexity**: 9/10  # Increased from 7

# Solution 3: Accept heuristic estimate
# Complexity is an estimate - adjust during implementation
```

### Debug Mode Instructions

**Enable Debug Mode**:
```bash
# Set debug flag
export PLAN_DEBUG=1

# Run command
/plan "feature description"

# Debug output will show:
# - Library sourcing
# - Path calculations
# - Agent invocations
# - Validation steps
```

**Debug Output Example**:
```
[DEBUG] Sourcing library: workflow-state-machine.sh
[DEBUG] Sourcing library: state-persistence.sh
[DEBUG] Topic directory: /home/user/project/specs/001_feature
[DEBUG] Plan path: /home/user/project/specs/001_feature/plans/001_implementation_plan.md
[DEBUG] Invoking feature analysis...
[DEBUG] Complexity: 7/10
[DEBUG] Research required: true
[DEBUG] Invoking research agents...
[DEBUG] Research topic 1: Architecture patterns
[DEBUG] Agent output path: specs/001_feature/reports/001_research.md
```

### Log File Locations

**Log Files**:
```bash
# Plan command logs
.claude/logs/plan.log

# Agent logs
.claude/logs/agents/plan-architect.log
.claude/logs/agents/research-specialist.log

# Workflow state
.claude/state/workflow-*.json
```

**Viewing Logs**:
```bash
# Recent plan executions
tail -n 100 .claude/logs/plan.log

# Search for errors
grep "ERROR" .claude/logs/plan.log

# Agent-specific logs
tail -n 50 .claude/logs/agents/plan-architect.log
```

### How to Report Bugs

**Before Reporting**:
1. Check troubleshooting section
2. Review debug logs
3. Try minimal reproduction case

**Bug Report Template**:
```markdown
## Bug Description
Brief description of the issue

## Environment
- OS: Linux/macOS/Windows
- Shell: bash/zsh
- Project directory: /path/to/project

## Steps to Reproduce
1. Run: /plan "feature description"
2. Observe: <error message>

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Logs
```bash
# Relevant log output
```

## Additional Context
Any other relevant information
```

**Where to Report**:
- Project issue tracker
- Internal documentation
- Team communication channel

---

## 10. Advanced Topics

This section covers advanced use cases and customization options.

### Custom Complexity Thresholds

**Default Thresholds**:
```bash
RESEARCH_THRESHOLD=7
EXPANSION_THRESHOLD=8
```

**Customize via Environment Variables**:
```bash
# Lower research threshold for more research
export PLAN_RESEARCH_THRESHOLD=5

# Raise expansion threshold for less expansion
export PLAN_EXPANSION_THRESHOLD=9

# Run command
/plan "feature description"
```

**Customize in Configuration File**:
```bash
# Create .claude/config/plan.conf
cat > .claude/config/plan.conf <<'EOF'
# Complexity thresholds
RESEARCH_THRESHOLD=5
EXPANSION_THRESHOLD=9

# Research settings
MAX_RESEARCH_TOPICS=5
RESEARCH_TIMEOUT=300

# Validation settings
REQUIRE_TEST_PHASE=true
MIN_TASKS_PER_PHASE=3
EOF

# Configuration auto-loaded by plan command
```

### Research Topic Customization

**Manual Topic Specification** (future):
```bash
/plan "feature" \
  --research-topics="OAuth2 patterns,Migration strategies,Security best practices"
```

**Custom Topic Templates**:
```bash
# Create topic template
cat > .claude/config/research-topics.json <<'EOF'
{
  "authentication": [
    "Authentication architecture patterns",
    "Security best practices for auth",
    "Token management strategies"
  ],
  "database": [
    "Database design patterns",
    "Query optimization techniques",
    "Data migration strategies"
  ]
}
EOF

# Command detects keywords and uses templates
/plan "Implement authentication system"
# Automatically uses "authentication" templates
```

### Validation Customization

**Custom Validation Rules**:
```bash
# Create custom validator
cat > .claude/lib/custom-plan-validator.sh <<'EOF'
#!/usr/bin/env bash

validate_custom_rules() {
  local PLAN_PATH="$1"
  local ERRORS=0

  # Custom rule: All phases must have success criteria
  PHASES=$(grep -c "^### Phase" "$PLAN_PATH")
  SUCCESS_CRITERIA=$(grep -c "#### Success Criteria" "$PLAN_PATH")

  if [[ $SUCCESS_CRITERIA -lt $PHASES ]]; then
    echo "ERROR: Not all phases have success criteria"
    ((ERRORS++))
  fi

  return $ERRORS
}
EOF

# Source in plan command
# Add to Phase 4 validation
```

**Disable Specific Validations**:
```bash
# Skip test validation
export PLAN_SKIP_TEST_VALIDATION=1

# Skip documentation validation
export PLAN_SKIP_DOC_VALIDATION=1

# Run command
/plan "feature"
```

### Integration with CI/CD

**CI Pipeline Integration**:
```yaml
# .github/workflows/plan-validation.yml
name: Plan Validation

on:
  pull_request:
    paths:
      - 'specs/**/plans/*.md'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Validate Plans
        run: |
          for plan in specs/**/plans/*.md; do
            .claude/lib/validate-plan.sh "$plan"
          done
```

**Pre-commit Hook**:
```bash
# .git/hooks/pre-commit
#!/usr/bin/env bash

# Validate plans before commit
for plan in $(git diff --cached --name-only --diff-filter=AM | grep "specs/.*plans/.*\.md$"); do
  if [[ -f "$plan" ]]; then
    .claude/lib/validate-plan.sh "$plan" || exit 1
  fi
done
```

### Batch Plan Generation

**Generate Plans from List**:
```bash
# Create feature list
cat > features.txt <<'EOF'
Add user authentication
Implement dashboard
Create API endpoints
Add data export
EOF

# Generate all plans
while IFS= read -r feature; do
  /plan "$feature"
done < features.txt
```

**Parallel Plan Generation**:
```bash
# Generate plans in parallel
cat features.txt | xargs -P 4 -I {} /plan "{}"
```

**Plan from Template with Variables**:
```bash
# Template with variables
PLAN_TEMPLATE="Implement $COMPONENT with $TECHNOLOGY"

# Generate plans
for COMPONENT in "auth" "dashboard" "api"; do
  for TECHNOLOGY in "React" "Vue" "Angular"; do
    FEATURE=$(COMPONENT="$COMPONENT" TECHNOLOGY="$TECHNOLOGY" envsubst <<< "$PLAN_TEMPLATE")
    /plan "$FEATURE"
  done
done
```

### Custom Plan Templates

**Create Template**:
```bash
# Create template file
cat > .claude/templates/plans/microservice.md <<'EOF'
# Implementation Plan: {{FEATURE}}

## Metadata
- **Type**: Microservice
- **Complexity**: {{COMPLEXITY}}/10
- **Technology**: {{TECHNOLOGY}}

## Phases

### Phase 1: Service Setup
- [ ] Initialize service structure
- [ ] Configure dependencies
- [ ] Set up database

### Phase 2: API Implementation
- [ ] Define API contracts
- [ ] Implement endpoints
- [ ] Add validation

### Phase 3: Testing
- [ ] Unit tests
- [ ] Integration tests
- [ ] Load tests

### Phase 4: Deployment
- [ ] Containerize service
- [ ] Configure CI/CD
- [ ] Deploy to staging
EOF

# Use template (future feature)
/plan-from-template microservice \
  FEATURE="User Service" \
  COMPLEXITY=7 \
  TECHNOLOGY="Node.js"
```

---

## 11. Agent Integration

The `/plan` command integrates with two specialized agents. This section details agent structure, requirements, and integration patterns.

**Implementation**: Agent invocation in `plan.md` Phase 1.5 (research-specialist) and Phase 3 (plan-architect).

### Plan-Architect Agent Structure

**Agent File**: `.claude/agents/plan-architect.md`

**Purpose**: Creates comprehensive implementation plans from feature descriptions and research.

**Behavioral Guidelines** (in agent file):
```markdown
# Plan-Architect Agent

## Role
You create detailed implementation plans following project standards.

## Inputs (via behavioral injection)
- `feature_description`: What to implement
- `output_path`: Where to write plan (absolute path)
- `standards_path`: Path to CLAUDE.md
- `complexity`: Complexity score 1-10
- `suggested_phases`: Recommended phase count
- `report_paths`: Research report paths (optional)
- `research_metadata`: Research summaries (optional)

## Process
1. Read standards from `standards_path`
2. Read research reports if provided
3. Design phase breakdown based on complexity
4. Create tasks following standards
5. Add metadata, dependencies, success criteria
6. Write plan to `output_path`

## Output Format
Use uniform plan template with:
- Metadata section (8 required fields)
- Executive summary
- Implementation phases (3-12 phases)
- Dependencies, success criteria per phase
- Risk assessment
- Rollback strategy

## Quality Checks
- All phases have dependencies specified
- All phases have success criteria
- Test coverage included
- Documentation tasks included
- Standards compliance applied
```

**Invocation Pattern**:
```bash
# In plan.md Phase 3
CONTEXT=$(cat <<EOF
{
  "feature_description": "$FEATURE_DESCRIPTION",
  "output_path": "$PLAN_PATH",
  "standards_path": "$STANDARDS_PATH",
  "complexity": $COMPLEXITY,
  "suggested_phases": $SUGGESTED_PHASES,
  "report_paths": $(printf '%s\n' "${REPORT_PATHS[@]}" | jq -R . | jq -s .),
  "research_metadata": $(printf '%s\n' "${RESEARCH_METADATA[@]}" | jq -R . | jq -s .)
}
EOF
)

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan for: $FEATURE_DESCRIPTION"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    Workflow context:
    $CONTEXT

    EXECUTE NOW: Create implementation plan.
}
```

### Research-Specialist Agent Requirements

**Agent File**: `.claude/agents/research-specialist.md`

**Purpose**: Researches specific topics related to features, creating comprehensive reports.

**Behavioral Guidelines** (in agent file):
```markdown
# Research-Specialist Agent

## Role
You research technical topics and create comprehensive reports.

## Inputs (via behavioral injection)
- `research_topic`: What to research
- `output_path`: Where to write report (absolute path)
- `feature_context`: Related feature description
- `standards_path`: Path to CLAUDE.md
- `complexity_level`: Feature complexity 1-10

## Process
1. Understand research topic and context
2. Research using available tools (WebSearch, documentation)
3. Analyze findings for relevance to feature
4. Organize into structured report
5. Write report to `output_path`

## Output Format
Research report with:
- Summary (250 tokens max for metadata extraction)
- Key findings (bullet points)
- Recommendations (actionable)
- Risks and considerations
- References and sources

## Quality Checks
- Summary is concise (≤250 tokens)
- Findings are relevant to feature
- Recommendations are actionable
- Risks are clearly identified
```

**Invocation Pattern**:
```bash
# In plan.md Phase 1.5
for TOPIC in "${RESEARCH_TOPICS[@]}"; do
  CONTEXT=$(cat <<EOF
{
  "research_topic": "$TOPIC",
  "output_path": "$REPORT_PATH",
  "feature_context": "$FEATURE_DESCRIPTION",
  "standards_path": "$STANDARDS_PATH",
  "complexity_level": $COMPLEXITY
}
EOF
)

  Task {
    subagent_type: "general-purpose"
    description: "Research: $TOPIC"
    prompt: |
      Read and follow behavioral guidelines from:
      ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

      Workflow context:
      $CONTEXT

      EXECUTE NOW: Create research report.
  }
done
```

### Behavioral Injection Pattern

**Pattern**: Separate behavioral guidelines from workflow-specific context.

**Behavioral File** (agent-specific):
```markdown
# Agent Behavioral Guidelines

## Role
General role description

## Process
Generic process steps

## Output Format
Generic output format

## Quality Checks
Generic quality checks
```

**Command File** (workflow-specific):
```bash
# Inject workflow context via JSON
CONTEXT=$(cat <<EOF
{
  "input": "workflow-specific input",
  "output_path": "pre-calculated absolute path",
  "config": "workflow-specific config"
}
EOF
)

# Reference behavioral file + inject context
Task {
  prompt: |
    Read behavioral guidelines from: .claude/agents/AGENT.md

    Workflow context:
    $CONTEXT

    EXECUTE NOW: Perform task.
}
```

**Benefits**:
1. **Single source of truth**: Behavioral logic in one place
2. **Easy updates**: Update agent file, all workflows benefit
3. **Testability**: Test behavioral guidelines separately
4. **Flexibility**: Same agent, different workflows

### Context Passing Conventions

**JSON Structure**:
```json
{
  "required_inputs": {
    "feature_description": "What to implement",
    "output_path": "/absolute/path/to/output.md"
  },
  "optional_inputs": {
    "standards_path": "/path/to/CLAUDE.md",
    "complexity": 7,
    "report_paths": ["/path/to/report1.md"]
  },
  "configuration": {
    "suggested_phases": 6,
    "template_type": "feature"
  }
}
```

**Naming Conventions**:
- **Inputs**: Lowercase with underscores (e.g., `feature_description`)
- **Paths**: Always absolute, end with `_path` (e.g., `output_path`)
- **Counts**: Numeric values (e.g., `complexity`, `suggested_phases`)
- **Flags**: Boolean values (e.g., `requires_research`)

**Path Pre-Calculation**:
All paths calculated BEFORE agent invocation:
```bash
# Phase 0: Pre-calculate paths
OUTPUT_PATH="$TOPIC_DIR/plans/${TOPIC_NUM}_implementation_plan.md"

# Phase 3: Pass to agent
CONTEXT='{"output_path": "'$OUTPUT_PATH'"}'
```

### Return Signal Format

**Success Signal**:
```
✓ Plan created: /path/to/plan.md
```

**Failure Signal**:
```
✗ ERROR: Plan creation failed
DIAGNOSTIC: <error details>
```

**Verification**:
```bash
# After agent invocation
if [[ ! -f "$OUTPUT_PATH" ]]; then
  echo "✗ ERROR: Agent failed to create output"
  exit 1
fi

# Check return code
if [[ $? -ne 0 ]]; then
  echo "✗ ERROR: Agent returned non-zero exit code"
  exit 1
fi
```

**Agent Output Format**:
Agents should output:
1. **Progress updates**: During execution
2. **Final status**: Success or failure with details
3. **File path**: Location of created file
4. **Metadata** (optional): Summary, key findings, etc.

---

## 12. API Reference

Complete reference for command-line arguments, environment variables, state format, and exit codes.

### Command-Line Arguments

**Syntax**:
```bash
/plan "<feature description>" [report-path1] [report-path2] ...
```

**Arguments**:

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `feature description` | String | Yes | Feature to implement (quoted if multi-word) |
| `report-path` | Path | No | Path to research report(s) in specs/ |

**Examples**:
```bash
# Minimal
/plan "Add button"

# With description
/plan "Add export button with CSV download"

# With research report
/plan "Feature" specs/001/reports/001_research.md

# With multiple reports
/plan "Feature" report1.md report2.md report3.md
```

**Future Flags** (planned):
```bash
--force-research          # Force research delegation
--research-topics="t1,t2" # Specify research topics
--template=TYPE           # Use specific template
--skip-validation         # Skip validation phase
--dry-run                 # Show what would be created
```

### Environment Variables

**Configuration Variables**:

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_PROJECT_DIR` | (detected) | Project root directory |
| `PLAN_RESEARCH_THRESHOLD` | 7 | Complexity threshold for research |
| `PLAN_EXPANSION_THRESHOLD` | 8 | Complexity threshold for expansion |
| `PLAN_DEBUG` | 0 | Enable debug output (1=on, 0=off) |
| `PLAN_SKIP_VALIDATION` | 0 | Skip validation phase |
| `PLAN_SKIP_TEST_VALIDATION` | 0 | Skip test coverage validation |
| `PLAN_SKIP_DOC_VALIDATION` | 0 | Skip documentation validation |

**Agent Configuration**:

| Variable | Default | Description |
|----------|---------|-------------|
| `PLAN_AGENT_TIMEOUT` | 300 | Agent timeout in seconds |
| `PLAN_MAX_RESEARCH_TOPICS` | 4 | Max research topics |
| `PLAN_RESEARCH_TIMEOUT` | 180 | Research agent timeout |

**Path Configuration**:

| Variable | Default | Description |
|----------|---------|-------------|
| `SPECS_DIR` | specs/ | Specifications directory |
| `CLAUDE_DIR` | .claude/ | Claude system directory |
| `UTILS_DIR` | .claude/lib/ | Utility library directory |

**Usage**:
```bash
# Set before command
export PLAN_RESEARCH_THRESHOLD=5
/plan "feature"

# Set inline
PLAN_DEBUG=1 /plan "feature"

# Set in config file
echo "PLAN_RESEARCH_THRESHOLD=5" >> .claude/config/plan.conf
/plan "feature"
```

### State File Format

**State Location**: `.claude/state/workflow-plan-XXXXXXXX.json`

**State Structure**:
```json
{
  "workflow_id": "plan-1705334400",
  "created_at": "2025-01-15T10:00:00Z",
  "phase": "plan_creation",
  "feature_description": "Add OAuth2 authentication",
  "topic_dir": "/home/user/project/specs/003_oauth_auth",
  "plan_path": "/home/user/project/specs/003_oauth_auth/plans/003_implementation_plan.md",
  "report_dir": "/home/user/project/specs/003_oauth_auth/reports",
  "complexity": 8,
  "suggested_phases": 7,
  "requires_research": true,
  "research_topics": [
    "OAuth2 authentication patterns",
    "Migration strategies",
    "Security best practices"
  ],
  "report_paths": [
    "/home/user/project/specs/003_oauth_auth/reports/001_oauth2_patterns.md",
    "/home/user/project/specs/003_oauth_auth/reports/002_migration.md",
    "/home/user/project/specs/003_oauth_auth/reports/003_security.md"
  ],
  "research_metadata": [
    {
      "path": "specs/003_oauth_auth/reports/001_oauth2_patterns.md",
      "summary": "OAuth2 patterns analysis...",
      "key_findings": ["finding1", "finding2"]
    }
  ],
  "standards_path": "/home/user/project/CLAUDE.md",
  "validation_status": "passed",
  "validation_warnings": 2,
  "expansion_recommended": true
}
```

**State Access**:
```bash
# Read state
state_get "plan_path"

# Write state
state_set "complexity" 8

# List all state
state_dump

# Clear state
state_clear
```

### Validation Report JSON Schema

**Report Location**: `$PLAN_PATH.validation.json`

**Schema**:
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "summary": {
      "type": "object",
      "properties": {
        "errors": {"type": "integer"},
        "warnings": {"type": "integer"},
        "plan_path": {"type": "string"},
        "validated_at": {"type": "string", "format": "date-time"}
      },
      "required": ["errors", "warnings", "plan_path"]
    },
    "metadata": {
      "type": "object",
      "properties": {
        "valid": {"type": "boolean"},
        "missing": {"type": "array", "items": {"type": "string"}}
      }
    },
    "dependencies": {
      "type": "object",
      "properties": {
        "valid": {"type": "boolean"},
        "issues": {"type": "array", "items": {"type": "string"}}
      }
    },
    "standards": {
      "type": "object",
      "properties": {
        "valid": {"type": "boolean"},
        "issues": {"type": "array", "items": {"type": "string"}}
      }
    },
    "structure": {
      "type": "object",
      "properties": {
        "valid": {"type": "boolean"},
        "phase_count": {"type": "integer"},
        "task_count": {"type": "integer"},
        "issues": {"type": "array", "items": {"type": "string"}}
      }
    }
  },
  "required": ["summary", "metadata", "dependencies", "standards", "structure"]
}
```

**Example Report**:
```json
{
  "summary": {
    "errors": 0,
    "warnings": 2,
    "plan_path": "/home/user/project/specs/003/plans/003_plan.md",
    "validated_at": "2025-01-15T10:05:00Z"
  },
  "metadata": {
    "valid": true,
    "missing": []
  },
  "dependencies": {
    "valid": true,
    "issues": []
  },
  "standards": {
    "valid": true,
    "issues": [
      "Test coverage target not specified",
      "Documentation tasks minimal"
    ]
  },
  "structure": {
    "valid": true,
    "phase_count": 7,
    "task_count": 28,
    "issues": []
  }
}
```

### Exit Codes

**Exit Code Reference**:

| Code | Meaning | Description |
|------|---------|-------------|
| 0 | Success | Plan created successfully |
| 1 | General error | Unspecified error occurred |
| 2 | Invalid arguments | Missing or invalid command arguments |
| 3 | File not found | Required file not found |
| 4 | Permission denied | Insufficient permissions |
| 5 | Validation failed | Plan validation errors |
| 6 | Agent failed | Agent invocation failed |
| 7 | Path error | Invalid or relative path |
| 8 | State error | Workflow state corruption |
| 9 | Standards error | CLAUDE.md not found or invalid |
| 10 | Research failed | All research agents failed |

**Usage in Scripts**:
```bash
# Check exit code
/plan "feature"
EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]]; then
  echo "Success!"
elif [[ $EXIT_CODE -eq 5 ]]; then
  echo "Validation failed - check plan and retry"
elif [[ $EXIT_CODE -eq 6 ]]; then
  echo "Agent failed - check logs"
else
  echo "Error code: $EXIT_CODE"
fi
```

**Error Handling**:
```bash
# Exit on any error
set -e
/plan "feature"

# Continue on error
set +e
/plan "feature" || echo "Plan creation failed, continuing..."

# Capture and handle
if ! /plan "feature"; then
  echo "Plan creation failed"
  # Cleanup or retry logic
fi
```

---

## 13. Execution Phases

The `/plan` command executes through 7 distinct phases. This section provides conceptual overviews - for implementation details, see `plan.md` lines 17-981.

### Phase 0: Orchestrator Initialization

**Purpose**: Initialize state management, detect project directory, pre-calculate all artifact paths.

**Implementation**: `plan.md` lines 17-184

**Key Operations**:
- Source libraries in dependency order (workflow state machine → state persistence → error handling → verification helpers)
- Parse feature description and optional report paths
- Validate absolute paths (STANDARD 13)
- Allocate topic directory atomically using unified location detection
- Pre-calculate plan output path BEFORE any agent invocations (critical for behavioral injection)
- Export all paths to workflow state for cross-phase access

**Path Pre-Calculation Strategy**: All artifact paths are calculated in Phase 0 to prevent behavioral injection vulnerabilities. This ensures agents receive fully-formed output paths as input, eliminating path negotiation during execution.

**State Management**: Uses workflow state machine for persistent state across phases, with automatic cleanup on exit.

### Phase 1: Feature Analysis (LLM Classification)

**Purpose**: Analyze feature complexity using LLM classification, with heuristic fallback.

**Implementation**: `plan.md` lines 186-299

**Key Operations**:
- Design classification prompt for haiku-4 model
- Invoke LLM classifier via Task tool (imperative marker: EXECUTE NOW)
- Fallback to heuristic algorithm if LLM unavailable
- Extract complexity score, suggested phases, research requirements
- Cache analysis results to workflow state

**Heuristic Algorithm** (used when LLM unavailable):

1. **Keyword Scoring**:
   - "architecture|migrate|redesign" → 8 points
   - "refactor|integrate|system" → 6 points
   - "implement|create|build" → 4 points
   - Default → 2 points

2. **Length Scoring**:
   - >40 words → 3 points
   - >20 words → 2 points
   - >10 words → 1 point

3. **Combined Score**: `COMPLEXITY_SCORE = KEYWORD_SCORE + LENGTH_SCORE`

4. **Research Trigger**: `requires_research = (COMPLEXITY_SCORE >= 7)`

**Output Format**:
```json
{
  "estimated_complexity": <1-10>,
  "suggested_phases": <3-10>,
  "template_type": "<architecture|feature|bugfix|refactor>",
  "keywords": ["keyword1", "keyword2"],
  "requires_research": <true|false>
}
```

### Phase 1.5: Research Delegation (Conditional)

**Purpose**: For complex features (complexity ≥7), delegate research to specialist agents.

**Implementation**: `plan.md` lines 301-547

**Trigger Conditions**:
- Complexity ≥7, OR
- Architecture keywords detected ("architecture", "design", "migrate", "refactor", "integrate", "performance")

**Research Topic Generation**:
- Topic count: 2-4 based on complexity (9+ → 4 topics, 7-8 → 3 topics, default → 2 topics)
- Generated from keyword analysis of feature description
- Generic topics added if keyword analysis yields insufficient topics

**Agent Invocation Strategy**:
- Pre-calculate ALL report paths BEFORE any agent invocation (STANDARD 16)
- Invoke research-specialist agents in parallel (40-60% time savings)
- Each agent receives: topic, output path, feature context, standards path, complexity level
- MANDATORY verification after EACH agent completes (STANDARD 0)
- Graceful degradation: Continue with partial research if agents fail

**Metadata Extraction**:
- Extract 250-token summaries from each report (95% context reduction: 2000 tokens → 100 tokens)
- Cache metadata to workflow state for plan-architect context injection
- Fallback to first 250 chars if metadata extraction fails

**Output**: Array of research report paths and metadata summaries saved to workflow state.

### Phase 2: Standards Discovery

**Purpose**: Discover CLAUDE.md and extract project standards.

**Implementation**: `plan.md` lines 550-602

**Discovery Process**:
1. Start from `CLAUDE_PROJECT_DIR`
2. Search upward for CLAUDE.md
3. Stop at first match or root directory
4. Create minimal CLAUDE.md if not found

**Minimal CLAUDE.md Template** (auto-created if missing):
```markdown
# Project Configuration

## Code Standards
- Follow language-specific conventions
- Use consistent indentation (2 spaces)
- Add comprehensive comments

## Testing Protocols
- Test coverage target: ≥80%
- Test location: tests/ or .claude/tests/
- Run tests before commits

## Documentation Policy
- Update README with changes
- Document public APIs
- Use clear, concise language
```

**Cache**: Standards file path saved to workflow state for plan-architect context injection.

### Phase 3: Plan Creation via Plan-Architect Agent

**Purpose**: Invoke plan-architect agent to create implementation plan with behavioral injection.

**Implementation**: `plan.md` lines 604-768

**Agent Invocation Pattern** (STANDARD 12):
- Reference agent behavioral file ONLY: `.claude/agents/plan-architect.md`
- No inline duplication of agent logic
- Imperative invocation marker: EXECUTE NOW
- Use Task tool with `subagent_type=general-purpose`

**Workflow-Specific Context** (injected via JSON):
```json
{
  "feature_description": "<feature>",
  "output_path": "<pre-calculated absolute path>",
  "standards_path": "<CLAUDE.md path>",
  "complexity": <1-10>,
  "suggested_phases": <3-10>,
  "report_paths": ["<path1>", "<path2>"]
}
```

**Temporary Fallback**: If agent not available, creates basic plan structure with metadata and phase placeholders.

**MANDATORY Verification** (STANDARD 0):
- File exists at expected path
- File size ≥500 bytes (basic plan check)
- Phase count ≥3 (minimum structure)
- Checkbox count ≥10 (task tracking for `/implement`)

**Error Diagnostic Template**:
```
✗ ERROR: Agent plan-architect failed to create: <path>
DIAGNOSTIC: Check agent output above for errors
DIAGNOSTIC: Expected file at: <path>
DIAGNOSTIC: Parent directory: <dirname>
DIAGNOSTIC: Directory exists: yes/no
```

### Phase 4: Plan Validation

**Purpose**: Validate created plan against project standards.

**Implementation**: `plan.md` lines 770-890

**Validation Library**: `$UTILS_DIR/validate-plan.sh` (sourced in Phase 0)

**Validation Checks**:
1. **Metadata Validation**: Required fields (Date, Feature, Scope, Phases, Hours, Structure Level, Complexity, Standards File)
2. **Dependency Validation**: Phase dependencies are valid and acyclic
3. **Standards Compliance**: Code standards, testing protocols, documentation policy adherence
4. **Test Coverage**: Test requirements present in phases
5. **Documentation**: Documentation requirements present in phases

**Output Format**:
```json
{
  "summary": {
    "errors": <count>,
    "warnings": <count>
  },
  "metadata": {
    "valid": <true|false>,
    "missing": ["<field1>", "<field2>"]
  },
  "dependencies": {
    "valid": <true|false>,
    "issues": ["<issue1>", "<issue2>"]
  },
  "standards": {
    "valid": <true|false>,
    "issues": ["<issue1>", "<issue2>"]
  }
}
```

**Fail-Fast** (STANDARD 0): Exit with error if validation finds critical errors (error count > 0).

**Graceful Degradation**: Skip validation if library not available (non-critical).

### Phase 5: Expansion Evaluation (Conditional)

**Purpose**: Evaluate if plan requires phase expansion based on complexity.

**Implementation**: `plan.md` lines 892-931

**Expansion Triggers**:
- Complexity ≥8, OR
- Phase count ≥7

**Expansion Recommendation**:
```
RECOMMENDATION: Consider using /expand command for detailed phase breakdown
Command: /expand <plan-path>

Expansion provides:
  - Detailed task breakdown per phase
  - Granular dependency management
  - Better progress tracking
  - Reduced cognitive load during implementation
```

**Note**: All plans start as Level 0 (single-file) regardless of complexity. Expansion is a post-creation operation.

### Phase 6: Plan Presentation

**Purpose**: Present plan summary to user with next steps.

**Implementation**: `plan.md` lines 933-981

**Output Format**:
```
=========================================
PLAN CREATED SUCCESSFULLY
=========================================

Feature: <description>
Plan location: <path>
Complexity: <N>/10
Phases: <count>
Tasks: <count>

Research reports: <count>
  - <path1>
  - <path2>

Validation: ✓ Passed
  (with N warning(s) - review recommended)

Next steps:
  1. Review plan: cat <path>
  2. Expand phases: /expand <path>  (recommended if complexity ≥8)
  3. Implement: /implement <path>
```

**Conditional Elements**:
- Research reports: Only shown if Phase 1.5 executed
- Validation status: Only shown if Phase 4 executed
- Expansion recommendation: Only shown if expansion needed (Phase 5)

---

## 14. Plan Structure

**Implementation**: See `plan.md` Phase 3 (lines 604-768) for plan creation logic and template generation.

### Uniform Plan Template

All plans follow a uniform structure regardless of complexity:

```markdown
# Implementation Plan: <Feature Name>

## Metadata
- **Plan ID**: NNN
- **Date Created**: YYYY-MM-DD
- **Type**: [Architecture/Feature/Bugfix/Refactor]
- **Scope**: Brief scope description
- **Priority**: [HIGH/MEDIUM/LOW]
- **Complexity**: N/10
- **Estimated Duration**: N hours
- **Standards File**: /path/to/CLAUDE.md
- **Related Specs**: []
- **Structure Level**: 0 (Single-file)

## Executive Summary

### Problem Statement
What problem does this solve?

### Solution Overview
High-level solution approach

### Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2

### Benefits
Key benefits of implementing this

---

## Implementation Phases

### Phase N: Phase Name

**Objective**: What this phase accomplishes

**Dependencies**: [Phase numbers or "None"]

**Complexity**: N/10

**Duration**: N hours

#### Tasks

- [ ] Task 1
- [ ] Task 2

#### Deliverables

1. Deliverable 1
2. Deliverable 2

#### Success Criteria

- [ ] Criterion 1
- [ ] Criterion 2

---

## Rollback Strategy

How to rollback if issues occur

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Risk 1 | Low/Medium/High | Low/Medium/High | How to mitigate |

---

## Success Metrics

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Metric 1 | Target | How to measure |

---

## Completion Criteria

This plan is complete when:
1. Criterion 1
2. Criterion 2
```

### Topic-Based Organization

Plans are organized in topic-based directories:

```
specs/
├── 001_authentication/
│   ├── plans/
│   │   └── 001_implementation_plan.md
│   ├── reports/
│   │   └── 001_research.md
│   └── summaries/
│       └── 001_implementation_summary.md
├── 042_database_migration/
│   ├── plans/
│   │   └── 042_implementation_plan.md
│   └── reports/
│       ├── 042_migration_analysis.md
│       └── 042_performance_benchmarks.md
└── SPECS.md
```

### Progressive Plan Levels

Plans support three structure levels:

- **Level 0** (Single-file): All phases inline (default for all new plans)
- **Level 1** (Phase-expanded): Complex phases in separate files (created via `/expand phase`)
- **Level 2** (Stage-expanded): Stages in separate files (created via `/expand stage`)

**Note**: All plans start as Level 0 regardless of complexity. Use `/expand` during implementation if phases become too complex.

---

## 15. See Also

- [/implement Command Guide](implement-command-guide.md) - Executing implementation plans
- [/research Command Guide](research-command-guide.md) - Creating research reports
- [/expand Command Guide](expand-command-guide.md) - Expanding phases/stages
- [/plan-from-template Command](../commands/plan-from-template.md) - Template-based planning
- [Directory Protocols](../concepts/directory-protocols.md) - Spec directory organization
- [Command Development Guide](command-development-guide.md) - Developing slash commands
- [Workflow State Machine](../reference/workflow-state-machine.md) - State management system
- [Plan Validation Library](../reference/plan-validation.md) - Validation details
