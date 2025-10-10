# User Guide: Parallel Expansion and Collapse Operations

## Introduction

This guide explains how to use the parallel expansion and collapse features to efficiently manage implementation plan structure.

## Quick Start

### Basic Usage

**Expand Multiple Phases in Parallel:**
```bash
/expand specs/plans/001_myplan.md --auto-analysis
```

**Collapse Multiple Phases in Parallel:**
```bash
/collapse specs/plans/001_myplan/ --auto-analysis
```

### When to Use Auto-Analysis Mode

Use `--auto-analysis` when:
- You have 3+ phases/stages to expand/collapse
- You want automatic complexity-based recommendations
- You trust the system to identify optimal candidates
- You want parallel execution for speed

Use explicit mode (specify phase numbers) when:
- You know exactly which phases to expand/collapse
- You need fine-grained control
- You have 1-2 items to process
- You want sequential execution

## Features

### 1. Batch Complexity Analysis

The system analyzes your entire plan in a single pass:

```bash
/expand specs/plans/001_auth_system.md --auto-analysis
```

**Output:**
```
Analyzing plan complexity...

Complexity Analysis Results:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase 1: Setup              Complexity: 3/10  Status: ✓ Simple
Phase 2: Authentication     Complexity: 9/10  Status: ⚠ Expand
Phase 3: Authorization      Complexity: 8/10  Status: ⚠ Expand
Phase 4: Testing            Complexity: 4/10  Status: ✓ Balanced
Phase 5: Deployment         Complexity: 5/10  Status: ✓ Balanced
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Recommendations: Expand phases 2, 3 (complexity ≥8)
```

### 2. Parallel Execution

Once candidates are identified, operations execute concurrently:

```
Expanding phases in parallel...
  ⟳ Expanding phase 2: Authentication
  ⟳ Expanding phase 3: Authorization

Results:
  ✓ Phase 2 expanded → specs/plans/001_auth_system/phase_2_authentication.md
  ✓ Phase 3 expanded → specs/plans/001_auth_system/phase_3_authorization.md

Completed 2 operations in 45s (vs 90s sequential)
```

### 3. Hierarchy Review

After operations complete, the system analyzes plan structure:

```
Reviewing plan hierarchy...

Hierarchy Analysis:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Current Structure:
  - Level: 1 (phase expansion)
  - Total Phases: 5
  - Expanded: 2
  - Balance: Good

Optimization Opportunities:

1. Phase 2: Authentication (complexity 9)
   Recommendation: Expand into stages
   Reason: Still highly complex after expansion

2. Phases 4-5: Testing and Deployment
   Recommendation: Consider merging
   Reason: Closely related, similar complexity
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 4. Second-Round Analysis

The system can re-analyze to find new candidates:

```
Running second-round analysis...

New Expansion Candidates:
  - Phase 2: Authentication (complexity increased to 9)

Would you like to proceed with second-round expansion? (y/n):
```

### 5. User Approval Gates

You control when operations proceed:

```
Recommendations Ready for Review
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Operations to perform:
  1. Expand phase 2 into stages
  2. Merge phases 4 and 5

Estimated time: 60s

