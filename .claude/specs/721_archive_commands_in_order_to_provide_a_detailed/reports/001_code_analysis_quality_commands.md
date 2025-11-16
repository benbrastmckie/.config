# Code Analysis and Quality Commands Research Report

## Metadata
- **Date**: 2025-11-15
- **Agent**: research-specialist
- **Topic**: Code Analysis and Quality Commands (refactor.md, analyze.md)
- **Report Type**: codebase analysis
- **Complexity Level**: 4

## Executive Summary

The archived `/refactor` and `/analyze` commands provide comprehensive code quality analysis and performance monitoring capabilities. The `/refactor` command orchestrates standards-based code review through delegation to the `code-reviewer` agent, while `/analyze` offers multi-dimensional system performance analysis including agent metrics, command bottlenecks, and usage trends. Both commands emphasize file creation enforcement, structured reporting, and actionable recommendations with quantified metrics.

**Key Findings**:
- `/refactor` implements mandatory file creation through orchestration delegation and fallback mechanisms
- `/analyze` provides three analysis modes (agents, metrics, patterns) with timeframe filtering
- Agent performance tracking includes efficiency scoring, tool usage analysis, and error pattern detection
- Standards-based code review supports multi-language detection patterns with severity classification

## Findings

### /refactor Command Analysis

#### Architecture and Delegation Pattern

The `/refactor` command implements a **single-agent orchestration pattern** rather than performing direct analysis:

**File**: `/home/benjamin/.config/.claude/archive/commands/refactor.md:11-19`
```markdown
**YOU MUST orchestrate refactoring analysis by delegating to code-reviewer agent.**

**YOUR ROLE**: You are the REFACTORING ORCHESTRATOR, not the code analyzer.
- **DO NOT** analyze code yourself using Read/Grep/Glob tools
- **ONLY** use Task tool to invoke code-reviewer agent for analysis
- **YOUR RESPONSIBILITY**: Determine scope, invoke agent, verify report creation
```

This separation of concerns achieves:
- **Clear responsibility boundaries**: Orchestrator manages workflow, agent performs analysis
- **Reusability**: Code-reviewer agent can be invoked by multiple commands
- **Context optimization**: Agent receives only analysis-relevant context
- **Fail-fast verification**: Orchestrator validates artifact creation

#### Code Quality Detection Categories

The code-reviewer agent examines six major categories (**refactor.md:86-116**):

**1. Code Quality Issues**:
- Duplication: Repeated code patterns requiring abstraction
- Complexity: Functions/modules exceeding maintainability thresholds
- Dead Code: Unused functions, variables, imports
- Inconsistent Patterns: Deviations from established conventions

**2. Nix-Specific Issues** (language-specific example):
- Indentation: Non-2-space violations
- Line Length: >80 character violations
- File Organization: Misplaced configurations
- Import Structure: Circular or inefficient dependencies
- Package Definitions: Non-idiomatic expressions

**3. Structure and Architecture**:
- Module Boundaries: Poorly defined or violated separation
- Coupling: Tight dependencies requiring loosening
- Cohesion: Low cohesion modules requiring splitting
- Layering: Architectural layer violations

**4. Testing Gaps**:
- Missing Tests: Components without coverage
- Test Quality: Tests not following standards
- Test Organization: Misplaced or disorganized tests

**5. Documentation Issues**:
- Missing Documentation: Undocumented complex logic
- Outdated Docs: Documentation-implementation mismatches
- Spec Compliance: Missing plans/reports per directory protocols

**6. Standards Violations**: Language-agnostic checking against CLAUDE.md

#### Refactoring Opportunity Categorization

The code-reviewer agent applies three-dimensional assessment (**refactor.md:119-138**):

**Priority Levels**:
- **Critical**: Breaking standards, bugs, security issues
- **High**: Significant maintainability/performance issues
- **Medium**: Quality improvements, better standards adherence
- **Low**: Nice-to-have improvements, minor inconsistencies

**Effort Estimation**:
- **Quick Win**: <30 minutes, isolated changes
- **Small**: 30 min - 2 hours, single file/module
- **Medium**: 2-8 hours, multiple files, testing required
- **Large**: 8+ hours, architectural changes, extensive testing

**Risk Assessment**:
- **Safe**: No functional changes, purely cosmetic
- **Low Risk**: Minor functional changes, well-tested
- **Medium Risk**: Significant changes, thorough testing needed
- **High Risk**: Core functionality changes, breaking changes possible

This matrix enables data-driven prioritization: "Quick Win + Safe + High Priority" recommendations are ideal first targets.

