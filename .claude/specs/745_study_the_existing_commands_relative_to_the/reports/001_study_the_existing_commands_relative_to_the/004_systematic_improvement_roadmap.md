# Systematic Improvement Roadmap

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Systematic approach to command compliance improvement
- **Report Type**: Strategy and roadmap
- **Overview Report**: [Research Overview](./OVERVIEW.md)

## Executive Summary

This report designs a systematic improvement approach for bringing all commands into compliance with the 16 architectural standards defined in command_architecture_standards.md. The roadmap prioritizes high-value commands first (coordinate, plan, research), provides update templates/checklists for consistent application, addresses backward compatibility through versioning and migration scripts, and establishes testing/validation frameworks. The phased rollout minimizes disruption while achieving uniform standards compliance across all 12 commands within 8-12 weeks with measurable success metrics (execution reliability, agent delegation rates, file creation rates).

## Findings

### Current Compliance Landscape

**Standards Analysis** (from /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md):

The project has 16 architectural standards covering:
- **Standard 0**: Execution Enforcement (imperative language, verification checkpoints, fallback mechanisms)
- **Standard 0.5**: Subagent Prompt Enforcement (agent-specific enforcement patterns)
- **Standard 1**: Executable Instructions Must Be Inline
- **Standard 2**: Reference Pattern (instructions first, references after)
- **Standard 3**: Critical Information Density
- **Standard 4**: Template Completeness
- **Standard 5**: Structural Annotations
- **Standard 11**: Imperative Agent Invocation Pattern
- **Standard 12**: Structural vs Behavioral Content Separation
- **Standard 13**: Project Directory Detection (CLAUDE_PROJECT_DIR)
- **Standard 14**: Executable/Documentation File Separation
- **Standard 15**: Library Sourcing Order
- **Standard 16**: Critical Function Return Code Verification

**Command Inventory** (from /home/benjamin/.config/.claude/commands/):

12 total commands discovered:
1. `/coordinate` - State-based orchestrator (1,084 lines, has guide)
2. `/plan` - Implementation plan creation (229 lines, has guide)
3. `/implement` - Plan execution (220 lines, has guide)
4. `/research` - Multi-agent research orchestration
5. `/debug` - Parallel hypothesis testing (202 lines, has guide)
6. `/revise` - Plan revision with auto-mode
7. `/expand` - Phase/stage expansion
8. `/collapse` - Phase/stage collapse
9. `/setup` - Project configuration (has guide)
10. `/optimize-claude` - Command optimization (has guide)
11. `/convert-docs` - Document format conversion
12. `/document` - Documentation generation (168 lines, has guide)

**Migration Evidence** (from command_architecture_standards.md:1686-1701):

7 commands already migrated to Standard 14 (Executable/Documentation Separation):
- `/coordinate`: 2,334 → 1,084 lines (54% reduction, guide: 1,250 lines)
- `/orchestrate`: 5,439 → 557 lines (90% reduction, guide: 4,882 lines) [ARCHIVED]
- `/implement`: 2,076 → 220 lines (89% reduction, guide: 921 lines)
- `/plan`: 1,447 → 229 lines (84% reduction, guide: 460 lines)
- `/debug`: 810 → 202 lines (75% reduction, guide: 375 lines)
- `/document`: 563 → 168 lines (70% reduction, guide: 669 lines)
- `/test`: 200 → 149 lines (26% reduction, guide: 666 lines) [NOT FOUND in commands/]

**Testing Infrastructure** (from /home/benjamin/.config/.claude/tests/):

Comprehensive test coverage exists:
- 90+ test scripts covering integration, unit, and validation
- 4 validation scripts for standards compliance:
  - `validate_executable_doc_separation.sh` (Standard 14)
  - `validate_command_behavioral_injection.sh` (Standard 11)
  - `validate_topic_based_artifacts.sh` (directory protocols)
  - `validate_no_agent_slash_commands.sh` (architectural separation)

### Compliance Gap Analysis

**High-Priority Gaps** (Critical for reliability):

1. **Standard 0 (Execution Enforcement)**: Commands may use descriptive language instead of imperative directives
   - Impact: Steps skipped, verification bypassed, silent failures
   - Affected: All commands not yet audited

2. **Standard 11 (Imperative Agent Invocation)**: Agent invocations may use documentation-only YAML pattern
   - Impact: 0% agent delegation rate (agents never invoked)
   - Historical evidence: /coordinate and /research fixed in Spec 495

3. **Standard 15 (Library Sourcing Order)**: Functions may be called before libraries sourced
   - Impact: "command not found" errors terminate workflows
   - Historical evidence: /coordinate fixed in Spec 675

