# Orchestrate Research Report Generation and Linking Implementation Plan

## Metadata
- **Date**: 2025-10-12
- **Specs Directory**: /home/benjamin/.config/.claude/specs/
- **Plan Number**: 041
- **Feature**: Ensure /orchestrate always creates and links research reports
- **Scope**: Modify /orchestrate command and research-specialist, plan-architect, debug-specialist agents to guarantee research reports are created via direct file writing (not /report command), saved with proper numbering, and automatically linked in implementation plans. Add debug report creation during testing phase failures.
- **Structure Level**: 0
- **Complexity Score**: 7.5
- **Estimated Phases**: 6
- **Estimated Tasks**: 32
- **Estimated Hours**: 10-14
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: None (initial plan)

## Overview

Currently, `/orchestrate` has infrastructure for research reports but doesn't consistently create them. The system uses an "artifact" pattern (`specs/artifacts/{project}/`) for temporary research storage, but these artifacts are not preserved as formal reports in `specs/reports/`. This plan ensures that:

1. **Research Phase**: All research conducted by `/orchestrate` is saved as numbered reports in `{project}/specs/reports/{topic}/NNN_report_name.md`
2. **Report Numbering**: Reports use incremental three-digit numbering (001, 002, 003...) within each topic subdirectory
3. **Automatic Linking**: Plans automatically reference all research reports used during planning phase
4. **Agent Behavior**:
   - research-specialist agents always create report files (not summaries)
   - plan-architect creates plans that link to all research reports
   - debug-specialist creates debug reports during testing failures
5. **Cross-Referencing**: Bidirectional links between reports and plans are automatically maintained

### Current State

**Problems Identified**:
- orchestrate.md:229-237: Research agents can output to artifacts OR return summaries, but artifact mode is optional
- orchestrate.md:352-373: Planning phase receives artifact references but doesn't guarantee report creation
- research-specialist.md:164-195: Artifact output mode is optional, default is summary-only
- plan-architect.md: No requirement to verify or reference research reports in generated plans
- No debug report creation during implementation/testing failures

**What Works**:
- Report numbering system (NNN format) exists and works
- SPECS.md registration for project/specs directories
- /plan command accepts report paths as arguments
- Plan metadata includes "Research Reports" field
- Agent behavioral injection pattern for specialized tasks

**What's Missing**:
- Mandatory report file creation by research-specialist agents during research phase
- Guaranteed linking of reports in plan metadata
- Cross-referencing: reports → plans and plans → reports
- Topic-based subdirectory organization for reports
- Debug report creation in separate debug/ directory during testing phase failures

## Success Criteria

- [ ] Every /orchestrate research phase creates at least one report file per research topic
- [ ] Reports are saved in `{project}/specs/reports/{topic}/NNN_report_name.md` with correct numbering
- [ ] Implementation plans automatically list all research reports in metadata
- [ ] Research reports include "Implementation Status" section linking back to plans
- [ ] research-specialist agents always output to report files (via Write tool), not summaries
- [ ] plan-architect agent verifies and links all research reports
- [ ] Debug reports are created in `{project}/debug/{topic}/NNN_debug_report_name.md` during testing phase failures
- [ ] Bidirectional linking is maintained automatically

## Technical Design

### Architecture Overview

```
/orchestrate workflow:
  1. Research Phase
     ├─→ Identify research topics (2-4 topics)
     ├─→ Determine topic names for directory structure
     ├─→ For each topic:
     │   ├─→ Invoke research-specialist agent with behavioral injection
     │   ├─→ Agent determines report number via Glob (find existing reports in topic dir)
     │   ├─→ Agent creates report file using Write tool: specs/reports/{topic}/NNN_report_name.md
     │   ├─→ Agent returns report path to orchestrator
     │   └─→ Store report path in orchestrator context
     └─→ Pass all report paths to planning phase

  2. Planning Phase
     ├─→ Receive list of report paths from research phase
     ├─→ Invoke plan-architect agent with behavioral injection + report paths
     ├─→ Agent reads all reports and incorporates findings
     ├─→ Agent creates plan with "Research Reports" metadata section
     ├─→ Agent uses Edit tool to update each report's "Implementation Status"
     └─→ Return plan path to orchestrator

  3. Implementation Phase
     ├─→ Invoke code-writer agent with plan path
     ├─→ Execute phases with testing
     └─→ If tests fail: Create debug reports (see Debugging Loop below)

  4. Debugging Loop (conditional - only if tests fail)
     ├─→ Invoke debug-specialist agent with failure details
     ├─→ Agent determines debug report number in debug/{topic}/ directory
     ├─→ Agent creates debug report: {project}/debug/{topic}/NNN_debug_report_name.md
     ├─→ Agent provides fix recommendations
     ├─→ code-writer applies fixes
     └─→ Retry tests (max 3 iterations)

  5. Documentation Phase
     ├─→ Verify bidirectional links exist
     ├─→ Add cross-references if missing
     └─→ Create implementation summary
```

