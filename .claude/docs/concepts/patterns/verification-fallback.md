# Verification and Fallback Pattern

**Path**: docs → concepts → patterns → verification-fallback.md

[Used by: /implement, /orchestrate, /plan, /report, all file creation commands and agents]

MANDATORY VERIFICATION checkpoints with fallback file creation mechanisms achieve 100% file creation rates.

## Terminology Clarification

**Critical Distinction**: "Verification fallback" and "creation fallback" have opposite meanings in fail-fast philosophy.

**Verification Fallback** (✓ ALLOWED - This Pattern):
- **Purpose**: Error DETECTION through verification checkpoints
- **Action**: Verify file exists after agent completion
- **On Failure**: Report clear diagnostics, terminate workflow
- **Philosophy**: Exposes agent behavioral issues for developer to fix
- **Result**: Proper agent implementation, not orchestrator compensation

**Creation Fallback** (✗ PROHIBITED - Error Masking):
- **Purpose**: Error HIDING through automatic file creation
- **Action**: Silently create placeholder files when agent fails
- **On Failure**: Masks problem, workflow continues with empty/invalid files
- **Philosophy**: Hides agent behavioral issues from developer
- **Result**: Agent failures go unnoticed, technical debt accumulates

**This Pattern Uses**: Verification fallback (allowed detection) NOT creation fallback (prohibited masking).

**Example Reconciliation**:
```bash
# ✓ GOOD - Verification Fallback (Detection)
if [ ! -f "$EXPECTED_PATH" ]; then
  echo "CRITICAL: File missing at $EXPECTED_PATH"
  echo "TROUBLESHOOTING: Review agent behavioral file and fix file creation logic"
  exit 1  # Fail fast - expose the problem
fi

# ✗ BAD - Creation Fallback (Masking)
if [ ! -f "$EXPECTED_PATH" ]; then
  touch "$EXPECTED_PATH"  # Silently mask agent failure
  echo "Created placeholder"  # No diagnostics, problem hidden
fi
```

**See Also**: [Defensive Programming Patterns](defensive-programming.md) → Section 2 (Null Safety) for additional fail-fast examples.

## Definition

Verification and Fallback is a pattern where commands and agents validate file creation after every write operation and implement fallback mechanisms when files don't exist. This eliminates file creation failures by catching and correcting missing files immediately rather than discovering failures at workflow end.

The pattern consists of three components:
1. **Path Pre-Calculation**: Calculate all file paths before execution
2. **Verification Checkpoints**: MANDATORY VERIFICATION after each file creation
3. **Fallback Mechanisms**: Create missing files if verification fails

## Relationship to Fail-Fast Policy

This pattern implements fail-fast error detection with agent responsibility enforcement, NOT fail-fast violation through silent error masking.

**Detection (Fail-Fast Component)**:
- MANDATORY VERIFICATION exposes file creation failures immediately
- No silent continuation when expected files missing
- Clear diagnostics showing exactly what failed and where
- Workflow terminates with troubleshooting guidance

**Agent Responsibility (Fail-Fast Enforcement)**:
- Agents must create their own artifacts using Write tool
- Orchestrator verifies existence (detection mechanism)
- Orchestrator does NOT create placeholder files (would mask agent failures)
- Missing files indicate agent behavioral issues requiring fixes

**Recovery Through Failure (Fail-Fast Pattern)**:
- Verification fails → Clear error with diagnostic steps
- User reviews agent behavioral file and invocation
- User fixes root cause (agent prompt, file path logic, etc.)
- User re-runs workflow after fixing
- Result: Actual problems solved, not masked

**Why This Aligns With Fail-Fast Philosophy**:

Fail-fast prohibits HIDING errors through silent fallbacks. This pattern EXPOSES errors immediately:
- Agent completes → file missing → CRITICAL error logged
- Workflow terminates immediately (not after all phases)
- Clear troubleshooting steps guide user to root cause
- No placeholder files masking agent failures
- Result: 100% file creation through proper agent implementation, not orchestrator compensation

**Critical Distinction** (Spec 057):
- **Bootstrap fallbacks**: Silent function definitions masking configuration errors → PROHIBITED (violate fail-fast)
- **Verification checkpoints**: Explicit error detection with workflow termination → REQUIRED (implement fail-fast)
- **Placeholder file creation**: Orchestrator masking agent failures → PROHIBITED (violate fail-fast)
- **Optimization fallbacks**: Performance cache degradation (state persistence) → ACCEPTABLE (optimization only)

