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

This plan optimizes the .claude/ command and agent system to achieve lean, efficient workflows with minimal console output and reduced token usage. Current analysis shows significant opportunities for improvement:

**Current State**:
- Commands embed 100-200+ line templates inline (report, debug, refactor)
- 17 agents averaging ~490 lines each (8,361 total lines)
- Verbose console output mixing essential info with procedural details
- Repeated agent templates (37+ Task invocation patterns)
- No standardized output pattern

**Target State**:
- Templates extracted to .claude/templates/ for reuse
- Agent prompts reduced 60-70% via template references
- Standardized "summary + link" output pattern
- Context usage <30% throughout workflows
- Token savings: 4,600+ per workflow

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

### Phase 2: Agent Optimization - Top 3 Verbose Agents
**Objective**: Reduce verbosity in doc-converter, spec-updater, and debug-specialist agents
**Complexity**: High
**Dependencies**: [1]
**Risk**: Medium
**Estimated Time**: 3-4 hours

Tasks:
- [ ] Audit doc-converter.md (949 lines) for extractable content
- [ ] Audit spec-updater.md (855 lines) for extractable content
- [ ] Audit debug-specialist.md (632 lines) for extractable content
- [ ] Create `.claude/templates/agent-invocation-patterns.md` consolidating Task tool usage examples
- [ ] Extract repeated Tool descriptions to `.claude/templates/agent-tool-descriptions.md`
- [ ] Update doc-converter.md to reference shared templates (target: <400 lines, 58% reduction)
- [ ] Update spec-updater.md to reference shared templates (target: <350 lines, 59% reduction)
- [ ] Update debug-specialist.md to reference shared templates (target: <250 lines, 60% reduction)
- [ ] Verify all agent functionality preserved

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
**Objective**: Apply optimization patterns to remaining 14 agents
**Complexity**: High
**Dependencies**: [2]
**Risk**: Medium
**Estimated Time**: 4-5 hours

Tasks:
- [ ] Create optimization checklist from Phase 2 learnings
- [ ] Optimize github-specialist.md (570 lines → target <250 lines)
- [ ] Optimize plan-architect.md (538 lines → target <220 lines)
- [ ] Optimize metrics-specialist.md (460 lines → target <200 lines)
- [ ] Optimize code-writer.md (441 lines → target <190 lines)
- [ ] Optimize test-specialist.md (439 lines → target <190 lines)
- [ ] Optimize research-specialist.md → target <150 lines
- [ ] Optimize doc-writer.md → target <150 lines
- [ ] Optimize code-reviewer.md → target <150 lines
- [ ] Optimize complexity-estimator.md → target <150 lines
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
**Objective**: Update all commands to use consistent minimal output pattern
**Complexity**: Medium
**Dependencies**: [1]
**Risk**: Low
**Estimated Time**: 3-4 hours

Tasks:
- [ ] Audit current output patterns across all commands
- [ ] Create output pattern test script: `.claude/tests/test_output_patterns.sh`
- [ ] Update `/report` command output to "✓ Report Complete\nArtifact: [path]\nSummary: [summary]"
- [ ] Update `/debug` command output to minimal pattern
- [ ] Update `/plan` command output to minimal pattern
- [ ] Update `/implement` command to use PROGRESS markers consistently
- [ ] Update `/orchestrate` command output (already has good PROGRESS markers)
- [ ] Update `/expand` command output to minimal pattern
- [ ] Update `/collapse` command output to minimal pattern
- [ ] Update `/test` and `/test-all` command outputs
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
**Dependencies**: [1, 2, 3, 4]
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
