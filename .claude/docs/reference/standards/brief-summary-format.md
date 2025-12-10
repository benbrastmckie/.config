# Brief Summary Format Standard

## Overview

This standard defines the concise summary format used in coordinator return signals to achieve 96%+ context reduction. Brief summaries enable orchestrator commands to track coordinator progress without consuming full implementation summary context (80 tokens vs 2,000 tokens).

**Purpose**: Enable multi-iteration workflows with minimal context consumption per iteration.

**Scope**: All coordinator return signals (research, implementer, testing, debug, repair).

**Related Standards**:
- [Coordinator Return Signals](coordinator-return-signals.md) - Return signal schema
- [Coordinator Patterns Standard](coordinator-patterns-standard.md) - Pattern 2: Metadata Extraction Pattern
- [Artifact Metadata Standard](artifact-metadata-standard.md) - Artifact metadata schema

---

## Standard Format Template

### Core Template

```
Completed Wave X-Y (Phase A,B,C) with N items. Context: P%. Next: ACTION.
```

**Field Specifications**:

| Field | Description | Format | Example | Required |
|-------|-------------|--------|---------|----------|
| Wave X-Y | Wave range completed | "Wave {start}-{end}" or "Wave {num}" | Wave 1-2 | Yes |
| Phase A,B,C | Phase identifiers completed | "Phase {comma_separated_list}" | Phase 1,2,3 | Yes |
| N items | Total work items completed | "{count} {unit}" | 42 tasks | Yes |
| P% | Context usage percentage | "{percentage}%" | 37% | Yes |
| ACTION | Next action or status | Imperative verb phrase | "Phase 4-6" or "COMPLETE" | Yes |

**Character Limit**: 150 characters maximum (includes all fields)

**Token Consumption**: ~80 tokens (vs ~2,000 tokens for full summary)

**Context Reduction**: 96% (80/2,000)

---

## Format Variants by Coordinator Type

### Research Coordinator Format

```
Completed research on N topics with X findings. Context: P%. Next: ACTION.
```

**Example**:
```
Completed research on 4 topics with 48 findings. Context: 35%. Next: Plan creation.
```

**Fields**:
- N topics: Number of research topics completed
- X findings: Total findings across all topics
- P%: Context usage percentage
- ACTION: Next step (typically "Plan creation" or "COMPLETE")

**Token Consumption**: ~75 tokens

---

### Implementer Coordinator Format

```
Completed Wave X-Y (Phase A,B,C) with N tasks. Context: P%. Next: ACTION.
```

**Example**:
```
Completed Wave 1-2 (Phase 1-3) with 42 tasks. Context: 37%. Next: Phase 4-6.
```

**Fields**:
- Wave X-Y: Wave range (1-2, 3-4, etc.) or single wave (Wave 1)
- Phase A,B,C: Phase list (1-3, 4-6, etc.)
- N tasks: Total tasks completed in wave
- P%: Context usage percentage
- ACTION: Next wave range or "COMPLETE"

**Token Consumption**: ~80 tokens

**Alternative Format (Final Wave)**:
```
Completed final Wave X (Phase Y,Z) with N tasks. Context: P%. Next: COMPLETE.
```

---

### Testing Coordinator Format

```
Completed N test suites with X/Y tests passing. Context: P%. Next: ACTION.
```

**Example**:
```
Completed 3 test suites with 48/48 tests passing. Context: 28%. Next: Coverage validation.
```

**Fields**:
- N test suites: Number of test suites executed
- X/Y tests: Passed/total ratio
- P%: Context usage percentage
- ACTION: Next step ("Coverage validation", "Fix failures", "COMPLETE")

**Token Consumption**: ~70 tokens

---

### Debug Coordinator Format

```
Debugged N issues in X files. Context: P%. Next: ACTION.
```

**Example**:
```
Debugged 5 issues in 8 files. Context: 42%. Next: Validation tests.
```

**Fields**:
- N issues: Number of issues debugged
- X files: Number of files modified
- P%: Context usage percentage
- ACTION: Next step ("Validation tests", "Integration tests", "COMPLETE")

**Token Consumption**: ~65 tokens

---

### Repair Coordinator Format

```
Repaired N instances of X pattern in Y files. Context: P%. Next: ACTION.
```

