# Migration Testing Guide

## Overview

This guide documents the testing procedures for execution enforcement migrations. The migration transforms commands and agents to use systematic execution enforcement patterns, achieving 100% file creation rates and ≥95/100 audit scores.

For complete migration process and enforcement patterns, see [Execution Enforcement Guide](./execution-enforcement/execution-enforcement-overview.md).

## Testing Infrastructure

### Test Scripts

#### File Creation Rate Test
**Location**: `.claude/tests/test_migration_file_creation.sh`

**Purpose**: Measure file creation reliability across 10 test runs

**Usage**:
```bash
./test_migration_file_creation.sh <command> <test_input> <expected_file_pattern> [test_runs]
```

**Example**:
```bash
# Test /report command file creation
./test_migration_file_creation.sh "/report" "Test topic" ".claude/specs/*/reports/*.md" 10
```

**Success Criteria**: 10/10 successful file creations (100% rate)

#### File Creation Rate Tracking
**Location**: `.claude/lib/track-file-creation-rate.sh`

**Purpose**: Record file creation rates in tracking spreadsheet

**Usage**:
```bash
./track-file-creation-rate.sh <type> <name> <success_count> <total_runs>
```

**Example**:
```bash
# Record test results for doc-writer agent
./track-file-creation-rate.sh "agent" "doc-writer.md" 10 10
```

**Output**: Updates `.claude/specs/plans/077_execution_enforcement_migration/077_migration_tracking.csv`

### Audit Script

**Location**: `.claude/lib/audit-execution-enforcement.sh`

**Purpose**: Score commands and agents on execution enforcement pattern compliance

**Usage**:
```bash
./audit-execution-enforcement.sh <file_path>
```

**Success Criteria**: Score ≥95/100

## Testing Procedures

### Per-Migration Testing

After migrating each command or agent, run all four tests:

#### Test 1: File Creation Rate (30 min)

```bash
#!/bin/bash
# Test file creation reliability

COMMAND="<command_name>"
TEST_INPUT="<appropriate_test_input>"
EXPECTED_FILE="<file_pattern>"

for i in {1..10}; do
  $COMMAND "$TEST_INPUT $i" 2>&1 > "/tmp/test_${i}.log"

  if [ -f "$EXPECTED_FILE" ]; then
    echo "✓ Run $i: SUCCESS"
    SUCCESS=$((SUCCESS + 1))
  else
    echo "✗ Run $i: FAILED"
  fi

  # Cleanup for next test
  rm -f "$EXPECTED_FILE" 2>/dev/null || true
done

echo "File creation rate: $SUCCESS/10"
[ $SUCCESS -eq 10 ] && echo "✓ PASSED" || echo "✗ FAILED"
```

**Expected Outcome**: 10/10 successful file creations

#### Test 2: Audit Score (15 min)

```bash
#!/bin/bash
# Verify enforcement pattern compliance

FILE_PATH="<path_to_migrated_file>"

.claude/lib/audit-execution-enforcement.sh "$FILE_PATH" > /tmp/audit_result.txt

SCORE=$(grep "^Score:" /tmp/audit_result.txt | awk '{print $2}' | cut -d'/' -f1)

echo "Audit score: $SCORE/100"

if [ "$SCORE" -ge 95 ]; then
  echo "✓ PASSED: Score ≥95/100"
else
  echo "✗ FAILED: Score <95/100"
  echo "Missing patterns:"
  grep "Missing:" /tmp/audit_result.txt
  exit 1
fi
```

**Expected Outcome**: Score ≥95/100

#### Test 3: Verification Checkpoint Execution (15 min)

