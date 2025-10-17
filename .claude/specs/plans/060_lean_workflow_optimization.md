# Lean Workflow Optimization Implementation Plan

## Metadata
- **Date**: 2025-10-16
- **Feature**: Optimize .claude/ commands and agents for lean, efficient workflows
- **Scope**: Commands, agents, templates, output patterns, context optimization
- **Estimated Phases**: 5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - Command verbosity analysis (user context)
  - Agent redundancy audit (user context)
  - AI workflow best practices 2025 (user context)

## Overview

This plan optimizes the .claude/ command and agent system to achieve lean, efficient workflows with minimal console output and reduced token usage. Comprehensive research has identified specific redundancies and optimization opportunities.

**Current State** (Research-Validated):
- **Commands**: 17 files with duplicated tool allowlists (~8,500 words redundant)
- **Checkpoint Management**: Repeated 5 times across commands (~3,000 words)
- **Agent Invocations**: Spec-updater pattern duplicated 6+ times (~1,200 words)
- **Agents**: 17 agents averaging ~490 lines each (8,361 total lines)
- **Output Patterns**: 3 different progress formats, inconsistent completion messages
- **Total Redundancy**: ~14,980 words of duplicated content identified

**Target State**:
- High-impact template extractions completed first (Phase 1.5)
- Tool allowlists, checkpoint patterns, agent invocations consolidated
- Agent prompts reduced 60-70% via template references
- Standardized output patterns across all commands
- Context usage <30% throughout workflows
- Token savings: ~14,980 words (~30% command verbosity reduction)

## Success Criteria
- [ ] All command templates extracted to .claude/templates/
- [ ] Agent prompt sizes reduced by 60-70%
- [ ] Console output follows "summary + link" pattern consistently
- [ ] Context usage maintained <30% in orchestrate workflows
- [ ] All functionality preserved and tested
- [ ] Token savings measured and documented

## Technical Design

### Template System Architecture

**Template Categories**:
1. **Output Templates** (`.claude/templates/output-patterns.md`)
   - Standard success/error formats
   - File notification patterns
   - Progress markers
   - Link formats

2. **Report Templates** (extract from commands)
   - Research report structure (from /report)
   - Debug report structure (from /debug)
   - Refactor report structure (from /refactor)

3. **Agent Invocation Templates** (consolidate existing)
   - Standard Task tool invocation format
   - Error handling patterns
   - Response validation patterns

### Output Pattern Standard

**Minimal Success Pattern**:
```
✓ [Operation] Complete
Artifact: [absolute-path]
Summary: [1-2 line description]
```

**Minimal Error Pattern**:
```
✗ [Operation] Failed
Error: [brief error message]
Details: [path-to-log or additional-context]
```

**Progress Markers** (for long operations):
```
PROGRESS: [Stage] - [Brief status]
```

### Context Optimization Strategy

1. **Aggressive Summarization**: Commands produce minimal output, details available via links
2. **External Memory**: Use artifact files for detailed logs, reference by path
3. **Stream Separation**: Results to stdout, messages to stderr (future enhancement)
4. **Agent Context Limits**: Enforce strict input/output token budgets

## Implementation Phases

### Phase 1: Template Extraction and Creation [COMPLETED]
**Objective**: Extract embedded templates from commands and create standardized output patterns
**Complexity**: Medium
**Dependencies**: []
**Risk**: Low
**Estimated Time**: 2-3 hours

Tasks:
- [x] Create `.claude/templates/output-patterns.md` with standard success/error/progress formats
- [x] Extract report template from `/report` command to `.claude/templates/report-structure.md`
- [x] Extract debug template from `/debug` command to `.claude/templates/debug-structure.md`
- [x] Extract refactor template from `/refactor` command (if exists) to `.claude/templates/refactor-structure.md`
- [x] Update `/report` command to reference template: "See .claude/templates/report-structure.md"
- [x] Update `/debug` command to reference template: "See .claude/templates/debug-structure.md"
- [x] Update `/refactor` command to reference template (if applicable)
- [x] Verify all extracted templates are complete and usable