#### Report Structure Standards

Refactoring reports follow comprehensive template (**refactor-structure.md:19-431**):

**Required Sections** (ALL mandatory):
1. **Executive Summary**: High-level findings, 3-5 key findings, overall assessment
2. **Critical Issues**: Must-fix problems (bugs, security, major violations)
3. **Refactoring Opportunities**: Six categories (duplication, complexity, standards, architecture, testing, docs)
4. **Implementation Roadmap**: Phased approach with effort/risk estimates
5. **Testing Strategy**: Verification approach for safe refactoring
6. **Migration Path**: Step-by-step application guide
7. **Metrics**: Files analyzed, issues found, effort estimates, expected benefits

**Content Requirements**:
- All findings include file:line references
- Specific remediation suggestions for each issue
- Priority matrix for scheduling work
- Code examples showing before/after
- Standards reference with violation locations

#### File Creation Enforcement

Multi-layer verification ensures 100% report creation (**refactor.md:149-242**):

**Step 1 - Path Pre-Calculation** (refactor.md:155-183):
```bash
# Calculate report path BEFORE agent invocation
SPECS_DIR="${CLAUDE_PROJECT_DIR}/specs"
REPORT_NUM=$(find "$SPECS_DIR/reports" -name "*_refactoring_*.md" | wc -l)
REPORT_PATH="$SPECS_DIR/reports/$(printf "%03d" $((REPORT_NUM + 1)))_refactoring_${SCOPE_SLUG}.md"
```

**Step 2 - Mandatory Verification** (refactor.md:204-229):
```bash
if [[ ! -f "$REPORT_PATH" ]]; then
  echo "❌ CRITICAL ERROR: Refactoring report not created"

  # FALLBACK: Search alternative locations
  FOUND_REPORT=$(find "$SPECS_DIR" -name "*refactoring*.md" -type f -newer /tmp/refactor_start | head -1)

  if [[ -n "$FOUND_REPORT" ]]; then
    REPORT_PATH="$FOUND_REPORT"
  else
    exit 1
  fi
fi

# Verify minimum content
REPORT_LINES=$(wc -l < "$REPORT_PATH")
[[ $REPORT_LINES -lt 50 ]] && echo "⚠️ WARNING: Report seems incomplete"
```

This achieves:
- **Pre-calculation**: Path known before agent invocation
- **Verification**: File existence check with size validation
- **Fallback search**: Locate report if created at alternate path
- **Quality gate**: Minimum line count ensures substantive content

#### Multi-Language Support

The code-reviewer agent adapts detection patterns by file type (**code-reviewer.md:343-369**):

**Lua Detection Patterns**:
- Tab detection: `grep -P '\t' file.lua` (BLOCKING)
- Line length: `awk 'length > 100 {print NR": "length" chars"}' file.lua` (WARNING)
- Naming: `grep -nE '[a-z][A-Z]' file.lua | grep -v '-- '` (WARNING - camelCase detection)
- Error handling: `grep -n 'io\.' file.lua | grep -v 'pcall'` (WARNING - unprotected I/O)
- Emoji: `grep -P '[\x{1F600}-\x{1F64F}]' file.lua` (BLOCKING)

**Shell Script Patterns**:
- Shebang check: `#!/bin/bash` presence
- Error handling: `set -e` usage
- Indentation: 2-space consistency
- Quoting: Proper variable quoting

**Markdown Patterns**:
- Unicode box-drawing validation
- Emoji prohibition in content
- Code block language specification
- Link validity
- CommonMark compliance

Each pattern includes severity level (BLOCKING/WARNING/SUGGESTION) guiding remediation priority.

### /analyze Command Analysis

#### Three Analysis Modes

The `/analyze` command provides multi-dimensional performance analysis (**analyze.md:22-43**):

**Mode 1: Agent Analysis** (`/analyze agents [timeframe]`):
- Comprehensive agent performance metrics
- Tool usage patterns with ASCII bar charts
- Error classification and examples
- Efficiency scoring with star ratings
- Performance trend comparison (7-day vs 30-day)

**Mode 2: Metrics Analysis** (`/analyze metrics [timeframe]`):
- Command execution bottleneck identification
- Usage trend visualization
- Success rate calculations
- Template effectiveness comparison
- Data-driven optimization recommendations

**Mode 3: Pattern Analysis** (`/analyze patterns`):
- **Status**: Not implemented (reserved for future)
- Originally planned for workflow pattern detection
- Removed due to cold start problem and maintenance complexity
- Alternatives: templates, manual JSONL analysis, external tools

