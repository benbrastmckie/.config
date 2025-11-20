# Revision-Specialist Agent Guide

## Overview

The revision-specialist agent is a specialized behavioral agent designed to revise existing implementation plans based on research findings. It integrates with the /coordinate command's research-and-revise workflow to enable research-driven plan improvements while maintaining safety through mandatory backups and revision history tracking.

**Agent Type**: Behavioral (invoked via Task tool)
**Model**: Sonnet 4.5
**Allowed Tools**: Read, Write, Edit, Bash, Task
**Agent File**: `/home/benjamin/.config/.claude/agents/revision-specialist.md`

### Key Capabilities

- **Research Integration**: Analyzes research reports to inform plan revisions
- **Safe Modifications**: Creates timestamped backups before any changes
- **Revision History**: Tracks all modifications with date, type, and rationale
- **Plan Preservation**: Maintains completed phases and /implement compatibility
- **Verification Checkpoints**: Ensures 100% file creation reliability

### Design Principles

1. **Backup First**: Never modify without backup (fail-fast if backup fails)
2. **Research-Driven**: All revisions informed by research report findings
3. **History Tracking**: Every revision documented with metadata
4. **Preserve Progress**: Never modify completed phases marked [COMPLETED]
5. **Format Compatibility**: Maintain /implement plan structure (checkboxes, phases)

## Revision Workflow

The revision-specialist follows a 5-step STEP-based execution process:

```
STEP 1: Receive and Validate
  ├─ Verify plan path (absolute, exists)
  ├─ Verify research reports (array of paths)
  ├─ Verify revision context (description)
  └─ Verify project standards (CLAUDE.md path)

STEP 1.5: Ensure Backup Directory
  ├─ Calculate backup directory path
  ├─ Create directory if not exists (mkdir -p)
  └─ Verify directory creation

STEP 2: Create Backup FIRST
  ├─ Generate timestamped filename (YYYYMMDD_HHMMSS)
  ├─ Copy plan to backups/ directory
  ├─ Verify backup file exists
  └─ Fail-fast if backup creation fails

STEP 3: Analyze Research Reports
  ├─ Read all provided research reports
  ├─ Extract key findings and recommendations
  ├─ Identify plan sections needing updates
  └─ Plan revision strategy

STEP 4: Apply Revisions to Plan
  ├─ Use Edit tool (preserves existing content)
  ├─ Skip completed phases (marked [COMPLETED])
  ├─ Update Technical Design section
  ├─ Add/modify phases and tasks
  └─ Maintain /implement compatibility

STEP 5: Update Revision History
  ├─ Add entry to ## Revision History section
  ├─ Record: date, type, reports used, changes
  ├─ Verify plan file updated successfully
  └─ Return: REVISION_COMPLETED: <absolute-path>
```

## Revision Types

The revision-specialist supports three primary revision types:

### 1. Research-Informed Revisions

**Trigger**: New research findings suggest better approaches or missing considerations

**Common Changes**:
- Update Technical Design section with new patterns
- Add references to research reports in metadata
- Modify implementation approach based on findings
- Add new phases for discovered complexity

**Example**:
```markdown
## Revision History

### 2025-11-10 - Research-Informed Revision
- **Type**: research-informed
- **Reports**: 001_auth_patterns.md, 002_security_best_practices.md
- **Changes**:
  - Updated Technical Design to use OAuth 2.1 (research recommended over 2.0)
  - Added Phase 4: Security Hardening (missing from original plan)
  - Modified Phase 2 tasks to include PKCE flow
- **Rationale**: Research revealed security vulnerabilities in original OAuth 2.0 approach
```

### 2. Complexity-Driven Revisions

**Trigger**: Adaptive planning discovers phase complexity exceeds threshold (score >8 or >10 tasks)

**Common Changes**:
- Expand high-complexity phases into separate files
- Break large tasks into smaller subtasks
- Add dependency tracking between phases
- Update time estimates based on complexity

**Example**:
```markdown
## Revision History

### 2025-11-10 - Complexity-Driven Revision
- **Type**: complexity-driven
- **Reports**: (adaptive planning analysis, no research reports)
- **Changes**:
  - Expanded Phase 3 (complexity score: 12.5) to separate file
  - Split "Implement auth middleware" into 5 subtasks
  - Added Phase 3.5: Integration Testing (discovered dependency)
- **Rationale**: Original Phase 3 exceeded complexity threshold, risked implementation failure
```

### 3. Scope-Expansion Revisions

**Trigger**: Implementation discovers out-of-scope work required for completion

**Common Changes**:
- Add new phases for discovered requirements
- Update success criteria to include new scope
- Add research report references for new areas
- Update time estimates and dependencies