Testing:
```bash
# Verify template files exist and are readable
ls -la .claude/templates/output-patterns.md
ls -la .claude/templates/report-structure.md
ls -la .claude/templates/debug-structure.md

# Verify commands reference templates correctly
grep -n "templates/" .claude/commands/report.md
grep -n "templates/" .claude/commands/debug.md
```

Expected Outcome:
- 3-4 new template files created
- Command file sizes reduced by ~100-200 lines each
- Templates maintain all structural information

### Phase 1.5: High-Impact Template Extraction [NEW]
**Objective**: Extract highest-redundancy patterns identified in research before agent optimization
**Complexity**: Medium
**Dependencies**: [1]
**Risk**: Low
**Estimated Time**: 3-4 hours

Tasks:
- [ ] Extract tool allowlists from 17 command files
  - [ ] Create `.claude/templates/command-frontmatter.md` with standard allowed-tools YAML
  - [ ] Update implement.md, orchestrate.md, plan.md, report.md, debug.md, document.md, refactor.md (line 2 of each)
  - [ ] Update test.md, test-all.md, revise.md, expand.md, collapse.md, list.md, analyze.md
  - [ ] Update migrate-specs.md, plan-from-template.md, plan-wizard.md
  - [ ] Replace inline allowlists with: "See `.claude/templates/command-frontmatter.md` for standard tool access"
- [ ] Extract checkpoint management pattern from 5 commands
  - [ ] Create `.claude/templates/checkpoint-management-pattern.md`
  - [ ] Extract from implement.md (lines 1166-1230), orchestrate.md (lines 2790-2860)
  - [ ] Update plan.md, debug.md, document.md to reference template
  - [ ] Template includes: save_checkpoint(), load_checkpoint(), checkpoint JSON schema
- [ ] Extract spec-updater invocation pattern from 6 commands
  - [ ] Create `.claude/templates/agent-invocation-spec-updater.md`
  - [ ] Extract from plan.md (lines 514-555), report.md (lines 102-141), orchestrate.md (lines 2730-2760)
  - [ ] Update implement.md, debug.md, document.md to reference template
  - [ ] Template includes: Task YAML structure, operation types, variable reference
- [ ] Extract forward message pattern from 3 commands
  - [ ] Create `.claude/templates/forward-message-complete-pattern.md`
  - [ ] Extract from implement.md (lines 596-625), orchestrate.md (lines 542-599), plan.md (lines 82-161)
  - [ ] Template includes: forward_message() usage, metadata extraction, context reduction workflow
- [ ] Extract complexity evaluation pattern from 4 commands
  - [ ] Create `.claude/docs/complexity-patterns.md` for documentation
  - [ ] Document patterns from implement.md (lines 430-500), plan.md (lines 235-300), orchestrate.md (lines 445-460)
  - [ ] Include threshold calculations, helper function patterns, evaluation workflow

Testing:
```bash
# Verify all new templates exist
ls -la .claude/templates/command-frontmatter.md
ls -la .claude/templates/checkpoint-management-pattern.md
ls -la .claude/templates/agent-invocation-spec-updater.md
ls -la .claude/templates/forward-message-complete-pattern.md
ls -la .claude/docs/complexity-patterns.md

# Verify commands reference templates correctly
grep -n "command-frontmatter" .claude/commands/implement.md
grep -n "checkpoint-management" .claude/commands/orchestrate.md
grep -n "spec-updater" .claude/commands/plan.md

# Count line reductions in key commands
wc -l .claude/commands/implement.md
wc -l .claude/commands/orchestrate.md
wc -l .claude/commands/plan.md
```

Expected Outcome:
- 5 new template/doc files created
- Tool allowlist extracted from 17 files (~8,500 words saved)
- Checkpoint pattern extracted from 5 files (~3,000 words saved)
- Spec-updater pattern extracted from 6 files (~1,200 words saved)
- Forward message pattern extracted from 3 files (~280 words saved)
- Complexity patterns documented (~1,080 words saved)
- **Total Phase 1.5 Savings**: ~14,060 words (28% command verbosity reduction)