4. **Standard 16 (Critical Function Return Code Verification)**: Missing return code checks on critical functions
   - Impact: Silent failures, delayed errors, incomplete state
   - Historical evidence: /coordinate and /orchestrate fixed in Spec 698

**Medium-Priority Gaps** (Quality/maintainability):

5. **Standard 0.5 (Subagent Prompt Enforcement)**: Agent behavioral files may use weak language
   - Impact: Variable file creation rates (60-80% vs 100% target)
   - Target: 95+/100 on enforcement rubric

6. **Standard 12 (Structural vs Behavioral Separation)**: Commands may duplicate behavioral content inline
   - Impact: 90% code bloat, synchronization burden
   - Detection: STEP sequences, PRIMARY OBLIGATION blocks in commands

7. **Standard 14 (Executable/Documentation Separation)**: 5 commands lack companion guide files
   - Impact: Meta-confusion (75% → 0% after migration)
   - Missing guides: /research, /expand, /collapse, /revise, /convert-docs

**Low-Priority Gaps** (Consistency):

8. **Standards 1-5** (Inline content, references, density, templates, annotations): Inconsistent application
9. **Standard 13** (Project Directory Detection): May use ${BASH_SOURCE[0]} in SlashCommand context

### Existing Migration Patterns

**Standard 14 Migration Evidence** (command_architecture_standards.md:1670-1687):

Templates exist and proven:
- `.claude/docs/guides/_template-executable-command.md` (56 lines)
- `.claude/docs/guides/_template-command-guide.md` (171 lines)

Results from 7 migrated commands:
- Average 70% executable file size reduction
- Average 1,300 lines of comprehensive documentation created
- 100% execution success rate (vs 25% pre-migration)
- 0% meta-confusion rate (vs 75% pre-migration)

**Validation Scripts Proven** (command_architecture_standards.md validation references):

- Three-layer validation: File size, guide existence, cross-references
- Automated via `.claude/tests/validate_executable_doc_separation.sh`
- Zero false positives in 7 migrated commands

## Recommendations

### 1. Prioritization Framework

**Tier 1 (Critical - Weeks 1-3)**: High-value orchestration commands
- **Commands**: `/coordinate`, `/plan`, `/research`
- **Rationale**: Multi-agent orchestrators used by other commands, highest failure impact
- **Standards focus**: 0, 11, 15, 16 (reliability-critical)
- **Expected impact**: 95%+ execution reliability, 100% agent delegation rate

**Tier 2 (High - Weeks 4-6)**: Execution and modification commands
- **Commands**: `/implement`, `/revise`, `/expand`, `/collapse`
- **Rationale**: Direct workflow execution, frequent use, moderate complexity
- **Standards focus**: 0, 14 (execution + documentation)
- **Expected impact**: 90%+ test pass rate, complete guide coverage

**Tier 3 (Medium - Weeks 7-9)**: Support and utility commands
- **Commands**: `/debug`, `/document`, `/convert-docs`
- **Rationale**: Support functions, lower usage frequency
- **Standards focus**: 14, 0.5 (consistency)
- **Expected impact**: Uniform quality, maintainability

**Tier 4 (Low - Weeks 10-12)**: Setup and optimization commands
- **Commands**: `/setup`, `/optimize-claude`
- **Rationale**: Already have guides, infrequent use
- **Standards focus**: Minor compliance gaps only
- **Expected impact**: Full compliance certification

**Prioritization Criteria**:
1. Command usage frequency (daily vs occasional)
2. Failure impact radius (affects other commands vs standalone)
3. Current compliance gaps (critical vs minor)
4. Architectural complexity (orchestrator vs simple executor)

### 2. Update Patterns and Checklists

**Master Compliance Checklist** (Template for all commands):