Proceed with these operations? (y/n):
```

## Workflows

### Workflow 1: Expand Complex Plan

**Goal:** Break down a complex plan into manageable pieces

**Steps:**

1. **Start with Level 0 plan:**
   ```bash
   cat specs/plans/001_feature.md
   # Shows: 8 phases, all inline
   ```

2. **Run auto-analysis expansion:**
   ```bash
   /expand specs/plans/001_feature.md --auto-analysis
   ```

3. **Review recommendations:**
   ```
   Recommendations: Expand phases 3, 5, 7 (complexity ≥8)

   Proceed? (y/n): y
   ```

4. **Operations execute in parallel:**
   ```
   Expanding 3 phases in parallel...
   ✓ Phase 3 expanded
   ✓ Phase 5 expanded
   ✓ Phase 7 expanded

   Completed in 45s
   ```

5. **Review hierarchy suggestions:**
   ```
   Hierarchy Review: Phase 5 still complex (9/10)
   Recommendation: Expand into stages

   Run second-round expansion? (y/n): y
   ```

6. **Second-round expansion:**
   ```
   /expand specs/plans/001_feature/phase_5_implementation.md --auto-analysis
   ```

7. **Final structure:**
   ```
   specs/plans/001_feature/
   ├── 001_feature.md (main plan)
   ├── phase_3_database.md
   ├── phase_5_implementation/
   │   ├── phase_5_overview.md
   │   ├── stage_1_setup.md
   │   ├── stage_2_core.md
   │   └── stage_3_testing.md
   └── phase_7_deployment.md
   ```

### Workflow 2: Collapse Over-Expanded Plan

**Goal:** Simplify a plan that's too granular

**Steps:**

1. **Start with expanded plan:**
   ```bash
   ls specs/plans/001_api/
   # Shows: 15 phase files, many simple
   ```

2. **Run auto-analysis collapse:**
   ```bash
   /collapse specs/plans/001_api/ --auto-analysis
   ```

3. **Review recommendations:**
   ```
   Recommendations: Collapse phases 2, 4, 6, 8 (complexity ≤4)

   These phases are simple enough to merge back.

   Proceed? (y/n): y
   ```

4. **Operations execute in parallel:**
   ```
   Collapsing 4 phases in parallel...
   ✓ Phase 2 collapsed
   ✓ Phase 4 collapsed
   ✓ Phase 6 collapsed
   ✓ Phase 8 collapsed

   Completed in 40s
   ```

5. **Verify structure:**
   ```bash
   cat specs/plans/001_api.md
   # Shows: Phases 2, 4, 6, 8 merged back inline
   ```

### Workflow 3: Iterative Optimization

**Goal:** Continuously optimize plan structure

**Steps:**

1. **Initial expansion:**
   ```bash
   /expand specs/plans/001_refactor.md --auto-analysis
   # Expands 3 complex phases
   ```

2. **Work on implementation:**
   ```bash
   # Discover phase 2 is simpler than expected
   ```

3. **Collapse simplified phase:**
   ```bash
   /collapse specs/plans/001_refactor/ phase 2
   ```

4. **Discover new complexity:**
   ```bash
   # Phase 5 becomes more complex during implementation
   ```

5. **Expand newly complex phase:**
   ```bash
   /expand specs/plans/001_refactor.md phase 5
   ```

6. **Final optimization:**
   ```bash
   /expand specs/plans/001_refactor.md --auto-analysis
   # Hierarchy review suggests merging phases 3-4
   ```

## Advanced Features

### Artifact-Based Result Aggregation

**What it is:**
Instead of loading full operation results into context, the system uses lightweight artifact references.

**Why it matters:**
- **85% context reduction**
- **Faster execution**
- **Supports more parallel operations**

**How it works:**
```bash
# Traditional approach (slow, context-heavy)
for phase in 1 2 3 4 5; do
  result=$(expand_phase $phase)
  all_results+="$result"  # 200+ lines × 5 = 1000 lines
done

# Artifact approach (fast, context-efficient)
# Each operation saves to: specs/artifacts/001_plan/expansion_$phase.md
# Supervisor collects only paths: ~50 words total
artifact_refs=$(aggregate_expansion_artifacts)
```

**Benefits:**
- Execute 6+ operations in parallel
- Avoid context overflow
- Selective artifact reading when needed

### Checkpoint System

**What it is:**
Before parallel operations, the system saves plan state for rollback capability.

**Why it matters:**
- **Safe experimentation**
- **Partial failure recovery**
- **Rollback on errors**

**How it works:**
```bash
# 1. Checkpoint saved automatically
#    → .claude/checkpoints/parallel_ops/parallel_expansion_*.json

