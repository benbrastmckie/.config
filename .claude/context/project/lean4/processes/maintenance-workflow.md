# Maintenance Workflow

**Version**: 1.0.0  
**Last Updated**: 2025-12-19  
**Purpose**: Standardized workflow for repository maintenance operations

---

## Overview

This document defines the standardized maintenance workflow for the LEAN 4 ProofChecker project, including TODO maintenance, project archiving, status document updates, and state management.

### Key Principles

1. **Single Source of Truth**: Use `state.json` files for machine-readable state
2. **Comprehensive Reports**: Generate detailed markdown reports for human review
3. **Atomic Operations**: All state changes are atomic and consistent
4. **Traceability**: Every operation is tracked with timestamps and references
5. **Standardization**: Use consistent naming and structure across all artifacts

---

## Maintenance Types

### 1. Scheduled Maintenance
- **Frequency**: Monthly or after major milestones
- **Trigger**: Calendar date or completion of significant work
- **Scope**: Comprehensive review of all maintenance areas
- **Duration**: 2-4 hours

### 2. Ad-hoc Maintenance
- **Frequency**: As needed
- **Trigger**: User request or specific issue
- **Scope**: Targeted maintenance of specific areas
- **Duration**: 30 minutes - 2 hours

### 3. Post-Milestone Maintenance
- **Frequency**: After completing major tasks/projects
- **Trigger**: Task completion, project archiving
- **Scope**: Update status documents, archive projects
- **Duration**: 1-2 hours

---

## Workflow Stages

### Stage 1: Preparation

**Actions**:
1. Load current state files:
   - `.claude/specs/state.json`
   - `.claude/specs/archive/state.json`
   - `.claude/specs/maintenance/state.json`
2. Load .claude/specs/TODO.md and status documents
3. Determine maintenance scope
4. Generate operation ID: `maintenance-YYYYMMDD`

**Outputs**:
- Operation ID
- Maintenance scope definition
- Baseline metrics

### Stage 2: .claude/specs/TODO.md Maintenance

**Actions**:
1. Scan .claude/specs/TODO.md for completed tasks
2. Identify tasks marked with [PASS], [x], or in "Completed" sections
3. If >5 completed tasks, request user confirmation
4. Remove completed tasks from active sections
5. Update "Completion History" section
6. Reorganize remaining tasks by priority
7. Update task counts in overview

**Outputs**:
- Updated .claude/specs/TODO.md
- List of removed tasks
- Before/after metrics

**State Updates**:
- None (.claude/specs/TODO.md is documentation, not state)

### Stage 3: Project Archiving

**Actions**:
1. Identify completed project directories in `.claude/specs/`
2. For each completed project:
   - Verify completion status
   - Collect project metadata
   - Preserve all artifacts
   - Add to archive state
3. Update archive/state.json with new projects
4. Optionally move directories to `.claude/specs/archive/`

**Outputs**:
- Updated archive/state.json
- List of archived projects
- Archive statistics

**State Updates**:
```json
{
  "archive/state.json": {
    "archived_projects": [
      {
        "project_number": "NNN",
        "project_name": "project_name",
        "archived_date": "YYYY-MM-DDTHH:MM:SSZ",
        // ... full project metadata
      }
    ],
    "archive_metadata": {
      "total_projects": N,
      "last_updated": "YYYY-MM-DDTHH:MM:SSZ"
    }
  }
}
```

### Stage 4: Codebase Scanning

**Actions**:
1. Scan Logos/ directory for:
   - Sorry placeholders (production vs documentation)
   - Axiom declarations (by module)
   - Tactic implementations
   - Module completion status
2. Compare against documented status
3. Identify discrepancies
4. Calculate completion percentages

**Outputs**:
- Sorry count by module
- Axiom count by module
- Tactic implementation status
- Discrepancy list

**State Updates**:
- None (scanning is read-only)

### Stage 5: Status Document Updates

**Actions**:
1. For each discrepancy found:
   - Determine correct value
   - Update status document
   - Document reason for change
2. Update IMPLEMENTATION_STATUS.md
3. Update SORRY_REGISTRY.md
4. Update TACTIC_REGISTRY.md
5. Verify all changes are accurate

**Outputs**:
- Updated status documents
- List of changes made
- Before/after comparisons

**State Updates**:
- None (status documents are documentation)

### Stage 6: State Synchronization

**Actions**:
1. Update maintenance/state.json:
   - Add new operation entry
   - Update health trends
   - Update metrics history
   - Update technical debt tracking
2. Update state.json:
   - Add to recent_activities
   - Update maintenance_summary
   - Update repository_health
3. Verify all state files are consistent

**Outputs**:
- Updated maintenance/state.json
- Updated state.json
- State consistency verification

