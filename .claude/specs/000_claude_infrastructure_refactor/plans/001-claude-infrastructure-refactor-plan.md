# .claude/ Infrastructure Refactor Implementation Plan

## Metadata
- **Date**: 2025-12-01
- **Feature**: Systematic refactor of .claude/ infrastructure aligned with Anthropic 2025 best practices
- **Scope**: Context management, example expansion, XML structure adoption, library consolidation, documentation optimization
- **Estimated Phases**: 10
- **Estimated Hours**: 52-66 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 185.0
- **Research Reports**:
  - [Infrastructure Refactor Analysis](../reports/001-infrastructure-refactor-analysis.md)
  - [Comprehensive Anthropic Best Practices Synthesis](../../989_no_name_error/reports/003-research-the-information-provided-in.md)

## Anthropic Documentation Sources

These official Anthropic resources inform the best practices implemented in this plan:

1. [Prompt Engineering Overview](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview) - Core techniques and sequencing
2. [System Prompts (Role Prompting)](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/system-prompts) - Role definition and design strategy
3. [Effective Context Engineering for AI Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) - Context engineering principles, compaction, sub-agents
4. [Long Context Prompting Tips](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/long-context-tips) - Document placement, quote extraction
5. [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) - Session management, progress tracking
6. [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices) - CLAUDE.md usage, structured workflows

## Overview

This plan implements a systematic refactor of the .claude/ directory infrastructure to align with Anthropic's 2025 best practices while maximizing efficiency and reducing complexity. The infrastructure currently scores 88/100 against Anthropic standards with strong foundations in hierarchical agents, hard barriers, and tool minimalism. This refactor targets a 95/100 alignment score through strategic improvements in context compaction, progressive disclosure, example coverage, XML structure, and library consolidation.

**Key Objectives**:
1. Implement LLM-based context compaction for multi-iteration workflows (40-60% context reduction)
2. Expand few-shot examples across commands from 1-2 to 3-4 diverse examples
3. Refine tool descriptions with detailed usage guidance (10-15% error reduction)
4. Adopt XML tag structure for clearer prompt formatting
5. Consolidate library files from 54 to ~45 files (16% reduction)
6. Optimize documentation structure (20-30% file reduction)
7. Add structured note-taking for long-running workflows
8. Implement progress completion estimates for better UX

## Research Summary

### Anthropic 2025 Best Practices (from report 003)

**Core Principles**:
- **Chain-of-Thought**: "Often Claude will respond more accurately if you simply tell it to think step by step"
- **Few-Shot Prompting**: "Providing examples is a well known best practice that Anthropic continues to strongly advise" (3-4 diverse examples recommended)
- **XML Tags**: "Templates often place variables between XML tags... providing a clear structure"
- **Context Compaction**: "Take a conversation nearing context limit, summarize contents, and reinitiate new context window with summary"
- **Sub-Agent Architectures**: "Main agent coordinates while subagents return condensed summaries (1,000-2,000 tokens)"
- **Tool Design**: "One of the most common failure modes is bloated tool sets... minimize functional overlap and ambiguity"

**Key Techniques**:
- Structured note-taking for persistent memory outside context window
- Just-in-time path retrieval vs. pre-loading all paths
- Quote extraction to reduce hallucination
- Document placement (context above instructions for 30K+ tokens)

### Current Infrastructure Assessment (from report 001)

**Strengths** (95-100/100):
- Hierarchical agent architecture with metadata-only passing (95% context reduction)
- Hard barrier pattern with pre-calculation and validation (100/100)
- Tool design minimalism with no functional overlap (95/100)
- Step-by-step reasoning with checkpoints (95/100)

**Improvement Areas** (65-85/100):
- Context compaction: Iteration-based persistence exists but no LLM summarization (75/100)
- Few-shot examples: 1-2 examples vs. recommended 3-4 (85/100)
- Progressive disclosure: Paths pre-loaded instead of just-in-time (65/100)
- XML structure: Uses Markdown headers instead of XML tags (90/100)

**Infrastructure Metrics**:
- Commands: 16 files, 684KB (largest: build.md at 1932 lines)
- Agents: 29 files, 608KB (largest: plan-architect.md at 1239 lines)
- Libraries: 54 files, 1.1MB (consolidation opportunity)
- Documentation: 492 markdown files, 3.6MB (optimization opportunity)

### Prioritized Improvements

**High Impact, Low-Medium Effort (Phase 1)**:
1. Refine tool descriptions (Opportunity 2C) - High impact, 1 phase
2. Expand few-shot examples (Opportunity 2B) - Medium impact, 1-2 phases
3. Structured note-taking (Opportunity 1B) - High impact, 1-2 phases
4. Progress completion estimates (Opportunity 4A) - Low impact (UX), 1 phase

**High Impact, Medium Effort (Phase 2)**:
1. Context compaction (Opportunity 1A) - High impact, 2-3 phases
2. XML tag structure (Opportunity 2A) - Medium impact, 2-3 phases
3. Pre-flight validation (Opportunity 4B) - Low impact, 1-2 phases
4. Layered role specificity (Opportunity 4C) - Low impact, 1 phase