**Mode 4: Combined** (`/analyze all`):
- Executes both agent and metrics analysis
- Consolidated report with separators

#### Agent Performance Tracking

Detailed agent analysis leverages JSONL metrics (**analyze.md:56-165**, **analyze-metrics.sh:354-570**):

**Data Sources**:
1. `.claude/agents/agent-registry.json` - Aggregate metrics
2. `.claude/data/metrics/agents/*.jsonl` - Per-invocation detailed records

**Calculated Statistics** (analyze-metrics.sh:391-452):
- **Success Metrics**: Success count, failure count, success rate percentage
- **Duration Metrics**: Average, min, max, median (handles outliers better than mean)
- **Tool Usage**: Aggregated counts by tool type with percentages
- **Error Analysis**: Grouped by error_type with occurrence counts
- **Timestamp Range**: First and last invocation for trend analysis

**Efficiency Scoring Algorithm** (analyze.md:78-81):
```
efficiency_score = (success_rate × 0.6) + (duration_score × 0.4)
duration_score = min(1.0, target_duration / actual_avg_duration)
```

**Target Durations by Agent Type** (analyze.md:82-90):
- research-specialist: 15000ms (15s)
- plan-architect: 20000ms (20s)
- code-writer: 12000ms (12s)
- test-specialist: 10000ms (10s)
- debug-assistant: 8000ms (8s)
- doc-writer: 8000ms (8s)
- default: 10000ms (10s)

This scoring system balances reliability (60% weight) with speed (40% weight), recognizing that success is more valuable than raw performance.

**Enhanced Report Format** (analyze.md:108-164):
```
1. ★★★★★ research-specialist (94% efficiency)
   Success: 98% (240/245) | Avg Duration: 13.2s | Invocations: 245

   Tool Usage (top 3):
   Read            ████████████████████  45% (108 calls)
   WebSearch       █████████████         30% (72 calls)
   Write           ███████               15% (36 calls)

   Recent Performance:
   - Last 7 days: 96% success (23/24)
   - Avg duration trend: ↓ improving (was 14.1s)
```

Visual elements include:
- **Star ratings**: ★★★★★ (5) to ★☆☆☆☆ (1) for quick assessment
- **ASCII bar charts**: Tool usage visualization (40 chars max)
- **Trend indicators**: ↑↓ showing performance direction
- **Color-coded status**: "Excellent", "Good", "Needs attention"

#### Tool Usage Analysis

Function `analyze_tool_usage()` provides insights into agent behavior (**analyze-metrics.sh:505-570**):

**Process**:
1. Extract `tools_used` JSON object from agent stats
2. Calculate total tool calls across all tools
3. Compute percentage for each tool
4. Generate sorted report with ASCII bars

**Example Output**:
```
Tool Usage: code-writer

Edit            ████████████████      40% (302 calls)
Read            ██████████████        35% (264 calls)
Bash            ██████                15% (113 calls)

Total tool calls: 755
Average tools per invocation: 4.0
```

**Analysis Value**:
- **Behavior validation**: Verify agents use expected tools
- **Performance optimization**: Identify tool usage bottlenecks
- **Resource planning**: Understand tool demand patterns
- **Debugging**: Detect unexpected tool usage indicating issues

#### Error Pattern Detection

Function `identify_common_errors()` aggregates failure modes (**analyze-metrics.sh:455-503**):

**Detection Process**:
1. Parse JSONL for records with `error_type != null`
2. Group by error type and count occurrences
3. Extract example error messages for each type
4. Sort by frequency (top N errors returned)

**Example Output**:
```
Common Errors: test-specialist

**test_failure** (7 occurrences)
  - Example: `Test execution failed: Command 'npm test' exited with code 1`

**timeout** (3 occurrences)
  - Example: `Test timeout after 30s`

Recommendation: Investigate test timeout issues, optimize test execution
```

**Actionable Insights**:
- **Error frequency**: Prioritize fixing high-occurrence errors
- **Error examples**: Concrete failure messages for debugging
- **Pattern recognition**: Identify systemic issues (e.g., timeout suggests performance problem)
- **Trend analysis**: Track error reduction over time

#### Metrics Bottleneck Identification

Function `identify_bottlenecks()` detects performance issues (**analyze-metrics.sh:83-128**):

**Bottleneck Detection**:
1. **Slowest Operations** (top 5):
   - Parse duration_ms from metrics
   - Sort descending by duration
   - Report in human-readable format (seconds)

2. **Most Common Failures**:
   - Filter records with status="error"|"failed"
   - Count by operation type
   - Sort by frequency