**Example**:
```
Repaired 8 instances of shared state file in 8 files. Context: 45%. Next: Validation.
```

**Fields**:
- N instances: Number of pattern instances fixed
- X pattern: Pattern name (abbreviated)
- Y files: Number of files modified
- P%: Context usage percentage
- ACTION: Next step ("Validation", "Integration tests", "COMPLETE")

**Token Consumption**: ~75 tokens

---

## Required Return Signal Fields

### Standard Fields (All Coordinators)

```yaml
coordinator_type: <type>              # Coordinator classification
summary_brief: "<brief_summary>"      # Brief summary (150 chars max)
work_remaining: <int or list>         # Work remaining (0 or list of phases)
context_exhausted: <bool>             # Context budget exhausted flag
context_usage_percent: <int>          # Context usage percentage
requires_continuation: <bool>         # Continuation required flag
```

**Field Specifications**:

| Field | Type | Format | Example | Required |
|-------|------|--------|---------|----------|
| coordinator_type | string | research, implementer, testing, debug, repair | implementer | Yes |
| summary_brief | string | Brief summary format (max 150 chars) | "Completed Wave 1-2..." | Yes |
| work_remaining | mixed | 0 or [phase_list] | [4, 5, 6] | Yes |
| context_exhausted | boolean | true or false | false | Yes |
| context_usage_percent | integer | 0-100 | 37 | Yes |
| requires_continuation | boolean | true or false | true | Yes |

---

### Type-Specific Fields

#### Research Coordinator

```yaml
topics_completed: [<list>]            # List of completed topic names
findings_total: <int>                 # Total findings across all topics
reports_created: <int>                # Number of research reports created
```

**Example**:
```yaml
coordinator_type: research
summary_brief: "Completed research on 4 topics with 48 findings. Context: 35%. Next: Plan creation."
topics_completed: [authentication, token_expiry, security, testing]
findings_total: 48
reports_created: 4
work_remaining: 0
context_exhausted: false
context_usage_percent: 35
requires_continuation: false
```

---

#### Implementer Coordinator

```yaml
phases_completed: [<list>]            # List of phase numbers completed
tasks_completed: <int>                # Total tasks completed
artifacts_created: [<list>]           # List of created artifact paths
```

**Example**:
```yaml
coordinator_type: implementer
summary_brief: "Completed Wave 1-2 (Phase 1-3) with 42 tasks. Context: 37%. Next: Phase 4-6."
phases_completed: [1, 2, 3]
tasks_completed: 42
artifacts_created: ["/path/to/artifact1.md", "/path/to/artifact2.sh"]
work_remaining: [4, 5, 6]
context_exhausted: false
context_usage_percent: 37
requires_continuation: true
```

---

#### Testing Coordinator

```yaml
test_suites_run: <int>                # Number of test suites executed
tests_passed: <int>                   # Total tests passed
tests_failed: <int>                   # Total tests failed
coverage_percent: <float>             # Code coverage percentage
```

**Example**:
```yaml
coordinator_type: testing
summary_brief: "Completed 3 test suites with 48/48 tests passing. Context: 28%. Next: Coverage validation."
test_suites_run: 3
tests_passed: 48
tests_failed: 0
coverage_percent: 87.5
work_remaining: ["coverage_validation"]
context_exhausted: false
context_usage_percent: 28
requires_continuation: true
```

---

#### Debug Coordinator

```yaml
issues_debugged: <int>                # Number of issues debugged
files_modified: <int>                 # Number of files modified
root_causes: [<list>]                 # List of root cause summaries
```

**Example**:
```yaml
coordinator_type: debug
summary_brief: "Debugged 5 issues in 8 files. Context: 42%. Next: Validation tests."
issues_debugged: 5
files_modified: 8
root_causes: ["State restoration failure", "Path validation error"]
work_remaining: ["validation_tests"]
context_exhausted: false
context_usage_percent: 42
requires_continuation: true
```

---

#### Repair Coordinator

```yaml
instances_fixed: <int>                # Number of pattern instances fixed
pattern_name: <string>                # Pattern name being repaired
files_modified: <int>                 # Number of files modified
validation_status: <string>           # Validation status
```

