# Artifact Metadata Standard

## Overview

This standard defines the YAML frontmatter metadata schema for all artifacts produced by hierarchical agent architectures. Standardized metadata enables metadata-only passing patterns that achieve 95%+ context reduction by extracting key information (110-150 tokens) instead of passing full artifacts (2,000-7,500 tokens).

**Purpose**: Enable coordinator agents to aggregate specialist outputs without consuming full artifact context.

**Scope**: All artifacts created by specialist agents (research reports, implementation plans, test summaries, debug reports, repair plans).

**Related Standards**:
- [Coordinator Patterns Standard](coordinator-patterns-standard.md) - Pattern 2: Metadata Extraction Pattern
- [Brief Summary Format](brief-summary-format.md) - Return signal summary format
- [Coordinator Return Signals](coordinator-return-signals.md) - Signal schema specifications

---

## Standard Metadata Fields

### Core Fields (Required for All Artifacts)

```yaml
artifact_type: <type>        # Artifact classification (see types below)
topic: <topic_string>         # Topic or feature name
status: <status>              # Artifact status (see statuses below)
created_date: YYYY-MM-DD      # Creation date
```

**Field Specifications**:

| Field | Type | Format | Example | Required |
|-------|------|--------|---------|----------|
| artifact_type | string | One of: research_report, implementation_plan, test_summary, debug_report, repair_plan | research_report | Yes |
| topic | string | Descriptive name (50-100 chars) | jwt_token_expiration_fix | Yes |
| status | string | One of: draft, in_progress, complete, blocked | complete | Yes |
| created_date | date | YYYY-MM-DD | 2025-12-10 | Yes |

---

### Type-Specific Fields

#### Research Reports (artifact_type: research_report)

```yaml
artifact_type: research_report
report_type: <type>           # Research category
findings_count: <int>         # Number of findings
recommendations_count: <int>  # Number of recommendations
topics_covered: [<list>]      # List of subtopics
```

**Field Specifications**:

| Field | Type | Format | Example | Required |
|-------|------|--------|---------|----------|
| report_type | string | implementation, debugging, optimization, comparison | implementation | Yes |
| findings_count | integer | Positive integer | 12 | Yes |
| recommendations_count | integer | Positive integer | 8 | Yes |
| topics_covered | array | List of strings | [authentication, token_expiry, security] | Yes |

**Context Reduction Example**:
- Full research report: ~7,500 tokens
- Metadata extraction: ~130 tokens (98.3% reduction)

---

#### Implementation Plans (artifact_type: implementation_plan)

```yaml
artifact_type: implementation_plan
plan_level: <level>           # Plan detail level (0, 1, 2)
phase_count: <int>            # Total number of phases
tasks_count: <int>            # Total number of tasks
estimated_hours: <range>      # Time estimate (e.g., "8-12 hours")
dependencies: [<list>]        # Phase dependency graph
```

**Field Specifications**:

| Field | Type | Format | Example | Required |
|-------|------|--------|---------|----------|
| plan_level | integer | 0 (single file), 1 (phase expansion), 2 (stage expansion) | 1 | Yes |
| phase_count | integer | Positive integer | 6 | Yes |
| tasks_count | integer | Positive integer | 42 | Yes |
| estimated_hours | string | "{low}-{high} hours" | 8-12 hours | Yes |
| dependencies | array | List of phase dependency strings | ["Phase 2 depends on Phase 1"] | No |

**Context Reduction Example**:
- Full implementation plan: ~5,000 tokens
- Metadata extraction: ~110 tokens (97.8% reduction)

---

#### Test Summaries (artifact_type: test_summary)

```yaml
artifact_type: test_summary
test_framework: <framework>   # Testing framework used
tests_run: <int>              # Total tests executed
tests_passed: <int>           # Tests that passed
tests_failed: <int>           # Tests that failed
coverage_percent: <float>     # Code coverage percentage
```

**Field Specifications**:

| Field | Type | Format | Example | Required |
|-------|------|--------|---------|----------|
| test_framework | string | pytest, jest, bats, etc. | pytest | Yes |
| tests_run | integer | Positive integer | 48 | Yes |
| tests_passed | integer | Non-negative integer | 48 | Yes |
| tests_failed | integer | Non-negative integer | 0 | Yes |
| coverage_percent | float | 0.0-100.0 | 87.5 | Yes |