```bash
#!/bin/bash
# Verify checkpoints execute during command/agent run

COMMAND="<command_name>"
TEST_INPUT="<test_input>"

$COMMAND "$TEST_INPUT" 2>&1 | tee /tmp/checkpoint_test.log

# Required checkpoint markers
REQUIRED_CHECKPOINTS=(
  "✓ VERIFIED:"
  "CHECKPOINT:"
  "PROGRESS:"
  "MANDATORY"
)

PASS=true
for checkpoint in "${REQUIRED_CHECKPOINTS[@]}"; do
  if grep -q "$checkpoint" /tmp/checkpoint_test.log; then
    echo "✓ Checkpoint found: $checkpoint"
  else
    echo "✗ Checkpoint missing: $checkpoint"
    PASS=false
  fi
done

[ "$PASS" = true ] && echo "✓ PASSED" || echo "✗ FAILED"
```

**Expected Outcome**: All required checkpoints present in output

#### Test 4: Fallback Mechanism (20 min)

```bash
#!/bin/bash
# Verify fallback creation works when agent doesn't create file

# 1. Temporarily modify agent to NOT create file
# 2. Run command that invokes the agent
# 3. Verify command fallback created the file
# 4. Restore agent

EXPECTED_FILE="<file_path>"
COMMAND="<command_name>"

# Simulate agent non-compliance (implementation-specific)
# ... modify agent temporarily ...

# Run command
$COMMAND "test input" 2>&1 > /tmp/fallback_test.log

# Check if fallback created file
if [ -f "$EXPECTED_FILE" ]; then
  echo "✓ PASSED: Fallback mechanism worked"
else
  echo "✗ FAILED: File not created despite fallback"
  exit 1
fi

# Restore agent
# ... restore original agent ...
```

**Expected Outcome**: File exists despite agent non-compliance

### System-Wide Testing

After completing all migrations, run comprehensive system tests:

#### Test 1: Hierarchical Pattern Test (/report)

```bash
#!/bin/bash
# Test hierarchical multi-agent research pattern

TOPIC="Comprehensive analysis of microservices architecture patterns with focus on event-driven design, CQRS, and service mesh implementations"

/report "$TOPIC" 2>&1 | tee /tmp/hierarchical_test.log

# Verify Task tool invocations (not direct Read/Grep usage)
TASK_COUNT=$(grep -c "Task {" /tmp/hierarchical_test.log || true)
if [ "$TASK_COUNT" -ge 2 ]; then
  echo "✓ Hierarchical delegation confirmed ($TASK_COUNT agents invoked)"
else
  echo "✗ Direct execution detected (no Task tool usage)"
  exit 1
fi

# Verify multiple subtopic reports created
REPORT_COUNT=$(find .claude/specs/*/reports/ -name "*.md" -newer /tmp/test_marker -type f | wc -l)
if [ "$REPORT_COUNT" -ge 3 ]; then
  echo "✓ Multiple reports created ($REPORT_COUNT reports)"
else
  echo "✗ Insufficient reports created"
  exit 1
fi

# Verify metadata-based context reduction (no full content in logs)
FULL_CONTENT_SIZE=$(grep -o "FULL_CONTENT:" /tmp/hierarchical_test.log | wc -c || echo 0)
if [ "$FULL_CONTENT_SIZE" -lt 1000 ]; then
  echo "✓ Context reduction working (minimal content in logs)"
else
  echo "✗ Full content being passed (context not reduced)"
  exit 1
fi
```

**Expected Outcomes**:
- Task tool invocations visible
- Multiple subtopic reports created in hierarchical structure
- Zero direct Read/Grep usage for research
- Context window usage <30%

#### Test 2: Conditional Orchestration Test (/plan, /implement)