**Example**:
```yaml
coordinator_type: repair
summary_brief: "Repaired 8 instances of shared state file in 8 files. Context: 45%. Next: Validation."
instances_fixed: 8
pattern_name: "Shared state ID file anti-pattern"
files_modified: 8
validation_status: "pending"
work_remaining: ["validation"]
context_exhausted: false
context_usage_percent: 45
requires_continuation: true
```

---

## Context Reduction Methodology

### Token Calculation

#### Full Summary Token Count

**Implementation Summary Structure** (~2,000 tokens):
- Work Status section: ~300 tokens
- Artifacts Created section: ~600 tokens
- Work Remaining section: ~400 tokens
- Testing Strategy section: ~200 tokens
- Performance Metrics section: ~200 tokens
- Key Achievements section: ~200 tokens
- Next Steps section: ~100 tokens

**Total**: ~2,000 tokens

---

#### Brief Summary Token Count

**Brief Summary Format** (~80 tokens):
- summary_brief field: ~20 tokens (150 chars)
- coordinator_type field: ~5 tokens
- phases_completed array: ~15 tokens (e.g., [1, 2, 3])
- work_remaining field: ~15 tokens (e.g., [4, 5, 6])
- context_exhausted field: ~5 tokens
- context_usage_percent field: ~5 tokens
- requires_continuation field: ~5 tokens
- Type-specific fields: ~10 tokens (e.g., tasks_completed: 42)

**Total**: ~80 tokens

---

### Context Reduction Calculation

**Reduction Percentage**:
```
reduction = (1 - (brief_tokens / full_tokens)) * 100
reduction = (1 - (80 / 2000)) * 100
reduction = 96%
```

**Multi-Iteration Impact**:

| Iterations | Full Summary (tokens) | Brief Summary (tokens) | Reduction |
|-----------|----------------------|------------------------|-----------|
| 1 | 2,000 | 80 | 96.0% |
| 3 | 6,000 | 240 | 96.0% |
| 5 | 10,000 | 400 | 96.0% |
| 10 | 20,000 | 800 | 96.0% |
| 20 | 40,000 | 1,600 | 96.0% |

**Iteration Capacity Increase**:
- Baseline (full summaries): 3-4 iterations before context exhaustion
- Brief summaries: 20+ iterations before context exhaustion
- **Improvement**: 5-7x more iterations

---

## Parsing Examples

### Bash Parsing

```bash
# Parse coordinator return signal
coordinator_output="<coordinator output>"

# Extract summary_brief
summary_brief=$(echo "$coordinator_output" | grep "^summary_brief:" | sed 's/^summary_brief: "//' | sed 's/"$//')

# Extract phases_completed array
phases_completed=$(echo "$coordinator_output" | grep "^phases_completed:" | sed 's/^phases_completed: //' | tr -d '[]')

# Extract work_remaining
work_remaining=$(echo "$coordinator_output" | grep "^work_remaining:" | sed 's/^work_remaining: //')

# Extract context_usage_percent
context_percent=$(echo "$coordinator_output" | grep "^context_usage_percent:" | awk '{print $2}')

# Extract requires_continuation
requires_continuation=$(echo "$coordinator_output" | grep "^requires_continuation:" | awk '{print $2}')

# Decision logic
if [ "$requires_continuation" = "true" ]; then
  echo "Iteration complete: $summary_brief"
  echo "Work remaining: $work_remaining"
  echo "Context usage: ${context_percent}%"
  echo "Continuing to next iteration..."
else
  echo "Workflow complete: $summary_brief"
  echo "Context usage: ${context_percent}%"
fi
```

---

### Python Parsing

