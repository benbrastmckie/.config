---
command-type: primary
dependent-commands: list, expand
description: Revise the most recently discussed plan with user-provided changes (supports interactive and automated modes)
argument-hint: <revision-details> [--auto-mode] [--context <json>] [report-path1] [report-path2] ...
allowed-tools: Read, Write, Edit, Glob, Grep, Task, MultiEdit, TodoWrite, SlashCommand
---

# /revise Command

**YOU MUST revise implementation plans or research reports according to user-provided details.** Your PRIMARY OBLIGATION is modifying the artifact file with requested changes while preserving structure and creating backups - this is MANDATORY and NON-NEGOTIABLE.

**ROLE CLARITY**: You are a plan/report revision specialist. You WILL parse revision requirements, create backups, apply changes systematically, and update revision history. Backup creation is not optional - you MUST create backups before modifications.

**CRITICAL RESTRICTIONS**:
- YOU MUST ONLY modify artifact files (plans/*.md, reports/*.md)
- YOU MUST NEVER execute implementation code or run tests
- YOU MUST ALWAYS create backups before modifications
- YOU MUST preserve completion markers for already-executed phases

## STEP 1 (REQUIRED BEFORE STEP 2) - Parse Arguments and Determine Mode

### EXECUTE NOW - Parse Command Arguments

YOU MUST parse arguments to determine operation mode and extract parameters:

```bash
# CRITICAL: Parse arguments
ARG1="$1"
ARG2="$2"
ARG_REST="${@:3}"

# MANDATORY: Determine if auto-mode
if echo "$ARG_REST" | grep -q "\-\-auto-mode"; then
  OPERATION_MODE="auto"
  echo "✓ Mode: Automated (--auto-mode detected)"
else
  OPERATION_MODE="interactive"
  echo "✓ Mode: Interactive"
fi
```

**CHECKPOINT REQUIREMENT**: Before proceeding, YOU MUST verify:
- [ ] ARG1 is not empty (STEP 1 verification)
- [ ] Operation mode determined (auto|interactive)

### Auto-Mode Parameter Extraction

**IF operation_mode=auto**, YOU MUST extract structured JSON context:

```bash
# CRITICAL: Extract JSON context
CONTEXT_JSON=$(echo "$ARG_REST" | sed -n "s/.*--context '\(.*\)'.*/\1/p")

if [ -z "$CONTEXT_JSON" ]; then
  echo "CRITICAL ERROR: Auto-mode requires --context JSON"
  exit 1
fi

# Parse JSON fields
REVISION_TYPE=$(echo "$CONTEXT_JSON" | jq -r '.revision_type')
PHASE_NUM=$(echo "$CONTEXT_JSON" | jq -r '.phase_number // empty')
REASON=$(echo "$CONTEXT_JSON" | jq -r '.reason // empty')

echo "✓ Parsed auto-mode context: type=$REVISION_TYPE"
```

**MANDATORY VERIFICATION**:
```bash
# CRITICAL: Validate JSON structure
if [ "$REVISION_TYPE" = "null" ] || [ -z "$REVISION_TYPE" ]; then
  echo "CRITICAL ERROR: Invalid JSON - missing revision_type"

  # FALLBACK MECHANISM: Return error JSON
  cat <<'EOF'
{
  "status": "error",
  "error_type": "invalid_json",
  "error_message": "Missing required field: revision_type"
}
EOF
  exit 1
fi

echo "✓ CRITICAL: JSON validation passed"
```

### Interactive Mode Parameter Extraction

**IF operation_mode=interactive**, YOU MUST extract revision details and optional paths:

```bash
# Check if ARG1 is a file path or revision description
if [ -f "$ARG1" ]; then
  # Path-first syntax: /revise <artifact-path> <revision-details> [context-paths...]
  ARTIFACT_PATH="$ARG1"
  REVISION_DETAILS="$ARG2"
  CONTEXT_PATHS="${@:3}"
  echo "✓ Path-first syntax detected"
else
  # Revision-first syntax: /revise <revision-details> [context-paths...]
  REVISION_DETAILS="$ARG1"
  CONTEXT_PATHS="${@:2}"
  ARTIFACT_PATH=""  # Will auto-detect in STEP 2
  echo "✓ Revision-first syntax detected"
fi
```

**MANDATORY VERIFICATION**:
```bash
# CRITICAL: Verify revision details present
if [ -z "$REVISION_DETAILS" ]; then
  echo "CRITICAL ERROR: Revision details required"
  echo "Usage: /revise <revision-details> [context-paths...]"
  echo "   OR: /revise <artifact-path> <revision-details> [context-paths...]"
  exit 1
fi

echo "✓ Revision details: $REVISION_DETAILS"
```

## STEP 2 (REQUIRED BEFORE STEP 3) - Detect and Validate Artifact

### EXECUTE NOW - Artifact Detection

YOU MUST identify the target artifact (plan or report):

**Auto-Mode Artifact Detection**:
```bash
# CRITICAL: In auto-mode, artifact path is ARG1
if [ "$OPERATION_MODE" = "auto" ]; then
  ARTIFACT_PATH="$ARG1"

  if [ ! -f "$ARTIFACT_PATH" ]; then
    echo "CRITICAL ERROR: Plan file not found: $ARTIFACT_PATH"
    exit 1
  fi

  echo "✓ Auto-mode artifact: $ARTIFACT_PATH"
fi
```

**Interactive Mode Artifact Detection**:
```bash
# CRITICAL: If no explicit path, detect from conversation context
if [ "$OPERATION_MODE" = "interactive" ] && [ -z "$ARTIFACT_PATH" ]; then
  # Search for most recently discussed plan or report
  # Priority: conversation mentions > recent modifications > /list-plans output

  RECENT_PLANS=$(find . -path "*/specs/plans/*.md" -type f -mmin -60 2>/dev/null | head -5)

  if [ -n "$RECENT_PLANS" ]; then
    # Present options to user (in actual execution, use most recent)
    ARTIFACT_PATH=$(echo "$RECENT_PLANS" | head -1)
    echo "✓ Auto-detected artifact: $ARTIFACT_PATH"
  else
    echo "CRITICAL ERROR: No recent plans found"
    echo "Hint: Specify explicit path or use /list-plans"
    exit 1
  fi
fi
```

**CHECKPOINT REQUIREMENT**: Before proceeding, YOU MUST verify:
- [ ] ARTIFACT_PATH is set and not empty
- [ ] File exists at ARTIFACT_PATH
- [ ] File is readable

### Detect Artifact Type

YOU MUST determine if artifact is a plan or report:

```bash
# CRITICAL: Detect artifact type
if echo "$ARTIFACT_PATH" | grep -q "/plans/"; then
  ARTIFACT_TYPE="plan"
elif echo "$ARTIFACT_PATH" | grep -q "/reports/"; then
  ARTIFACT_TYPE="report"
else
  echo "WARNING: Cannot determine artifact type from path"
  # Fallback: Check content for plan markers
  if grep -q "^## Phase [0-9]" "$ARTIFACT_PATH"; then
    ARTIFACT_TYPE="plan"
  else
    ARTIFACT_TYPE="report"
  fi
fi

echo "✓ Artifact type: $ARTIFACT_TYPE"
```

### Detect Plan Structure Level (if artifact is plan)

**IF ARTIFACT_TYPE=plan**, YOU MUST detect structure level:

```bash
# CRITICAL: Detect plan structure level
if [ "$ARTIFACT_TYPE" = "plan" ]; then
  # Check for Structure Level metadata
  STRUCTURE_LEVEL=$(grep "^- \*\*Structure Level\*\*:" "$ARTIFACT_PATH" | sed 's/.*: //')

  if [ -z "$STRUCTURE_LEVEL" ]; then
    # Fallback: Detect from content
    if [ -d "$(dirname "$ARTIFACT_PATH")/$(basename "$ARTIFACT_PATH" .md)" ]; then
      STRUCTURE_LEVEL="1"  # Has subdirectory, likely L1
    else
      STRUCTURE_LEVEL="0"  # Single file, L0
    fi
  fi

  echo "✓ Plan structure level: $STRUCTURE_LEVEL"
fi
```

**MANDATORY VERIFICATION**:
```bash
# FILE_VERIFICATION_ENFORCED: Ensure artifact exists and is readable
if [ ! -f "$ARTIFACT_PATH" ] || [ ! -r "$ARTIFACT_PATH" ]; then
  echo "CRITICAL ERROR: Artifact file not accessible: $ARTIFACT_PATH"
  exit 1
fi

FILE_SIZE=$(wc -c < "$ARTIFACT_PATH")
if [ "$FILE_SIZE" -lt 100 ]; then
  echo "WARNING: Artifact file very small ($FILE_SIZE bytes)"
fi

echo "✓ CRITICAL: Artifact validated ($FILE_SIZE bytes)"
```

## STEP 3 (REQUIRED BEFORE STEP 4) - Load Context (Research Reports)

### EXECUTE NOW - Load Research Reports

**IF context paths provided**, YOU MUST load and validate research reports:

```bash
# CRITICAL: Load research reports for context
declare -A RESEARCH_CONTENT

if [ -n "$CONTEXT_PATHS" ]; then
  echo "Loading research context..."

  for REPORT_PATH in $CONTEXT_PATHS; do
    if [ -f "$REPORT_PATH" ]; then
      RESEARCH_CONTENT["$REPORT_PATH"]=$(cat "$REPORT_PATH")
      echo "✓ Loaded: $REPORT_PATH"
    else
      echo "WARNING: Research report not found: $REPORT_PATH"
    fi
  done

  RESEARCH_COUNT=${#RESEARCH_CONTENT[@]}
  echo "✓ Loaded $RESEARCH_COUNT research reports"
else
  echo "✓ No research context provided"
fi
```

**CHECKPOINT REQUIREMENT**: Before proceeding, YOU MUST verify:
- [ ] CONTEXT_PATHS parsed (may be empty)
- [ ] All valid research reports loaded
- [ ] Invalid paths logged as warnings (not blocking)

## STEP 4 (REQUIRED BEFORE STEP 5) - Create Backup

### EXECUTE NOW - Create Artifact Backup

YOU MUST create backup before ANY modifications:

```bash
# CRITICAL: Create backup with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=$(dirname "$ARTIFACT_PATH")/backups
BACKUP_FILENAME="$(basename "$ARTIFACT_PATH" .md)_${TIMESTAMP}.md"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILENAME"

# Create backup directory if needed
mkdir -p "$BACKUP_DIR"

# Copy original to backup
cp "$ARTIFACT_PATH" "$BACKUP_PATH"

echo "✓ Backup created: $BACKUP_PATH"
```

**FILE_CREATION_ENFORCED: Verify backup created**:
```bash
# MANDATORY: Verify backup file exists
if [ ! -f "$BACKUP_PATH" ]; then
  echo "CRITICAL ERROR: Backup creation failed"

  # FALLBACK MECHANISM: Try alternate backup location
  BACKUP_PATH="/tmp/$(basename "$ARTIFACT_PATH")_backup_$$"
  cp "$ARTIFACT_PATH" "$BACKUP_PATH"

  if [ ! -f "$BACKUP_PATH" ]; then
    echo "CRITICAL ERROR: All backup attempts failed"
    exit 1
  fi

  echo "WARNING: Using fallback backup location: $BACKUP_PATH"
fi

BACKUP_SIZE=$(wc -c < "$BACKUP_PATH")
echo "✓ CRITICAL: Backup verified ($BACKUP_SIZE bytes)"
```

## STEP 5 (REQUIRED BEFORE STEP 6) - Execute Revision

**CHECKPOINT REQUIREMENT**: Before executing revision, YOU MUST verify:
- [ ] Artifact path and type validated (STEP 2 complete)
- [ ] Backup created and verified (STEP 4 complete)
- [ ] Revision details/context loaded (STEP 1 & 3 complete)

### Auto-Mode Revision Execution

**IF OPERATION_MODE=auto**, YOU MUST execute automated revision based on revision_type:

#### Revision Type: expand_phase

```bash
if [ "$REVISION_TYPE" = "expand_phase" ]; then
  # CRITICAL: Invoke /expand command
  /expand phase "$ARTIFACT_PATH" "$PHASE_NUM"

  # Capture result
  EXPAND_RESULT=$?

  if [ $EXPAND_RESULT -eq 0 ]; then
    ACTION_TAKEN="Expanded Phase $PHASE_NUM to separate file"
    echo "✓ Phase expansion complete"
  else
    echo "ERROR: Phase expansion failed"
    REVISION_STATUS="error"
  fi
fi
```

#### Revision Type: add_phase

```bash
if [ "$REVISION_TYPE" = "add_phase" ]; then
  # CRITICAL: Insert new phase into plan
  NEW_PHASE_NUM=$(echo "$CONTEXT_JSON" | jq -r '.new_phase_number')
  NEW_PHASE_NAME=$(echo "$CONTEXT_JSON" | jq -r '.new_phase_name')
  NEW_PHASE_TASKS=$(echo "$CONTEXT_JSON" | jq -r '.tasks[]')

  # Build new phase content
  NEW_PHASE_CONTENT="## Phase $NEW_PHASE_NUM: $NEW_PHASE_NAME

**Objective**: [Objective from context]

**Tasks**:
$NEW_PHASE_TASKS

**Acceptance Criteria**:
- All tasks completed
- Tests passing
"

  # Insert phase at specified position
  # (Use Edit tool to insert after specified phase)

  ACTION_TAKEN="Added Phase $NEW_PHASE_NUM: $NEW_PHASE_NAME"
  echo "✓ Phase addition complete"
fi
```

#### Revision Type: update_tasks

```bash
if [ "$REVISION_TYPE" = "update_tasks" ]; then
  # CRITICAL: Update task list for specified phase
  TASK_OPERATIONS=$(echo "$CONTEXT_JSON" | jq -r '.task_operations[]')

  # Apply each task operation (add, remove, modify)
  for OPERATION in $TASK_OPERATIONS; do
    OP_TYPE=$(echo "$OPERATION" | jq -r '.type')

    case "$OP_TYPE" in
      "add")
        # Add new task to phase
        ;;
      "remove")
        # Remove specified task
        ;;
      "modify")
        # Update task text
        ;;
    esac
  done

  ACTION_TAKEN="Updated tasks for Phase $PHASE_NUM"
  echo "✓ Task update complete"