**State Updates**:
```json
{
  "maintenance/state.json": {
    "operations": [
      {
        "operation_id": "maintenance-YYYYMMDD",
        "date": "YYYY-MM-DDTHH:MM:SSZ",
        "type": "scheduled",
        "coordinator": "reviewer",
        "duration_hours": X.X,
        "status": "completed",
        // ... full operation details
      }
    ]
  },
  "state.json": {
    "recent_activities": [
      {
        "type": "maintenance",
        "timestamp": "YYYY-MM-DDTHH:MM:SSZ",
        "summary": "Brief summary"
      }
    ],
    "maintenance_summary": {
      "last_maintenance": "YYYY-MM-DD",
      "next_scheduled": "YYYY-MM-DD"
    }
  }
}
```

### Stage 7: Report Generation

**Actions**:
1. Create comprehensive maintenance report
2. Use standard template: `maintenance-report-template.md`
3. Include all sections:
   - Executive summary
   - Operations performed
   - Discrepancies found
   - Project health snapshot
   - State updates
   - Recommendations
   - Verification commands
4. Save as: `.claude/specs/maintenance/report-YYYYMMDD.md`

**Outputs**:
- Comprehensive maintenance report
- Report reference for state.json

**Naming Convention**:
- **Format**: `report-YYYYMMDD.md`
- **Location**: `.claude/specs/maintenance/`
- **Example**: `report-20251219.md`

### Stage 8: Verification

**Actions**:
1. Run verification commands:
   - Verify sorry counts
   - Verify axiom counts
   - Verify build status
   - Verify test status
2. Compare results with documented values
3. Resolve any discrepancies
4. Update report with verification results

**Outputs**:
- Verification results
- Confirmation of accuracy

### Stage 9: Return Results

**Actions**:
1. Prepare summary for orchestrator
2. Include:
   - Operation ID
   - Report path
   - Key metrics
   - Recommendations
   - Status
3. Return only references, not full content

**Return Format**:
```json
{
  "operation_id": "maintenance-YYYYMMDD",
  "type": "scheduled",
  "status": "completed",
  "duration_hours": X.X,
  "report_path": ".claude/specs/maintenance/report-YYYYMMDD.md",
  "summary": "Brief 2-3 sentence summary",
  "key_metrics": {
    "tasks_removed": N,
    "projects_archived": N,
    "discrepancies_resolved": N,
    "health_score": XX
  },
  "recommendations": {
    "high_priority": N,
    "medium_priority": N,
    "low_priority": N
  },
  "next_maintenance": "YYYY-MM-DD"
}
```

---

## File Naming Conventions

### Maintenance Reports
- **Format**: `report-YYYYMMDD.md`
- **Location**: `.claude/specs/maintenance/`
- **Example**: `report-20251219.md`

### State Files
- **Archive State**: `.claude/specs/archive/state.json`
- **Maintenance State**: `.claude/specs/maintenance/state.json`
- **Global State**: `.claude/specs/state.json`

### Archived Projects
- **Format**: `NNN_project_name/`
- **Location**: `.claude/specs/archive/`
- **Example**: `052_fix_aesop_duplicate/`

---

## State Management

### Archive State (archive/state.json)

**Purpose**: Track all archived completed projects

**Schema**:
```json
{
  "_comment": "Archive state tracking all completed projects",
  "schema_version": "1.0.0",
  "archive_metadata": {
    "total_projects": N,
    "last_updated": "YYYY-MM-DDTHH:MM:SSZ",
    "retention_policy": "indefinite",
    "archive_location": ".claude/specs/archive/"
  },
  "archived_projects": [
    {
      "project_number": "NNN",
      "project_name": "project_name",
      "type": "documentation | bugfix | feature | verification | maintenance",
      "archived_date": "YYYY-MM-DDTHH:MM:SSZ",
      "timeline": { /* ... */ },
      "summary": { /* ... */ },
      "artifacts": { /* ... */ },
      "deliverables": { /* ... */ },
      "impact": { /* ... */ },
      "verification": { /* ... */ },
      "references": { /* ... */ },
      "tags": [],
      "lessons_learned": []
    }
  ],
  "statistics": { /* ... */ },
  "search_indices": { /* ... */ }
}
```

### Maintenance State (maintenance/state.json)

**Purpose**: Track all maintenance operations and repository health

**Schema**:
```json
{
  "_comment": "Maintenance state tracking operations and health trends",
  "schema_version": "1.0.0",
  "maintenance_metadata": {
    "last_maintenance": "YYYY-MM-DD",
    "next_scheduled": "YYYY-MM-DD",
    "maintenance_frequency": "monthly",
    "coordinator": "reviewer"
  },
  "operations": [
    {
      "operation_id": "maintenance-YYYYMMDD",
      "date": "YYYY-MM-DDTHH:MM:SSZ",
      "type": "scheduled | ad-hoc | post-milestone",
      "coordinator": "reviewer",
      "subagents": [],
      "scope": { /* ... */ },
      "execution": { /* ... */ },
      "activities": { /* ... */ },
      "metrics": { /* ... */ },
      "findings": { /* ... */ },
      "artifacts": { /* ... */ },
      "health_snapshot": { /* ... */ },
      "recommendations": { /* ... */ }
    }
  ],
  "scheduled_maintenance": { /* ... */ },
  "health_trends": [ /* ... */ ],
  "technical_debt": { /* ... */ },
  "quality_gates": { /* ... */ },
  "metrics_history": { /* ... */ },
  "cumulative_statistics": { /* ... */ }
}
```

