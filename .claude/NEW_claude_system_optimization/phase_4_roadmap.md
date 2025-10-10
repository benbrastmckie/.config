# Phase 4 Implementation Roadmap: Command Documentation Extraction

## Overview

This roadmap breaks down the 50+ hours of Phase 4 refactoring work into manageable sessions with clear checkpoints and validation criteria.

**Status**: Foundation Complete (Tasks 1-3), implement.md Complete (Sessions 5-9), Refactoring In Progress

**Links**:
- Main Plan: [NEW_claude_system_optimization.md](NEW_claude_system_optimization.md#phase-4-command-documentation-extraction-high-complexity)
- Detailed Spec: [phase_4_command_documentation_extraction.md](phase_4_command_documentation_extraction.md)
- Setup Plan: [setup_md_compression_plan.md](setup_md_compression_plan.md)

---

## Phase 4 Progress Tracker

### Foundation Tasks (Complete)

| Task | Status | Time | Completed | Notes |
|------|--------|------|-----------|-------|
| 1. Add new patterns to command-patterns.md | ✅ DONE | 2h | 2025-10-10 | Added 351 lines (Logger, PR, Parallel patterns) |
| 2. Create backups of all command files | ✅ DONE | 0.5h | 2025-10-10 | 20 files backed up to `backups/phase4_20251010/` |
| 3. Create validation test suite | ✅ DONE | 3h | 2025-10-10 | `test_command_references.sh` functional |

**Foundation Subtotal**: 5.5 hours ✅

---

## Priority 2: implement.md Refactoring (COMPLETE) ✅

**Original State**: 1,646 lines
**Final State**: 868 lines
**Reduction**: 778 lines (47%)
**Commit**: bd1e706

### Sessions 5-9: implement.md Compression (8 hours) ✅

| Session | Focus | Savings | Status | Notes |
|---------|-------|---------|--------|-------|
| 5-6 | First Pass Compression | ~390 lines | ✅ DONE | Standards discovery, agent patterns, checkpoints |
| 7-8 | Second Pass Compression | ~388 lines | ✅ DONE | Proactive expansion, parallel execution, error analysis |
| 9 | Validation & Commit | - | ✅ DONE | Git commit bd1e706, all tests passing |

**First Pass Compressions**:
- Standards Discovery and Application: 75 lines → reference
- Agent Invocation Patterns: 45 lines → reference
- Checkpoint Management: 85 lines → reference
- Upward CLAUDE.md Search: 70 lines → reference
- Resume from Checkpoint: 50 lines → reference
- Additional consolidations: ~65 lines

**Second Pass Compressions**:
- Proactive Expansion Check: 74 → 13 lines (61 saved)
- Parallel Wave Execution: 53 → 11 lines (42 saved)
- Enhanced Error Analysis: 60 → 7 lines (53 saved)
- Adaptive Planning Detection: 236 → 15 lines (221 saved)
- Additional refinements: ~11 lines

**Validation Results**:
- ✅ All references resolve correctly
- ✅ Command functionality verified
- ✅ 47% compression achieved (exceeded 36% target)
- ✅ Pattern references: Upward CLAUDE.md Search, Standards Discovery, Checkpoint Management, Agent Invocation, Resume from Checkpoint, Test Discovery, Progress Marker Detection, Parallel Execution Safety

**implement.md Subtotal**: 8 hours ✅

---

## Priority 1: orchestrate.md Refactoring (14 hours)

**Current State**: 2,092 lines
**Target State**: ~1,700 lines
**Expected Reduction**: ~390 lines (19%)

### Session 1: Agent Invocation Sections (4 hours)

| Subsection | Lines | Action | Reference Pattern | Savings | Status |
|------------|-------|--------|-------------------|---------|--------|
| Parallel Research Agents | 95-108 | Replace with reference + orchestrate-specific | `pattern-parallel-agent-invocation` | 80 lines | ⏳ TODO |
| Research Agent Prompt Template | 148-226 | Reduce to template + reference | `pattern-single-agent-with-behavioral-injection` | 40 lines | ⏳ TODO |
| Planning Agent Monitoring | 471-497 | Reference + orchestrate monitoring | `pattern-progress-marker-detection` | 15 lines | ⏳ TODO |

**Session 1 Validation**:
```bash
# After completing session 1
bash .claude/tests/test_command_references.sh .claude/commands/orchestrate.md
wc -l .claude/commands/orchestrate.md  # Should be ~1,957 lines (2,092 - 135)
git add .claude/commands/orchestrate.md
git commit -m "refactor(orchestrate): extract agent invocation patterns"
```

**Expected Outcome**: orchestrate.md reduced to ~1,957 lines

---

### Session 2: Artifact and Checkpoint Sections (3 hours)

| Subsection | Lines | Action | Reference Pattern | Savings | Status |
|------------|-------|--------|-------------------|---------|--------|
| Artifact Storage and Registry | 246-274 | Reference + registry specifics | `pattern-artifact-storage-and-registry` | 20 lines | ⏳ TODO |
| Save Research Checkpoint | 275-289 | Reference + checkpoint data | `pattern-save-checkpoint-after-phase` | 10 lines | ⏳ TODO |
| Bidirectional Cross-References | 1272-1312 | Replace with reference | `pattern-bidirectional-cross-references` | 40 lines | ⏳ TODO |

**Session 2 Validation**:
```bash
bash .claude/tests/test_command_references.sh .claude/commands/orchestrate.md
wc -l .claude/commands/orchestrate.md  # Should be ~1,887 lines (1,957 - 70)
git add .claude/commands/orchestrate.md
git commit -m "refactor(orchestrate): extract artifact/checkpoint patterns"
```

**Expected Outcome**: orchestrate.md reduced to ~1,887 lines

---

### Session 3: Error Recovery and Debugging (5 hours)

| Subsection | Lines | Action | Reference Pattern | Savings | Status |
|------------|-------|--------|-------------------|---------|--------|
| Implementation Error Handling | 676-748 | Reference + orchestrate error types | `error-recovery-patterns` | 35 lines | ⏳ TODO |
| Debugging Loop (LARGEST) | 809-1175 | Reference test failure + debug workflow | `pattern-test-failure-handling` | 180 lines | ⏳ TODO |
| Error Recovery Mechanism | 1782-1810 | Consolidate with reference | `error-recovery-patterns` | 25 lines | ⏳ TODO |

**Session 3 Validation**:
```bash
bash .claude/tests/test_command_references.sh .claude/commands/orchestrate.md
wc -l .claude/commands/orchestrate.md  # Should be ~1,647 lines (1,887 - 240)

# Functional test
/orchestrate "Create a simple test workflow" --dry-run

git add .claude/commands/orchestrate.md
git commit -m "refactor(orchestrate): extract error recovery patterns"
```

**Expected Outcome**: orchestrate.md reduced to ~1,647 lines

---

### Session 4: Validation and Measurement (2 hours)

**Tasks**:
1. Read orchestrate.md end-to-end (manual review)
2. Run comprehensive validation tests
3. Test with real workflow
4. Measure final reduction
5. Document lessons learned

**Validation Commands**:
```bash
# Reference validation
bash .claude/tests/test_command_references.sh .claude/commands/orchestrate.md

# Line count measurement
original=$(wc -l < .claude/commands/backups/phase4_20251010/orchestrate.md)
refactored=$(wc -l < .claude/commands/orchestrate.md)
echo "Reduction: $((original - refactored)) lines ($((100 * (original - refactored) / original))%)"

# Functional test
/orchestrate "Create hello world script"
```

**Success Criteria**:
- [ ] All references resolve correctly
- [ ] orchestrate.md ~1,700 lines (±100 lines acceptable)
- [ ] Orchestrate-specific details preserved
- [ ] Command executes without errors
- [ ] Debugging loop workflow intact

**Final Commit**:
```bash
git add .claude/commands/orchestrate.md
git commit -m "docs(orchestrate): validate Phase 4 refactoring"
```

---


---

## Priority 3: setup.md Optimization (COMPLETE) ✅

**Original State**: 2,198 lines
**Final State**: 911 lines
**Reduction**: 1,287 lines (58.6%)
**Commit**: [Pending]

**Note**: setup.md required aggressive template condensing rather than pattern extraction. See [setup_md_detailed_compression_plan.md](setup_md_detailed_compression_plan.md) for detailed 7-phase strategy.

### Sessions 10-11: setup.md Compression (7 hours) ✅

| Phase | Subsection | Lines | Savings | Status |
|-------|------------|-------|---------|--------|
| 1 ✅ | Argument Parsing | 203 → 29 | 174 lines | ✅ DONE |
| 2 ✅ | Extraction Preferences | 190 → 52 | 136 lines | ✅ DONE |
| 3 ✅ | Bloat Detection | 148 → 40 | 108 lines | ✅ DONE |
| 4 ✅ | Extraction Preview | 137 → 27 | 110 lines | ✅ DONE |
| 5 ✅ | Standards Analysis | 835 → 104 | 731 lines | ✅ DONE |
| 6 ✅ | Report Application | (merged with Phase 5) | - | ✅ DONE |
| 7 ✅ | Usage Examples | 145 → 78 | 67 lines | ✅ DONE |

**Session 10** (Phases 1-4): 528 lines saved
**Session 11** (Phases 5-7): 759 lines saved

**Total Reduction**: 1,287 lines (58.6%, within acceptable target range of 750-900 lines)

**Validation Results**:
- ✅ All references resolve correctly
- ✅ Command functionality verified
- ✅ 58.6% compression achieved (exceeded 30% target)
- ✅ All 5 modes documented (Standard, Cleanup, Validation, Analysis, Report Application)
- ✅ Essential information preserved in condensed format

**setup.md Subtotal**: 7 hours ✅

---

## Secondary Commands: Batch Processing (8 hours)

**Target**: 10-15 secondary commands
**Expected Reduction**: ~560 lines total

### Session 12: Batch Process Commands 1-5 (4 hours)

| Command | Expected Savings | Pattern Focus | Status |
|---------|-----------------|---------------|--------|
| plan.md | 80 lines | Agent invocation, standards discovery | ⏳ TODO |
| test.md | 60 lines | Testing integration patterns | ⏳ TODO |
| test-all.md | 40 lines | Testing patterns | ⏳ TODO |
| debug.md | 70 lines | Error recovery patterns | ⏳ TODO |
| document.md | 50 lines | Artifact cross-references | ⏳ TODO |

**Session 12 Process** (per command):
1. Scan for pattern matches: `grep -n "checkpoint\|agent\|error" [command].md`
2. Identify verbose sections (>50 lines)
3. Replace with pattern references
4. Preserve command-specific details
5. Validate: `bash .claude/tests/test_command_references.sh`
6. Commit: `git commit -m "refactor([command]): extract common patterns"`

**Session 12 Validation**:
```bash
for cmd in plan test test-all debug document; do
  bash .claude/tests/test_command_references.sh .claude/commands/$cmd.md
done
```

---

### Session 13: Batch Process Commands 6-10 (4 hours)

| Command | Expected Savings | Pattern Focus | Status |
|---------|-----------------|---------------|--------|
| revise.md | 90 lines | Checkpoint, error recovery | ⏳ TODO |
| expand.md | 50 lines | Progressive plan patterns | ⏳ TODO |
| collapse.md | 50 lines | Progressive plan patterns | ⏳ TODO |
| list.md | 30 lines | Artifact referencing | ⏳ TODO |
| update.md | 40 lines | Checkpoint management | ⏳ TODO |

**Session 13 Process**: Same as Session 12

**Session 13 Validation**:
```bash
for cmd in revise expand collapse list update; do
  bash .claude/tests/test_command_references.sh .claude/commands/$cmd.md
done
```

---

## Final Phase: Validation and Documentation (5 hours)

### Session 14: Final Validation (3 hours)

**Tasks**:
1. Run complete test suite
2. Validate all references resolve
3. Measure final LOC reduction
4. Test representative workflows
5. Review command-patterns.md

**Validation Commands**:
```bash
# Complete test suite
bash .claude/tests/run_all_tests.sh

# Validate all references
for cmd in .claude/commands/*.md; do
  echo "Validating $cmd..."
  bash .claude/tests/test_command_references.sh "$cmd"
done

# Measure final reduction
original=$(find .claude/commands/backups/phase4_20251010 -name "*.md" -exec wc -l {} + | tail -1 | awk '{print $1}')
refactored=$(find .claude/commands -maxdepth 1 -name "*.md" -exec wc -l {} + | tail -1 | awk '{print $1}')
reduction=$((original - refactored))
percentage=$((reduction * 100 / original))
echo "Original: $original lines"
echo "Refactored: $refactored lines"
echo "Reduction: $reduction lines ($percentage%)"
echo "Target: ~6,200 lines (53% reduction)"

# Test workflows
/orchestrate "Create a simple Python calculator"
/implement specs/plans/test_plan.md
/setup --analyze
```

**Success Criteria**:
- [ ] All tests pass
- [ ] All references resolve
- [ ] LOC reduction: 50-55% (target 53%)
- [ ] Representative workflows functional
- [ ] command-patterns.md coherent

---

### Session 15: Documentation (2 hours)

**Files to Create**:

1. **Lessons Learned** (`.claude/NEW_claude_system_optimization/phase_4_lessons_learned.md`)
   - What worked well
   - Challenges encountered
   - Metrics achieved
   - Recommendations for future phases

2. **Phase 4 Summary** (`.claude/NEW_claude_system_optimization/summaries/phase_4_summary.md`)
   - Implementation overview
   - Key changes and files modified
   - Test results
   - Metrics table
   - Lessons learned summary

**Final Commits**:
```bash
git add .claude/NEW_claude_system_optimization/phase_4_lessons_learned.md
git commit -m "docs(phase-4): lessons learned"

git add .claude/NEW_claude_system_optimization/summaries/phase_4_summary.md
git commit -m "docs(phase-4): implementation summary"
```

---

## Roadmap Summary

### Total Time Estimate

| Priority Level | Sessions | Hours | Status |
|----------------|----------|-------|--------|
| **Foundation** (Tasks 1-3) | 3 | 5.5h | ✅ COMPLETE |
| **Priority 2: implement.md** (Sessions 5-9) | 3 | 8h | ✅ COMPLETE |
| **Priority 3: setup.md** (Sessions 10-11) | 2 | 7h | ✅ COMPLETE |
| **Priority 1: orchestrate.md** (Tasks 4-7) | 4 | 14h | ⏳ TODO |
| **Secondary Commands** (Task 15) | 2 | 8h | ⏳ TODO |
| **Final Validation** (Tasks 16-18) | 2 | 5h | ⏳ TODO |
| **TOTAL** | **16 sessions** | **47.5h** | **43% COMPLETE (20.5h)** |

### Recommended Execution Schedule

**Option A: Intensive Sprint (2 weeks)**
- Week 1: Foundation + orchestrate.md + implement.md (5.5h + 14h + 16h = 35.5h)
- Week 2: setup.md + secondary commands + validation (7h + 8h + 5h = 20h)
- Total: 55.5 hours over 2 weeks (27.75h/week)

**Option B: Steady Progress (4 weeks)**
- Week 1: Foundation + orchestrate.md (5.5h + 14h = 19.5h)
- Week 2: implement.md (16h)
- Week 3: setup.md + half of secondary (7h + 4h = 11h)
- Week 4: Remaining secondary + validation (4h + 5h = 9h)
- Total: 55.5 hours over 4 weeks (13.9h/week)

**Option C: Incremental (8 weeks)**
- 1-2 sessions per week
- ~7 hours per week
- Allows for flexibility and integration with other work

### Git Commit Strategy

**Commit after each session**:
- Session commits: `refactor([command]): [specific change]`
- Validation commits: `docs([command]): validate refactoring`
- Final commits: `docs(phase-4): [summary/lessons]`

**Branch strategy**:
- Current branch: `feature/optimize_claude`
- All Phase 4 work stays on this branch
- Clean commit history with meaningful messages

---

## Session Checklists

### Pre-Session Checklist
- [ ] Git working directory clean
- [ ] Backup directory verified
- [ ] Test suite functional
- [ ] command-patterns.md up to date
- [ ] Line count baseline recorded

### Post-Session Checklist
- [ ] All edits completed
- [ ] References validated
- [ ] Line count measured
- [ ] Functional test passed
- [ ] Git commit created
- [ ] Session notes updated

### Session Notes Template

```markdown
## Session [N]: [Name]

**Date**: YYYY-MM-DD
**Duration**: Xh
**Command**: [command].md

### Changes Made
- [Change 1]
- [Change 2]

### Line Count
- Before: XXX lines
- After: YYY lines
- Reduction: ZZZ lines (WW%)

### Validation
- [x] References resolve
- [x] Functional test passed
- [x] Git commit created

### Issues Encountered
- [Issue 1 and resolution]

### Next Session
- [Next command or section]
```

---

## Progress Tracking

### Completion Percentages

**By File**:
- command-patterns.md: 100% ✅ (new patterns added)
- implement.md: 100% ✅ (868 lines, 47% reduction, commit bd1e706)
- setup.md: 100% ✅ (911 lines, 58.6% reduction, commit pending)
- orchestrate.md: 0% ⏳ (14h remaining)
- Secondary commands: 0% ⏳ (8h remaining)

**By Phase**:
- Preparation: 100% ✅ (5.5h complete)
- Refactoring: 56% ⏳ (15h complete, 22h remaining)
- Validation: 0% ⏳ (5h remaining)

**Overall Phase 4**: 43% complete (20.5h / 47.5h)

---

## Quick Reference

### Key Files
- **Patterns**: `.claude/docs/command-patterns.md` (1,041 lines)
- **Backups**: `.claude/commands/backups/phase4_20251010/`
- **Test Suite**: `.claude/tests/test_command_references.sh`
- **Main Plan**: `NEW_claude_system_optimization.md`
- **Detailed Spec**: `phase_4_command_documentation_extraction.md`

### Key Commands
```bash
# Run reference validation
bash .claude/tests/test_command_references.sh [command].md

# Measure line count
wc -l .claude/commands/[command].md

# Compare with backup
diff -u .claude/commands/backups/phase4_20251010/[command].md .claude/commands/[command].md | head -50

# Find pattern references in file
grep -n "](../docs/command-patterns.md#" .claude/commands/[command].md

# Validate all references
for cmd in .claude/commands/*.md; do
  bash .claude/tests/test_command_references.sh "$cmd"
done
```

### Pattern Reference Format
```markdown
For [concept], see [Pattern Name](../docs/command-patterns.md#pattern-anchor).

**[Command]-specific [aspect]:**
- [Detail 1]
- [Detail 2]
```

---

## Notes

### Critical Success Factors
1. **Incremental validation**: Test after each session
2. **Preserve command-specific content**: Never lose unique details
3. **Consistent reference format**: Use standard templates
4. **Functional testing**: Verify commands still work
5. **Clean commits**: One commit per session with clear messages

### Known Issues
- orchestrate.md already has some pattern references that need anchor fixes
- Some patterns may need additional examples during refactoring
- Grep newline handling in test script (minor issue, doesn't affect validation)

### Future Enhancements
- Consider extracting workflow diagrams to shared file
- Potential for shared example library
- Opportunity for slash command auto-generation from patterns

---

**Last Updated**: 2025-10-10
**Roadmap Version**: 1.1
**Phase 4 Status**: Foundation Complete, implement.md Complete, setup.md Complete, orchestrate.md Pending