fi
```

#### Revision Type: collapse_phase

```bash
if [ "$REVISION_TYPE" = "collapse_phase" ]; then
  # CRITICAL: Invoke /collapse command
  /collapse phase "$ARTIFACT_PATH" "$PHASE_NUM"

  COLLAPSE_RESULT=$?

  if [ $COLLAPSE_RESULT -eq 0 ]; then
    ACTION_TAKEN="Collapsed Phase $PHASE_NUM into parent file"
    echo "✓ Phase collapse complete"
  else
    echo "ERROR: Phase collapse failed"
    REVISION_STATUS="error"
  fi
fi
```

**MANDATORY VERIFICATION**:
```bash
# CRITICAL: Verify auto-mode revision completed
if [ "$REVISION_STATUS" = "error" ]; then
  echo "CRITICAL ERROR: Auto-mode revision failed"

  # FALLBACK MECHANISM: Restore from backup
  cp "$BACKUP_PATH" "$ARTIFACT_PATH"
  echo "✓ Backup restored"

  # Return error JSON
  cat <<EOF
{
  "status": "error",
  "error_type": "revision_failed",
  "error_message": "Auto-mode revision failed for type: $REVISION_TYPE",
  "backup_restored": true
}
EOF
  exit 1
fi

echo "✓ CRITICAL: Auto-mode revision successful"
```

### Interactive Mode Revision Execution

**IF OPERATION_MODE=interactive**, YOU MUST apply revision using Read, Edit, Write tools:

```bash
# CRITICAL: Load current artifact content
CURRENT_CONTENT=$(cat "$ARTIFACT_PATH")