### Phase 2: Agent Optimization - Top 3 Verbose Agents [PARTIAL]
**Objective**: Reduce verbosity in doc-converter, spec-updater, and debug-specialist agents by removing redundant tool docs
**Complexity**: High
**Dependencies**: [1, 1.5]
**Risk**: Medium
**Estimated Time**: 3-4 hours

**Research Findings**:
- All agents contain redundant Tool usage instructions (~500 words each)
- Agent invocation examples are duplicated across agents
- Tool access documentation repeated from command files
- Opportunity: Remove tool docs, reference shared template instead

Tasks:
- [x] Audit doc-converter.md (949 lines) for extractable content
- [x] Audit spec-updater.md (855 lines) for extractable content
- [x] Audit debug-specialist.md (632 lines) for extractable content
- [x] Create `.claude/templates/agent-invocation-patterns.md` consolidating Task tool usage examples
- [x] Extract repeated Tool descriptions to `.claude/templates/agent-tool-descriptions.md`
- [ ] Update doc-converter.md to reference shared templates (target: <400 lines, 58% reduction)
  - [ ] Remove redundant Tool usage sections (reference agent-tool-descriptions.md)
  - [ ] Remove duplicated invocation examples (reference agent-invocation-patterns.md)
  - [ ] Preserve core conversion logic and behavioral guidelines
- [ ] Update spec-updater.md to reference shared templates (target: <350 lines, 59% reduction)
  - [ ] Remove redundant Tool sections
  - [ ] Remove duplicated checkpoint management docs (now in Phase 1.5 template)
  - [ ] Preserve artifact lifecycle and gitignore logic
- [ ] Update debug-specialist.md to reference shared templates (target: <250 lines, 60% reduction)
  - [ ] Remove redundant Tool sections
  - [ ] Remove duplicated debugging workflow (extract to shared debug pattern)
  - [ ] Preserve specialized debugging strategies
- [ ] Verify all agent functionality preserved through test invocations

**Note**: Phase 1.5 templates provide foundation for agent optimization. Focus on removing redundant tool documentation and referencing shared patterns.

Testing:
```bash
# Verify size reductions
wc -l .claude/agents/doc-converter.md
wc -l .claude/agents/spec-updater.md
wc -l .claude/agents/debug-specialist.md

# Test agent invocations work correctly
/test .claude/tests/test_command_integration.sh
```

Expected Outcome:
- doc-converter: 949 → ~400 lines (58% reduction)
- spec-updater: 855 → ~350 lines (59% reduction)
- debug-specialist: 632 → ~250 lines (60% reduction)
- Total savings: 1,436 lines from top 3 agents alone

### Phase 3: Agent Optimization - Remaining Agents
**Objective**: Apply optimization patterns to remaining 14 agents, consolidate agent invocation patterns
**Complexity**: High
**Dependencies**: [1.5, 2]
**Risk**: Medium
**Estimated Time**: 4-5 hours

**Research Findings**:
- 37+ Task invocation patterns identified across agents (highly redundant)
- All agents repeat similar Tool usage instructions
- Agent invocation examples could be consolidated to 3-4 standard patterns

Tasks:
- [ ] Create optimization checklist from Phase 2 learnings
- [ ] Consolidate agent invocation patterns
  - [ ] Analyze 37+ Task invocation examples across agents
  - [ ] Create 3-4 standard invocation templates in agent-invocation-patterns.md
  - [ ] Include: research agent pattern, implementation agent pattern, analysis agent pattern, utility agent pattern
- [ ] Optimize github-specialist.md (570 lines → target <250 lines)
  - [ ] Remove Tool docs (reference shared template)
  - [ ] Remove redundant invocation examples
- [ ] Optimize plan-architect.md (538 lines → target <220 lines)
  - [ ] Remove Tool docs and complexity calculation redundancy
- [ ] Optimize metrics-specialist.md (460 lines → target <200 lines)
  - [ ] Remove Tool docs and checkpoint management redundancy
- [ ] Optimize code-writer.md (441 lines → target <190 lines)
  - [ ] Remove Tool docs