**Context Reduction Example**:
- Full test output: ~3,000 tokens
- Metadata extraction: ~95 tokens (96.8% reduction)

---

#### Debug Reports (artifact_type: debug_report)

```yaml
artifact_type: debug_report
error_type: <type>            # Error classification
root_cause: <description>     # Root cause summary (1-line)
fix_strategy: <description>   # Fix approach summary (1-line)
affected_files: [<list>]      # List of affected file paths
```

**Field Specifications**:

| Field | Type | Format | Example | Required |
|-------|------|--------|---------|----------|
| error_type | string | state_error, validation_error, parse_error, etc. | state_error | Yes |
| root_cause | string | One-line description (max 100 chars) | "WORKFLOW_ID restoration failing due to shared state file" | Yes |
| fix_strategy | string | One-line description (max 100 chars) | "Replace shared state file with state discovery pattern" | Yes |
| affected_files | array | List of file paths (relative or absolute) | [".claude/commands/create-plan.md"] | Yes |

**Context Reduction Example**:
- Full debug report: ~4,000 tokens
- Metadata extraction: ~125 tokens (96.9% reduction)

---

#### Repair Plans (artifact_type: repair_plan)

```yaml
artifact_type: repair_plan
error_pattern: <pattern>      # Error pattern being fixed
affected_count: <int>         # Number of affected instances
fix_phases: <int>             # Number of fix phases
validation_method: <method>   # Validation approach
```

**Field Specifications**:

| Field | Type | Format | Example | Required |
|-------|------|--------|---------|----------|
| error_pattern | string | Descriptive pattern name | "Shared state ID file anti-pattern" | Yes |
| affected_count | integer | Positive integer | 8 | Yes |
| fix_phases | integer | Positive integer | 3 | Yes |
| validation_method | string | programmatic, integration, manual | programmatic | Yes |

**Context Reduction Example**:
- Full repair plan: ~6,000 tokens
- Metadata extraction: ~120 tokens (98.0% reduction)

---

## Metadata Update Protocol

### Count Field Updates

When specialists create artifacts, they MUST update count fields to reflect actual content:

```bash
# Update findings_count in research report
total_findings=$(grep -c "^### Finding" research-report.md)
sed -i "s/^findings_count: .*/findings_count: $total_findings/" research-report.md

# Update tasks_count in implementation plan
total_tasks=$(grep -c "^- \[ \]" implementation-plan.md)
sed -i "s/^tasks_count: .*/tasks_count: $total_tasks/" implementation-plan.md

# Update tests_run in test summary
tests_run=$(pytest --collect-only -q | tail -1 | awk '{print $1}')
sed -i "s/^tests_run: .*/tests_run: $tests_run/" test-summary.md
```

**Requirements**:
- Count fields MUST be updated after artifact creation
- Counts MUST reflect actual content (not estimates)
- Update pattern MUST use sed or equivalent for atomic updates
- Coordinators MUST NOT trust count fields without validation

---

## Metadata-Only Passing Pattern

### Extraction Pattern

Coordinators extract metadata without reading full artifact content:

```bash
# Extract metadata from artifact (first 20 lines contain YAML frontmatter)
artifact_metadata=$(head -20 "$artifact_path" | grep -A 50 "^---$" | grep -B 50 "^---$")

# Parse specific fields
artifact_type=$(echo "$artifact_metadata" | grep "^artifact_type:" | cut -d: -f2- | xargs)
findings_count=$(echo "$artifact_metadata" | grep "^findings_count:" | cut -d: -f2- | xargs)
status=$(echo "$artifact_metadata" | grep "^status:" | cut -d: -f2- | xargs)
```

**Token Consumption**:
- YAML frontmatter extraction: ~20 lines = ~40 tokens
- Field parsing (5-10 fields): ~50 tokens
- Metadata aggregation logic: ~20 tokens
- **Total per artifact**: ~110 tokens vs ~5,000 tokens full read (97.8% reduction)