**Example**:
```markdown
## Revision History

### 2025-11-10 - Scope-Expansion Revision
- **Type**: scope-expansion
- **Reports**: 003_session_management.md (new research)
- **Changes**:
  - Added Phase 5: Session Management (not in original scope)
  - Updated success criteria to include session persistence
  - Added dependency: Phase 5 depends on Phase 3 completion
- **Rationale**: Implementation revealed authentication requires session management (original plan assumed stateless)
```

## Backup and Recovery Procedures

### Backup Creation

**Location**: `<plan-directory>/backups/`
**Filename Format**: `<plan-name>_YYYYMMDD_HHMMSS.md`
**Timing**: BEFORE any modifications (Step 2)

**Example Backup Path**:
```
Original: /home/user/.config/.claude/specs/042_auth/plans/001_auth_plan.md
Backup:   /home/user/.config/.claude/specs/042_auth/plans/backups/001_auth_plan_20251110_143522.md
```

### Recovery from Backup

If revision introduces errors or needs to be reverted:

```bash
# 1. Locate most recent backup
cd /path/to/specs/042_auth/plans/backups
ls -t *.md | head -1

# 2. Verify backup contents
cat 001_auth_plan_20251110_143522.md

# 3. Restore backup (overwrites current plan)
cp 001_auth_plan_20251110_143522.md ../001_auth_plan.md

# 4. Verify restoration
diff 001_auth_plan_20251110_143522.md ../001_auth_plan.md
# (should show no differences)
```

### Backup Retention

- **Policy**: Backups are never automatically deleted
- **Manual Cleanup**: Users can remove old backups after confirming revisions successful
- **Git Integration**: Backups are gitignored (ephemeral artifacts)

## Integration Examples

### 1. /coordinate Research-and-Revise Workflow

**Most Common Usage**: Let /coordinate handle everything automatically

```bash
# /coordinate detects "research...and revise" pattern
# automatically invokes revision-specialist agent
/coordinate "research authentication best practices and revise 042 plan"

# Flow:
# 1. Workflow scope detected: research-and-revise
# 2. STATE_INITIALIZE: Discovers existing plan in specs/042_auth/plans/
# 3. STATE_RESEARCH: Creates 2-4 research reports
# 4. STATE_PLAN: Invokes revision-specialist agent
#    - Creates backup
#    - Analyzes research reports
#    - Updates plan with findings
#    - Updates revision history
# 5. STATE_COMPLETE: Workflow terminates
```

### 2. /implement with --report-scope-drift

**Usage**: Revision during implementation when scope drift detected

```bash
# /implement detects out-of-scope work
/implement specs/042_auth/plans/001_auth_plan.md \
  --report-scope-drift "Session management required (not in original plan)"

# Flow:
# 1. /implement pauses at current phase
# 2. Creates research report on session management
# 3. Invokes /revise --auto-mode (which uses revision-specialist internally)
# 4. Plan updated with new Phase 5: Session Management
# 5. /implement resumes with revised plan
```

### 3. Manual Task Tool Invocation

**Usage**: Direct invocation for custom revision workflows

```bash
# In a custom command or workflow
Task {
  subagent_type: "general-purpose"
  description: "Revise plan based on security audit findings"
  timeout: 180000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/revision-specialist.md

    **Workflow-Specific Context**:
    - Existing Plan Path: /home/benjamin/.config/.claude/specs/042_auth/plans/001_auth_plan.md
    - Research Reports: [\"/home/benjamin/.config/.claude/specs/042_auth/reports/003_security_audit.md\"]
    - Revision Scope: Update plan based on security audit findings
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Backup Required: true

    Execute revision following all guidelines in behavioral file.
    Return: REVISION_COMPLETED: /home/benjamin/.config/.claude/specs/042_auth/plans/001_auth_plan.md
  "
}
```

## Troubleshooting

### Common Failures and Solutions

#### 1. Backup Creation Failed

**Symptom**: Error message "CRITICAL ERROR: Backup creation failed"

**Causes**:
- Backup directory doesn't exist (permissions issue)
- Disk space exhausted
- Invalid plan path (relative path instead of absolute)

**Solutions**:
```bash
# Check disk space
df -h

# Verify backup directory exists and is writable
PLAN_DIR=$(dirname "$EXISTING_PLAN_PATH")
ls -la "$PLAN_DIR/backups/"

# Create backup directory manually if needed
mkdir -p "$PLAN_DIR/backups"
chmod 755 "$PLAN_DIR/backups"
```

#### 2. Invalid Plan Path

**Symptom**: Error message "CRITICAL ERROR: Plan path is not absolute"

**Cause**: Invoking command passed relative path instead of absolute path