```python
import re

def parse_coordinator_signal(output: str) -> dict:
    """Parse coordinator return signal into structured data."""
    signal = {}

    # Extract summary_brief
    match = re.search(r'^summary_brief: "(.*?)"$', output, re.MULTILINE)
    if match:
        signal['summary_brief'] = match.group(1)

    # Extract phases_completed array
    match = re.search(r'^phases_completed: \[(.*?)\]$', output, re.MULTILINE)
    if match:
        signal['phases_completed'] = [int(x.strip()) for x in match.group(1).split(',')]

    # Extract work_remaining
    match = re.search(r'^work_remaining: (.+)$', output, re.MULTILINE)
    if match:
        value = match.group(1)
        signal['work_remaining'] = 0 if value == '0' else eval(value)

    # Extract context_usage_percent
    match = re.search(r'^context_usage_percent: (\d+)$', output, re.MULTILINE)
    if match:
        signal['context_usage_percent'] = int(match.group(1))

    # Extract requires_continuation
    match = re.search(r'^requires_continuation: (true|false)$', output, re.MULTILINE)
    if match:
        signal['requires_continuation'] = match.group(1) == 'true'

    return signal

# Usage
coordinator_output = """
coordinator_type: implementer
summary_brief: "Completed Wave 1-2 (Phase 1-3) with 42 tasks. Context: 37%. Next: Phase 4-6."
phases_completed: [1, 2, 3]
work_remaining: [4, 5, 6]
context_usage_percent: 37
requires_continuation: true
"""

signal = parse_coordinator_signal(coordinator_output)
print(f"Summary: {signal['summary_brief']}")
print(f"Phases done: {signal['phases_completed']}")
print(f"Context: {signal['context_usage_percent']}%")
print(f"Continue: {signal['requires_continuation']}")
```

---

## Anti-Patterns

### Anti-Pattern 1: Verbose Summary Exceeding Character Limit

**Problem**: Defeats context reduction by using excessive tokens.

```yaml
# WRONG: 250+ character summary (120 tokens)
summary_brief: "Successfully completed implementation of Wave 1 and Wave 2, which includes Phase 1 (Architecture Decision Framework), Phase 2 (Three-Tier Coordination Pattern), and Phase 3 (Coordinator Pattern Standards) with a total of 42 tasks across all phases. Current context usage is at 37% of the total budget. Next steps include proceeding with Phase 4, Phase 5, and Phase 6 in the next iteration."
```

**Solution**: Use concise format with abbreviations.

```yaml
# CORRECT: 80 character summary (20 tokens)
summary_brief: "Completed Wave 1-2 (Phase 1-3) with 42 tasks. Context: 37%. Next: Phase 4-6."
```

**Impact**: Verbose format uses 6x more tokens than standard format.

---

### Anti-Pattern 2: Missing Required Fields

**Problem**: Forces orchestrator to read full summary, defeating context reduction.

```yaml
# WRONG: Missing work_remaining, context_usage_percent, requires_continuation
coordinator_type: implementer
summary_brief: "Completed Wave 1-2 (Phase 1-3) with 42 tasks."
# Missing: work_remaining, context_exhausted, context_usage_percent, requires_continuation
```

**Solution**: Include all required fields.

```yaml
# CORRECT: All required fields present
coordinator_type: implementer
summary_brief: "Completed Wave 1-2 (Phase 1-3) with 42 tasks. Context: 37%. Next: Phase 4-6."
work_remaining: [4, 5, 6]
context_exhausted: false
context_usage_percent: 37
requires_continuation: true
```

---

### Anti-Pattern 3: Non-Standard Summary Format

**Problem**: Prevents automated parsing, requires custom logic per coordinator.

```yaml
# WRONG: Non-standard format
summary_brief: "I've finished working on phases 1 through 3, which had 42 tasks total. I've used about 37% of the context budget so far. I'll continue with phases 4-6 next."
```

**Solution**: Use standard template format.

```yaml
# CORRECT: Standard format
summary_brief: "Completed Wave 1-2 (Phase 1-3) with 42 tasks. Context: 37%. Next: Phase 4-6."
```

---

### Anti-Pattern 4: Inconsistent Field Types

**Problem**: Breaks parsing logic, requires type coercion.

```yaml
# WRONG: Inconsistent types
phases_completed: "1, 2, 3"           # Should be array: [1, 2, 3]
context_usage_percent: "37%"          # Should be integer: 37
requires_continuation: "yes"          # Should be boolean: true
```

**Solution**: Use standard field types.

```yaml
# CORRECT: Standard types
phases_completed: [1, 2, 3]           # Array of integers
context_usage_percent: 37             # Integer
requires_continuation: true           # Boolean
```

---

## Performance Metrics

### Token Consumption by Coordinator Type

| Coordinator Type | Full Summary (tokens) | Brief Summary (tokens) | Reduction % |
|-----------------|----------------------|------------------------|-------------|
| Research | 2,200 | 75 | 96.6% |
| Implementer | 2,000 | 80 | 96.0% |
| Testing | 1,800 | 70 | 96.1% |
| Debug | 1,900 | 65 | 96.6% |
| Repair | 2,100 | 75 | 96.4% |

