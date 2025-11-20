# Agent Development: Testing and Validation

**Related Documents**:
- [Fundamentals](agent-development-fundamentals.md) - Creating agents
- [Patterns](agent-development-patterns.md) - Invocation patterns
- [Troubleshooting](agent-development-troubleshooting.md) - Common issues

---

## Testing Agents

### Unit Testing

Test individual agent behavior:

```bash
#!/bin/bash
# test_research_specialist.sh

test_file_creation() {
  # Setup
  OUTPUT_PATH="/tmp/test_report_$$_.md"

  # Invoke agent (simulated)
  # In real test, invoke via Task tool

  # Verify
  if [ ! -f "$OUTPUT_PATH" ]; then
    echo "FAIL: File not created"
    return 1
  fi

  # Check required sections
  if ! grep -q "## Overview" "$OUTPUT_PATH"; then
    echo "FAIL: Missing Overview section"
    return 1
  fi

  # Cleanup
  rm -f "$OUTPUT_PATH"
  echo "PASS: File creation test"
  return 0
}

test_file_creation
```

### Integration Testing

Test agent within command workflow:

```bash
#!/bin/bash
# test_orchestrate_workflow.sh

test_research_phase() {
  # Run actual command
  /orchestrate "Test feature authentication"

  # Verify all expected outputs
  TOPIC_DIR=".claude/specs/*/reports"

  if [ "$(ls -1 $TOPIC_DIR/*.md 2>/dev/null | wc -l)" -lt 1 ]; then
    echo "FAIL: No research reports created"
    return 1
  fi

  echo "PASS: Research phase complete"
  return 0
}

test_research_phase
```

### Validation Checklist

For each agent, verify:

- [ ] File created at exact specified path
- [ ] All required sections present
- [ ] Output format matches specification
- [ ] Confirmation signal returned
- [ ] No tool restriction violations
- [ ] Quality criteria met

---

## Verification Patterns

### Post-Invocation Verification

```bash
verify_agent_output() {
  local expected_path="$1"
  local required_sections=("Overview" "Findings" "Recommendations")

  # Check file exists
  if [ ! -f "$expected_path" ]; then
    echo "CRITICAL: File not created at $expected_path"
    return 1
  fi

  # Check required sections
  for section in "${required_sections[@]}"; do
    if ! grep -q "## $section" "$expected_path"; then
      echo "WARN: Missing section: $section"
    fi
  done

  echo "Verified: $expected_path"
  return 0
}
```

### Signal Validation

```bash
validate_signal() {
  local output="$1"
  local signal="$2"

  if ! echo "$output" | grep -q "^$signal:"; then
    echo "CRITICAL: Missing $signal signal"
    return 1
  fi

  VALUE=$(echo "$output" | grep -oP "^$signal:\s*\K.+")
  echo "$VALUE"
  return 0
}

# Usage
CREATED_PATH=$(validate_signal "$AGENT_OUTPUT" "CREATED")
```

### Batch Verification

```bash
verify_all_outputs() {
  local -n paths=$1
  local failed=0

  for key in "${!paths[@]}"; do
    if [ ! -f "${paths[$key]}" ]; then
      echo "MISSING: ${paths[$key]}"
      ((failed++))
    else
      echo "OK: ${paths[$key]}"
    fi
  done

  if [ $failed -gt 0 ]; then
    echo "CRITICAL: $failed files missing"
    return 1
  fi

  echo "All files verified"
  return 0
}
```

---

## Quality Metrics

### Target Metrics

| Metric | Target | Minimum |
|--------|--------|---------|
| File creation rate | 100% | 95% |
| Section completeness | 100% | 90% |
| Signal compliance | 100% | 100% |
| Format adherence | 100% | 95% |

### Measuring Quality

```bash
measure_agent_quality() {
  local report_dir="$1"
  local total=0
  local passed=0

  for report in "$report_dir"/*.md; do
    ((total++))

    # Check completeness
    sections=$(grep -c "^## " "$report")
    if [ "$sections" -ge 4 ]; then
      ((passed++))
    fi
  done

  echo "Quality: $passed/$total reports complete"
  echo "Rate: $(( passed * 100 / total ))%"
}
```

---

## Debugging Agents

### Enable Verbose Output

Add to agent prompt:
```markdown
**Debug Mode**: Emit progress markers:
- PROGRESS: Starting analysis
- PROGRESS: Found N patterns
- PROGRESS: Creating report
- PROGRESS: Verification complete
```

### Capture Output

```bash
# Capture full agent output
AGENT_OUTPUT=$(invoke_agent 2>&1)

# Log for debugging
echo "$AGENT_OUTPUT" >> ".claude/logs/agent_debug.log"

# Extract signals
CREATED=$(echo "$AGENT_OUTPUT" | grep "^CREATED:")
STATUS=$(echo "$AGENT_OUTPUT" | grep "^STATUS:")
```

### Common Debug Points

1. **Check agent received context**
   - Add echo of received parameters

2. **Check tool usage**
   - Log tool invocations

3. **Check output format**
   - Print structure before returning

---

## Regression Testing

### Test Suite Structure

```
.claude/tests/
    agents/
        test_research_specialist.sh
        test_plan_architect.sh
        test_implementation_agent.sh
        test_common.sh  # Shared utilities
```

### Running Tests

```bash
# Run all agent tests
for test in .claude/tests/agents/test_*.sh; do
  echo "Running: $test"
  bash "$test" || echo "FAILED: $test"
done

# Run specific test
bash .claude/tests/agents/test_research_specialist.sh
```

### CI Integration

```yaml
# .github/workflows/test-agents.yml
name: Agent Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run agent tests
        run: |
          for test in .claude/tests/agents/test_*.sh; do
            bash "$test" || exit 1
          done
```

---

## Test Fixtures

### Sample Input Fixture

```bash
# fixtures/research_input.json
{
  "topic": "Authentication patterns",
  "output_path": "/tmp/test_auth_report.md",
  "thinking_mode": "think"
}
```

### Expected Output Fixture

```markdown
<!-- fixtures/expected_research_output.md -->
# Authentication Patterns

## Overview
[2-3 sentence summary]

## Current State
[Analysis of existing patterns]

## Research Findings
- Finding 1
- Finding 2
- Finding 3
- Finding 4
- Finding 5

## Recommendations
- Recommendation 1
- Recommendation 2
- Recommendation 3
```

### Fixture Comparison

```bash
compare_output() {
  local actual="$1"
  local expected="$2"

  # Compare structure (sections present)
  for section in "Overview" "Current State" "Findings" "Recommendations"; do
    if grep -q "## $section" "$expected"; then
      if ! grep -q "## $section" "$actual"; then
        echo "FAIL: Missing $section in actual output"
        return 1
      fi
    fi
  done

  echo "PASS: Structure matches expected"
  return 0
}
```

---

## Performance Testing

### Measure Execution Time

```bash
time_agent() {
  local start=$(date +%s.%N)

  # Invoke agent
  invoke_agent "$@"

  local end=$(date +%s.%N)
  local duration=$(echo "$end - $start" | bc)

  echo "Duration: ${duration}s"
}
```

### Context Usage

```bash
measure_context() {
  local prompt="$1"

  # Rough estimate: 4 chars = 1 token
  local chars=${#prompt}
  local tokens=$((chars / 4))

  echo "Estimated tokens: $tokens"
}
```

---

## Related Documentation

- [Fundamentals](agent-development-fundamentals.md)
- [Patterns](agent-development-patterns.md)
- [Troubleshooting](agent-development-troubleshooting.md)
- [Testing Standards](../reference/standards/testing-protocols.md)