```markdown
# Command Compliance Audit: [command-name]

## Standard 0: Execution Enforcement
- [ ] All critical operations use "EXECUTE NOW", "YOU MUST", "MANDATORY"
- [ ] Verification checkpoints use "MANDATORY VERIFICATION" headers
- [ ] Fallback mechanisms exist for agent-dependent operations
- [ ] Phase 0 (Pre-Calculate Paths) exists if orchestrator
- [ ] Checkpoint reporting uses "CHECKPOINT REQUIREMENT" pattern

## Standard 0.5: Subagent Prompt Enforcement (if uses agents)
- [ ] Agent prompts use "Read and follow: .claude/agents/[name].md"
- [ ] Context injection provides paths, not behavioral guidelines
- [ ] Completion signal required in agent return value
- [ ] Agent behavioral files score 95+/100 on enforcement rubric

## Standard 11: Imperative Agent Invocation
- [ ] Agent invocations preceded by "EXECUTE NOW: USE the Task tool"
- [ ] No YAML code block wrappers (` ```yaml ... ``` `)
- [ ] No "Example" prefixes before Task blocks
- [ ] No undermining disclaimers after imperative directives

## Standard 12: Structural vs Behavioral Separation
- [ ] Zero STEP sequences for agent behavior (should be in agent files)
- [ ] Zero PRIMARY OBLIGATION blocks (agent files only)
- [ ] Task invocations <50 lines (context injection, not duplication)

## Standard 13: Project Directory Detection
- [ ] Uses CLAUDE_PROJECT_DIR (not ${BASH_SOURCE[0]})
- [ ] Git-based detection with pwd fallback
- [ ] Enhanced error diagnostics for library sourcing failures

## Standard 14: Executable/Documentation Separation
- [ ] Executable file <250 lines (simple) or <1,200 lines (orchestrator)
- [ ] Guide file exists in .claude/docs/guides/[name]-command-guide.md
- [ ] Bidirectional cross-references (command ↔ guide)
- [ ] Guide has: Purpose, Architecture, Examples, Troubleshooting

## Standard 15: Library Sourcing Order
- [ ] workflow-state-machine.sh sourced first
- [ ] state-persistence.sh sourced second
- [ ] error-handling.sh sourced before first error function call
- [ ] verification-helpers.sh sourced before first verify_* call
- [ ] No function calls before library sourcing

## Standard 16: Critical Function Return Code Verification
- [ ] sm_init() checked: `if ! sm_init ... 2>&1; then handle_state_error ... fi`
- [ ] initialize_workflow_paths() checked
- [ ] source_required_libraries() checked
- [ ] classify_workflow_comprehensive() checked
- [ ] Variables verified after successful function calls

## Standards 1-5: Content Quality
- [ ] Execution steps inline and numbered (not reference-only)
- [ ] Tool invocation examples complete (not truncated)
- [ ] Critical warnings present (CRITICAL/IMPORTANT/NEVER)
- [ ] Templates copy-paste ready
- [ ] Decision logic includes conditions and thresholds
- [ ] Error recovery procedures specific
- [ ] References supplement (not replace) inline instructions
```

**Standard 14 Migration Template** (Proven pattern):

```bash
#!/bin/bash
# migrate-to-standard-14.sh [command-name]

COMMAND_NAME="$1"
COMMAND_FILE=".claude/commands/${COMMAND_NAME}.md"
GUIDE_FILE=".claude/docs/guides/${COMMAND_NAME}-command-guide.md"

# 1. Backup original
cp "$COMMAND_FILE" "${COMMAND_FILE}.backup"

# 2. Extract documentation sections (move to guide)
# - Extended examples (beyond core 1-2)
# - Background/rationale sections
# - Alternative approaches
# - Troubleshooting details
# - Design decisions

# 3. Create guide from template
cp .claude/docs/guides/_template-command-guide.md "$GUIDE_FILE"

# 4. Populate guide sections
# - Copy extracted documentation
# - Add architecture diagrams
# - Create comprehensive examples
# - Document edge cases

# 5. Reduce executable to essentials
# - Keep: Bash blocks, phase markers, imperative instructions
# - Keep: Critical warnings, verification checkpoints
# - Keep: 1-2 core examples per pattern
# - Remove: Extended background, alternatives, deep dives

# 6. Add cross-references
# Executable: **Documentation**: See .claude/docs/guides/[name]-command-guide.md
# Guide: **Executable**: .claude/commands/[name].md

# 7. Validate
bash .claude/tests/validate_executable_doc_separation.sh

# 8. Test execution
# Run command and verify it works without reading guide
```

**Agent Behavioral File Strengthening Template** (Standard 0.5):

```bash
#!/bin/bash
# strengthen-agent-behavioral.sh [agent-name]

AGENT_FILE=".claude/agents/${1}.md"

# Transform patterns:
# 1. "I am a specialized agent" → "YOU MUST perform these exact steps"
# 2. Unordered lists → "STEP N (REQUIRED BEFORE STEP N+1)"
# 3. "Tasks:" → "PRIMARY OBLIGATION - File Creation"
# 4. Passive voice → Active imperatives (should → MUST)
# 5. Flexible formats → "THIS EXACT TEMPLATE (No modifications)"

# Add sections:
# 1. COMPLETION CRITERIA - ALL REQUIRED (explicit checklist)
# 2. WHY THIS MATTERS (enforcement rationale)
# 3. NON-COMPLIANCE CONSEQUENCES (what happens if skipped)

# Validation:
# Score agent file with enforcement rubric (target: 95+/100)
```

### 3. Backward Compatibility Strategy

**Version Detection** (Prevents breaking existing workflows):