### Component Changes

#### 1. /orchestrate Command Changes
- **File**: `.claude/commands/orchestrate.md`
- **Changes**:
  - Remove optional artifact mode references (orchestrate.md:70, 77, 164-195, 229-273)
  - Mandate report file creation in research phase
  - Update research-specialist agent prompts to include report file creation instructions
  - Add topic subdirectory path calculation before invoking agents
  - Pass report paths to plan-architect agent invocation
  - Add report path collection in workflow state (orchestrate.md:52-88)
  - Update checkpoint data to include report paths (orchestrate.md:251-265)

#### 2. research-specialist Agent Updates
- **File**: `.claude/agents/research-specialist.md`
- **Changes**:
  - Remove summary-only output mode (research-specialist.md:36-59)
  - Remove artifact output mode section (research-specialist.md:164-195)
  - Add mandatory report file creation instructions
  - Document report numbering via Glob pattern matching
  - Add Write tool usage for report file creation
  - Include report structure template with required metadata fields
  - Update examples to show direct file creation
  - Return report path in structured format

#### 3. plan-architect Agent Updates
- **File**: `.claude/agents/plan-architect.md`
- **Changes**:
  - Make report paths mandatory in invocation context (plan-architect.md:194-260)
  - Add validation logic: verify all reports are referenced (plan-architect.md:430-441)
  - Add "Research Reports" metadata section to plan template (plan-architect.md:299-363)
  - Implement Edit tool workflow for updating report "Implementation Status"
  - Update agent examples with report paths and linking
  - Add quality checklist item for report verification (plan-architect.md:430-442)

#### 4. debug-specialist Agent Updates
- **File**: `.claude/agents/debug-specialist.md`
- **Changes**:
  - Add debug report file creation capability during testing phase
  - Document debug/ directory structure separate from reports/
  - Add Write tool usage for debug report creation in debug/{topic}/NNN_*.md
  - Include numbering via Glob in debug directories
  - Keep existing diagnostic format for standalone /debug use
  - Add orchestrate-invoked mode for file-based debug reports

#### 5. /orchestrate Debugging Loop Integration
- **File**: `.claude/commands/orchestrate.md`
- **Changes**:
  - Add debug-specialist invocation during test failures (orchestrate.md:785-860)
  - Pass failed test details and context to debug-specialist
  - Collect debug report paths from agent output
  - Include debug reports in final workflow summary
  - Link debug reports in implementation summary

### Data Structures

#### Workflow State (orchestrate.md)
```yaml
workflow_state:
  project_name: "user_authentication"  # Derived from workflow description
  research_phase:
    topics: ["existing_patterns", "security_practices", "alternatives"]
    reports: [
      {
        topic: "existing_patterns",
        path: "specs/reports/existing_patterns/001_auth_patterns.md",
        number: "001"
      },
      {
        topic: "security_practices",
        path: "specs/reports/security_practices/001_best_practices.md",
        number: "001"
      },
      {
        topic: "alternatives",
        path: "specs/reports/alternatives/001_implementation_options.md",
        number: "001"
      }
    ]
  plan_path: "specs/plans/042_user_authentication.md"
```

#### Report Metadata (all reports)
```markdown
## Metadata
- **Date**: YYYY-MM-DD
- **Specs Directory**: {project}/specs/
- **Report Number**: NNN (within topic subdirectory)
- **Topic**: {topic_name}
- **Created By**: /orchestrate | /report | /debug
- **Workflow**: {workflow_description if from /orchestrate}

## Implementation Status
- **Status**: Research Complete | Planning In Progress | Implementation Started | Completed
- **Plan**: [Link to plan if created]
- **Implementation**: [Link to summary if completed]
- **Date**: YYYY-MM-DD
```