- [ ] Optimize test-specialist.md (439 lines → target <190 lines)
  - [ ] Remove Tool docs
- [ ] Optimize research-specialist.md → target <150 lines
  - [ ] Remove Tool docs, consolidate research patterns
- [ ] Optimize doc-writer.md → target <150 lines
- [ ] Optimize code-reviewer.md → target <150 lines
- [ ] Optimize complexity-estimator.md → target <150 lines
  - [ ] Remove complexity calculation redundancy (now in Phase 1.5 template)
- [ ] Optimize expansion-specialist.md → target <150 lines
- [ ] Optimize collapse-specialist.md → target <150 lines
- [ ] Optimize plan-expander.md → target <150 lines
- [ ] Update agents/README.md with template references and optimization notes
- [ ] Verify all agent functionality preserved through testing

Testing:
```bash
# Verify all agents reduced in size
for agent in .claude/agents/*.md; do
  echo "$(basename $agent): $(wc -l < $agent) lines"
done | grep -v README

# Run comprehensive agent integration tests
/test-all
```

Expected Outcome:
- All agents reference shared templates
- Average agent size: ~150-200 lines (60-70% reduction from ~490 avg)
- Total agent lines: 8,361 → ~2,500-2,800 (67-70% reduction)
- No functionality lost

### Phase 4: Output Pattern Standardization
**Objective**: Update all commands to use consistent minimal output pattern based on research findings
**Complexity**: Medium
**Dependencies**: [1, 1.5]
**Risk**: Low
**Estimated Time**: 3-4 hours

**Research Findings**:
- **Progress Markers**: 3 different formats found
  - implement.md: `PROGRESS: Phase X - description`
  - orchestrate.md: `PROGRESS: [phase] - [action_description]`
  - debug.md: Similar but slightly different format
- **Completion Messages**: Each command has custom format (inconsistent)
  - implement.md lines 1230+: Verbose completion message
  - orchestrate.md lines 1890+: Different format, similar content
  - plan.md: No explicit completion message format
- **Context Metrics**: Inconsistent reporting (95% vs 99.75% vs 92-95%)

Tasks:
- [ ] Audit current output patterns across all commands (document findings)
- [ ] Create output pattern test script: `.claude/tests/test_output_patterns.sh`
- [ ] Standardize progress marker format
  - [ ] Define unified format in output-patterns.md: `PROGRESS: [component] - [action] - [context]`
  - [ ] Update implement.md to use standard format
  - [ ] Update orchestrate.md to use standard format
  - [ ] Update debug.md to use standard format
  - [ ] Update plan.md, document.md, refactor.md to use standard format
- [ ] Standardize completion message format
  - [ ] Create completion-message-template.md with Unicode box-drawing
  - [ ] Template variables: [DURATION], [ARTIFACTS], [METRICS]
  - [ ] Update implement.md (lines 1230+) to use template
  - [ ] Update orchestrate.md (lines 1890+) to use template
  - [ ] Update plan.md to add completion message using template
  - [ ] Update all commands to use consistent completion format
- [ ] Standardize context metrics reporting
  - [ ] Define standard calculation method in context-metrics-standard.md
  - [ ] Update implement.md (lines 596-625): standardize "95% context reduction" reporting
  - [ ] Update orchestrate.md (lines 542-599): standardize "99.75% context reduction" reporting
  - [ ] Update plan.md (lines 82-161): standardize "92-95% reduction" reporting
  - [ ] All commands use same metrics format and calculation
- [ ] Update minimal success pattern for all commands
  - [ ] Format: "✓ [Operation] Complete\nArtifact: [absolute-path]\nSummary: [1-2 line description]"
  - [ ] Update /report, /debug, /plan, /expand, /collapse, /test, /test-all
- [ ] Add stderr separation documentation (for future implementation)
- [ ] Update CLAUDE.md with standard output pattern documentation

Testing:
```bash
# Test output patterns
.claude/tests/test_output_patterns.sh

# Visual verification of each command
/plan "test feature" | head -20
/report "test topic" | head -20
```