```bash
# In each updated command file (after Standard X compliance)

COMMAND_VERSION="2.0"  # Increment on breaking changes
COMMAND_STANDARDS_COMPLIANT=(0 11 14 15 16)  # Standards met

# Detect old checkpoint format and migrate
if [ -f "$CHECKPOINT_FILE" ]; then
  CHECKPOINT_VERSION=$(jq -r '.version // "1.0"' "$CHECKPOINT_FILE")

  if [ "$CHECKPOINT_VERSION" != "$COMMAND_VERSION" ]; then
    echo "Migrating checkpoint from v$CHECKPOINT_VERSION to v$COMMAND_VERSION"
    migrate_checkpoint "$CHECKPOINT_FILE" "$CHECKPOINT_VERSION" "$COMMAND_VERSION"
  fi
fi
```

**Migration Scripts** (One-time conversion for each standard):

```bash
# .claude/scripts/migrate-standard-11-invocations.sh
# Converts documentation-only YAML to imperative invocations

find .claude/commands -name "*.md" -type f | while read cmd; do
  # Detect: ```yaml ... Task { ... } ... ```
  # Transform: **EXECUTE NOW**: USE the Task tool... Task { ... }
  # Validate: grep for imperative markers before Task blocks
done
```

**Deprecation Warnings** (Graceful transition period):

```bash
# In commands using old patterns
if ! check_standard_compliance "Standard 11"; then
  echo "WARNING: This command uses deprecated agent invocation pattern"
  echo "Migration guide: .claude/docs/migrations/standard-11-migration.md"
  echo "This pattern will be removed in v3.0 (2025-12)"
  sleep 2  # Ensure user sees warning
fi
```

**Compatibility Matrix** (Documented in each guide):

```markdown
## Backward Compatibility

| Command Version | Standards Compliance | Checkpoint Format | Agent Protocol |
|-----------------|---------------------|-------------------|----------------|
| v1.0 (legacy)   | None                | v1 (JSON flat)    | Text summaries |
| v2.0 (current)  | 0, 11, 14, 15, 16   | v2 (JSON schema)  | File creation  |
| v3.0 (planned)  | All 16 standards    | v3 (state-based)  | State machine  |

### Migration Paths
- v1.0 → v2.0: Automatic checkpoint migration, manual workflow restart recommended
- v2.0 → v3.0: State-based migration script, checkpoints preserved
```

### 4. Testing Strategy

**Four-Layer Testing Approach**:

**Layer 1: Standards Validation** (Automated, pre-commit)
```bash
# Run all validation scripts
bash .claude/tests/validate_executable_doc_separation.sh      # Standard 14
bash .claude/tests/validate_command_behavioral_injection.sh   # Standard 11
bash .claude/scripts/validate-agent-invocation-pattern.sh     # Standards 0, 0.5

# New validators needed:
bash .claude/tests/validate_library_sourcing_order.sh         # Standard 15
bash .claude/tests/validate_return_code_checks.sh             # Standard 16
bash .claude/tests/validate_execution_enforcement.sh          # Standard 0
```

**Layer 2: Integration Testing** (Command execution)
```bash
# Test each updated command end-to-end
test_command_execution() {
  local cmd="$1"
  local test_input="$2"

  # Execute command with test input
  output=$($cmd "$test_input" 2>&1)
  exit_code=$?

  # Verify success
  if [ $exit_code -ne 0 ]; then
    echo "FAIL: Command exited with code $exit_code"
    return 1
  fi

  # Verify expected artifacts created
  verify_artifacts_created "$cmd" "$test_input"

  # Verify checkpoint updated
  verify_checkpoint_valid "$cmd"

  echo "PASS: $cmd executed successfully"
}

# Test matrix: Each command × (simple/moderate/complex) scenarios
```

**Layer 3: Agent Behavioral Compliance** (Subagent testing)
```bash
# From testing-protocols.md:39-100
test_agent_file_creation_compliance() {
  # Invoke agent with path injection
  # Verify file exists at expected path
  # Verify file is not empty
  # Verify completion signal format correct
}

test_agent_step_structure() {
  # Verify STEP markers in output
  # Verify sequential execution
  # Verify checkpoint reporting
}

# Run for each agent: research-specialist, plan-architect, etc.
```

**Layer 4: Regression Testing** (Prevent breaking existing functionality)
```bash
# Existing test suites continue to pass
bash .claude/tests/run_all_tests.sh

# Specific regression tests for standards compliance
bash .claude/tests/test_orchestration_commands.sh  # Standards 0, 11
bash .claude/tests/test_coordinate_all.sh          # State machine integration
bash .claude/tests/test_agent_validation.sh        # Agent behavioral compliance
```

**Test Success Criteria** (Per tier completion):