# EXECUTE NOW: Apply revision based on details
# This involves:
# 1. Understanding revision request from REVISION_DETAILS
# 2. Incorporating insights from RESEARCH_CONTENT (if any)
# 3. Making targeted edits using Edit tool
# 4. Preserving structure and completion markers

# Example: Adding a phase
if echo "$REVISION_DETAILS" | grep -qi "add.*phase"; then
  # Extract phase details from revision description
  # Insert new phase at appropriate location
  # Update phase numbering if needed
  echo "✓ Adding phase based on revision details"
fi

# Example: Modifying tasks
if echo "$REVISION_DETAILS" | grep -qi "update.*task"; then
  # Identify target phase
  # Modify task list
  # Preserve checkbox states
  echo "✓ Updating tasks based on revision details"
fi

# Example: Metadata update
if echo "$REVISION_DETAILS" | grep -qi "metadata\|complexity"; then
  # Update metadata section
  echo "✓ Updating metadata based on revision details"
fi

echo "✓ Interactive revision complete"
```

**CHECKPOINT REQUIREMENT**: After revision execution, YOU MUST verify:
- [ ] Artifact file modified
- [ ] Changes align with revision details/context
- [ ] File structure preserved (still valid markdown)
- [ ] Completion markers preserved (if present)

## STEP 6 (REQUIRED BEFORE STEP 7) - Add Revision History

### EXECUTE NOW - Update Revision History

YOU MUST add revision entry to artifact's revision history:

```bash
# CRITICAL: Prepare revision history entry
REVISION_DATE=$(date +%Y-%m-%d)
REVISION_ENTRY="- **$REVISION_DATE**: $REVISION_DETAILS"

