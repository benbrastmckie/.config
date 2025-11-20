# Checkpoint Recovery Pattern

**Path**: docs → concepts → patterns → checkpoint-recovery.md

[Used by: /implement, /orchestrate, /plan, long-running multi-phase workflows]

State preservation and restoration enables resilient workflows that can resume after failures or interruptions.

## Definition

Checkpoint Recovery is a pattern where workflow state (current phase, completed work, paths, metadata) is periodically saved to checkpoint files, enabling workflows to resume from the last successful checkpoint rather than restarting from the beginning. This provides resilience against failures, interruptions, and enables adaptive replanning.

Components:
- **Checkpoint Creation**: Save state after each phase completion
- **Checkpoint Validation**: Verify checkpoint integrity before use
- **Resume Logic**: Restore state and continue from checkpoint
- **Replan Tracking**: Track adaptive replanning events to prevent loops

## Rationale

### Why This Pattern Matters

Multi-phase workflows fail catastrophically without checkpoints:

1. **Lost Progress**: 6-hour workflow fails in Phase 5 → must restart from Phase 1 (6 hours lost)
2. **Non-Deterministic Failures**: Transient errors (network, API limits) cause restart → wasted computation
3. **Adaptive Replanning**: Cannot track replan history → infinite replan loops
4. **Debugging**: No state history → difficult to diagnose failure points

With checkpoints:
- Resume from last successful phase (minutes vs hours)
- Automatic resume on transient failures
- Replan tracking prevents infinite loops
- Complete audit trail for debugging

## Implementation

### Core Mechanism

**Step 1: Checkpoint Structure**

```json
{
  "workflow_id": "implement_027_auth",
  "plan_path": "specs/027_auth/plans/001_implementation.md",
  "current_phase": 3,
  "completed_phases": [1, 2],
  "phase_metadata": {
    "1": {
      "status": "completed",
      "artifacts": ["specs/027_auth/implementation/phase_1_log.md"],
      "duration_minutes": 45,
      "timestamp": "2025-10-21T10:30:00Z"
    },
    "2": {
      "status": "completed",
      "artifacts": ["specs/027_auth/implementation/phase_2_log.md"],
      "duration_minutes": 60,
      "timestamp": "2025-10-21T11:45:00Z"
    }
  },
  "replan_history": [
    {
      "phase": 3,
      "reason": "complexity_exceeded",
      "timestamp": "2025-10-21T12:00:00Z"
    }
  ],
  "replan_count": {
    "3": 1
  },
  "artifact_paths": {
    "implementation_dir": "specs/027_auth/implementation/",
    "test_results": "specs/027_auth/test_results/"
  },
  "context_metadata": {
    "research_reports": ["001_oauth.md", "002_security.md"],
    "plan_metadata": {...}
  }
}
```

**Step 2: Checkpoint Creation**

```markdown
## Phase Completion - Create Checkpoint

After Phase N completes successfully:

EXECUTE NOW:
1. Extract phase metadata:
   - Status: completed
   - Artifacts created: [list of file paths]
   - Duration: <calculated from timestamps>
   - Key results: <50-word summary>

2. Update checkpoint file:
   checkpoint_path=".claude/data/checkpoints/implement_027_auth.json"

   jq --arg phase "$phase_num" \
      --arg status "completed" \
      --argjson artifacts "$artifacts_json" \
      '.completed_phases += [$phase | tonumber] |
       .current_phase = ($phase | tonumber) + 1 |
       .phase_metadata[$phase] = {status: $status, artifacts: $artifacts, ...}' \
      "$checkpoint_path" > "$checkpoint_path.tmp"

   mv "$checkpoint_path.tmp" "$checkpoint_path"

3. Verify checkpoint integrity:
   - File exists: ✓
   - Valid JSON: ✓
   - All required fields present: ✓

4. Proceed to next phase
```

**Step 3: Resume from Checkpoint**

```markdown
## Workflow Resume

EXECUTE ON WORKFLOW START:

1. Check for existing checkpoint:
   checkpoint_path=".claude/data/checkpoints/implement_027_auth.json"

   IF checkpoint exists:
     - Load checkpoint data
     - Validate checkpoint integrity
     - Check if workflow complete (all phases done)
     - If incomplete, offer resume option

2. Resume decision:
   IF user confirms resume:
     - Load checkpoint state
     - Extract current_phase
     - Extract artifact_paths
     - Extract context_metadata
     - Skip completed phases (execute from current_phase)

   IF user declines resume:
     - Archive old checkpoint (rename with timestamp)
     - Create fresh checkpoint
     - Start workflow from Phase 1

3. Resume execution:
   current_phase=$(jq -r '.current_phase' "$checkpoint_path")
   completed=$(jq -r '.completed_phases | join(",")' "$checkpoint_path")

   echo "Resuming from Phase $current_phase"
   echo "Completed phases: $completed"
   echo "Skipping completed work..."

   # Jump to current_phase execution
```

### Code Example

Real implementation from Plan 077 - /implement with checkpoint recovery:

```markdown
## /implement Command - Checkpoint Recovery Integration

### Initialization Phase

EXECUTE NOW:

1. Determine checkpoint path:
   plan_file="specs/027_auth/plans/001_implementation.md"
   workflow_id=$(echo "$plan_file" | md5sum | cut -d' ' -f1)
   checkpoint_path=".claude/data/checkpoints/${workflow_id}.json"

2. Check for existing checkpoint:
   if [ -f "$checkpoint_path" ]; then
     echo "Found existing checkpoint for this plan."
     echo "Current phase: $(jq -r '.current_phase' "$checkpoint_path")"
     echo "Completed phases: $(jq -r '.completed_phases | join(",")' "$checkpoint_path")"

     ASK USER: Resume from checkpoint? (Y/n)

     IF yes:
       load_checkpoint "$checkpoint_path"
       current_phase=$CHECKPOINT_CURRENT_PHASE
       completed_phases=$CHECKPOINT_COMPLETED_PHASES
       SKIP_TO_PHASE=$current_phase
     ELSE:
       archive_checkpoint "$checkpoint_path"
       create_fresh_checkpoint "$checkpoint_path"
       current_phase=1
   else
     create_fresh_checkpoint "$checkpoint_path"
     current_phase=1
   fi

### Phase Execution with Checkpointing

FOR each phase in plan:
  IF phase in completed_phases:
    echo "Skipping Phase $phase (already completed)"
    CONTINUE to next phase

  echo "Executing Phase $phase..."

  # Execute phase (invoke implementer agent, run tests, etc.)
  execute_phase "$phase"

  IF phase execution successful:
    # Create checkpoint
    update_checkpoint "$checkpoint_path" "$phase" "completed" "$artifacts"

    # Update replan tracking if this was a replanned phase
    if [ -n "$REPLANNED" ]; then
      increment_replan_count "$checkpoint_path" "$phase"
      add_replan_history "$checkpoint_path" "$phase" "$replan_reason"
    fi

    PROCEED to next phase

  ELSE:
    # Phase failed
    update_checkpoint "$checkpoint_path" "$phase" "failed" "$error_message"

    # Offer resume or abort
    ASK USER: Retry phase, Skip phase, or Abort workflow?
```

## Anti-Patterns

### Violation 1: No Checkpointing

```markdown
❌ BAD - Long workflow with no checkpoints:

Execute all 8 phases sequentially without checkpoints.
If Phase 6 fails → restart from Phase 1.

Time wasted: 5 hours of completed work (Phases 1-5)
```

### Violation 2: Checkpointing at Wrong Granularity

```markdown
❌ BAD - Too frequent checkpointing:

Checkpoint after every agent invocation (20+ checkpoints per phase)
Overhead: 500ms per checkpoint × 100 checkpoints = 50 seconds wasted

❌ BAD - Too infrequent checkpointing:

Checkpoint only at workflow end
No benefit (cannot resume from middle)
```

**Correct Granularity**: Checkpoint after each phase (5-10 checkpoints per workflow)

### Violation 3: Infinite Replan Loop

```markdown
❌ BAD - No replan tracking:

Phase 3 exceeds complexity → invoke /revise to replan
Replanned Phase 3 still exceeds complexity → invoke /revise again
Loop infinitely

WITHOUT checkpoint replan tracking:
- No limit on replans per phase
- No detection of replan loops
- Workflow never completes
```

## Performance Impact

**Recovery Time:**
- Without checkpoints: 6-hour workflow fails at Phase 5 → restart from Phase 1 (6 hours lost)
- With checkpoints: Resume from Phase 5 checkpoint (5 minutes to resume)

**Resilience:**
- Transient failures (network, API limits): Automatic resume
- User interruptions: Resume next session
- Adaptive replanning: Track replan history, prevent loops

**Real-World Example (Plan 077):**
```
/implement workflow with checkpoint recovery:
- Phase 1-4: Complete successfully (4 hours)
- Phase 5: Test failures detected, replan triggered
- Replan count: 1 (within limit of 2)
- Phase 5 (revised): Executes successfully
- Phase 6-8: Complete successfully

WITHOUT checkpoints:
- Phase 5 failure → manual diagnosis and fix
- Restart workflow from Phase 1
- Total time: 4h (lost) + 6h (re-execution) = 10 hours

WITH checkpoints:
- Phase 5 failure → automatic replan
- Resume from Phase 5 checkpoint
- Total time: 4h (preserved) + 0.5h (replan) + 2h (phases 5-8) = 6.5 hours
- Time saved: 3.5 hours (35%)
```

## Related Patterns

- [Verification and Fallback](./verification-fallback.md) - Checkpoint success/failure status
- [Context Management](./context-management.md) - Store metadata in checkpoints, prune from context
- [Metadata Extraction](./metadata-extraction.md) - Checkpoint contains artifact metadata
- [Behavioral Injection](./behavioral-injection.md) - Restore artifact paths from checkpoint

## See Also

- [Creating Commands Guide](../../guides/development/command-development/command-development-fundamentals.md) - Checkpoint integration
- `.claude/lib/workflow/checkpoint-utils.sh` - Checkpoint management utilities
- `.claude/lib/core/unified-logger.sh` - Logging with checkpoint integration
- `.claude/data/checkpoints/` - Checkpoint storage directory