- **Tier 1**: 95%+ execution reliability, 100% agent delegation rate
- **Tier 2**: 90%+ test pass rate, all commands have guides
- **Tier 3**: 85%+ coverage on support commands
- **Tier 4**: 100% standards validation pass rate

**Test Automation** (CI/CD integration):

```yaml
# .github/workflows/standards-compliance.yml
name: Standards Compliance Validation

on: [push, pull_request]

jobs:
  validate-standards:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Validate Standard 14 (Executable/Doc Separation)
        run: bash .claude/tests/validate_executable_doc_separation.sh

      - name: Validate Standard 11 (Behavioral Injection)
        run: bash .claude/tests/validate_command_behavioral_injection.sh

      - name: Run Integration Tests
        run: bash .claude/tests/run_all_tests.sh

      - name: Generate Compliance Report
        run: bash .claude/scripts/generate-compliance-report.sh
```

### 5. Migration Timeline (Phased Rollout)

**Phase 1: Foundation (Weeks 1-3)** - Tier 1 Commands
- **Week 1**: Audit `/coordinate`, `/plan`, `/research` against all standards
  - Run compliance checklists
  - Document current gaps
  - Create migration plans per command

- **Week 2**: Apply Standards 0, 11, 15, 16 (reliability-critical)
  - Transform to imperative language (Standard 0)
  - Fix agent invocations (Standard 11)
  - Fix library sourcing order (Standard 15)
  - Add return code checks (Standard 16)
  - Test extensively (all 4 layers)

- **Week 3**: Apply Standard 14, validate Tier 1
  - Create guide files for `/research` (missing)
  - Validate with automated scripts
  - Deploy to production
  - Monitor for regressions

**Phase 2: Execution Layer (Weeks 4-6)** - Tier 2 Commands
- **Week 4**: Audit `/implement`, `/revise`, `/expand`, `/collapse`
  - Focus on Standards 0, 14 (execution + documentation)
  - Leverage patterns proven in Phase 1

- **Week 5**: Apply standards and create guides
  - `/revise` guide (missing)
  - `/expand` and `/collapse` guides (missing)
  - Update `/implement` for latest patterns

- **Week 6**: Validation and deployment
  - Integration testing with Phase 1 commands
  - Checkpoint format compatibility verification
  - Production deployment

**Phase 3: Support Layer (Weeks 7-9)** - Tier 3 Commands
- **Week 7**: Audit `/debug`, `/document`, `/convert-docs`
  - Standards 14, 0.5 focus
  - Document existing patterns

- **Week 8**: Apply standards
  - `/convert-docs` guide (missing)
  - Strengthen agent behavioral files (Standard 0.5)

- **Week 9**: Comprehensive testing
  - Full system integration tests
  - Cross-command workflow testing
  - Performance validation

**Phase 4: Finalization (Weeks 10-12)** - Tier 4 + Certification
- **Week 10**: Audit `/setup`, `/optimize-claude`
  - Minor compliance gap fixes only
  - Documentation updates

- **Week 11**: Full system validation
  - All validation scripts pass
  - All integration tests pass
  - All commands have guides
  - All standards achieved

- **Week 12**: Certification and documentation
  - Generate compliance report
  - Update all documentation
  - Create migration guides for future commands
  - Publish standards compliance matrix

**Rollout Risk Mitigation**:

1. **Per-command branches**: Each command updated in feature branch
2. **Incremental merge**: Merge after validation passes
3. **Rollback capability**: Backup versions preserved
4. **Monitoring**: Track execution metrics post-deployment
5. **User communication**: Deprecation warnings for breaking changes

### 6. Documentation Update Requirements

**Per-Command Documentation** (Standard 14 compliance):

For 5 commands missing guides:
- `/research-command-guide.md` (orchestration patterns, multi-agent coordination)
- `/revise-command-guide.md` (auto-mode, context preservation, plan diff analysis)
- `/expand-command-guide.md` (progressive organization, phase expansion)
- `/collapse-command-guide.md` (consolidation patterns, backup management)
- `/convert-docs-command-guide.md` (format conversion, concurrency)

Guide template sections (from _template-command-guide.md):
1. Overview (Purpose, When to Use, When NOT to Use)
2. Architecture (Design Principles, Workflow Phases, Integration Points)
3. Usage Examples (Basic, Advanced, Edge Cases)
4. Advanced Topics (Performance, Customization, Patterns)
5. Troubleshooting (Common Issues, Symptoms → Causes → Solutions)
6. References (Standards, Patterns, Related Commands)

**Central Standards Documentation**:

Create migration guides:
- `/home/benjamin/.config/.claude/docs/migrations/standard-11-migration.md`
- `/home/benjamin/.config/.claude/docs/migrations/standard-14-migration.md`
- `/home/benjamin/.config/.claude/docs/migrations/standard-15-migration.md`