**Medium Impact, Medium-High Effort (Phase 3)**:
1. Library consolidation (Opportunity 3A) - Medium impact, 3-4 phases
2. Documentation optimization (Opportunity 3B) - Medium impact, 2-3 phases
3. Just-in-time path retrieval (Opportunity 1C) - Medium impact, 2-3 phases

## Success Criteria

- [ ] Context compaction reduces multi-iteration context usage from 88% to <70% (25% improvement)
- [ ] Tool description refinement reduces tool selection errors by 10-15%
- [ ] Few-shot example expansion reduces edge case errors by 15-20%
- [ ] Library consolidation reduces file count from 54 to ~45 (16% reduction)
- [ ] Documentation optimization reduces files from 492 to 350-400 (20-30% reduction)
- [ ] Overall Anthropic alignment improves from 88/100 to 95/100
- [ ] All changes maintain backward compatibility during transitions
- [ ] Comprehensive testing validates functionality across all commands
- [ ] Standards documentation updated to reflect new patterns
- [ ] Zero regression in existing command functionality

## Technical Design

### Architecture

**Three-Phase Implementation Strategy**:

**Phase 1: Quick Wins (4-6 weeks)**
- Tool description refinement across all agent behavioral files
- Few-shot example expansion for high-use commands (/research, /plan, /build) with quote-based research pattern
- Structured note-taking implementation (NOTES.md pattern)
- Progress completion estimates in progress markers

**Phase 2: Context Management (6-8 weeks)**
- Context compaction agent creation and integration into /build iteration loop
- XML tag structure templates with document placement optimization and migration to high-priority commands
- Pre-flight validation library with machine-readable feature lists and integration
- Enhanced layered role specificity in system prompts (all 29 agents)

**Phase 3: Infrastructure Consolidation (8-12 weeks)**
- Library consolidation (plan libraries, workflow libraries, artifact libraries)
- Documentation structure optimization (archive audit, guide consolidation)
- Just-in-time path retrieval (optional - defer if time constrained)

### Context Compaction Design

**Compaction Agent Pattern**:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Compact iteration ${ITERATION} context for next cycle"
  prompt: "
    <background_information>
    You are compacting context for a long-running build workflow.
    This enables the next iteration to start with a clean, focused context window.
    </background_information>

    <input>
    Read the implementation summary from iteration ${ITERATION}:
    ${CONTINUATION_CONTEXT}
    </input>

    <instructions>
    Create a high-fidelity summary preserving:
    - Architectural decisions made
    - Unresolved issues or blockers
    - Implementation details critical for next iteration
    - Phase completion status

    Discard:
    - Redundant tool outputs
    - Verbose debug information
    - Completed task details (keep only status)

    Output: Condensed summary (<2000 tokens) for iteration $((ITERATION + 1))
    </instructions>
  "
}
```

**Integration Point**: After iteration completion in /build command, before next iteration.

**Expected Benefit**: 40-60% context reduction per iteration with high-fidelity preservation.

### XML Tag Structure Pattern

**Template Format**:
```markdown
Task {
  prompt: "
    <background_information>
    [Role and workflow context]
    </background_information>

    <input_contract>
      <plan_path>$PLAN_FILE</plan_path>
      <topic_path>$TOPIC_PATH</topic_path>
      <iteration>$ITERATION</iteration>
    </input_contract>

    <instructions>
    [Step-by-step execution instructions]
    </instructions>

    <expected_output>
    [Return signal format]
    </expected_output>
  "
}
```

**Migration Strategy**: Start with new commands, gradually migrate high-priority existing commands.

### Structured Note-Taking Pattern

**NOTES.md Format**:
```markdown
# Workflow Notes: [Topic Name]

## Iteration 1 (Date: YYYY-MM-DD)
- **Architecture Decision**: [Decision made and rationale]
- **Blocker**: [Issue preventing progress]
- **Finding**: [Discovery during implementation]
- **Next**: [Next steps for continuation]