#### Plan Metadata (all plans)
```markdown
## Metadata
- **Date**: YYYY-MM-DD
- **Specs Directory**: {project}/specs/
- **Plan Number**: NNN
- **Research Reports**:
  - [Existing Patterns](../reports/existing_patterns/001_auth_patterns.md)
  - [Security Practices](../reports/security_practices/001_best_practices.md)
  - [Alternative Approaches](../reports/alternatives/001_implementation_options.md)

## Research Summary
Brief synthesis of key findings from research reports:
- Finding 1 from existing_patterns report
- Finding 2 from security_practices report
- Finding 3 from alternatives report
```

### Directory Structure

```
{project}/
├── specs/
│   ├── reports/
│   │   ├── existing_patterns/
│   │   │   ├── 001_auth_patterns.md
│   │   │   └── 002_session_patterns.md
│   │   ├── security_practices/
│   │   │   └── 001_best_practices.md
│   │   └── alternatives/
│   │       └── 001_implementation_options.md
│   ├── plans/
│   │   ├── 042_user_authentication.md
│   │   └── 043_session_refactor.md
│   └── summaries/
│       ├── 042_implementation_summary.md
│       └── 043_implementation_summary.md
└── debug/
    ├── phase1_failures/
    │   ├── 001_config_initialization.md
    │   └── 002_dependency_missing.md
    └── integration_issues/
        └── 001_auth_timeout.md
```

## Implementation Phases

### Phase 1: Update research-specialist Agent for Direct Report File Creation [COMPLETED]
**Objective**: Modify research-specialist to create report files directly using Write tool
**Complexity**: Medium
**Dependencies**: []

Tasks:
- [x] Remove summary-only output mode documentation (research-specialist.md:36-59)
- [x] Remove artifact output mode section entirely (research-specialist.md:164-195)
- [x] Add report file creation instructions using Write tool
- [x] Document report numbering via Glob (find existing {topic}/NNN_*.md files)
- [x] Add report structure template with required metadata fields
- [x] Document topic subdirectory path determination
- [x] Update example usage to show direct file creation
- [x] Add structured report path return format for orchestrator parsing

Testing:
```bash
# Test research-specialist agent invocation manually
# Create test prompt that includes report file creation

# Verify agent can:
# 1. Determine report number via Glob
ls -la specs/reports/existing_patterns/*.md | wc -l

# 2. Create report file with correct structure
cat specs/reports/existing_patterns/001_test_report.md

# 3. Return report path in parseable format
# Expected: "REPORT_PATH: specs/reports/existing_patterns/001_test_report.md"
```

Expected Outcomes:
- Agent documentation clearly specifies Write tool usage
- Report numbering logic using Glob is documented
- Report structure template is complete with metadata
- Examples show end-to-end file creation

### Phase 2: Update /orchestrate Research Phase for Direct Agent Report Creation [COMPLETED]
**Objective**: Modify orchestrate to prompt research agents for direct report file creation
**Complexity**: Medium
**Dependencies**: [1]

Tasks:
- [x] Remove artifact mode references (orchestrate.md:70, 77, 164-195, 229-273)
- [x] Update research agent prompt template to include file creation instructions
- [x] Add topic name generation from research descriptions (orchestrate.md:209-222)
- [x] Add specs directory path determination before agent invocation
- [x] Include report numbering instructions in agent prompt
- [x] Add report structure template to agent prompt
- [x] Parse report paths from agent output
- [x] Store report paths in workflow state (orchestrate.md:52-88)
- [x] Update checkpoint data to include report paths (orchestrate.md:251-265)

Testing:
```bash
# Test orchestrate workflow with research
/orchestrate "Add user authentication with OAuth2"

# Verify reports created
ls -la specs/reports/*/
# Expected subdirectories: existing_patterns/, security_practices/, alternatives/
# Expected files: 001_*.md in each subdirectory

# Verify report structure
cat specs/reports/existing_patterns/001_*.md
# Expected: Complete metadata, findings, recommendations

# Check workflow state includes report paths
# (inspect checkpoint or orchestrator output)

# Verify no artifacts directory created
ls -la specs/artifacts/ 2>/dev/null
# Expected: Directory doesn't exist
```