**Average Reduction**: 96.3%

---

### Multi-Iteration Context Consumption

**Scenario**: 5-iteration implementer workflow

| Iteration | Full Summary (cumulative) | Brief Summary (cumulative) | Reduction |
|-----------|--------------------------|---------------------------|-----------|
| 1 | 2,000 | 80 | 96.0% |
| 2 | 4,000 | 160 | 96.0% |
| 3 | 6,000 | 240 | 96.0% |
| 4 | 8,000 | 320 | 96.0% |
| 5 | 10,000 | 400 | 96.0% |

**Context Savings**: 9,600 tokens over 5 iterations

**Iteration Capacity**: Brief format enables 5 iterations where full format would exhaust context after 3 iterations (assuming 200K token budget and 70K base consumption).

---

## Integration with Coordinator Return Signals

### Signal Structure

Brief summary format is embedded in coordinator return signals:

```
IMPLEMENTATION_COMPLETE: {PHASE_COUNT}
plan_file: /path/to/plan.md
topic_path: /path/to/topic
summary_path: /path/to/summary.md
work_remaining: [4, 5, 6]
context_exhausted: false
context_usage_percent: 37
checkpoint_path: /path/to/checkpoint.md
requires_continuation: true
stuck_detected: false

# Structured metadata (parsed from summary file)
coordinator_type: implementer
summary_brief: "Completed Wave 1-2 (Phase 1-3) with 42 tasks. Context: 37%. Next: Phase 4-6."
phases_completed: [1, 2, 3]
tasks_completed: 42
artifacts_created: ["/path/to/artifact1.md"]
```

**Parsing Pattern**:
```bash
# Extract return signal
signal=$(echo "$coordinator_output" | grep -A 20 "IMPLEMENTATION_COMPLETE:")

# Extract brief summary from signal
summary_brief=$(echo "$signal" | grep "^summary_brief:" | sed 's/^summary_brief: "//' | sed 's/"$//')

# Extract context usage
context_percent=$(echo "$signal" | grep "^context_usage_percent:" | awk '{print $2}')

# Extract continuation flag
requires_continuation=$(echo "$signal" | grep "^requires_continuation:" | awk '{print $2}')
```

See [Coordinator Return Signals](coordinator-return-signals.md) for complete signal schema.

---

## Standards Compliance Checklist

### Coordinator Agent Compliance

- [ ] summary_brief field uses standard template format
- [ ] summary_brief field is max 150 characters
- [ ] All required return signal fields included
- [ ] Field types match specification (array, integer, boolean)
- [ ] coordinator_type field specifies coordinator classification
- [ ] work_remaining field uses 0 or array format
- [ ] context_usage_percent field is numeric (0-100)
- [ ] requires_continuation field is boolean (true/false)
- [ ] Type-specific fields included based on coordinator_type

### Orchestrator Command Compliance

- [ ] Parses summary_brief field from coordinator output
- [ ] Uses summary_brief for progress logging (not full summary)
- [ ] Checks requires_continuation flag for iteration control
- [ ] Monitors context_usage_percent for budget management
- [ ] Validates work_remaining field for completion detection
- [ ] Only reads full summary when debugging or error analysis needed
- [ ] Achieves 96%+ context reduction through brief summary usage

---

## Related Documentation

- [Coordinator Return Signals](coordinator-return-signals.md) - Complete return signal schema
- [Coordinator Patterns Standard](coordinator-patterns-standard.md) - Pattern 2: Metadata Extraction Pattern
- [Artifact Metadata Standard](artifact-metadata-standard.md) - Artifact metadata schema for specialists
- [Three-Tier Coordination Pattern](../../../concepts/three-tier-coordination-pattern.md) - Tier 2: Coordinator responsibilities
- [Hierarchical Agent Architecture Overview](../../../concepts/hierarchical-agents-overview.md) - Architecture context

---

## Revision History

- **2025-12-10**: Initial standard created (Phase 4 of hierarchical agent architecture documentation)
- Defines brief summary format for 96% context reduction
- Specifies required return signal fields by coordinator type
- Documents parsing examples and performance metrics