**Example Output**:
```
## Performance Bottlenecks

### Slowest Operations

- implement: 180s (180000ms)
- plan: 45s (45000ms)
- report: 30s (30000ms)

### Most Common Failures

- test: 5 failures
- implement: 3 failures
```

**Optimization Recommendations** (analyze-metrics.sh:224-301):
- **High-failure operations** (>5 failures): Review error handling, add validation
- **Slow operations** (>10s): Profile for bottlenecks, consider caching, review I/O
- **Template adoption**: Compare manual vs template usage, suggest template creation

#### Usage Trend Visualization

Function `generate_trend_report()` creates ASCII charts (**analyze-metrics.sh:168-221**):

**Visualization Approach**:
1. Count operations by type
2. Find maximum count for scaling
3. Generate ASCII bar proportional to count (max 40 chars)
4. Display with operation name and count

**Example Output**:
```
### Command Usage

plan                      45 ████████████████████████████████████████
implement                 38 ████████████████████████████████████
plan-from-template        25 ███████████████████████████
test                      20 ████████████████████████

### Success Rate

- Total operations: 143
- Successful: 135
- Success rate: 94%
```

**Analysis Value**:
- **Usage patterns**: Identify most-used commands
- **Success trends**: Monitor overall system reliability
- **Adoption tracking**: Measure template vs manual workflows
- **Capacity planning**: Understand workload distribution

#### Template Effectiveness Analysis

Function `calculate_template_effectiveness()` measures workflow efficiency gains (**analyze-metrics.sh:130-166**):

**Comparison Methodology**:
1. Filter metrics for `operation == "plan-from-template"`
2. Calculate average duration for template-based planning
3. Filter metrics for `operation == "plan"`
4. Calculate average duration for manual planning
5. Compute time savings percentage

**Example Output**:
```
## Template Effectiveness Analysis

- Template-based planning: 15s average
- Manual planning: 45s average
- Time savings: 67% faster with templates
```

**Interpretation**:
- **Time savings**: Quantifies workflow optimization value
- **Adoption guidance**: Demonstrates ROI for template creation
- **Workflow improvement**: Identifies high-value template opportunities

### Best Use Cases

#### /refactor Command Use Cases

**Use Case 1: Pre-Feature Refactoring**
- **Scenario**: Planning new feature implementation
- **Process**: `/refactor [module] "Adding OAuth support"`
- **Value**: Identifies preparatory refactoring to ease feature integration
- **Output**: Report with "Integration with New Features" section (refactor-structure.md:148-162)

**Use Case 2: Standards Compliance Audit**
- **Scenario**: Enforcing project coding standards
- **Process**: `/refactor [directory]` (no specific concerns)
- **Value**: Comprehensive standards violations detection across six categories
- **Output**: Categorized findings with priority/effort/risk matrix

**Use Case 3: Technical Debt Assessment**
- **Scenario**: Understanding codebase quality and maintenance burden
- **Process**: `/refactor .` (entire project)
- **Value**: Quantified metrics (files, issues, effort), phased roadmap
- **Output**: Implementation roadmap with four phases (critical, high priority, standards, enhancements)

**Use Case 4: Quality Gate Enforcement**
- **Scenario**: Pre-merge code review
- **Process**: Invoke code-reviewer agent directly with changed files
- **Value**: Fast blocking issue detection (tabs, emojis)
- **Output**: PASS/FAIL status with review report if failures found (code-reviewer.md:412-419)

#### /analyze Command Use Cases

**Use Case 1: Agent Performance Optimization**
- **Scenario**: Investigating slow or failing agents
- **Process**: `/analyze agents 30`
- **Value**: Efficiency scores, tool usage patterns, error analysis
- **Output**: Ranked agents with actionable recommendations

**Use Case 2: System Health Monitoring**
- **Scenario**: Regular system performance review
- **Process**: `/analyze all` (weekly/monthly)
- **Value**: Comprehensive metrics across agents and commands
- **Output**: Combined report with trends and bottlenecks

**Use Case 3: Command Bottleneck Investigation**
- **Scenario**: Identifying slow workflow steps
- **Process**: `/analyze metrics 7` (recent timeframe)
- **Value**: Top 5 slowest operations with optimization suggestions
- **Output**: Bottleneck report with profiling recommendations

**Use Case 4: Template ROI Measurement**
- **Scenario**: Justifying template creation investment
- **Process**: `/analyze metrics 90` (longer timeframe for statistical significance)
- **Value**: Quantified time savings percentage
- **Output**: Template effectiveness comparison (e.g., "67% faster")

