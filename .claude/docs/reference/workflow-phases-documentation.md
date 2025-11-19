# Workflow Phases: Documentation

**Related Documents**:
- [Overview](workflow-phases-overview.md) - Phase coordination
- [Testing](workflow-phases-testing.md) - Test execution
- [Implementation](workflow-phases-implementation.md) - Code execution

---

## Documentation Phase (Sequential Execution)

The documentation phase updates all affected documentation based on implementation changes, creates workflow summaries, and ensures documentation stays in sync with code.

## When to Use

- Always after testing phase passes
- For any workflow with user-facing changes
- Skip only for internal-only changes (refactoring, optimization)

## Quick Overview

1. Load implementation results from checkpoint
2. Identify affected documentation files
3. Invoke doc-writer agent to update docs
4. Verify documentation changes
5. Create workflow summary
6. Final checkpoint with completion status

## Execution Procedure

### Step 1: Load Checkpoint

```bash
CHECKPOINT=$(load_checkpoint "orchestrate")
PLAN_PATH=$(echo "$CHECKPOINT" | jq -r '.planning.plan_path')
TEST_STATUS=$(echo "$CHECKPOINT" | jq -r '.testing.status')

# Only proceed if tests passed
if [ "$TEST_STATUS" != "pass" ]; then
  echo "SKIP: Documentation phase - tests not passing"
  exit 0
fi
```

### Step 2: Identify Affected Docs

```bash
identify_affected_docs() {
  local changed_files="$1"

  # Find README files in affected directories
  for file in $changed_files; do
    dir=$(dirname "$file")
    if [ -f "$dir/README.md" ]; then
      echo "$dir/README.md"
    fi
  done | sort -u

  # Check for feature-specific docs
  if grep -q "auth" <<< "$changed_files"; then
    echo "docs/AUTH.md"
  fi
}

CHANGED_FILES=$(git diff --name-only HEAD~5)
AFFECTED_DOCS=$(identify_affected_docs "$CHANGED_FILES")
```

### Step 3: Invoke Doc Writer Agent

```markdown
**EXECUTE NOW**: Update documentation

Task {
  subagent_type: "general-purpose"
  description: "Update documentation for implementation changes"
  prompt: |
    Read and follow: .claude/agents/doc-writer.md

    **Context**:
    Plan: ${PLAN_PATH}
    Changed Files:
    ${CHANGED_FILES}

    Affected Documentation:
    ${AFFECTED_DOCS}

    **Requirements**:
    - Update each affected README
    - Add usage examples for new features
    - Update CHANGELOG.md
    - Create workflow summary

    Output: ${SUMMARY_PATH}

    Return: DOCS_COMPLETE: ${SUMMARY_PATH}
}
```

### Step 4: Verify Documentation Changes

```bash
verify_documentation() {
  # Check all affected docs updated
  for doc in $AFFECTED_DOCS; do
    if ! git diff --name-only | grep -q "$doc"; then
      echo "WARN: $doc not updated"
    fi
  done

  # Check summary created
  if [ ! -f "$SUMMARY_PATH" ]; then
    echo "CRITICAL: Summary not created"
    return 1
  fi

  echo "Documentation verified"
  return 0
}
```

### Step 5: Create Workflow Summary

Expected summary structure:

```markdown
# Workflow Summary: [Feature Name]

## Overview
- **Started**: [timestamp]
- **Completed**: [timestamp]
- **Status**: Complete

## Research Phase
- Topics researched: 3
- Reports created: 3

## Planning Phase
- Plan: .claude/specs/NNN_topic/plans/001_implementation.md
- Phases: 5
- Waves: 3

## Implementation Phase
- Phases completed: 5
- Files changed: 12
- Tests passed: 28

## Documentation Updates
- README.md
- docs/FEATURE.md
- CHANGELOG.md

## Final Status
All phases complete. Feature ready for review.
```

### Step 6: Final Checkpoint

```bash
CHECKPOINT=$(echo "$CHECKPOINT" | jq \
  --arg summary "$SUMMARY_PATH" \
  --arg completed "$(date -Iseconds)" '
  .current_phase = "complete" |
  .state = "completed" |
  .documentation = {
    summary_path: $summary,
    completed_at: $completed
  }
')

save_checkpoint "orchestrate" "$CHECKPOINT"

echo "Workflow complete: $SUMMARY_PATH"
```

## Documentation Standards

### README Updates

Each affected README should have:
- Updated feature descriptions
- New usage examples
- API documentation updates
- Updated troubleshooting

### CHANGELOG Entry

```markdown
## [Unreleased]

### Added
- [Feature name] - Brief description

### Changed
- [Affected module] - What changed
```

### Summary Requirements

- **Timing metrics**: How long each phase took
- **Artifact locations**: Where reports/plans/code are
- **Test coverage**: What was tested
- **Next steps**: Any follow-up needed

## Example Timing

```
Load Checkpoint: 1s
Identify Docs: 3s
Agent Invocation: 30s
Verification: 2s
Final Checkpoint: 1s

Total: ~37s
```

## Skip Conditions

Skip documentation phase when:
- No user-facing changes
- Internal refactoring only
- Performance optimization only
- Test-only changes

```bash
# Check if should skip
if is_internal_only "$CHANGED_FILES"; then
  echo "SKIP: Documentation phase - internal changes only"
  mark_phase_complete "documentation"
  exit 0
fi
```

## Key Requirements

1. **Update affected docs** - Keep in sync
2. **Create summary** - Document workflow
3. **Update CHANGELOG** - Track changes
4. **Verify changes** - Check updates made

---

## Related Documentation

- [Overview](workflow-phases-overview.md)
- [Documentation Standards](../../CLAUDE.md#documentation-policy)
- [Doc Writer Agent](../../agents/doc-writer.md)