## Iteration 2 (Date: YYYY-MM-DD)
- **Resolved**: [Previous blocker resolution]
- **New Finding**: [Additional discovery]
- **Next**: [Updated next steps]
```

**Integration Point**: Workflow initialization creates NOTES.md, agents append notes incrementally.

### Library Consolidation Strategy

**Target Consolidations**:

1. **Plan Libraries** (7 files → 3 files):
   - Merge: `plan-parsing.sh`, `plan-core-bundle.sh`, `checkbox-utils.sh` → `plan-operations.sh`
   - Merge: `auto-analysis-utils.sh`, `plan-complexity-classifier.sh` → `plan-analysis.sh`
   - Keep: `topic-decomposition.sh` (distinct purpose)

2. **Workflow Libraries** (6 files → 3 files):
   - Merge: `workflow-init.sh`, `workflow-initialization.sh` → `workflow-setup.sh` (redundant)
   - Merge: `context-pruning.sh`, `metadata-extraction.sh` → `context-management.sh`
   - Keep: `workflow-state-machine.sh`, `checkpoint-utils.sh` (core infrastructure)

3. **Artifact Libraries** (3 files → 2 files):
   - Merge: `artifact-registry.sh`, `template-integration.sh` → `artifact-management.sh`

**Total Reduction**: 54 → 45 library files (16% reduction)

**Backward Compatibility**: Maintain shims during transition period.

### Risk Mitigation

**High-Risk Changes**:
- **Library Consolidation**: Comprehensive dependency analysis before consolidation, backward compatibility shims, extensive testing
- **Command Size Normalization**: Deferred to future (Phase 4) due to high effort, low priority

**Medium-Risk Changes**:
- **XML Tag Structure**: Start with new commands, gradual migration, maintain Markdown fallback support
- **JIT Path Retrieval**: Robust error handling, fallback to pre-loaded paths on failure

**Low-Risk Changes**:
- **Tool Description Refinement**: Additive change only, review for accuracy
- **Few-Shot Examples**: Additive examples, test for correctness
- **Structured Note-Taking**: Optional feature, graceful degradation if missing
- **Context Compaction**: Test compaction fidelity, fallback to full context on failure

## Implementation Phases

### Phase 1: Tool Description Refinement [NOT STARTED]
dependencies: []

**Objective**: Refine tool descriptions across all agent behavioral files with detailed usage guidance to reduce tool selection errors by 10-15%.

**Complexity**: Low

**Tasks**:
- [ ] Audit existing tool descriptions in all 29 agent behavioral files
- [ ] Create tool description refinement template with examples (file: `.claude/docs/reference/tool-description-template.md`)
- [ ] Refine research-specialist.md tool descriptions (file: `.claude/agents/research-specialist.md`)
- [ ] Refine plan-architect.md tool descriptions (file: `.claude/agents/plan-architect.md`)
- [ ] Refine implementer-coordinator.md tool descriptions (file: `.claude/agents/implementer-coordinator.md`)
- [ ] Refine debug-specialist.md tool descriptions (file: `.claude/agents/debug-specialist.md`)
- [ ] Refine spec-updater.md tool descriptions (file: `.claude/agents/spec-updater.md`)
- [ ] Refine remaining 24 agent behavioral files with enhanced tool descriptions
- [ ] Update command authoring standards with tool description requirements (file: `.claude/docs/reference/standards/command-authoring.md`)

**Testing**:
```bash
# Verify all agent behavioral files have enhanced tool descriptions
grep -r "### Tool Access" .claude/agents/*.md | wc -l
# Expected: 29 matches

# Verify tool description format (should include use cases, parameters, examples)
grep -A 10 "### Tool Access" .claude/agents/research-specialist.md
# Verify enhanced format present

# Test tool selection accuracy with refined descriptions
# Run sample workflows and log tool selection decisions
bash .claude/tests/integration/test_tool_selection_accuracy.sh
```

**Expected Duration**: 6-8 hours

### Phase 2: Few-Shot Example Expansion and Quote-Based Research Pattern [NOT STARTED]
dependencies: []

**Objective**: Expand few-shot examples from 1-2 to 3-4 diverse examples covering standard, edge, error, and advanced cases to reduce edge case errors by 15-20%. Implement quote-based research pattern to reduce hallucination and improve research quality.

**Complexity**: Medium

**Tasks**:
- [ ] Create few-shot example expansion guide with standard/edge/error/advanced template (file: `.claude/docs/guides/development/few-shot-example-guide.md`)
- [ ] Create quote-based research pattern documentation (file: `.claude/docs/concepts/patterns/quote-based-research.md`)
- [ ] Implement two-stage research pattern in research-specialist agent: Stage 1 (extract quotes), Stage 2 (synthesize analysis) (file: `.claude/agents/research-specialist.md`)
- [ ] Expand /research command examples to 3-4 examples including quote extraction example (file: `.claude/commands/research.md`)
- [ ] Expand /plan command examples to 3-4 examples (file: `.claude/commands/plan.md`)
- [ ] Expand /build command examples to 3-4 examples (file: `.claude/commands/build.md`)
- [ ] Expand /debug command examples to 3-4 examples (file: `.claude/commands/debug.md`)
- [ ] Expand /repair command examples to 3-4 examples (file: `.claude/commands/repair.md`)
- [ ] Expand /expand command examples to 3-4 examples (file: `.claude/commands/expand.md`)
- [ ] Expand /collapse command examples to 3-4 examples (file: `.claude/commands/collapse.md`)
- [ ] Expand /revise command examples to 3-4 examples (file: `.claude/commands/revise.md`)
- [ ] Expand /errors command examples to 3-4 examples (file: `.claude/commands/errors.md`)
- [ ] Update command authoring standards with 3-4 example requirement and quote-based research guidance (file: `.claude/docs/reference/standards/command-authoring.md`)

**Testing**:
```bash
# Verify each command has 3-4 examples
for cmd in research plan build debug repair expand collapse revise errors; do
  count=$(grep -c "^\*\*Example" .claude/commands/$cmd.md)
  echo "$cmd: $count examples"
  [[ $count -ge 3 ]] || echo "WARNING: $cmd has fewer than 3 examples"
done

# Test quote-based research pattern with large documentation
bash .claude/tests/integration/test_quote_based_research.sh

# Verify quote extraction reduces hallucination (compare before/after)
bash .claude/tests/agents/test_research_hallucination_rate.sh

# Test edge case handling with expanded examples
bash .claude/tests/integration/test_edge_case_handling.sh

# Verify examples cover standard, edge, error, and advanced cases
grep -A 5 "Examples" .claude/commands/research.md
```

**Expected Duration**: 10-12 hours

### Phase 3: Structured Note-Taking Implementation [NOT STARTED]
dependencies: []

**Objective**: Implement persistent NOTES.md files for long-running workflows to improve context recovery and debugging.

**Complexity**: Low

**Tasks**:
- [ ] Create structured note-taking pattern documentation (file: `.claude/docs/concepts/patterns/structured-note-taking.md`)
- [ ] Create NOTES.md template (file: `.claude/lib/templates/NOTES_template.md`)
- [ ] Add notes file creation to workflow initialization (file: `.claude/lib/workflow/workflow-init.sh`)
- [ ] Update research-specialist to append notes (file: `.claude/agents/research-specialist.md`)
- [ ] Update plan-architect to append notes (file: `.claude/agents/plan-architect.md`)
- [ ] Update implementer-coordinator to append notes incrementally (file: `.claude/agents/implementer-coordinator.md`)
- [ ] Update debug-specialist to append debugging notes (file: `.claude/agents/debug-specialist.md`)
- [ ] Add notes file reading to workflow resume logic (file: `.claude/lib/workflow/workflow-state-machine.sh`)
- [ ] Update command authoring standards with note-taking pattern (file: `.claude/docs/reference/standards/command-authoring.md`)

**Testing**:
```bash
# Verify NOTES.md template exists
test -f .claude/lib/templates/NOTES_template.md || echo "ERROR: Template missing"

# Test notes file creation during workflow initialization
bash .claude/tests/lib/test_workflow_init_notes.sh

# Test notes appending in long-running workflows
bash .claude/tests/integration/test_notes_persistence.sh

# Verify notes format and content after sample workflow
cat .claude/specs/test_topic/NOTES.md
```

**Expected Duration**: 4-6 hours

### Phase 4: Progress Completion Estimates [NOT STARTED]
dependencies: []

**Objective**: Add phase numbers and percentage completion to progress markers for better user visibility into workflow duration.

**Complexity**: Low

**Tasks**:
- [ ] Update progress marker template in research-specialist.md with completion estimates (file: `.claude/agents/research-specialist.md`)
- [ ] Update progress marker template in plan-architect.md with phase numbers (file: `.claude/agents/plan-architect.md`)
- [ ] Update progress marker template in implementer-coordinator.md with percentage complete (file: `.claude/agents/implementer-coordinator.md`)
- [ ] Update progress marker template in debug-specialist.md with completion tracking (file: `.claude/agents/debug-specialist.md`)
- [ ] Update output formatting standards with enhanced progress format (file: `.claude/docs/reference/standards/output-formatting.md`)
- [ ] Test enhanced progress markers in sample workflows

**Testing**:
```bash
# Verify progress markers include phase numbers and percentages
bash .claude/tests/integration/test_research_command.sh 2>&1 | grep "PROGRESS:"
# Expected: "PROGRESS: ... [Phase 2/4, 50% complete]"

# Test progress parsing in command layer
bash .claude/tests/lib/test_progress_parsing.sh

# Verify user-visible progress formatting
bash .claude/tests/integration/test_progress_visibility.sh
```

**Expected Duration**: 2-3 hours

### Phase 5: Context Compaction Agent Creation [NOT STARTED]
dependencies: [3]

**Objective**: Create context compaction agent behavioral file and integrate into /build iteration loop to reduce context window pressure by 40-60% per iteration.

**Complexity**: Medium

**Tasks**:
- [ ] Create context-compaction-agent.md behavioral file (file: `.claude/agents/context-compaction-agent.md`)
- [ ] Define compaction agent tool set (Read, Write for compaction summaries)
- [ ] Document compaction fidelity requirements (preserve decisions, blockers, discard verbose outputs)
- [ ] Create compaction output format specification (<2000 tokens)
- [ ] Add compaction agent to agent registry (file: `.claude/agents/README.md`)
- [ ] Create compaction agent tests (file: `.claude/tests/agents/test_context_compaction.sh`)
- [ ] Document compaction pattern in concepts (file: `.claude/docs/concepts/patterns/context-compaction.md`)

**Testing**:
```bash
# Verify compaction agent behavioral file exists
test -f .claude/agents/context-compaction-agent.md || echo "ERROR: Agent file missing"

# Test compaction agent invocation with sample continuation context
bash .claude/tests/agents/test_context_compaction.sh

# Verify compaction output is <2000 tokens
wc -w < .claude/tmp/compaction_test_output.md
# Expected: <2000

# Verify high-fidelity preservation (architectural decisions present)
grep -q "Architecture Decision" .claude/tmp/compaction_test_output.md
```

**Expected Duration**: 6-8 hours

### Phase 6: Context Compaction Integration [NOT STARTED]
dependencies: [5]

**Objective**: Integrate context compaction agent into /build command iteration loop to enable multi-iteration context management.

**Complexity**: Medium

**Tasks**:
- [ ] Add compaction invocation after iteration completion in /build command (file: `.claude/commands/build.md`)
- [ ] Create compaction summary storage location (BUILD_WORKSPACE)
- [ ] Update CONTINUATION_CONTEXT to use compacted summary
- [ ] Add compaction failure fallback (use full context if compaction fails)
- [ ] Update workflow state machine to handle compaction artifacts (file: `.claude/lib/workflow/workflow-state-machine.sh`)
- [ ] Add compaction metrics tracking (context size before/after)
- [ ] Update build command tests with compaction validation (file: `.claude/tests/commands/test_build_compaction.sh`)
- [ ] Document compaction integration in build command guide (file: `.claude/docs/guides/commands/build-command-guide.md`)

**Testing**:
```bash
# Test compaction invocation in multi-iteration workflow
bash .claude/tests/integration/test_build_multi_iteration.sh

# Verify context size reduction (should be 40-60% smaller)
bash .claude/tests/lib/test_compaction_metrics.sh

# Test compaction failure fallback (should use full context)
bash .claude/tests/integration/test_compaction_fallback.sh

# Verify workflow completion with compacted context
grep -q "IMPLEMENTATION_COMPLETE" .claude/tmp/build_test_output.log
```

**Expected Duration**: 8-10 hours

### Phase 7: XML Tag Structure Migration and Document Placement [NOT STARTED]
dependencies: []

**Objective**: Create XML tag structure templates, migrate high-priority commands (/build, /plan, /research) to use XML for improved prompt clarity, and implement document placement optimization for large files (>20K tokens).

**Complexity**: Medium

**Tasks**:
- [ ] Create XML tag structure template documentation with examples (file: `.claude/docs/reference/xml-tag-templates.md`)
- [ ] Define standard XML tags (background_information, input_contract, instructions, expected_output, documents)
- [ ] Create document placement pattern for large files >20K tokens (~80,000 characters) (file: `.claude/docs/concepts/patterns/document-placement.md`)
- [ ] Migrate /research command Task invocations to XML structure (file: `.claude/commands/research.md`)
- [ ] Migrate /plan command Task invocations to XML structure (file: `.claude/commands/plan.md`)
- [ ] Migrate /build command Task invocations to XML structure with document-first ordering for large plans (file: `.claude/commands/build.md`)
- [ ] Update agent behavioral files to reference XML structure pattern and document placement guidelines
- [ ] Add file size detection logic for automatic document-first ordering (threshold: 80,000 characters)
- [ ] Test LLM parsing with both Markdown and XML formats (validation)
- [ ] Update command authoring standards with XML structure guidance and document placement rules (file: `.claude/docs/reference/standards/command-authoring.md`)

**Testing**:
```bash
# Verify XML tags present in migrated commands
grep -c "<input_contract>" .claude/commands/research.md
# Expected: >0

# Test document placement with large files
bash .claude/tests/lib/test_document_placement.sh

# Verify file size detection and automatic document-first ordering
bash .claude/tests/lib/test_large_file_detection.sh

# Test command execution with XML structure
bash .claude/tests/integration/test_research_command.sh
bash .claude/tests/integration/test_plan_command.sh
bash .claude/tests/integration/test_build_command.sh

# Verify backward compatibility (Markdown fallback)
bash .claude/tests/integration/test_markdown_fallback.sh

# Verify prompt clarity improvement with XML (qualitative assessment)
# Compare agent response quality before/after XML migration

# Test 30% improvement in large file processing (Anthropic benchmark)
bash .claude/tests/integration/test_document_placement_improvement.sh
```

**Expected Duration**: 12-14 hours

### Phase 8: Library Consolidation [NOT STARTED]
dependencies: []

**Objective**: Consolidate related library files to reduce count from 54 to ~45 (16% reduction) while maintaining backward compatibility.

**Complexity**: High

**Tasks**:
- [ ] Analyze library dependencies and create detailed consolidation plan (file: `.claude/specs/000_claude_infrastructure_refactor/plans/library-consolidation-plan.md`)
- [ ] Merge plan-parsing.sh, plan-core-bundle.sh, checkbox-utils.sh into plan-operations.sh (file: `.claude/lib/plan/plan-operations.sh`)
- [ ] Merge auto-analysis-utils.sh, plan-complexity-classifier.sh into plan-analysis.sh (file: `.claude/lib/plan/plan-analysis.sh`)
- [ ] Merge workflow-init.sh, workflow-initialization.sh into workflow-setup.sh (file: `.claude/lib/workflow/workflow-setup.sh`)
- [ ] Merge context-pruning.sh, metadata-extraction.sh into context-management.sh (file: `.claude/lib/workflow/context-management.sh`)
- [ ] Merge artifact-registry.sh, template-integration.sh into artifact-management.sh (file: `.claude/lib/artifact/artifact-management.sh`)
- [ ] Create backward compatibility shims for deprecated libraries
- [ ] Update sourcing references across all commands and agents
- [ ] Test consolidated libraries with existing commands
- [ ] Remove deprecated library files after successful migration
- [ ] Update library documentation (file: `.claude/lib/README.md`)

**Testing**:
```bash
# Verify consolidated libraries exist
test -f .claude/lib/plan/plan-operations.sh || echo "ERROR: plan-operations.sh missing"
test -f .claude/lib/plan/plan-analysis.sh || echo "ERROR: plan-analysis.sh missing"
test -f .claude/lib/workflow/workflow-setup.sh || echo "ERROR: workflow-setup.sh missing"

# Test backward compatibility shims
bash .claude/tests/lib/test_backward_compatibility.sh

# Test all commands with consolidated libraries
bash .claude/tests/integration/test_all_commands.sh

# Verify library count reduction
ls .claude/lib/*/*.sh | wc -l
# Expected: ~45 (down from 54)