**Use Case 5: Error Pattern Detection**
- **Scenario**: Debugging recurring failures
- **Process**: `/analyze agents [agent-name]`
- **Value**: Error type aggregation with concrete examples
- **Output**: Common errors section with occurrence counts and example messages

**Use Case 6: Tool Usage Validation**
- **Scenario**: Verifying agents use appropriate tools
- **Process**: `/analyze agents [agent-name]`
- **Value**: Tool usage breakdown with percentages
- **Output**: ASCII bar chart showing tool distribution

## Recommendations

### Command Integration Recommendations

1. **Combine Refactoring with Analysis**
   - Run `/analyze agents code-reviewer` after batch refactoring reports
   - Verify code-reviewer efficiency remains above 90%
   - Monitor tool usage to ensure Read/Grep/Glob balance appropriate

2. **Establish Performance Baselines**
   - Run `/analyze all` monthly to establish historical trends
   - Track agent efficiency scores over time
   - Set thresholds for intervention (e.g., <75% efficiency triggers investigation)

3. **Integrate into CI/CD Pipeline**
   - Add `/refactor` quality gate before merge (detect blocking issues)
   - Generate metrics reports on release branches
   - Track success rate trends to detect degradation

### Workflow Optimization Recommendations

4. **Prioritize Quick Wins**
   - Use refactoring priority matrix to identify "Quick Win + Safe + High Priority" items
   - Target 5-10 quick wins per week for continuous improvement
   - Track cumulative time saved through refactoring

5. **Template-Driven Development**
   - Analyze manual planning patterns with `/analyze metrics`
   - Create templates for patterns used >5 times
   - Measure adoption rate and time savings

6. **Agent Performance Tuning**
   - Investigate agents with efficiency <80%
   - Review tool usage patterns for anomalies (e.g., excessive Bash usage)
   - Address common error patterns before they compound

### Report Structure Recommendations

7. **Standardize Refactoring Reports**
   - Always include all seven required sections
   - Provide quantified metrics (files, issues, effort estimates)
   - Use priority matrix for scheduling guidance

8. **Automate Metrics Collection**
   - Schedule weekly `/analyze all` runs
   - Archive reports in `specs/reports/` for trend analysis
   - Create dashboards from JSONL data for real-time monitoring

9. **Cross-Reference Artifacts**
   - Link refactoring reports to implementation plans
   - Update "Implementation Status" section when work begins/completes
   - Maintain bidirectional links between related artifacts

### Enhancement Recommendations

10. **Extend Language Support**
    - Add detection patterns for additional languages (Python, JavaScript, TypeScript)
    - Create language-specific standards checklists
    - Implement configurable thresholds per language

11. **Enhance Metrics Visualization**
    - Generate HTML reports with interactive charts
    - Add time-series graphs for trend analysis
    - Create performance dashboards for at-a-glance assessment

12. **Implement Automated Fixes**
    - Create auto-fix mode for safe refactorings (tabs→spaces, line wrapping)
    - Generate patch files from refactoring recommendations
    - Add preview mode before applying fixes

## References

### Codebase Files

- `/home/benjamin/.config/.claude/archive/commands/refactor.md` - Refactoring orchestrator command (lines 11-19: delegation pattern, 86-116: quality categories, 119-138: assessment dimensions, 155-242: file creation enforcement)
- `/home/benjamin/.config/.claude/archive/commands/analyze.md` - Performance analysis command (lines 22-43: analysis modes, 56-165: agent tracking, 167-290: metrics functions)
- `/home/benjamin/.config/.claude/agents/code-reviewer.md` - Code review agent behavioral specification (lines 44-78: standards enforcement, 343-399: multi-language detection patterns, 412-419: quality gate integration)
- `/home/benjamin/.config/.claude/lib/analyze-metrics.sh` - Metrics analysis library (lines 354-383: parse_agent_jsonl, 391-452: calculate_agent_stats, 455-503: identify_common_errors, 505-570: analyze_tool_usage, 83-128: identify_bottlenecks, 168-221: generate_trend_report, 130-166: calculate_template_effectiveness)
- `/home/benjamin/.config/.claude/docs/reference/refactor-structure.md` - Refactoring report template specification (lines 19-431: complete template structure, 338-410: section guidelines and best practices)

### Standards Documentation

- `/home/benjamin/.config/CLAUDE.md` - Project coding standards and conventions
- `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` - Specs directory structure and artifact lifecycle

### Related Artifacts

- Agent registry: `.claude/agents/agent-registry.json`
- Agent metrics: `.claude/data/metrics/agents/*.jsonl`
- Command metrics: `.claude/data/metrics/*.jsonl`