**Solution**:
```bash
# In invoking command, convert relative to absolute
EXISTING_PLAN_PATH=$(realpath "$RELATIVE_PATH")

# Or use direct absolute path
EXISTING_PLAN_PATH="/home/benjamin/.config/.claude/specs/042_auth/plans/001_auth_plan.md"
```

#### 3. Missing Research Reports

**Symptom**: Agent receives empty REPORT_PATHS array

**Cause**: research-and-revise workflow invoked before research phase complete

**Solution**:
```bash
# Verify research phase completed before planning phase
# In /coordinate, check STATE_RESEARCH transition:
if [ ${#REPORT_PATHS[@]} -eq 0 ]; then
  echo "ERROR: No research reports found, cannot revise plan"
  exit 1
fi
```

#### 4. Plan File Truncated After Revision

**Symptom**: Plan file smaller after revision, content missing

**Cause**: Agent used Write tool instead of Edit tool (overwrites entire file)

**Solution**: Restore from backup and re-run revision
```bash
# Restore from most recent backup
cp "$PLAN_DIR/backups/$(ls -t $PLAN_DIR/backups/*.md | head -1)" "$EXISTING_PLAN_PATH"

# Verify agent uses Edit tool for modifications (check behavioral file)
```

#### 5. Revision History Not Updated

**Symptom**: Plan modified but ## Revision History section unchanged

**Cause**: Agent skipped Step 5 or revision history section missing from original plan

**Solutions**:
```bash
# If plan has no Revision History section, add one:
echo "## Revision History" >> "$EXISTING_PLAN_PATH"
echo "" >> "$EXISTING_PLAN_PATH"
echo "Initial plan created: $(date +%Y-%m-%d)" >> "$EXISTING_PLAN_PATH"

# Re-run revision-specialist agent
```

## Completion Criteria

The revision-specialist agent follows 35+ completion criteria before returning. Key criteria include:

### Validation (STEP 1)
1. Plan path is absolute (starts with /)
2. Plan file exists and is readable
3. Research reports array is non-empty
4. Revision context is non-empty string
5. Project standards file exists

### Backup Creation (STEP 2)
6. Backup directory exists
7. Backup filename follows YYYYMMDD_HHMMSS format
8. Backup file created successfully
9. Backup file size matches original plan size
10. Original plan still exists (cp command preserves source)

### Research Analysis (STEP 3)
11. All research reports read successfully
12. Key findings extracted from each report
13. Recommendations identified for plan updates
14. Plan sections requiring updates identified
15. Revision strategy documented

### Plan Modification (STEP 4)
16. Edit tool used (not Write tool)
17. Completed phases preserved (no modifications to [COMPLETED] phases)
18. Technical Design section updated with research findings
19. New phases added if complexity discovered
20. Task checkboxes maintained (- [ ] format for /implement)
21. Phase dependencies preserved or updated
22. Time estimates updated if scope changed
23. Success criteria updated to reflect new scope

### Revision History (STEP 5)
24. Revision History section exists
25. New entry added with current date
26. Revision type recorded (research-informed/complexity-driven/scope-expansion)
27. Research reports referenced in entry
28. Key changes documented (3-5 bullet points)
29. Rationale provided (why revision needed)

### Verification (STEP 5)
30. Plan file exists after modification
31. Plan file size increased (content added, not deleted)
32. Plan structure valid (parseable markdown)
33. No syntax errors introduced (checkboxes, headings)
34. Completion signal returned with absolute path
35. No error messages in agent output

## Related Documentation

- **Agent File**: [revision-specialist.md](../../agents/revision-specialist.md) - Behavioral execution script
- **/coordinate Guide**: [coordinate-command-guide.md](../commands/build-command-guide.md) - Research-and-revise workflow integration
- **Behavioral Injection Pattern**: [behavioral-injection.md](../concepts/patterns/behavioral-injection.md) - Agent invocation pattern
- **State Machine Architecture**: [state-based-orchestration-overview.md](../architecture/state-based-orchestration-overview.md) - Workflow state management
- **Testing**: `.claude/tests/test_revision_specialist.sh` - Comprehensive test suite

## Future Enhancements

Potential improvements to revision-specialist agent:

1. **Multi-Version Backups**: Keep N most recent backups, auto-delete older ones
2. **Diff Generation**: Create .diff file showing changes made during revision
3. **Conflict Detection**: Detect when revision conflicts with in-progress implementation
4. **Rollback Commands**: `/rollback-revision <timestamp>` to restore specific backup
5. **Revision Preview**: Show proposed changes before applying (dry-run mode)
6. **Semantic Versioning**: Version plans (1.0.0 → 1.1.0 for research-informed revisions)

## Version History

- **2025-11-10**: Initial version (created as part of Spec 651 implementation)