Update existing standards documentation:
- `command_architecture_standards.md`: Add compliance checklist appendix
- `command-development-guide.md`: Add "Compliance Validation" section
- `testing-protocols.md`: Add "Standards Compliance Testing" section

**Compliance Dashboard** (Real-time visibility):

Create `.claude/docs/compliance/standards-dashboard.md`:

```markdown
# Standards Compliance Dashboard

Last Updated: 2025-11-17

## Overall Compliance: 58% (7/12 commands fully compliant)

### By Command

| Command | Std 0 | Std 0.5 | Std 11 | Std 12 | Std 13 | Std 14 | Std 15 | Std 16 | Status |
|---------|-------|---------|--------|--------|--------|--------|--------|--------|--------|
| /coordinate | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | COMPLIANT |
| /plan | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ? | ? | IN PROGRESS |
| /research | ? | ? | ✓ | ? | ✓ | ✗ | ? | ? | NEEDS AUDIT |
[... remaining commands ...]

### By Standard

| Standard | Compliant Commands | Compliance % |
|----------|-------------------|--------------|
| 0: Execution Enforcement | 8/12 | 67% |
| 11: Imperative Invocation | 10/12 | 83% |
| 14: Exec/Doc Separation | 7/12 | 58% |
| 15: Library Sourcing | 9/12 | 75% |
| 16: Return Code Checks | 7/12 | 58% |

### Milestone Progress

- [x] Phase 1 Complete (Tier 1: 3 commands)
- [ ] Phase 2 In Progress (Tier 2: 1/4 commands)
- [ ] Phase 3 Pending (Tier 3: 0/3 commands)
- [ ] Phase 4 Planned (Tier 4: 0/2 commands)
```

**Agent Behavioral File Documentation**:

Enhance each agent file with compliance metadata:

```markdown
---
compliance:
  standard_0.5_score: 95/100
  last_audit: 2025-11-17
  enforcement_categories_passed: 10/10
  known_gaps: []
---

# Agent Name

[Strengthened behavioral content per Standard 0.5 template]
```

### 7. Risk Mitigation (Fallback Strategies)

**Risk Category 1: Breaking Changes**

*Risk*: Updated commands incompatible with existing workflows
*Probability*: Medium (30%)
*Impact*: High (workflow failures, data loss)

*Mitigation*:
1. **Version detection**: Commands detect old checkpoint format and migrate
2. **Deprecation period**: 4-week warning period before removing old patterns
3. **Rollback scripts**: Automated rollback to previous command version
4. **Compatibility testing**: Test new commands with old checkpoints

*Fallback*:
```bash
# If migration fails, preserve old version
if ! migrate_checkpoint_v1_to_v2 "$CHECKPOINT_FILE"; then
  echo "Migration failed, using legacy mode"
  exec ".claude/commands-v1/${COMMAND_NAME}.md" "$@"
fi
```

**Risk Category 2: Standards Conflicts**

*Risk*: Standard X conflicts with Standard Y in specific command
*Probability*: Low (10%)
*Impact*: Medium (compliance blocked)

*Mitigation*:
1. **Exception documentation**: Document why conflict exists
2. **Standards reconciliation**: Update standards with clarifying examples
3. **Precedence rules**: Establish standard priority (e.g., Standard 0 > Standard 12)

*Fallback*:
- Allow documented exceptions with justification
- Update compliance dashboard to reflect exceptions
- Review exceptions quarterly for resolution

**Risk Category 3: Test Coverage Gaps**

*Risk*: Edge cases not covered by tests, failures in production
*Probability*: Medium (25%)
*Impact*: Medium (runtime failures, user frustration)

*Mitigation*:
1. **Staged rollout**: Deploy to subset of users first
2. **Monitoring**: Track execution metrics (success rate, error rate)
3. **Fast rollback**: Automatic rollback if error rate >5%

*Fallback*:
```bash
# Automatic rollback trigger
if [ "$ERROR_RATE" -gt 5 ]; then
  echo "ERROR: High failure rate detected (${ERROR_RATE}%)"
  echo "Rolling back to previous version"
  git revert HEAD
  git push
fi
```

**Risk Category 4: Resource Constraints**

*Risk*: 12-week timeline too aggressive, quality suffers
*Probability*: Medium (20%)
*Impact*: Medium (incomplete compliance, technical debt)

*Mitigation*:
1. **Flexible timeline**: Allow 2-week buffer per phase
2. **Prioritize critical standards**: Focus on 0, 11, 15, 16 first
3. **Parallel work**: Multiple commands can be audited simultaneously

*Fallback*:
- Extend timeline to 16 weeks if needed
- Deploy partial compliance (critical standards only)
- Document remaining gaps for future phases

**Risk Category 5: Agent Behavioral Regressions**