Expected Outcomes:
- Research agents create report files directly
- Reports saved in topic-specific subdirectories
- Report paths collected in workflow state
- Artifact pattern completely removed

### Phase 3: Update plan-architect Agent for Report Verification and Linking [COMPLETED]
**Objective**: Ensure plan-architect receives, validates, and links all research reports
**Complexity**: Medium
**Dependencies**: [1, 2]

Tasks:
- [x] Make report paths mandatory in agent invocation context (plan-architect.md:194-260)
- [x] Add report paths to agent behavioral injection prompt
- [x] Add validation: verify all provided reports are referenced
- [x] Add "Research Reports" metadata section to plan template (plan-architect.md:299-363)
- [x] Add "Research Summary" section to plan body
- [x] Implement Edit tool workflow for updating report "Implementation Status"
- [x] Update agent examples to show report handling
- [x] Add quality checklist item for report verification (plan-architect.md:430-442)

Testing:
```bash
# Test plan-architect via /orchestrate with reports
/orchestrate "Implement rate limiting for API endpoints"

# Verify plan includes all research reports in metadata
PLAN=$(ls specs/plans/ | grep -E "^[0-9]{3}_" | sort -n | tail -1)
grep -A 10 "Research Reports" specs/plans/$PLAN
# Expected: Links to all research report files

# Verify Research Summary section exists
grep -A 15 "Research Summary" specs/plans/$PLAN
# Expected: Synthesis of key findings from reports

# Verify reports updated with plan link
grep -A 5 "Implementation Status" specs/reports/**/001_*.md
# Expected: "Plan: ../plans/NNN_*.md"
# Expected: "Status: Planning In Progress"
```

Expected Outcomes:
- plan-architect receives report paths in prompt
- All reports referenced in plan metadata
- Research Summary section present and accurate
- Reports automatically updated with plan links
- Validation prevents missing reports

### Phase 4: Update /orchestrate Planning Phase Integration [COMPLETED]
**Objective**: Connect research phase output (report paths) to planning phase input
**Complexity**: Low
**Dependencies**: [1, 2, 3]

Tasks:
- [x] Update planning phase prompt generation (orchestrate.md:344-446)
- [x] Pass collected report paths to plan-architect agent
- [x] Format report paths list for agent prompt
- [x] Add workflow description context to planning prompt
- [x] Verify bidirectional linking in documentation phase
- [x] Add report verification to final workflow summary

Testing:
```bash
# Test complete research→planning flow
/orchestrate "Add email notification system with templates"

# Verify planning phase receives report paths
# Check orchestrator output for plan-architect invocation
# Expected: report paths visible in agent prompt

# Verify plan created with proper links
grep "Research Reports" specs/plans/*_email_notification*.md

# Verify all reports have plan links
find specs/reports -name "00*.md" -exec grep -l "Implementation Status" {} \;
# Expected: All research reports from this workflow
```

Expected Outcomes:
- Report paths passed from research to planning phase
- plan-architect receives complete report list
- Bidirectional links verified in documentation phase
- Workflow summary includes all report references

### Phase 5: Add debug-specialist Integration for Testing Phase Failures [COMPLETED]
**Objective**: Create debug reports when implementation tests fail
**Complexity**: Medium
**Dependencies**: [1]

Tasks:
- [x] Update debug-specialist agent for file-based debug reports
- [x] Add debug/ directory structure documentation
- [x] Add Write tool usage for debug report creation
- [x] Document debug report numbering in debug/{topic}/ directories
- [x] Update /orchestrate debugging loop (orchestrate.md:785-860)
- [x] Add debug-specialist invocation on test failures
- [x] Collect debug report paths in workflow state
- [x] Link debug reports in implementation summary

Testing:
```bash
# Test debug report creation manually
# Create failing test scenario in implementation

# Verify debug report created
ls -la debug/*/
# Expected: debug/{topic}/001_*.md files

# Check debug report structure
cat debug/phase1_failures/001_*.md
# Expected: Complete diagnostic report

# Verify debug reports linked in summary
grep "debug/" specs/summaries/*_implementation_summary.md
```