# Validate sourcing pattern compliance
bash .claude/scripts/check-library-sourcing.sh
```

**Expected Duration**: 12-16 hours

### Phase 9: Documentation Structure Optimization [NOT STARTED]
dependencies: []

**Objective**: Audit archive, consolidate fragmented guides, and reduce documentation files from 492 to 350-400 (20-30% reduction).

**Complexity**: Medium

**Tasks**:
- [ ] Audit .claude/docs/archive/ for obsolete documents (identify removal candidates)
- [ ] Create documentation consolidation plan (file: `.claude/specs/000_claude_infrastructure_refactor/plans/documentation-consolidation-plan.md`)
- [ ] Consolidate command development guides (identify overlapping content)
- [ ] Consolidate workflow pattern guides (merge similar topics)
- [ ] Remove obsolete archived documents (after verification)
- [ ] Update cross-references in remaining documentation
- [ ] Create single-source-of-truth policy documentation (file: `.claude/docs/reference/standards/documentation-standards.md`)
- [ ] Verify no broken links after consolidation
- [ ] Update documentation index and navigation (file: `.claude/docs/README.md`)

**Testing**:
```bash
# Verify documentation file count reduction
find .claude/docs -name "*.md" | wc -l
# Expected: 350-400 (down from 492)

# Test for broken links after consolidation
bash .claude/scripts/validate-links-quick.sh