*Risk*: Strengthened agent files cause unexpected behavior changes
*Probability*: Low (15%)
*Impact*: High (file creation failures, workflow blocks)

*Mitigation*:
1. **A/B testing**: Run old and new agent versions in parallel
2. **Behavioral compliance tests**: Validate file creation rate before deployment
3. **Gradual rollout**: Deploy to one orchestrator at a time

*Fallback*:
```bash
# Agent version selection based on compliance testing
if [ "$AGENT_FILE_CREATION_RATE" -lt 95 ]; then
  echo "WARNING: New agent version underperforming"
  echo "Using previous agent version"
  AGENT_FILE=".claude/agents/${AGENT_NAME}.v1.md"
fi
```

### 8. Success Metrics (Measurement Framework)

**Tier 1 Metrics** (Critical reliability):

1. **Execution Reliability**
   - Measurement: Success rate of command execution
   - Baseline: 85% (current)
   - Target: 95%+
   - Collection: Log all command invocations and exit codes

2. **Agent Delegation Rate**
   - Measurement: % of agent invocations that execute
   - Baseline: 60-90% (varies by command)
   - Target: 100%
   - Collection: Parse command output for Task tool usage

3. **File Creation Rate**
   - Measurement: % of expected artifacts created
   - Baseline: 70% (agents), 100% (commands)
   - Target: 100%
   - Collection: Verify file existence in expected paths

**Tier 2 Metrics** (Quality/maintainability):

4. **Standards Compliance Rate**
   - Measurement: % of commands passing all validation scripts
   - Baseline: 58% (7/12 commands)
   - Target: 100%
   - Collection: Automated validation in CI/CD

5. **Guide Coverage**
   - Measurement: % of commands with complete guide files
   - Baseline: 58% (7/12 commands)
   - Target: 100%
   - Collection: File existence check + section validation

6. **Test Pass Rate**
   - Measurement: % of tests passing in test suite
   - Baseline: 95% (current)
   - Target: 98%+
   - Collection: Test runner output parsing

**Tier 3 Metrics** (User experience):

7. **Meta-Confusion Incidents**
   - Measurement: # of recursive invocation bugs per week
   - Baseline: 2-3 incidents/week (pre-Standard 14)
   - Target: 0 incidents/week
   - Collection: Error log analysis for "Permission denied" on .md files

8. **Context Window Usage**
   - Measurement: Average tokens used per command execution
   - Baseline: 75% (high context usage)
   - Target: <50%
   - Collection: Token counter integration

9. **Error Recovery Time**
   - Measurement: Time from error to workflow resumption
   - Baseline: 15 minutes (manual debugging)
   - Target: <5 minutes (automated recovery)
   - Collection: Timestamp analysis in error logs

**Measurement Infrastructure**:

```bash
# .claude/lib/metrics-collection.sh

log_command_execution() {
  local command="$1"
  local exit_code="$2"
  local timestamp=$(date -Iseconds)

  echo "${timestamp},${command},${exit_code}" >> .claude/metrics/executions.csv
}

log_agent_delegation() {
  local command="$1"
  local agents_invoked="$2"
  local agents_executed="$3"
  local timestamp=$(date -Iseconds)

  echo "${timestamp},${command},${agents_invoked},${agents_executed}" >> .claude/metrics/delegations.csv
}

calculate_delegation_rate() {
  awk -F',' '{invoked+=$3; executed+=$4} END {print (executed/invoked)*100}' .claude/metrics/delegations.csv
}
```

**Reporting Dashboard** (Weekly updates):

```markdown
# Standards Compliance Metrics - Week 5

## Execution Reliability
- Current: 92% (↑7% from baseline)
- Target: 95%
- Status: ON TRACK

## Agent Delegation Rate
- Current: 98% (↑8-38% from baseline)
- Target: 100%
- Status: NEARLY ACHIEVED

## File Creation Rate
- Current: 95% (↑25% from baseline)
- Target: 100%
- Status: ON TRACK

[... additional metrics ...]

## Phase Progress
- Phase 1: COMPLETE (3/3 commands)
- Phase 2: IN PROGRESS (2/4 commands)
- Phase 3: NOT STARTED
- Phase 4: NOT STARTED

Overall Timeline: ON TRACK (Week 5 of 12)
```

**Success Criteria for Phase Completion**:

- **Phase 1 Complete**: Tier 1 metrics all ≥95%
- **Phase 2 Complete**: Tier 1 + Tier 2 metrics ≥90%
- **Phase 3 Complete**: All metrics ≥85%
- **Phase 4 Complete**: 100% standards compliance, all validation scripts pass

## Implementation Guidance

### Quick Start (First Command Migration)