### Global State (state.json)

**Purpose**: Coordinate all project state

**Updates**:
```json
{
  "schema_version": "1.0.0",
  "state_references": {
    "archive_state": ".claude/specs/archive/state.json",
    "maintenance_state": ".claude/specs/maintenance/state.json"
  },
  "repository_health": {
    "health_score": XX,
    "layer_0_completion": XX,
    "last_verified": "YYYY-MM-DD"
  },
  "maintenance_summary": {
    "last_maintenance": "YYYY-MM-DD",
    "next_scheduled": "YYYY-MM-DD",
    "operations_count": N
  },
  "archive_summary": {
    "total_archived": N,
    "last_archived": "YYYY-MM-DD"
  },
  // ... existing fields preserved
}
```

---

## Agent Coordination

### Reviewer Agent (Orchestrator)
- **Role**: Coordinate maintenance workflow
- **Responsibilities**:
  - Execute all workflow stages
  - Coordinate subagents
  - Generate comprehensive report
  - Update all state files
  - Return results to user

### Verification Specialist (Subagent)
- **Role**: Verify proofs and code quality
- **Responsibilities**:
  - Scan codebase for sorry/axioms
  - Verify against standards
  - Identify discrepancies
  - Return verification results

### TODO Manager (Subagent)
- **Role**: Manage .claude/specs/TODO.md updates
- **Responsibilities**:
  - Clean up completed tasks
  - Update task priorities
  - Reorganize .claude/specs/TODO.md
  - Return summary of changes

---

## Migration from Legacy Approach

### Phase 1: Create State Files (Completed)
1. [PASS] Create archive/state.json with schema
2. [PASS] Create maintenance/state.json with schema
3. [PASS] Update state.json with references
4. [PASS] Document schemas in STATE_SCHEMA_GUIDE.md

### Phase 2: Migrate ARCHIVE_INDEX.md (Next)
1. Extract all project data from ARCHIVE_INDEX.md
2. Populate archive/state.json with extracted data
3. Verify all data migrated correctly
4. Mark ARCHIVE_INDEX.md as deprecated
5. Add note pointing to archive/state.json

### Phase 3: Standardize Report Naming (Next)
1. Rename existing reports to report-YYYYMMDD.md format
2. Update maintenance/state.json with report references
3. Update all agents to use new naming convention
4. Document naming convention in this workflow

### Phase 4: Update Agents (Next)
1. Update reviewer.md to use new workflow
2. Update todo.md command to use new workflow
3. Update review.md command to use new workflow
4. Update verification-specialist.md for new reports
5. Update todo-manager.md for new reports

### Phase 5: Consolidate Reports (Future)
1. Merge codebase-scan, todo-cleanup into single report
2. Use maintenance-report-template.md for all reports
3. Update agents to generate consolidated reports
4. Archive old report formats

---

## Best Practices

### 1. State Management
- Always update state files atomically
- Verify state consistency after updates
- Use ISO 8601 timestamps consistently
- Include operation IDs for traceability

### 2. Report Generation
- Use standard template for all reports
- Include all required sections
- Provide verification commands
- Link to state files for details

### 3. Archiving
- Archive projects immediately upon completion
- Preserve all artifacts in archive
- Update archive/state.json atomically
- Verify archive integrity

### 4. Documentation
- Keep status documents synchronized
- Document all discrepancies found
- Provide rationale for all changes
- Include before/after comparisons

### 5. Verification
- Run verification commands after updates
- Compare results with documented values
- Resolve discrepancies immediately
- Update reports with verification results

---

## Troubleshooting

### Issue: State files out of sync
**Solution**: Run verification commands, identify discrepancies, update state files

### Issue: Report generation fails
**Solution**: Check template exists, verify all required data available, use fallback format

### Issue: Archive migration incomplete
**Solution**: Compare ARCHIVE_INDEX.md with archive/state.json, migrate missing projects

### Issue: Discrepancies not resolved
**Solution**: Document in report, create follow-up task, track in maintenance/state.json

---

## Future Enhancements

1. **Automated Verification**: Run verification commands automatically during maintenance
2. **Health Scoring**: Implement automated health score calculation
3. **Trend Analysis**: Generate trend charts from metrics_history
4. **Predictive Maintenance**: Predict next maintenance needs based on trends
5. **Report Templates**: Create specialized templates for different maintenance types