**Best Practice**: Verification checkpoints detect errors; agents fix their implementations. This maintains fail-fast integrity while ensuring complete artifact creation through proper design, not error masking.

See [Fail-Fast Policy Analysis](../../../specs/634_001_coordinate_improvementsmd_implements/reports/001_fail_fast_policy_analysis.md) for complete taxonomy and case studies.

## Rationale

### Why This Pattern Matters

File creation failures cascade through multi-phase workflows:

1. **Silent Failures**: Agents believe they created files but files don't exist (e.g., wrong directory, permission issues, tool failures)
2. **Downstream Breakage**: Subsequent phases fail when dependencies don't exist
3. **Late Discovery**: Failures discovered after entire workflow completes
4. **Difficult Diagnosis**: Root cause unclear without checkpoint tracking

### Problems Solved

- **100% File Creation Rate**: Achieved through verification + fallback (10/10 tests vs 6-8/10 without pattern)
- **Immediate Correction**: Files created via fallback within same phase
- **Clear Diagnostics**: Verification checkpoints identify exact failure point
- **Predictable Workflows**: Eliminate cascading phase failures

## Implementation

### Core Mechanism

**Step 1: Path Pre-Calculation**

Before any file operations, calculate and display all paths:

```markdown
## EXECUTE NOW - Calculate Paths

MANDATORY: Calculate ALL file paths before proceeding to execution:

1. Determine project root: /home/benjamin/.config
2. Calculate topic directory: specs/027_authentication/
3. Assign report paths:
   REPORT_1="${topic_dir}/reports/001_oauth_patterns.md"
   REPORT_2="${topic_dir}/reports/002_security_analysis.md"
   PLAN_PATH="${topic_dir}/plans/001_implementation.md"

4. Verify directories exist:
   - specs/027_authentication/reports/ ✓
   - specs/027_authentication/plans/ ✓

5. Paths calculated successfully. Proceed to agent invocation.
```

**Step 2: MANDATORY VERIFICATION Checkpoints**

After each file creation, verify file exists:

```markdown
## MANDATORY VERIFICATION - Report Creation

EXECUTE NOW (REQUIRED BEFORE NEXT STEP):

1. Verify report file exists:
   ls -la specs/027_authentication/reports/001_oauth_patterns.md

2. Expected output:
   -rw-r--r-- 1 user group 15420 Oct 21 10:30 001_oauth_patterns.md

3. Verify file size > 0:
   [ -s specs/027_authentication/reports/001_oauth_patterns.md ] && echo "✓ File created"

4. If verification fails, proceed to FALLBACK MECHANISM.
5. If verification succeeds, proceed to next agent invocation.
```

**Step 3: Fallback File Creation**

If verification fails, create file directly:

```markdown
## FALLBACK MECHANISM - Manual File Creation

TRIGGER: File verification failed for 001_oauth_patterns.md

EXECUTE IMMEDIATELY:

1. Create file directly using Write tool:
   Write tool invocation:
   {
     "file_path": "specs/027_authentication/reports/001_oauth_patterns.md",
     "content": "<agent's report content from previous response>"
   }

2. MANDATORY VERIFICATION (repeat):
   ls -la specs/027_authentication/reports/001_oauth_patterns.md

3. If still fails, escalate to user with error details.
4. If succeeds, log fallback usage and continue workflow.
```

### Code Example

Real implementation from Plan 077 - /implement command migration:

```markdown
## Phase 3: Implementation

YOUR ROLE: You are the ORCHESTRATOR. Delegate implementation to implementer agent.

### Step 1: Path Pre-Calculation (EXECUTE NOW)

Calculate implementation artifact paths:

IMPLEMENTATION_DIR="specs/027_authentication/implementation/"
mkdir -p "$IMPLEMENTATION_DIR"

IMPLEMENTATION_LOG="${IMPLEMENTATION_DIR}/phase_3_log.md"
CODE_CHANGES="${IMPLEMENTATION_DIR}/code_changes.diff"

Paths calculated: ✓

### Step 2: Invoke Implementer Agent

Task tool invocation:
{
  "agent": "implementer",
  "task": "Implement OAuth 2.0 authentication per plan phase 3",
  "context": {
    "plan_path": "specs/027_authentication/plans/001_implementation.md",
    "phase": 3,
    "output_paths": {
      "log": "specs/027_authentication/implementation/phase_3_log.md",
      "diff": "specs/027_authentication/implementation/code_changes.diff"
    }
  }
}

### Step 3: MANDATORY VERIFICATION (EXECUTE AFTER AGENT COMPLETES)

VERIFICATION CHECKPOINT - Implementation Artifacts:

1. Verify implementation log exists:
   ls -la specs/027_authentication/implementation/phase_3_log.md

2. Verify code changes exist:
   ls -la specs/027_authentication/implementation/code_changes.diff

3. Verify log file size > 100 bytes:
   [ $(wc -c < specs/027_authentication/implementation/phase_3_log.md) -gt 100 ] && echo "✓ Log complete"

4. Results:
   IF ALL VERIFICATIONS PASS:
     - Log verification: ✓
     - Diff verification: ✓
     - Size verification: ✓
     - Proceed to Step 4 (Testing)

   IF ANY VERIFICATION FAILS:
     - Trigger FALLBACK MECHANISM
     - Create missing files manually
     - Re-verify before proceeding

### Step 4: FALLBACK MECHANISM (TRIGGER IF VERIFICATION FAILS)

FALLBACK - Create Missing Implementation Log:

IF phase_3_log.md does not exist:

1. Extract log content from implementer agent response
2. Create file directly:
   Write tool:
   {
     "file_path": "specs/027_authentication/implementation/phase_3_log.md",
     "content": "<extracted log content>"
   }

3. MANDATORY RE-VERIFICATION:
   ls -la specs/027_authentication/implementation/phase_3_log.md

4. Log fallback usage:
   echo "FALLBACK USED: Manual creation of phase_3_log.md" >> workflow_log.md

5. If re-verification succeeds: ✓ Continue to Step 4
   If re-verification fails: ❌ Escalate to user
```

### Usage Context

**When to Apply:**
- All commands that create files (reports, plans, implementations, documentation)
- All agents that write artifacts
- Multi-phase workflows where phases depend on files from previous phases
- Any workflow scoring <100% on file creation tests

**When Not to Apply:**
- Read-only operations (analysis, search, grep)
- File modification operations (Edit tool on existing files)
- Utility functions that return data (no file creation)

## Anti-Patterns

### Example Violation 1: No Verification

```markdown
❌ BAD - File creation without verification:

## Phase 1: Research

I'll invoke the research-specialist agent to create a report.

Task tool: { "agent": "research-specialist", ... }

[Agent completes]

Great! Research complete. Proceeding to planning phase.
```

**Why This Fails:**
1. No verification that report file was created
2. Planning phase will fail if report doesn't exist (cascading failure)
3. Failure discovered too late (after planning phase starts)
4. Difficult to diagnose which agent/phase caused the failure

**Real-World Impact from Plan 077:**
- Before pattern: 6-8/10 file creation success rate
- After pattern: 10/10 file creation success rate (100%)

### Example Violation 2: Verification Without Fallback

```markdown
❌ BAD - Verification without fallback:

## VERIFICATION CHECKPOINT

Verify report exists:
ls -la specs/027_auth/reports/001_oauth.md

[File not found]

Hmm, the file doesn't exist. Let me continue to the next phase anyway.
```

**Why This Fails:**
1. Detected missing file but didn't correct it
2. Next phase will fail due to missing dependency
3. Wasted effort proceeding without required file

### Example Violation 3: Late Path Calculation

```markdown
❌ BAD - Paths calculated during agent execution:

## Phase 1: Research

Task tool: {
  "agent": "research-specialist",
  "task": "Research OAuth and save report somewhere in specs/"
}

[Agent decides path during execution - may choose wrong location]
```