# Verify archive cleanup
ls .claude/docs/archive/ | wc -l
# Expected: Significantly reduced

# Verify navigation integrity
bash .claude/tests/validators/test_documentation_navigation.sh

# Verify README structure compliance
bash .claude/scripts/validate-readmes.sh
```

**Expected Duration**: 10-14 hours

### Phase 10: Pre-Flight Validation, Machine-Readable Feature Lists, and Layered Role Specificity [NOT STARTED]
dependencies: []

**Objective**: Add pre-flight validation for fail-fast error handling, implement machine-readable feature lists for programmatic workflow tracking, and enhance system prompts with layered role specificity.

**Complexity**: Medium

**Tasks**:
- [ ] Create validation-utils.sh library (possibly merge with existing validation-utils.sh) (file: `.claude/lib/workflow/validation-utils.sh`)
- [ ] Implement validate_research_prerequisites function
- [ ] Implement validate_plan_prerequisites function
- [ ] Implement validate_build_prerequisites function
- [ ] Add validation calls to /research command (file: `.claude/commands/research.md`)
- [ ] Add validation calls to /plan command (file: `.claude/commands/plan.md`)
- [ ] Add validation calls to /build command (file: `.claude/commands/build.md`)
- [ ] Create machine-readable feature list template (JSON format) (file: `.claude/lib/templates/feature-list.json`)
- [ ] Add feature list creation to workflow initialization (file: `.claude/lib/workflow/workflow-init.sh`)
- [ ] Implement programmatic feature status validation (prevents premature completion declaration)
- [ ] Update /build command to use feature list for completion validation (file: `.claude/commands/build.md`)
- [ ] Enhance system prompt in /research with layered role specificity (title, context, expertise, constraints) (file: `.claude/commands/research.md`)
- [ ] Enhance system prompt in /plan with layered role specificity (file: `.claude/commands/plan.md`)
- [ ] Enhance system prompt in /build with layered role specificity (file: `.claude/commands/build.md`)
- [ ] Update all 29 agent behavioral files with enhanced role definitions (file: `.claude/agents/*.md`)
- [ ] Update command authoring standards with validation, feature list, and role specificity patterns (file: `.claude/docs/reference/standards/command-authoring.md`)

**Testing**:
```bash
# Test validation functions with invalid inputs
bash .claude/tests/lib/test_validation_utils.sh

# Verify fail-fast behavior on invalid inputs
bash .claude/tests/integration/test_preflight_validation.sh

# Test machine-readable feature list creation and validation
bash .claude/tests/lib/test_feature_list.sh

# Verify programmatic completion validation prevents premature declaration
bash .claude/tests/integration/test_completion_validation.sh

# Test enhanced role specificity (qualitative assessment)
# Compare agent response quality with enhanced system prompts
bash .claude/tests/integration/test_layered_role_specificity.sh

# Verify clear error messages on validation failures
bash .claude/commands/research.md --invalid-input 2>&1 | grep "ERROR:"

# Verify all 29 agent behavioral files have enhanced role definitions
grep -c "Expertise:" .claude/agents/*.md | wc -l
# Expected: 29
```

**Expected Duration**: 8-10 hours

## Testing Strategy

### Unit Testing
- Test individual library functions after consolidation
- Test compaction agent with sample continuation contexts
- Test validation functions with edge cases
- Test progress marker parsing and formatting

### Integration Testing
- Test full command workflows with all enhancements
- Test multi-iteration workflows with context compaction
- Test edge case handling with expanded examples
- Test backward compatibility with consolidated libraries

### Validation Testing
- Validate tool selection accuracy with refined descriptions
- Validate context reduction metrics (40-60% target)
- Validate error reduction metrics (15-20% target for tool selection and edge cases)
- Validate library count reduction (54 → 45 files)
- Validate documentation count reduction (492 → 350-400 files)

### Regression Testing
- Run existing test suite to ensure zero functionality regression
- Validate all commands execute successfully after changes
- Verify agent behavioral files produce expected outputs
- Confirm state machine transitions remain valid

### Test Commands
```bash
# Run all unit tests
bash .claude/tests/run_all_unit_tests.sh

# Run all integration tests
bash .claude/tests/run_all_integration_tests.sh

# Run validation tests
bash .claude/tests/run_validation_tests.sh

# Run regression tests
bash .claude/tests/run_regression_tests.sh

# Run comprehensive test suite
bash .claude/tests/run_all_tests.sh

# Validate standards compliance
bash .claude/scripts/validate-all-standards.sh --all
```

## Documentation Requirements

### New Documentation Files
- [ ] Tool description template (`.claude/docs/reference/tool-description-template.md`)
- [ ] Few-shot example expansion guide (`.claude/docs/guides/development/few-shot-example-guide.md`)
- [ ] Quote-based research pattern (`.claude/docs/concepts/patterns/quote-based-research.md`)
- [ ] Document placement pattern (`.claude/docs/concepts/patterns/document-placement.md`)
- [ ] Structured note-taking pattern (`.claude/docs/concepts/patterns/structured-note-taking.md`)
- [ ] Context compaction pattern (`.claude/docs/concepts/patterns/context-compaction.md`)
- [ ] XML tag structure templates (`.claude/docs/reference/xml-tag-templates.md`)
- [ ] Machine-readable feature list template (`.claude/lib/templates/feature-list.json`)
- [ ] Library consolidation plan (`.claude/specs/000_claude_infrastructure_refactor/plans/library-consolidation-plan.md`)
- [ ] Documentation consolidation plan (`.claude/specs/000_claude_infrastructure_refactor/plans/documentation-consolidation-plan.md`)

### Updated Documentation Files
- [ ] Command authoring standards (`.claude/docs/reference/standards/command-authoring.md`)
- [ ] Output formatting standards (`.claude/docs/reference/standards/output-formatting.md`)
- [ ] Documentation standards (`.claude/docs/reference/standards/documentation-standards.md`)
- [ ] Build command guide (`.claude/docs/guides/commands/build-command-guide.md`)
- [ ] Agent registry (`.claude/agents/README.md`)
- [ ] Library documentation (`.claude/lib/README.md`)
- [ ] Documentation index (`.claude/docs/README.md`)

### Documentation Updates Per Phase
Each phase must update relevant standards documentation to reflect new patterns and requirements.

## Dependencies

### External Dependencies
- None (all changes are internal to .claude/ infrastructure)

### Internal Dependencies
- Phase 6 (Context Compaction Integration) depends on Phase 5 (Context Compaction Agent Creation)
- Phase 5 (Context Compaction Agent Creation) depends on Phase 3 (Structured Note-Taking) for optimal compaction quality
- All other phases are independent and can be implemented in parallel

### Parallelization Strategy

**Wave-Based Execution** (for /build command):
- **Wave 1 (Parallel)**: Phases 1, 2, 3, 4, 7, 8, 9, 10 - No dependencies, maximum parallelization
- **Wave 2 (Sequential)**: Phase 5 - Depends on Phase 3 (note-taking infrastructure)
- **Wave 3 (Sequential)**: Phase 6 - Depends on Phase 5 (compaction agent)

**Dependency Syntax**:
- `dependencies: []` = Wave 1 (no prerequisites)
- `dependencies: [3]` = Wave 2 (Phase 5 waits for Phase 3)
- `dependencies: [5]` = Wave 3 (Phase 6 waits for Phase 5)

**Parallelization Benefits**:
- 8 out of 10 phases can run in parallel (Wave 1)
- Only 2 phases require sequential execution (Waves 2-3)
- Estimated 40-60% time savings vs. sequential execution

### Tool Dependencies
- Bash 4.0+ for library functions
- grep, wc, find for validation scripts
- git for version control and rollback capability

## Risk Assessment

### High-Risk Areas
- **Library Consolidation (Phase 8)**: Breaking changes to sourcing patterns across codebase
  - Mitigation: Comprehensive dependency analysis, backward compatibility shims, extensive testing
- **Context Compaction (Phases 5-6)**: Compaction quality issues could degrade multi-iteration workflows
  - Mitigation: Test compaction fidelity, fallback to full context on failure, iterative refinement

### Medium-Risk Areas
- **XML Tag Structure (Phase 7)**: Compatibility issues with existing commands
  - Mitigation: Start with new commands, gradual migration, maintain Markdown fallback support
- **Documentation Optimization (Phase 9)**: Risk of removing needed documentation
  - Mitigation: Careful audit before removal, verify no broken links, maintain archive backups

### Low-Risk Areas
- **Tool Description Refinement (Phase 1)**: Additive change only
- **Few-Shot Examples (Phase 2)**: Additive examples
- **Structured Note-Taking (Phase 3)**: Optional feature, graceful degradation
- **Progress Estimates (Phase 4)**: Cosmetic enhancement
- **Pre-Flight Validation (Phase 10)**: Additive validation layer

## Expected Outcomes

### Quantitative Metrics
- Context efficiency: 88% → <70% context usage (25% improvement via compaction)
- Tool selection errors: 10-15% reduction (via refined descriptions)
- Edge case errors: 15-20% reduction (via expanded examples)
- Research hallucination: Measurable reduction (via quote-based pattern)
- Large file processing: 30% improvement (via document placement, per Anthropic benchmark)
- Library files: 54 → 45 files (16% reduction)
- Documentation files: 492 → 350-400 files (20-30% reduction)
- Overall Anthropic alignment: 88/100 → 95/100

### Qualitative Improvements
- Improved user visibility with progress completion estimates
- Better context recovery across sessions with structured notes
- Clearer prompt structure with XML tags and document placement
- Reduced hallucination in research reports via quote-based pattern
- More accurate agent behavior via enhanced role definitions
- Programmatic workflow tracking via machine-readable feature lists
- Easier library maintenance with consolidation
- Better documentation discoverability with optimization
- Faster failure on invalid inputs with pre-flight validation

### Performance Improvements
- Multi-iteration workflows sustain coherence longer (compaction)
- Reduced context window pressure enables more complex workflows
- Faster error detection with pre-flight validation
- Improved agent accuracy with refined tool descriptions and examples

## Rollback Strategy

### Phase-Level Rollback
Each phase is independently reversible:
- **Phase 1-2, 4**: Revert to previous agent behavioral files and command files
- **Phase 3**: Remove NOTES.md creation, agents gracefully degrade
- **Phase 5-6**: Remove compaction agent invocation, fallback to full context
- **Phase 7**: Revert to Markdown structure (minimal impact)
- **Phase 8**: Restore backup libraries, revert sourcing references
- **Phase 9**: Restore archived documentation from backups
- **Phase 10**: Remove validation calls, revert system prompts

### Version Control Strategy
- Create git branch for refactor work
- Tag before each phase implementation
- Commit after each phase completion
- Maintain main branch stability during refactor

### Rollback Testing
- Test rollback procedures for high-risk phases (8, 9)
- Verify backward compatibility shims function correctly
- Confirm commands execute after rollback

## Success Metrics

### Completion Criteria
- [ ] All 10 phases completed successfully
- [ ] All tests passing (unit, integration, validation, regression)
- [ ] Context efficiency target achieved (<70% usage)
- [ ] Error reduction targets achieved (10-15% tool selection, 15-20% edge cases)
- [ ] File reduction targets achieved (45 libraries, 350-400 docs)
- [ ] Anthropic alignment target achieved (95/100)
- [ ] Machine-readable feature lists implemented for workflow tracking
- [ ] Quote-based research pattern integrated into research-specialist agent
- [ ] Document placement optimization applied to large file scenarios (>20K tokens)
- [ ] Zero functionality regression
- [ ] All documentation updated
- [ ] Standards compliance validated

### Quality Gates
- Each phase must pass its testing section before proceeding
- Regression tests must pass after each phase
- Standards validation must pass after each phase
- Backward compatibility must be maintained during transitions

### Review Checkpoints
- After Phase 4: Review quick wins and assess impact
- After Phase 7: Review context management and assess multi-iteration improvement
- After Phase 9: Review infrastructure consolidation and assess maintainability
- Final Review: Comprehensive assessment of all improvements and alignment score
