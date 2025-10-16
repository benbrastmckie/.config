# .claude/ Directory Modularization - Extraction Plan

## Summary Statistics
- **Total lines to extract**: ~3,500 lines from 4 commands
- **Target shared files**: 13 files (10 high priority, 3 medium priority)
- **Expected file size reductions**:
  - orchestrate.md: 2,720 → <1,200 lines (56% reduction, ~1,520 lines extracted)
  - implement.md: 987 → <500 lines (49% reduction, ~490 lines extracted)
  - setup.md: 911 → <400 lines (56% reduction, ~510 lines extracted)
  - revise.md: 878 → <400 lines (54% reduction, ~480 lines extracted)

## Baseline Verification (October 14, 2025)

Current file sizes verified:
- orchestrate.md: 2,720 lines (88KB)
- implement.md: 987 lines (43KB)
- setup.md: 911 lines (exact size TBD)
- revise.md: 878 lines (exact size TBD)

## High Priority Extractions (Stage 2: orchestrate.md, setup.md, revise.md)

### From orchestrate.md (2,720 → <1,200 lines)

| Section Name | Source File | Line Range | Target File | Est. Lines | Dependencies | Priority |
|--------------|-------------|------------|-------------|------------|--------------|----------|
| Workflow Phases Details | orchestrate.md | 417-870 | workflow-phases.md | 450 | None | High |
| Error Recovery Patterns | orchestrate.md | 298-327, 2342-2395 | error-recovery.md | 300 | None | High |
| Context Management | orchestrate.md | 2305-2412 | context-management.md | 200 | None | High |
| Agent Coordination | orchestrate.md | 415-540, 2605-2648 | agent-coordination.md | 300 | None | High |
| Orchestrate Examples | orchestrate.md | 2451-2720 | orchestrate-examples.md | 300 | None | High |

**Notes**:
- Line ranges are estimates based on section headings from file structure
- Workflow phases include: Research (parallel), Planning (sequential), Implementation (adaptive),
  Debugging (conditional), Documentation (sequential)
- Error recovery includes retry patterns, error classification, checkpoint recovery
- Context management covers orchestrator state, subagent context, context passing protocol
- Agent coordination covers parallel/sequential execution patterns, agent invocation templates
- Examples section includes 4 detailed workflow examples (simple, medium, complex, escalation)

### From setup.md (911 → <400 lines)

| Section Name | Source File | Line Range | Target File | Est. Lines | Dependencies | Priority |
|--------------|-------------|------------|-------------|------------|--------------|----------|
| Command Modes | setup.md | TBD | setup-modes.md | 300 | None | High |
| Bloat Detection | setup.md | TBD | bloat-detection.md | 150 | None | High |
| Extraction Strategies | setup.md | TBD | extraction-strategies.md | 100 | None | High |

**Notes**:
- Command modes: 5 different operational modes with distinct workflows
- Bloat detection: Algorithms for identifying documentation bloat, thresholds
- Extraction strategies: Preference patterns for extracting sections

### From revise.md (878 → <400 lines)

| Section Name | Source File | Line Range | Target File | Est. Lines | Dependencies | Priority |
|--------------|-------------|------------|-------------|------------|--------------|----------|
| Auto-mode Specification | revise.md | TBD | revise-auto-mode.md | 250 | None | High |
| Revision Types | revise.md | TBD | revision-types.md | 250 | None | High |

**Notes**:
- Auto-mode: JSON schemas, automated revision logic, context handling
- Revision types: 5 distinct revision type descriptions with workflows

## Medium Priority Extractions (Stage 3: implement.md)

### From implement.md (987 → <500 lines)

| Section Name | Source File | Line Range | Target File | Est. Lines | Dependencies | Priority |
|--------------|-------------|------------|-------------|------------|--------------|----------|
| Adaptive Planning Guide | implement.md | TBD | adaptive-planning.md | 200 | None | Medium |
| Progressive Structure | implement.md | TBD | progressive-structure.md | 150 | None | Medium |
| Phase Execution Protocol | implement.md | TBD | phase-execution.md | 180 | error-recovery.md (ref) | Medium |

**Notes**:
- Adaptive planning: Replan triggers, complexity thresholds, loop prevention, logging
- Progressive structure: L0→L1→L2 plan evolution, expansion/collapse operations
- Phase execution: Checkpoint management, test requirements, commit workflow

## Extraction Sequence

### Stage 2: Extract All Command Documentation
Extract from all 4 commands in single stage:

**Substage 2A: orchestrate.md extraction** (5 shared files)
1. workflow-phases.md (450 lines) - Workflow phase descriptions
2. error-recovery.md (300 lines) - Error handling patterns
3. context-management.md (200 lines) - Context optimization
4. agent-coordination.md (300 lines) - Agent invocation patterns
5. orchestrate-examples.md (300 lines) - Usage examples

**Substage 2B: setup.md extraction** (3 shared files)
6. setup-modes.md (300 lines) - Command modes
7. bloat-detection.md (150 lines) - Bloat detection
8. extraction-strategies.md (100 lines) - Extraction preferences

**Substage 2C: revise.md extraction** (2 shared files)
9. revise-auto-mode.md (250 lines) - Auto-mode spec
10. revision-types.md (250 lines) - Revision types