**Recommended First Command**: `/research` (high value, moderate complexity)

**Day 1: Audit**
```bash
# Run compliance checklist
bash .claude/scripts/audit-command-compliance.sh research

# Review output:
# - Current compliance: 6/16 standards
# - Critical gaps: Standards 14 (no guide), 0.5 (weak agent prompts)
# - Estimated effort: 8-12 hours
```

**Day 2: Apply Standards 0, 11, 15, 16**
```bash
# Transform to imperative language
# Fix agent invocations
# Fix library sourcing order
# Add return code checks
# Test execution
```

**Day 3: Create Guide (Standard 14)**
```bash
# Extract documentation from command file
cp .claude/docs/guides/_template-command-guide.md .claude/docs/guides/research-command-guide.md

# Populate sections:
# - Architecture (multi-agent orchestration)
# - Examples (simple/moderate/complex research)
# - Troubleshooting (agent delegation failures, file creation issues)

# Validate
bash .claude/tests/validate_executable_doc_separation.sh
```

**Day 4: Testing and Deployment**
```bash
# Layer 1: Standards validation
bash .claude/tests/validate_command_behavioral_injection.sh

# Layer 2: Integration testing
bash .claude/tests/test_orchestration_commands.sh

# Layer 3: Agent behavioral compliance
bash .claude/tests/test_agent_validation.sh

# Layer 4: Regression testing
bash .claude/tests/run_all_tests.sh

# Deploy if all tests pass
git add .claude/commands/research.md .claude/docs/guides/research-command-guide.md
git commit -m "feat(research): achieve Standards 0, 11, 14, 15, 16 compliance"
```

**Estimated Timeline**: 3-4 days per command (first few), 1-2 days per command (after patterns established)

### Command-Specific Considerations

**Orchestrators** (/coordinate, /research):
- Focus heavily on Standards 0, 11 (agent coordination)
- Phase 0 (Pre-Calculate Paths) critical
- Library sourcing order (Standard 15) critical

**Executors** (/implement, /document):
- Standard 14 (guide creation) high value
- Standard 16 (return code checks) prevents silent failures

**Utilities** (/expand, /collapse, /convert-docs):
- Standards 1-5 (content quality) for consistency
- Standard 13 (project directory detection) for portability

### Continuous Improvement

**Quarterly Reviews**:
- Review standards compliance dashboard
- Identify new gaps from recent command additions
- Update validation scripts for new patterns
- Refine compliance checklists based on learnings

**New Command Checklist** (Prevent regression):
```markdown
# New Command Acceptance Criteria

Before merging new command:
- [ ] All 16 standards validated (automated scripts pass)
- [ ] Guide file created with complete sections
- [ ] Integration tests written and passing
- [ ] Metrics collection integrated
- [ ] Compliance dashboard updated
```

## References

### Standards Documentation
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` - Complete 16-standard specification (lines 1-2572)
- `/home/benjamin/.config/.claude/docs/reference/code-standards.md` - Language-specific and architectural standards (lines 1-84)
- `/home/benjamin/.config/.claude/docs/concepts/directory-organization.md` - Directory structure and file placement (lines 1-276)

### Command Files
- `/home/benjamin/.config/.claude/commands/` - 12 command files analyzed
- `/home/benjamin/.config/.claude/docs/guides/` - 7 existing guide files identified

### Testing Infrastructure
- `/home/benjamin/.config/.claude/tests/` - 90+ test scripts
- `/home/benjamin/.config/.claude/tests/validate_executable_doc_separation.sh` - Standard 14 validation
- `/home/benjamin/.config/.claude/tests/validate_command_behavioral_injection.sh` - Standard 11 validation
- `/home/benjamin/.config/.claude/docs/reference/testing-protocols.md` - Testing standards (lines 1-100)

### Migration Evidence
- command_architecture_standards.md:1686-1701 - Standard 14 migration results for 7 commands
- command_architecture_standards.md:1308-1354 - Standard 11 historical fixes (Specs 438, 495, 057, 497)
- command_architecture_standards.md:2391-2460 - Standard 15 library sourcing fixes (Spec 675)

### Templates
- `/home/benjamin/.config/.claude/docs/guides/_template-executable-command.md` - Executable command template (56 lines)
- `/home/benjamin/.config/.claude/docs/guides/_template-command-guide.md` - Guide file template (171 lines)

### Historical Specifications
- Spec 438 (2025-10-24): /supervise agent delegation fix
- Spec 495 (2025-10-27): /coordinate and /research agent delegation failures
- Spec 057 (2025-10-27): /supervise robustness improvements and fail-fast error handling
- Spec 497: Unified orchestration improvements and validation
- Spec 675 (2025-11-11): Library sourcing order fix
- Spec 698: Critical function return code verification