---

### Aggregation Pattern

Coordinators aggregate metadata from multiple specialist artifacts:

```bash
# Aggregate metadata from 4 research reports
total_findings=0
total_recommendations=0
topics_covered=()

for report in reports/*.md; do
  metadata=$(head -20 "$report" | grep -A 50 "^---$" | grep -B 50 "^---$")
  findings=$(echo "$metadata" | grep "^findings_count:" | cut -d: -f2- | xargs)
  recommendations=$(echo "$metadata" | grep "^recommendations_count:" | cut -d: -f2- | xargs)
  topic=$(echo "$metadata" | grep "^topic:" | cut -d: -f2- | xargs)

  total_findings=$((total_findings + findings))
  total_recommendations=$((total_recommendations + recommendations))
  topics_covered+=("$topic")
done

# Create aggregated summary
summary="Completed research on ${#topics_covered[@]} topics with $total_findings findings and $total_recommendations recommendations."
```

**Context Reduction Calculation**:
- 4 specialist reports × 7,500 tokens each = 30,000 tokens (full read)
- 4 specialist reports × 110 tokens metadata = 440 tokens (metadata-only)
- **Context reduction**: 98.5% (440/30,000)

---

## Validation Requirements

### Metadata Completeness Validation

Coordinators MUST validate metadata completeness before extraction:

```bash
validate_metadata() {
  local artifact_path="$1"
  local required_fields="$2"  # Space-separated list

  # Extract metadata block
  metadata=$(head -20 "$artifact_path" | grep -A 50 "^---$" | grep -B 50 "^---$")

  # Check for required fields
  for field in $required_fields; do
    if ! echo "$metadata" | grep -q "^${field}:"; then
      echo "ERROR: Missing required field: $field in $artifact_path"
      return 1
    fi
  done

  return 0
}

# Usage
required_fields="artifact_type topic status created_date findings_count"
if ! validate_metadata "$report_path" "$required_fields"; then
  log_command_error "validation_error" "Incomplete metadata" "$report_path"
  exit 1
fi
```

**Validation Checklist**:
- [ ] All core fields present (artifact_type, topic, status, created_date)
- [ ] Type-specific fields present (varies by artifact_type)
- [ ] Count fields are numeric (findings_count, tasks_count, etc.)
- [ ] Date fields match YYYY-MM-DD format
- [ ] Status field uses allowed values (draft, in_progress, complete, blocked)

---

### Metadata Consistency Validation

Coordinators SHOULD validate metadata consistency with artifact content:

```bash
validate_metadata_consistency() {
  local artifact_path="$1"

  # Extract claimed findings_count from metadata
  claimed_count=$(head -20 "$artifact_path" | grep "^findings_count:" | cut -d: -f2- | xargs)

  # Count actual findings in content
  actual_count=$(grep -c "^### Finding" "$artifact_path")

  # Allow 10% tolerance for formatting variations
  tolerance=$(echo "$claimed_count * 0.1" | bc | awk '{print int($1+0.5)}')
  diff=$((claimed_count - actual_count))
  diff=${diff#-}  # Absolute value

  if [ "$diff" -gt "$tolerance" ]; then
    echo "WARNING: Metadata count mismatch in $artifact_path (claimed: $claimed_count, actual: $actual_count)"
    return 1
  fi

  return 0
}
```

**Consistency Checks**:
- [ ] findings_count matches actual finding sections
- [ ] tasks_count matches actual task checkboxes
- [ ] tests_run matches actual test execution count
- [ ] phase_count matches actual phase sections
- [ ] Status field reflects completion state

---

## Implementation Examples

### Example 1: Research Report Metadata

```yaml
---
artifact_type: research_report
topic: jwt_token_expiration_fix
report_type: implementation
status: complete
created_date: 2025-12-10
findings_count: 12
recommendations_count: 8
topics_covered:
  - authentication
  - token_expiry
  - security_best_practices
---

# Research Report: JWT Token Expiration Fix

[Report content follows...]
```