```bash
#!/bin/bash
# Test conditional execution (simple → direct, complex → orchestration)

# Test 1: Simple feature (direct execution)
echo "=== Testing Simple Feature (Direct Execution) ==="
/plan "Add a new keybinding for saving all buffers" 2>&1 | tee /tmp/plan_simple.log

TASK_COUNT=$(grep -c "Task {" /tmp/plan_simple.log || true)
if [ "$TASK_COUNT" -eq 0 ]; then
  echo "✓ Simple feature: Direct execution (no agents)"
else
  echo "✗ Simple feature: Unexpected agent invocation"
fi

# Test 2: Complex feature (orchestration)
echo "=== Testing Complex Feature (Orchestration) ==="
/plan "Implement distributed tracing system with OpenTelemetry integration, custom exporters, and performance monitoring dashboard" 2>&1 | tee /tmp/plan_complex.log

TASK_COUNT=$(grep -c "Task {" /tmp/plan_complex.log || true)
if [ "$TASK_COUNT" -ge 1 ]; then
  echo "✓ Complex feature: Orchestration ($TASK_COUNT agents invoked)"
else
  echo "✗ Complex feature: No orchestration detected"
  exit 1
fi
```

**Expected Outcomes**:
- Simple features: No Task tool invocations (direct execution)
- Complex features: Task tool invocations for research (orchestration)

#### Test 3: Parallel Execution Test

```bash
#!/bin/bash
# Verify parallel agent execution

/report "Authentication best practices" 2>&1 | tee /tmp/parallel_test.log

# Count Task invocations
TASK_COUNT=$(grep -c "Task {" /tmp/parallel_test.log)

# Measure execution time
START_TIME=$(date +%s)
/report "Multi-faceted topic requiring 4 subtopics"
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "Execution time: ${DURATION}s"
echo "Task invocations: $TASK_COUNT"

# Parallel execution should be faster than 4x sequential research time
# (Assuming ~30s per research task, sequential would be 120s, parallel ~40s)
if [ "$DURATION" -lt 80 ]; then
  echo "✓ Parallel execution confirmed (faster than sequential)"
else
  echo "⚠ Execution time suggests sequential processing"
fi
```

**Expected Outcome**: Time savings from parallel execution (40-60% faster)

#### Test 4: Context Window Usage Test

```bash
#!/bin/bash
# Monitor context window usage during /orchestrate

/orchestrate "Complete feature development from research to documentation" 2>&1 | tee /tmp/orchestrate_test.log

# Extract context usage metrics from orchestrator logs
# (Implementation depends on logging format)

# Expected metrics:
# - Research phase: <20% context usage
# - Planning phase: <25% context usage
# - Implementation phase: <30% context usage
# - Documentation phase: <20% context usage

echo "Context usage metrics:"
grep "Context usage:" /tmp/orchestrate_test.log

# Overall target: <30% average context usage
```

**Expected Outcome**: Context usage <30% throughout workflow

### Regression Testing

After all migrations, verify no regressions:

```bash
#!/bin/bash
# Run full test suite

cd /home/benjamin/.config

# Run all tests
.claude/tests/run_all_tests.sh

# Check for failures
if [ $? -eq 0 ]; then
  echo "✓ All tests passed (zero regressions)"
else
  echo "✗ Test failures detected (regressions found)"
  exit 1
fi
```

**Expected Outcome**: All existing tests pass

## Tracking and Reporting

### Migration Tracking Spreadsheet

**Location**: `.claude/specs/plans/077_execution_enforcement_migration/077_migration_tracking.csv`

**Format**:
```csv
Type,Name,Pre-Score,Post-Score,File Creation Rate,Success Count,Total Runs,Duration,Status,Date
agent,doc-writer.md,45/100,95/100,100%,10,10,6h,PASSED,2025-10-20
agent,debug-specialist.md,40/100,95/100,100%,10,10,4h,PASSED,2025-10-20
command,report.md,60/100,95/100,100%,10,10,8h,PASSED,2025-10-20
```

**Fields**:
- **Type**: "command" or "agent"
- **Name**: File name
- **Pre-Score**: Audit score before migration
- **Post-Score**: Audit score after migration
- **File Creation Rate**: Percentage (0-100%)
- **Success Count**: Successful file creations
- **Total Runs**: Total test runs (usually 10)
- **Duration**: Migration time (hours)
- **Status**: PENDING, IN_PROGRESS, PASSED, FAILED
- **Date**: Completion date (YYYY-MM-DD)