**Why This Fails:**
1. Agent determines path (inconsistent locations)
2. Cannot verify correct path (orchestrator doesn't know where to check)
3. Violates behavioral injection pattern (paths should be injected)

## Testing Validation

### Validation Script

```bash
#!/bin/bash
# .claude/tests/validate_verification_fallback.sh

COMMAND_FILE="$1"

echo "Validating verification and fallback pattern in $COMMAND_FILE..."

# Check 1: Path pre-calculation present
if ! grep -q "EXECUTE NOW.*Calculate Paths" "$COMMAND_FILE" && \
   ! grep -q "Calculate ALL file paths before" "$COMMAND_FILE"; then
  echo "❌ MISSING: Path pre-calculation"
  exit 1
fi

# Check 2: MANDATORY VERIFICATION checkpoints present
verification_count=$(grep -c "MANDATORY VERIFICATION" "$COMMAND_FILE")
if [ "$verification_count" -lt 1 ]; then
  echo "❌ MISSING: MANDATORY VERIFICATION checkpoints (found: $verification_count)"
  exit 1
fi

# Check 3: Fallback mechanisms present
if ! grep -q "FALLBACK MECHANISM" "$COMMAND_FILE"; then
  echo "❌ MISSING: Fallback mechanism"
  exit 1
fi

# Check 4: File existence checks present
if ! grep -E "ls -la|test -f|\\[ -s " "$COMMAND_FILE"; then
  echo "⚠️  WARNING: No explicit file existence checks found"
fi

echo "✓ Verification and fallback pattern validated"
echo "  - Verification checkpoints: $verification_count"
```

### Expected Results

**File Creation Test:**
```bash
# Test 100% file creation rate
for i in {1..10}; do
  run_workflow_test
  check_all_files_exist || echo "FAILURE in run $i"
done

# Expected: 10/10 success rate (100%)
```

**Compliant Implementation:**
- Path pre-calculation before execution
- MANDATORY VERIFICATION after each file creation
- Fallback mechanism triggers on verification failure
- 10/10 file creation success rate

**Non-Compliant Implementation:**
- No verification checkpoints
- No fallback mechanisms
- 6-8/10 file creation success rate (60-80%)

## Performance Impact

### Measurable Improvements

**File Creation Rate (Real Metrics from Plan 077):**

| Command | Before Pattern | After Pattern | Improvement |
|---------|---------------|---------------|-------------|
| /report | 7/10 (70%) | 10/10 (100%) | +43% |
| /plan | 6/10 (60%) | 10/10 (100%) | +67% |
| /implement | 8/10 (80%) | 10/10 (100%) | +25% |
| **Average** | **7/10 (70%)** | **10/10 (100%)** | **+43%** |

**Downstream Reliability:**
- Before: 30% of workflows fail due to missing files from earlier phases
- After: 0% workflow failures due to missing files

**Diagnostic Time:**
- Before: 10-20 minutes to identify which phase/agent failed to create file
- After: Immediate identification via verification checkpoint logs

### Real-World Example (Plan 077)

**/implement command - Before pattern:**
```
Phase 1: Research - Agent creates report
Phase 2: Planning - Reads report (SUCCESS)
Phase 3: Implementation - Reads plan (SUCCESS)
Phase 4: Testing - Reads implementation (FAILURE - file missing)
  ❌ Implementation log not found

Root cause: Phase 3 agent believed it created file, but tool failed silently
Diagnosis time: 15 minutes reviewing logs
Recovery: Manual file creation, restart from Phase 4
```

**/implement command - After pattern:**
```
Phase 1: Research - Agent creates report
  ✓ VERIFICATION: Report exists (15420 bytes)
Phase 2: Planning - Reads report (SUCCESS)
  ✓ VERIFICATION: Plan exists (8932 bytes)
Phase 3: Implementation - Reads plan (SUCCESS)
  ❌ VERIFICATION: Implementation log missing
  ⚡ FALLBACK: Creating log manually
  ✓ RE-VERIFICATION: Log exists (2104 bytes)
Phase 4: Testing - Reads implementation (SUCCESS)

Result: All files present, workflow completes successfully
```

## Related Patterns

- [Behavioral Injection](./behavioral-injection.md) - Provides paths for verification checkpoints
- [Checkpoint Recovery](./checkpoint-recovery.md) - Stores verification results for recovery
- [Metadata Extraction](./metadata-extraction.md) - Includes file paths in metadata for verification
- [Context Management](./context-management.md) - Verification reduces debugging context needs

## See Also

- [Testing Patterns Guide](../../guides/patterns/testing-patterns.md) - File creation testing strategies
- [Command Architecture Standards](../../reference/architecture/overview.md) - Standard 0 requirements and validation
- [Creating Commands Guide](../../guides/development/command-development/command-development-fundamentals.md) - Implementation best practices