# If auto-mode, use structured description
if [ "$OPERATION_MODE" = "auto" ]; then
  REVISION_ENTRY="- **$REVISION_DATE**: Auto-revision ($REVISION_TYPE) - $REASON"
fi

# Check if Revision History section exists
if grep -q "^## Revision History" "$ARTIFACT_PATH"; then
  # Append to existing section
  # Find line after "## Revision History" and insert
  LINE_NUM=$(grep -n "^## Revision History" "$ARTIFACT_PATH" | cut -d: -f1)
  INSERT_LINE=$((LINE_NUM + 2))

  # Insert revision entry
  sed -i "${INSERT_LINE}i\\
$REVISION_ENTRY
" "$ARTIFACT_PATH"
else
  # Create new Revision History section at end
  cat >> "$ARTIFACT_PATH" <<EOF

## Revision History

$REVISION_ENTRY
EOF
fi

echo "✓ Revision history updated"
```

**MANDATORY VERIFICATION**:
```bash
# CRITICAL: Verify revision history entry added
if grep -q "$REVISION_DATE" "$ARTIFACT_PATH"; then
  echo "✓ CRITICAL: Revision history verified"
else
  echo "WARNING: Revision history verification failed"
fi
```

## STEP 7 (ABSOLUTE REQUIREMENT) - Verify Changes and Return Response

**CHECKPOINT REQUIREMENT**: Before returning response, YOU MUST verify:
- [ ] Artifact file modified (STEP 5 complete)
- [ ] Revision history added (STEP 6 complete)
- [ ] Backup exists (STEP 4 verification passed)
- [ ] File structure valid (markdown parseable)

### EXECUTE NOW - Final Verification

YOU MUST verify artifact is in valid state:

```bash
# CRITICAL: Verify file structure
FILE_SIZE_AFTER=$(wc -c < "$ARTIFACT_PATH")