**Total Stage 2**: 10 shared files, ~2,600 lines extracted

### Stage 3: implement.md Documentation (3 shared files)
11. adaptive-planning.md (200 lines)
12. progressive-structure.md (150 lines)
13. phase-execution.md (180 lines) - References error-recovery.md from Stage 2

**Total Stage 3**: 3 shared files, ~530 lines extracted

**Combined Total**: 13 shared files, ~3,130 lines extracted

## Cross-Reference Opportunities

Sections that can reference shared files created in earlier stages:

- **implement.md Phase Execution Protocol** → references `shared/error-recovery.md`
  (created in Stage 2)
- **All commands** → can reference `shared/error-handling.md`
  (future low-priority extraction)
- **orchestrate.md examples** → can reference `shared/phase-execution.md`
  (created in Stage 3 for consistent patterns)

## Validation Strategy

After each file extraction:

1. **Content Verification**:
   ```bash
   # Verify extracted file exists and has expected size
   test -f shared/workflow-phases.md && wc -l shared/workflow-phases.md
   # Expected: ~450 lines
   ```

2. **Source File Reduction**:
   ```bash
   # Verify source file reduced appropriately
   wc -l orchestrate.md
   # Expected reduction after workflow-phases.md extraction: ~450 lines
   ```

3. **Reference Links**:
   ```bash
   # Verify reference was added to source file
   grep "workflow-phases.md" orchestrate.md
   # Expected: Link with 50-100 word summary before reference
   ```

4. **Incremental Testing**:
   ```bash
   # Run tests after each extraction
   cd .claude/tests && ./run_all_tests.sh
   # Compare against baseline (Task 6 results)
   ```

## Extraction Pattern

For each section to extract:

1. **Read source section** (exact line range)
2. **Create shared file** with extracted content
3. **Add 50-100 word summary** to source file at extraction point
4. **Add reference link** to shared file
5. **Remove extracted content** from source file
6. **Verify reduction** (wc -l before/after)
7. **Test immediately** (run test suite)
8. **Commit if passing** (atomic commit per extraction)

## Section Summary Template

When replacing extracted sections with summaries, use this pattern:

```markdown
### [Section Title]

[50-100 word summary of what this section covers]

For detailed [section topic], see [Section Name](shared/file-name.md).
```

Example:
```markdown
### Research Phase

The research phase coordinates 2-4 specialized agents in parallel to investigate
different aspects of the workflow simultaneously. Agents create research reports
in specs/reports/{topic}/ directories, which are then verified and passed to
the planning phase. Parallel execution reduces research time by ~66% for 3 agents.

For complete research phase execution procedure, patterns, and examples,
see [Research Phase Documentation](shared/workflow-phases.md#research-phase).
```

## Success Criteria Per File

### orchestrate.md
- [x] Baseline: 2,720 lines verified
- [ ] After extraction: <1,200 lines (target met)
- [ ] 5 shared files created (workflow-phases, error-recovery, context-management,
      agent-coordination, orchestrate-examples)
- [ ] All references functional
- [ ] Tests pass

### implement.md
- [x] Baseline: 987 lines verified
- [ ] After extraction: <500 lines (target met)
- [ ] 3 shared files created (adaptive-planning, progressive-structure, phase-execution)
- [ ] Cross-reference to error-recovery.md works
- [ ] Tests pass

### setup.md
- [x] Baseline: 911 lines verified
- [ ] After extraction: <400 lines (target met)
- [ ] 3 shared files created (setup-modes, bloat-detection, extraction-strategies)
- [ ] All references functional
- [ ] Tests pass

### revise.md
- [x] Baseline: 878 lines verified
- [ ] After extraction: <400 lines (target met)
- [ ] 2 shared files created (revise-auto-mode, revision-types)
- [ ] All references functional
- [ ] Tests pass

## Notes

### Why This Extraction Order?

1. **Stage 2 (all commands)**: Extract all high-priority sections in one stage
   - Creates foundation of shared documentation
   - Enables cross-references in Stage 3
   - All 4 commands improved in parallel

2. **Stage 3 (implement.md)**: Extract remaining medium-priority sections
   - Can reference error-recovery.md created in Stage 2
   - Completes the full set of 13 shared files

### Estimated Time Per Extraction

- **Simple extraction** (no cross-refs): 10-15 minutes
  - Read, extract, create shared file, add reference, test

- **Complex extraction** (with cross-refs): 15-20 minutes
  - Additional cross-reference verification and updates

- **Total estimated time**:
  - Stage 2 (10 files): ~2.5 hours
  - Stage 3 (3 files): ~45 minutes
  - **Total**: ~3-3.5 hours for all extractions

### Risk Mitigation

- **Atomic commits**: One commit per successfully tested extraction
- **Rollback capability**: Git allows reverting any failed extraction
- **Progressive testing**: Test suite run after each extraction
- **Baseline comparison**: Compare against Task 6 baseline results

## Next Steps

After completing this extraction plan (Task 5):

1. **Task 6**: Run and verify baseline tests (establish pre-extraction test status)
2. **Stage 2**: Begin extractions following this plan
3. **Stage 3**: Complete implement.md extractions
4. **Stage 4**: Utility consolidation (separate from documentation extraction)
5. **Stage 5**: Final testing and validation