Expected Outcomes:
- debug-specialist creates debug report files
- Debug reports organized in debug/{topic}/ directories
- Debug reports linked in workflow summaries
- Debugging loop invokes agent on test failures

### Phase 6: Integration Testing and Documentation [COMPLETED]
**Objective**: Validate complete workflow and update all documentation
**Complexity**: Low
**Dependencies**: [1, 2, 3, 4, 5]

Tasks:
- [x] Test complete /orchestrate workflow end-to-end
- [x] Verify report→plan→summary linking chain
- [x] Verify debug reports created on test failures
- [x] Update orchestrate.md with new research phase workflow
- [x] Update research-specialist.md with file creation examples
- [x] Update plan-architect.md with report verification docs
- [x] Update debug-specialist.md with debug report creation
- [x] Update CLAUDE.md with directory structure documentation

Testing:
```bash
# Integration test: complete workflow
/orchestrate "Implement user profile management with avatar uploads"

# Verify directory structure
tree specs/reports/
tree specs/plans/
tree specs/summaries/
tree debug/ 2>/dev/null

# Check all cross-references
grep -r "specs/reports" specs/plans/
grep -r "specs/plans" specs/reports/
grep -r "debug/" specs/summaries/

# Verify SPECS.md updated
cat .claude/SPECS.md | grep -A 20 "specs/"
```

Expected Outcomes:
- Complete workflow creates all expected files
- All cross-references are bidirectional and correct
- Directory structure matches specification
- Documentation is complete and accurate

## Testing Strategy

### Unit Testing
Each phase has specific test commands for validation. Focus on:
- Command invocation and argument parsing
- Directory creation and file naming
- Metadata formatting and cross-referencing
- Error handling for missing directories or files

### Integration Testing
Test complete /orchestrate workflows:
1. **Simple workflow** (2 research topics):
   ```bash
   /orchestrate "Add email notifications"
   # Verify: 2 reports, 1 plan, all linked
   ```

2. **Complex workflow** (4 research topics + debug):
   ```bash
   /orchestrate "Implement distributed caching with Redis"
   # Verify: 4 reports, 1 plan, bidirectional links
   ```

3. **Debug workflow**:
   ```bash
   /orchestrate "Debug and fix memory leak in background worker"
   # Verify: debug report created and linked
   ```

### Validation Checks
After each test workflow:
- [ ] All research topics have corresponding reports
- [ ] Reports saved in correct topic subdirectories
- [ ] Report numbers increment correctly per topic
- [ ] Plan metadata lists all reports
- [ ] Reports include "Implementation Status" with plan link
- [ ] SPECS.md updated with new reports
- [ ] No artifact files created (deprecated pattern)

### Edge Cases
- **No research phase**: Simple tasks skip research, no reports expected
- **Single topic**: Only one report created, still linked properly
- **Existing topic directory**: Numbering continues from existing reports
- **Interrupted workflow**: Checkpoint includes partial report paths

## Documentation Requirements

### Command Documentation
- [ ] Update orchestrate.md with new research phase workflow
- [ ] Update report.md with topic subdirectory usage
- [ ] Update plan.md with report linking requirements
- [ ] Update debug.md with research-mode invocation

### Agent Documentation
- [ ] Update research-specialist.md removing artifact mode
- [ ] Update plan-architect.md with report validation
- [ ] Update debug-specialist.md with research-mode template

### CLAUDE.md Updates
- [ ] Document topic subdirectory structure in specs protocol
- [ ] Add report-plan linking requirements to standards
- [ ] Update /orchestrate usage examples with report creation

### README Updates
- [ ] Update .claude/commands/README.md with new workflow
- [ ] Add examples showing report→plan→implementation flow
- [ ] Document topic-based organization pattern

## Dependencies

### External
- None (all changes internal to command/agent system)

### Internal
- **Phase 1** must complete before Phase 2 (report command ready)
- **Phases 1-2** must complete before Phase 3 (reports exist for plan to link)
- **Phase 4** depends on Phase 1 (agent uses updated /report)
- **Phase 5** depends on Phases 1-3 (requires full workflow)
- **Phase 6** depends on Phase 1 (uses same report creation mechanism)

### Configuration
- SPECS.md must exist (created by /setup if missing)
- CLAUDE.md should exist for standards (fallback: defaults)

## Risk Assessment