Expected Outcome:
- All commands follow standardized output pattern
- Console output reduced by 70-80%
- File paths always provided for detailed information
- Consistent user experience across all commands

### Phase 5: Context Optimization and Validation
**Objective**: Ensure context usage stays <30% throughout workflows and measure improvements
**Complexity**: Medium
**Dependencies**: [1, 1.5, 2, 3, 4]
**Risk**: Low
**Estimated Time**: 2-3 hours

Tasks:
- [ ] Create context monitoring utility: `.claude/lib/context-monitor.sh`
- [ ] Add context usage tracking to `/orchestrate` workflow phases
- [ ] Add context warnings when approaching 30% threshold
- [ ] Test full `/orchestrate` workflow with complex feature
- [ ] Measure token savings from template extraction
- [ ] Measure token savings from agent optimization
- [ ] Measure output reduction (line count before/after)
- [ ] Document all measurements in summary report
- [ ] Update CLAUDE.md with context optimization guidelines
- [ ] Create optimization summary: `specs/summaries/060_optimization_results.md`

Testing:
```bash
# Full workflow test with context monitoring
/orchestrate "Add user authentication feature" --dry-run

# Verify context stays under 30%
grep "Context usage" .claude/data/logs/orchestrate-*.log

# Run complete test suite
/test-all
```

Expected Outcome:
- Context usage measured and validated <30%
- Token savings: 4,600+ per workflow documented
- Output reduction: 70-80% documented
- All tests passing
- Complete optimization metrics in summary report

## Testing Strategy

### Unit Testing
- Template extraction: Verify templates are complete and referenced correctly
- Agent updates: Test each agent invocation independently
- Output patterns: Verify format compliance

### Integration Testing
- Command workflows: Test full command execution paths
- Agent coordination: Test multi-agent workflows
- Template references: Verify all references resolve correctly

### Performance Testing
- Context usage monitoring throughout /orchestrate workflow
- Token counting before/after optimization
- Output line counting for reduction metrics

### Regression Testing
- All existing tests must pass
- No functionality lost
- Backward compatibility for user workflows

## Optimization Targets

### Token Savings Breakdown
1. **Template Extraction**: ~4,600 tokens per workflow
   - Report command: ~1,500 tokens
   - Debug command: ~1,800 tokens
   - Refactor command: ~1,300 tokens

2. **Agent Optimization**: ~5,800 tokens per agent invocation
   - Top 3 agents: ~1,900 tokens each
   - Remaining 14 agents: ~300-400 tokens each
   - Average workflow uses 3-5 agents: ~17,400-29,000 token savings

3. **Total Per Workflow**: ~22,000-33,600 tokens saved

### Size Reduction Targets
1. **Commands**:
   - /report: 302 → ~150 lines (50% reduction)
   - /debug: 411 → ~200 lines (51% reduction)
   - /refactor: estimate ~200 lines (50% reduction)

2. **Agents**:
   - Total: 8,361 → ~2,500-2,800 lines (67-70% reduction)
   - Average: 490 → ~150-200 lines per agent

3. **Output**:
   - Console output: 70-80% reduction
   - Essential information retained, details in files

## Context Optimization Techniques

### 1. Progressive Disclosure
- Default: Minimal output (summary + link)
- Verbose flag: Full details (future enhancement)
- On-demand: User reads linked file for details

### 2. External Memory Pattern
- Detailed logs: Written to artifact files
- Command output: Path to detailed log
- Agent responses: Summarized to essential info

### 3. Template References
- Commands: Reference external templates instead of embedding
- Agents: Reference shared patterns instead of duplicating
- Documentation: Link to templates instead of inline examples

### 4. Stream Separation (Future)
- stdout: Results and file paths only
- stderr: Progress messages and status updates
- Allows filtering for scripting

## Dependencies
- .claude/lib/artifact-operations.sh (existing)
- .claude/lib/template-integration.sh (existing)
- .claude/templates/ directory (existing)

## Risk Mitigation

### Medium Risk: Agent Functionality Loss
- **Mitigation**: Test each agent after optimization
- **Validation**: Run all integration tests
- **Rollback**: Keep original agent files in .claude/agents/backup/