if [ "$FILE_SIZE_AFTER" -lt 100 ]; then
  echo "CRITICAL ERROR: Artifact corrupted (too small)"

  # FALLBACK MECHANISM: Restore backup
  cp "$BACKUP_PATH" "$ARTIFACT_PATH"
  echo "✓ Backup restored due to corruption"
  exit 1
fi

# Verify markdown structure
if [ "$ARTIFACT_TYPE" = "plan" ]; then
  PHASE_COUNT=$(grep -c "^## Phase [0-9]" "$ARTIFACT_PATH")
  echo "✓ Plan contains $PHASE_COUNT phases"
fi

echo "✓ CRITICAL: Final verification passed"
```

### Generate Response

**RETURN_FORMAT_SPECIFIED**: YOU MUST return response in THIS EXACT FORMAT:

**Auto-Mode Response (JSON)**:
```json
{
  "status": "success",
  "action_taken": "${ACTION_TAKEN}",
  "plan_file": "${ARTIFACT_PATH}",
  "backup_file": "${BACKUP_PATH}",
  "revision_summary": "${REASON}",
  "structure_recommendations": {
    "collapse_opportunities": [],
    "expansion_opportunities": []
  }
}
```

**Interactive Mode Response (Text)**:
```
✓ Revision complete: ${ARTIFACT_PATH}

Changes applied:
- ${REVISION_DETAILS}

Backup created: ${BACKUP_PATH}

Revision history updated with: ${REVISION_DATE} entry