### High Risk
- **Breaking existing workflows**: Artifact pattern still used by other systems?
  - **Mitigation**: Grep for artifact references, verify only /orchestrate uses it
  - **Rollback**: Keep artifact code path with deprecation warning

### Medium Risk
- **Report numbering conflicts**: Multiple workflows creating reports simultaneously
  - **Mitigation**: Use file locking or atomic directory creation
  - **Rollback**: Manual conflict resolution, user notification

- **Large number of reports**: Topic subdirectories fill up over time
  - **Mitigation**: Document archival process, add /list reports filtering
  - **Rollback**: None needed, this is organizational not functional

### Low Risk
- **SPECS.md corruption**: Concurrent updates to SPECS.md
  - **Mitigation**: Use Edit tool atomic operations, validate before writing
  - **Rollback**: SPECS.md is discoverable, can be regenerated

- **Broken links**: Report/plan paths change after linking
  - **Mitigation**: Validate links during /document phase
  - **Rollback**: Manual link repair, or rerun /orchestrate documentation phase

## Success Metrics

### Quantitative
- [ ] 100% of /orchestrate workflows create reports (no failures)
- [ ] 100% of plans include all research reports in metadata
- [ ] 0 artifact files created after implementation
- [ ] Average report creation time < 2 minutes per topic
- [ ] Numbering collisions: 0 (atomic numbering)

### Qualitative
- [ ] Reports are readable and comprehensive (manual review)
- [ ] Links navigate correctly between reports and plans
- [ ] SPECS.md remains organized and up-to-date
- [ ] Workflow feels natural to users
- [ ] Documentation is clear and complete

## Notes

### Design Decisions

**Why topic subdirectories?**
- Organizes related research reports together
- Prevents report directory from becoming overwhelmingly large
- Allows topic-specific numbering (reset to 001 per topic)
- Makes finding related reports easier

**Why deprecate artifacts?**
- Artifacts were temporary/ephemeral by design
- Reports are permanent documentation
- Removes confusion between artifact and report concepts
- Simplifies the system (one pattern for research output)

**Why mandatory report creation?**
- Ensures research is never lost
- Provides audit trail for decisions
- Enables future plan updates based on old research
- Supports /list reports and research discovery

### Future Enhancements

Not in scope for this plan, but worth considering:
- [ ] Report templates for different research types
- [ ] Automatic report summarization for very long reports
- [ ] Report versioning (update existing reports)
- [ ] Cross-project report discovery
- [ ] Report archival after implementation completion
- [ ] Report quality scoring or validation

### Implementation Order

Recommended sequence:
1. Phase 1 (report command) - Foundation
2. Phase 4 (research-specialist) - Agent uses new report command
3. Phase 2 (orchestrate research) - Workflow uses updated agent
4. Phase 3 (plan linking) - Plans connect to reports
5. Phase 5 (plan-architect) - Agent enforces linking
6. Phase 6 (debug-specialist) - Complete integration

### Rollback Strategy

If critical issues arise:
1. **Phase 1-2**: Restore artifact-based research (revert orchestrate.md)
2. **Phase 3-5**: Make report linking optional (revert validation)
3. **Phase 6**: Disable debug research-mode (revert to standalone only)

Full rollback: git revert commits in reverse order of implementation.

## Revision History

### 2025-10-12 - Revision 2
**Changes**: Clarified agent roles - plan-architect creates plans, not reports
**Reason**: User pointed out confusion in Overview section where it said plan-architect creates report files
**Key Updates**:
- Clarified: research-specialist creates report files
- Clarified: plan-architect creates plans that link to reports
- Clarified: debug-specialist creates debug reports
- Each agent has distinct file output type

### 2025-10-12 - Revision 1
**Changes**: Removed /report and /debug command modifications; agents now create report files directly
**Reason**: User clarified that subagents should create reports directly via Write tool, not invoke /report command. Debug reports should be created in separate debug/ directory during testing phase failures, not during research phase.
**Key Updates**:
- Research-specialist agents use Write tool directly to create report files
- Removed all /report command integration tasks
- Debug reports go to {project}/debug/{topic}/ not specs/reports/debugging/
- Debug reports created only during implementation testing failures, not research phase
- Simplified architecture: agents → files → orchestrator, no command intermediaries