**Metadata Extraction**:
```bash
metadata=$(head -20 report.md | grep -A 50 "^---$" | grep -B 50 "^---$")
findings_count=$(echo "$metadata" | grep "^findings_count:" | cut -d: -f2- | xargs)  # 12
report_type=$(echo "$metadata" | grep "^report_type:" | cut -d: -f2- | xargs)        # implementation
status=$(echo "$metadata" | grep "^status:" | cut -d: -f2- | xargs)                  # complete
```

---

### Example 2: Implementation Plan Metadata

```yaml
---
artifact_type: implementation_plan
topic: concurrent_execution_safety
plan_level: 1
status: complete
created_date: 2025-12-10
phase_count: 6
tasks_count: 42
estimated_hours: 8-12 hours
dependencies:
  - "Phase 2 depends on Phase 1"
  - "Phase 6 depends on Phases 1-5"
---

# Implementation Plan: Concurrent Execution Safety

[Plan content follows...]
```

**Metadata Extraction**:
```bash
metadata=$(head -20 plan.md | grep -A 50 "^---$" | grep -B 50 "^---$")
phase_count=$(echo "$metadata" | grep "^phase_count:" | cut -d: -f2- | xargs)        # 6
tasks_count=$(echo "$metadata" | grep "^tasks_count:" | cut -d: -f2- | xargs)        # 42
estimated_hours=$(echo "$metadata" | grep "^estimated_hours:" | cut -d: -f2- | xargs) # 8-12 hours
```

---

### Example 3: Test Summary Metadata

```yaml
---
artifact_type: test_summary
topic: concurrent_execution_tests
test_framework: pytest
status: complete
created_date: 2025-12-10
tests_run: 48
tests_passed: 48
tests_failed: 0
coverage_percent: 87.5
---

# Test Summary: Concurrent Execution Safety

[Test results follow...]
```

**Metadata Extraction**:
```bash
metadata=$(head -20 summary.md | grep -A 50 "^---$" | grep -B 50 "^---$")
tests_run=$(echo "$metadata" | grep "^tests_run:" | cut -d: -f2- | xargs)            # 48
tests_passed=$(echo "$metadata" | grep "^tests_passed:" | cut -d: -f2- | xargs)      # 48
coverage_percent=$(echo "$metadata" | grep "^coverage_percent:" | cut -d: -f2- | xargs) # 87.5
```

---

## Anti-Patterns

### Anti-Pattern 1: Embedding Full Content in Metadata

**Problem**: Defeats context reduction by duplicating artifact content.

```yaml
# WRONG: Full content in metadata
findings_summary: |
  Finding 1: Authentication tokens expire after 24 hours without refresh mechanism.
  Finding 2: Token expiry is hardcoded in configuration file.
  [... 2000 tokens of findings ...]
```

**Solution**: Use count fields only, read full content when needed.

```yaml
# CORRECT: Count fields only
findings_count: 12
recommendations_count: 8
```

---

### Anti-Pattern 2: Missing Required Fields

**Problem**: Prevents metadata-only passing, forces full artifact reads.

```yaml
# WRONG: Missing required fields
artifact_type: research_report
# Missing: topic, status, created_date, findings_count
```

**Solution**: Always include all required core and type-specific fields.

```yaml
# CORRECT: All required fields present
artifact_type: research_report
topic: jwt_token_expiration_fix
status: complete
created_date: 2025-12-10
findings_count: 12
recommendations_count: 8
```

---

### Anti-Pattern 3: Stale Count Fields

**Problem**: Metadata counts don't reflect actual content, breaks trust.

```yaml
# WRONG: Stale count (claimed 12, actual 8)
findings_count: 12
```

**Solution**: Update count fields after content modification.

```bash
# Update count fields programmatically
findings_count=$(grep -c "^### Finding" report.md)
sed -i "s/^findings_count: .*/findings_count: $findings_count/" report.md
```

---

### Anti-Pattern 4: Non-Standard Field Names

**Problem**: Prevents standard metadata extraction patterns.

```yaml
# WRONG: Non-standard field names
type: research_report           # Should be: artifact_type
total_findings: 12              # Should be: findings_count
subject: jwt_token_expiry       # Should be: topic
```

**Solution**: Use standard field names from this specification.