### Low Risk: Template Reference Errors
- **Mitigation**: Verify all paths are correct
- **Validation**: Grep for broken references
- **Fix**: Update paths if directory structure changes

### Low Risk: Output Pattern Inconsistency
- **Mitigation**: Create output pattern test script
- **Validation**: Automated format checking
- **Fix**: Quick regex-based corrections

## Documentation Requirements

### Updates Required
1. **CLAUDE.md**: Add output pattern standard section
2. **.claude/templates/README.md**: Document new templates
3. **.claude/commands/README.md**: Update with output patterns
4. **.claude/agents/README.md**: Document optimization approach
5. **Optimization Summary**: Create detailed results report

### New Documentation
1. `.claude/templates/output-patterns.md` - Standard formats
2. `.claude/templates/agent-invocation-patterns.md` - Task tool patterns
3. `.claude/templates/agent-tool-descriptions.md` - Shared tool docs
4. `specs/summaries/060_optimization_results.md` - Metrics and results

## Notes

### Implementation Strategy
- Start with template extraction (lowest risk)
- Optimize agents incrementally with testing
- Standardize output patterns across all commands
- Validate context optimization in real workflows

### Measurement Criteria
All optimizations will be measured against baseline:
- Token usage per workflow
- Agent prompt sizes
- Console output line counts
- Context usage percentages

### Backward Compatibility
No breaking changes to user-facing command interfaces:
- Command arguments unchanged
- Agent capabilities unchanged
- Output format enhanced (more concise)
- Templates provide same structural guidance

## Spec Updater Integration

### Phase Completion Checklist
When each phase completes:
- [ ] Update this plan with completion status
- [ ] Create checkpoint for phase completion
- [ ] Run tests and document results
- [ ] Commit changes with phase-specific commit message

### Final Summary
When all phases complete:
- [ ] Invoke spec-updater agent to create implementation summary
- [ ] Summary should include:
  - All metrics (token savings, size reductions, output reduction)
  - Links to modified commands and agents
  - Links to new templates created
  - Testing results and validation
  - Performance improvements measured
- [ ] Summary location: `specs/summaries/060_lean_workflow_optimization.md`

## Revision History

### 2025-10-17 - Revision 1: Research-Based Optimization
**Changes**:
- Added new Phase 1.5: High-Impact Template Extraction (5 major extractions)
- Updated Overview with research-validated current state and specific redundancy metrics
- Updated Phase 2 dependencies to include Phase 1.5, added specific redundancy removal tasks
- Updated Phase 3 dependencies and tasks with agent invocation pattern consolidation
- Updated Phase 4 with specific output pattern issues and standardization targets
- Updated Phase 5 dependencies to include Phase 1.5

**Reason**:
Comprehensive codebase research identified specific high-impact optimization opportunities:
- ~14,980 words of redundant content across commands/agents
- Tool allowlists duplicated across 17 files
- Checkpoint management patterns repeated 5 times
- Spec-updater invocations repeated 6+ times
- Inconsistent output patterns across 8+ commands

**Research Findings Used**:
- Top 5 verbosity patterns with file:line references
- Top 3 redundancy issues with affected files
- Recommended template extractions with specific sources
- Output pattern standardization opportunities

**Modified Phases**:
- Phase 1: Already completed (no changes)
- Phase 1.5: NEW - High-impact template extraction before agent optimization
- Phase 2: Updated dependencies [1, 1.5], added specific redundancy removal subtasks
- Phase 3: Updated dependencies [1.5, 2], added agent invocation pattern consolidation
- Phase 4: Updated dependencies [1, 1.5], added specific output pattern fixes
- Phase 5: Updated dependencies to include [1.5]

**Priority Rationale**:
Phase 1.5 extracts the highest-redundancy patterns (~14,060 words) before agent optimization, providing:
1. Immediate 28% command verbosity reduction
2. Foundation templates for Phase 2/3 agent optimization
3. Clear reference patterns for output standardization in Phase 4
4. Reduced risk by validating template approach before agent changes