# 2. Operations execute
#    → Some succeed, some fail

# 3. On failure, restore checkpoint
#    → Plan returns to pre-operation state
```

**Manual checkpoint management:**
```bash
# List checkpoints
ls -lh .claude/checkpoints/parallel_ops/

# Validate checkpoint
validate_checkpoint_integrity "path/to/checkpoint.json"

# Restore manually (if needed)
restore_from_checkpoint "path/to/checkpoint.json"
```

### Retry Strategies

**Timeout Errors:**

If an operation times out, the system automatically retries with extended timeout:

```
Attempt 1: timeout = 120s  → Failed
Attempt 2: timeout = 180s  → Failed  (1.5x)
Attempt 3: timeout = 270s  → Success (2.25x)
```

**Toolset Fallback:**

If operations fail repeatedly, the system reduces available tools:

```
Attempt 1: tools = [Read, Write, Edit, Bash]  → Failed
Attempt 2: tools = [Read, Write]               → Success
```

**User Escalation:**

After max retries, the system asks you:

```
Operation Failed After 3 Attempts
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Operation: expand_phase_3
Error: Timeout exceeded

Recovery Options:
  1. Retry with extended timeout (5 minutes)
  2. Skip this operation
  3. Abort all operations

Choose an option (1-3):
```

### Partial Failure Handling

**What it is:**
When some operations succeed and others fail, the system continues with successful operations.

**Example:**

```
5 Operations:
  ✓ Expand phase 1  → Success
  ✓ Expand phase 3  → Success
  ✓ Expand phase 5  → Success
  ✗ Expand phase 7  → Failed (timeout)
  ✗ Expand phase 9  → Failed (permission denied)

Result: 3 successful, 2 failed

Decision:
  - Update metadata for phases 1, 3, 5 (successful)
  - Offer retry for phases 7, 9 (failed)
  - Don't rollback everything due to partial failure
```

**User prompt:**

```
Partial Success: 3/5 Operations Completed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Successful: phases 1, 3, 5
Failed: phases 7, 9

Options:
  1. Continue with successful operations
  2. Retry failed operations
  3. Rollback all operations

Choose an option (1-3):
```

## Performance Considerations

### Execution Speed

**Small Plans (1-3 phases):**
- Parallel overhead > sequential benefit
- Recommendation: Use explicit mode (sequential)

**Medium Plans (4-6 phases):**
- Parallel: ~2-3x faster
- Recommendation: Use auto-analysis (parallel)

**Large Plans (7+ phases):**
- Parallel: ~3-4x faster
- Recommendation: Use auto-analysis (parallel)

### Context Usage

**Guidelines:**

| Operations | Context Usage | Recommended Mode |
|------------|---------------|------------------|
| 1-2        | Low (~500 tokens) | Sequential |
| 3-4        | Medium (~1200 tokens) | Parallel |
| 5-6        | Medium (~1500 tokens) | Parallel |
| 7+         | Risk overflow | Batch into groups |

### System Resources

**Monitoring:**

```bash
# Check disk space (for checkpoints and artifacts)
df -h .claude/checkpoints/
df -h specs/artifacts/