```yaml
# CORRECT: Standard field names
artifact_type: research_report
findings_count: 12
topic: jwt_token_expiration_fix
```

---

## Performance Metrics

### Context Reduction by Artifact Type

| Artifact Type | Full Read (tokens) | Metadata Only (tokens) | Reduction % |
|--------------|-------------------|------------------------|-------------|
| Research Report | 7,500 | 130 | 98.3% |
| Implementation Plan | 5,000 | 110 | 97.8% |
| Test Summary | 3,000 | 95 | 96.8% |
| Debug Report | 4,000 | 125 | 96.9% |
| Repair Plan | 6,000 | 120 | 98.0% |

**Average Context Reduction**: 97.6%

---

### Coordinator Aggregation Scenarios

| Scenario | Specialist Count | Full Read (tokens) | Metadata Only (tokens) | Reduction % |
|----------|-----------------|-------------------|------------------------|-------------|
| Research Coordinator (4 reports) | 4 | 30,000 | 520 | 98.3% |
| Implementer Coordinator (6 summaries) | 6 | 12,000 | 570 | 95.2% |
| Testing Coordinator (3 test suites) | 3 | 9,000 | 285 | 96.8% |
| Debug Coordinator (5 debug reports) | 5 | 20,000 | 625 | 96.9% |

**Average Coordinator Reduction**: 96.8%

---

## Integration with Coordinator Patterns

### Pattern 2: Metadata Extraction Pattern

This standard provides the schema referenced in [Coordinator Patterns Standard - Pattern 2](coordinator-patterns-standard.md#pattern-2-metadata-extraction-pattern).

**Integration Requirements**:
1. All specialist artifacts MUST include standard metadata
2. Coordinators MUST extract metadata using standard field names
3. Coordinators MUST validate metadata completeness before extraction
4. Coordinators SHOULD validate metadata consistency with content

**Context Reduction Target**: 95%+ (achieved via 110-150 token metadata extraction)

---

### Brief Summary Format Integration

Metadata fields populate the brief summary format returned by coordinators. See [Brief Summary Format](brief-summary-format.md) for return signal integration.

**Example Mapping**:
```yaml
# Metadata fields
phase_count: 6
tasks_count: 42
status: complete

# Brief summary format
"Completed Wave 1-2 (Phase 1-3) with 42 tasks. Context: 37%. Next: Phase 4-6."
```

---

## Standards Compliance Checklist

### Specialist Agent Compliance

- [ ] All artifacts include core metadata fields (artifact_type, topic, status, created_date)
- [ ] Type-specific metadata fields included based on artifact_type
- [ ] Count fields updated after artifact creation
- [ ] Metadata appears in first 20 lines of artifact
- [ ] YAML frontmatter uses triple-dash delimiters (---)
- [ ] Field names match standard specification exactly
- [ ] Date fields use YYYY-MM-DD format
- [ ] Status field uses allowed values

### Coordinator Agent Compliance

- [ ] Metadata extraction uses head -20 pattern
- [ ] Metadata validation checks required fields
- [ ] Metadata parsing uses standard field names
- [ ] Aggregation logic sums count fields correctly
- [ ] Context reduction achieves 95%+ target
- [ ] Metadata-only passing pattern documented
- [ ] Full artifact reads only when necessary
- [ ] Metadata consistency validation implemented

---

## Related Documentation

- [Coordinator Patterns Standard](coordinator-patterns-standard.md) - Pattern 2: Metadata Extraction Pattern
- [Brief Summary Format](brief-summary-format.md) - Return signal summary format
- [Coordinator Return Signals](coordinator-return-signals.md) - Signal schema specifications
- [Three-Tier Coordination Pattern](../../../concepts/three-tier-coordination-pattern.md) - Tier 3: Specialist responsibilities
- [Hierarchical Agent Architecture Overview](../../../concepts/hierarchical-agents-overview.md) - Architecture context

---

## Revision History

- **2025-12-10**: Initial standard created (Phase 4 of hierarchical agent architecture documentation)
- Defines YAML frontmatter schema for all artifact types
- Specifies metadata-only passing pattern for 95%+ context reduction
- Documents validation requirements and implementation examples