### Test Log Organization

Store all test logs in `/tmp/` with descriptive names:

```
/tmp/
├── doc_writer_file_creation_1.log
├── doc_writer_file_creation_2.log
├── ...
├── doc_writer_audit_post.txt
├── doc_writer_checkpoint_test.log
├── doc_writer_fallback_test.log
├── hierarchical_test.log
├── parallel_test.log
└── orchestrate_test.log
```

## Success Criteria

### Per-Migration Success

- [x] File creation rate: 10/10 (100%)
- [x] Audit score: ≥95/100
- [x] Verification checkpoints: All executing
- [x] Fallback mechanism: Working

### System-Wide Success

- [x] All 12 commands migrated with ≥95/100 scores
- [x] All 10 agents migrated with ≥95/100 scores
- [x] Hierarchical pattern working (/report)
- [x] Conditional orchestration working (/plan, /implement)
- [x] Parallel execution working (40-60% time savings)
- [x] Context window usage <30% for orchestrators
- [x] Zero regressions (all existing tests pass)

## Troubleshooting

### File Creation Rate <100%

**Symptom**: Some test runs fail to create expected file

**Diagnosis**:
1. Check agent logs for error messages
2. Verify path calculation is using absolute paths
3. Check for missing verification checkpoints
4. Verify Write tool is being called

**Solutions**:
- Add MANDATORY VERIFICATION blocks after file creation
- Add fallback creation mechanism in command
- Ensure path pre-calculation executes

### Audit Score <95/100

**Symptom**: Migrated file scores below 95/100 on audit

**Diagnosis**:
1. Run audit script to see missing patterns
2. Compare against reference models
3. Check for incomplete passive voice elimination
4. Verify template markers present

**Solutions**:
- Add missing enforcement patterns from audit output
- Complete all 5 phases of transformation
- Use migration guide checklist
- Study reference models (research-specialist.md, plan-architect.md, code-writer.md)

### Verification Checkpoints Not Executing

**Symptom**: Checkpoint markers not appearing in command/agent output

**Diagnosis**:
1. Check if CHECKPOINT markers are in file
2. Verify checkpoint code is not in comments
3. Check if STEP dependencies are being followed

**Solutions**:
- Ensure CHECKPOINT markers are executable (not just comments)
- Add echo statements for checkpoints
- Verify sequential STEP execution

### Fallback Mechanism Not Working

**Symptom**: File not created when agent fails

**Diagnosis**:
1. Check if command has verification block
2. Verify fallback creation code is present
3. Check for path calculation errors

**Solutions**:
- Add MANDATORY VERIFICATION after agent invocation
- Add fallback Write call with basic template
- Ensure paths are pre-calculated before agent invocation

## Best Practices

1. **Test After Each Migration**: Don't batch migrations without testing
2. **Use Reference Models**: Study compliant agents for patterns
3. **Run Full Test Suite**: Verify zero regressions frequently
4. **Update Tracking Immediately**: Record results right after testing
5. **Save Test Logs**: Keep logs for debugging and analysis
6. **Verify Checkpoints**: Always check checkpoint execution
7. **Test Fallbacks**: Explicitly test fallback mechanisms
8. **Measure Time Savings**: Track parallel execution performance

## Related Documentation

- [Execution Enforcement Guide](./execution-enforcement/execution-enforcement-overview.md) - Complete migration process, enforcement patterns, validation techniques
- [Command Architecture Standards](../reference/architecture/overview.md) - Standard 0 and 0.5 definitions
- [Agent Reference](../../agents/README.md) - Agent catalog and usage
- [Command Reference](../../commands/README.md) - Command catalog and usage

---

**Guide Status**: ✅ ACTIVE
**Version**: 1.1 (Updated to reference consolidated enforcement guide)
**Last Updated**: 2025-10-21