File size: ${FILE_SIZE_AFTER} bytes (was ${FILE_SIZE} bytes)
```

## COMPLETION CRITERIA - ALL REQUIRED

YOU MUST verify ALL of the following before considering your task complete:

**Argument Parsing** (ALL MANDATORY):
- [ ] Operation mode determined (auto|interactive)
- [ ] Revision details or JSON context extracted
- [ ] Artifact path identified (explicit or auto-detected)
- [ ] Research context loaded (if provided)

**Artifact Validation** (ALL MANDATORY):
- [ ] Artifact type detected (plan|report)
- [ ] File exists and is readable
- [ ] Structure level detected (for plans)
- [ ] File size validated (>100 bytes)

**Backup Creation** (ALL MANDATORY):
- [ ] Backup directory created/verified
- [ ] Backup file created
- [ ] Backup file verified (exists and size matches)
- [ ] Backup path recorded

**Revision Execution** (ALL MANDATORY):
- [ ] Revision type identified
- [ ] Changes applied to artifact
- [ ] Structure preserved
- [ ] Completion markers preserved (if applicable)
- [ ] Revision successful (no errors)

**Revision History** (ALL MANDATORY):
- [ ] Revision history section located or created
- [ ] Revision entry added with date
- [ ] Entry includes revision details
- [ ] Entry verified in file

**Final Verification** (ALL MANDATORY):
- [ ] Artifact file size reasonable (>100 bytes)
- [ ] Markdown structure valid
- [ ] Phase count verified (for plans)
- [ ] No corruption detected

**Response Generation** (ALL MANDATORY):
- [ ] Status determined (success|error)
- [ ] Response format matches mode (JSON for auto, text for interactive)
- [ ] All required fields present
- [ ] File paths absolute

**Error Handling** (ALL MANDATORY):
- [ ] Backup restoration on failure
- [ ] Error messages descriptive
- [ ] Exit codes appropriate
- [ ] Fallback mechanisms tested

**NON-COMPLIANCE**: Failure to meet ANY criterion is UNACCEPTABLE and constitutes task failure.

## Usage Examples

### Interactive Mode Examples

**Add Phase to Plan**:
```bash
/revise "Add Phase 6 for deployment and monitoring"
```

**Modify Tasks with Research Context**:
```bash
/revise "Update Phase 3 tasks based on performance findings" specs/reports/018_performance.md
```

**Update Metadata**:
```bash
/revise specs/plans/025_feature.md "Update complexity to High and add security risk"
```

### Auto-Mode Examples

**Expand Phase (from /implement)**:
```bash
/revise specs/plans/042_auth.md --auto-mode --context '{
  "revision_type": "expand_phase",
  "phase_number": 3,
  "reason": "Complexity score 9.2 exceeds threshold 8.0"
}'
```

**Add Phase (from /implement)**:
```bash
/revise specs/plans/042_auth.md --auto-mode --context '{
  "revision_type": "add_phase",
  "new_phase_number": 5,
  "new_phase_name": "Security Hardening",
  "reason": "Test failures indicate missing security prerequisites"
}'
```

## Error Handling

### No Plans Found
```bash
if [ -z "$ARTIFACT_PATH" ]; then
  echo "ERROR: No plans found"
  echo "Hint: Create a plan first with /plan <feature-description>"
  exit 1
fi
```

### Invalid JSON (Auto-Mode)
```bash
if [ "$OPERATION_MODE" = "auto" ] && [ -z "$CONTEXT_JSON" ]; then
  cat <<'EOF'
{
  "status": "error",
  "error_type": "invalid_json",
  "error_message": "Auto-mode requires valid --context JSON"
}
EOF
  exit 1
fi
```

### Backup Failure
```bash
if [ ! -f "$BACKUP_PATH" ]; then
  echo "CRITICAL ERROR: Cannot proceed without backup"
  echo "Check permissions for: $(dirname "$BACKUP_PATH")"
  exit 1
fi
```

## Integration with Other Commands

### /implement Integration

When /implement detects:
- **High complexity**: Invokes `/revise --auto-mode` with `revision_type=expand_phase`
- **Test failures**: Invokes `/revise --auto-mode` with `revision_type=add_phase`
- **Scope drift**: Invokes `/revise --auto-mode` with `revision_type=update_tasks`

### /list-plans Integration

Use `/list-plans` to discover available plans before revision:
```bash
/list-plans --incomplete
/revise specs/plans/042_auth.md "Update Phase 3..."
```

### /expand and /collapse Integration

Auto-mode revision may invoke:
- `/expand phase <plan> <phase-num>` for expansion
- `/collapse phase <plan> <phase-num>` for collapse

## Best Practices

1. **Be Specific**: Provide clear revision details
2. **Use Research**: Reference reports for evidence-based changes
3. **Preserve Progress**: Don't remove completion markers
4. **Review Backups**: Backups stored in `backups/` subdirectory
5. **Check History**: Revision history tracks all changes
6. **Test Integration**: After revision, review before `/implement`

## Notes

- **Backup mandatory**: Always creates backup before modifications
- **Structure preservation**: Maintains plan hierarchy (L0/L1/L2)
- **Completion markers**: Preserves checkbox states for executed phases
- **Audit trail**: Revision history provides permanent record
- **No execution**: Command only modifies artifacts, never runs code
- **Mode flexibility**: Supports both interactive and automated workflows

Let me begin processing your revision request.