# Monitor memory usage
# (Parallel operations use more memory)
free -h
```

**Recommendations:**
- Ensure 100MB+ free disk space
- Limit to 6 concurrent operations max
- Clean up artifacts regularly

## Tips and Best Practices

### Planning

**Start Simple:**
- Begin with Level 0 (single file)
- Expand only when phases become complex
- Don't over-expand prematurely

**Use Thresholds:**
- Expand at complexity ≥8
- Collapse at complexity ≤4
- Balanced complexity: 5-7

**Iterative Approach:**
- Expand → Implement → Review → Optimize
- Use hierarchy review regularly
- Don't hesitate to collapse if over-expanded

### Execution

**Trust Auto-Analysis:**
- Complexity scores are reliable
- Recommendations are conservative
- Manual override available if needed

**Review Recommendations:**
- Always review before approving
- Understand why operations recommended
- Use approval gates to maintain control

**Monitor Progress:**
- Watch for errors during execution
- Check artifact creation
- Validate metadata after completion

### Optimization

**Balance Structure:**
- Not too flat (all Level 0)
- Not too deep (Level 2 everywhere)
- Match structure to actual complexity

**Regular Maintenance:**
- Run hierarchy review periodically
- Collapse simplified phases
- Expand newly complex phases

**Cleanup:**
- Remove old artifacts
- Delete obsolete checkpoints
- Keep plan structure clean

## Examples

### Example 1: Feature Implementation

**Initial Plan:**
```markdown
# Feature: User Authentication

## Phases
1. Setup (simple)
2. Core Auth Logic (complex)
3. Database Integration (complex)
4. API Endpoints (moderate)
5. Testing (simple)
6. Deployment (simple)
```

**Auto-Analysis:**
```bash
/expand specs/plans/002_auth.md --auto-analysis

# Recommends: Expand phases 2, 3
# Complexity: phase 2 = 9, phase 3 = 8
```

**Result:**
```
specs/plans/002_auth/
├── 002_auth.md
├── phase_2_core_auth_logic.md
└── phase_3_database_integration.md
```

### Example 2: Bug Fix

**Initial Plan:**
```markdown
# Bug Fix: Memory Leak

## Phases
1. Reproduce (simple)
2. Investigate (moderate)
3. Fix (simple)
4. Test (simple)
```

**Decision:** No expansion needed
```bash
# All phases have complexity ≤6
# Keep as Level 0 (single file)
# No auto-analysis required
```

### Example 3: Refactoring

**Initial Plan:** 15 micro-phases (over-expanded)

**Auto-Analysis:**
```bash
/collapse specs/plans/005_refactor/ --auto-analysis

# Recommends: Collapse phases 1, 3, 5, 7, 9, 11, 13, 15
# Complexity: all ≤4
```

**Result:** 8 phases (better balance)

## Troubleshooting

For common issues and solutions, see: [Troubleshooting Guide](troubleshooting_parallel_operations.md)

**Quick Fixes:**

**Issue:** Context overflow
**Solution:** Reduce parallel operations to 4-6

**Issue:** Operations timing out
**Solution:** Retry with extended timeout

**Issue:** Metadata inconsistent
**Solution:** Validate and repair metadata

**Issue:** Checkpoint corrupted
**Solution:** Use previous checkpoint or manual recovery

## Reference

### Command Options

```bash
/expand <plan-path> [--auto-analysis] [phase <N>]
/collapse <plan-path> [--auto-analysis] [phase <N>] [stage <M>]
```

**Options:**
- `--auto-analysis`: Enable automatic complexity-based recommendations and parallel execution
- `phase <N>`: Explicitly specify phase to expand/collapse (sequential mode)
- `stage <M>`: Explicitly specify stage to collapse (sequential mode)

### Complexity Thresholds

- **Expand:** complexity ≥ 8/10
- **Collapse:** complexity ≤ 4/10
- **Balanced:** complexity 5-7/10

### Structure Levels

- **Level 0:** Single file, all phases inline
- **Level 1:** Directory, some phases in separate files
- **Level 2:** Phase directories with stage files

### Performance Metrics

- **Context Reduction:** 60-85% with artifact-based aggregation
- **Execution Speed:** 2-4x faster with parallel execution
- **Max Parallel Operations:** 4-6 recommended
- **Timeout:** Base 120s, retry at 180s, 270s

## Feedback and Support

For questions, issues, or suggestions:
- Documentation: `specs/parallel_execution_architecture.md`
- Troubleshooting: `specs/troubleshooting_parallel_operations.md`
- Test Examples: `.claude/tests/test_parallel_*.sh`
