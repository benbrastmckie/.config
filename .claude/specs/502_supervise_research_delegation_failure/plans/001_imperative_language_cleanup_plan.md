# Imperative Language Cleanup and Streamlining Plan

## Metadata
- **Date**: 2025-10-27
- **Feature**: Streamline /supervise and /coordinate commands by removing undermined imperative patterns and improving documentation
- **Scope**: Command files, documentation (validation enhancement optional)
- **Estimated Phases**: 4
- **Complexity**: Medium
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - /home/benjamin/.config/.claude/specs/502_supervise_research_delegation_failure/reports/001_root_cause_analysis.md

## Revision History

### 2025-10-27 - Revision 1
**Changes**: Reduced from 5 phases to 4, made validation enhancement optional
**Reason**: User requested focus on streamlining commands and clear documentation over validation complexity
**Modified Phases**:
- Removed mandatory Phase 3 (validation script enhancement) - now optional
- Reordered phases to prioritize command fixes and documentation
- Simplified success criteria to focus on command quality over validation tooling

## Overview

This plan addresses the **undermined imperative pattern** anti-pattern discovered in `/supervise` command (line 1072) where template disclaimers contradict imperative directives, causing 0% agent delegation rates. The fix will:

1. **Streamline `/supervise` and `/coordinate` commands** - Remove all undermining disclaimers and convert to clean bullet-point patterns
2. **Provide clear documentation** - Add comprehensive anti-pattern examples to guide future development
3. **Maintain simplicity** - Focus on economical, efficient workflows without unnecessary complexity
4. **Optional validation** - Validation script enhancement is optional and only if simple to implement

**Root Cause**: The phrase "**Note**: The actual implementation will generate N Task calls" on line 1072 of `/supervise` creates template assumption that contradicts the imperative directive on line 1050, causing AI to skip agent invocation.

**Impact**: Commands with undermined imperatives show 0% delegation rates vs >90% for clean imperatives.

**Philosophy**: Clear, simple command files are the primary defense against anti-patterns. Documentation teaches the pattern. Validation is helpful but secondary to good design.

## Success Criteria

### Essential (Must Have)
- [ ] `/supervise` command has 0 undermining disclaimers after imperative directives
- [ ] `/coordinate` command has 0 undermining disclaimers after imperative directives
- [ ] All agent invocations use bullet-point pattern (not YAML-style curly braces)
- [ ] Commands are streamlined for clarity and efficiency
- [ ] Documentation includes "Undermined Imperative Pattern" anti-pattern with clear examples
- [ ] Imperative Language Guide updated with undermining disclaimer pitfall
- [ ] Manual testing confirms >90% delegation rate for both commands

### Optional (Nice to Have)
- [ ] Validation script enhanced to detect undermining disclaimers (only if straightforward)
- [ ] Pre-commit hook to catch future regressions (only if validation enhancement done)

## Technical Design

### Architecture

**Pattern Transformation** (Streamlined Approach):
```
BEFORE (Undermined - Confusing):
**EXECUTE NOW**: USE the Task tool...
Task { ... }
**Note**: The actual implementation will generate N calls

AFTER (Clean - Simple and Clear):
**EXECUTE NOW**: USE the Task tool for each topic with these parameters:
- subagent_type: "general-purpose"
- description: "Research [insert topic name]..."
- prompt: |
    ...
```

**Streamlining Principles**:
1. **Clarity over cleverness** - Straightforward instructions without template language
2. **Consistency** - All agent invocations follow same bullet-point pattern
3. **Simplicity** - Remove confusing disclaimers and notes that undermine directives
4. **Efficiency** - Economical workflows that accomplish goals without bloat

### Key Changes

**What Gets Removed**:
- All "**Note**:" disclaimers following imperative directives
- Template language suggesting "future generation" of invocations
- YAML-style `Task { }` blocks that look like code examples
- Confusing references to "actual implementation" vs current execution

**What Gets Added**:
- Clear "for each [item]" phrasing to indicate loop expectations
- Placeholder syntax `[insert value]` that signals substitution
- Bullet-point parameter lists that look like instructions, not code
- Direct, unambiguous imperatives with no hedging

## Implementation Phases

### Phase 0: Analysis and Preparation [COMPLETED]
**Objective**: Identify all instances of undermined imperatives and prepare fix locations
**Complexity**: Low
**Estimated Time**: 20 minutes

Tasks:
- [x] Search `/supervise` for all "**Note**:" phrases within 25 lines of "**EXECUTE NOW**"
  ```bash
  grep -n -A 25 "\*\*EXECUTE NOW\*\*" .claude/commands/supervise.md | grep -B 25 "\*\*Note\*\*"
  ```
- [x] Search `/coordinate` for all "**Note**:" phrases within 25 lines of "**EXECUTE NOW**"
  ```bash
  grep -n -A 25 "\*\*EXECUTE NOW\*\*" .claude/commands/coordinate.md | grep -B 25 "\*\*Note\*\*"
  ```
- [x] Document all line numbers with undermining disclaimers in both files
- [x] Identify all YAML-style `Task { }` blocks that should be converted to bullet-point patterns
- [x] Create backup copies for safety:
  ```bash
  cp .claude/commands/supervise.md .claude/commands/supervise.md.backup-$(date +%Y%m%d_%H%M%S)
  cp .claude/commands/coordinate.md .claude/commands/coordinate.md.backup-$(date +%Y%m%d_%H%M%S)
  ```

**Analysis Results**:
- supervise.md: 6 YAML-style blocks, undermining disclaimer at line 1072
- coordinate.md: 2 YAML-style blocks, no undermining disclaimers found
- Backups created: supervise.md.backup-20251027-phase0, coordinate.md.backup-20251027-phase0

Testing:
```bash
# Find undermining disclaimers
grep -n -A 25 "\*\*EXECUTE NOW\*\*" .claude/commands/supervise.md | grep -B 25 "\*\*Note\*\*"
grep -n -A 25 "\*\*EXECUTE NOW\*\*" .claude/commands/coordinate.md | grep -B 25 "\*\*Note\*\*"

# Count YAML-style blocks
grep -c "^Task {" .claude/commands/supervise.md
grep -c "^Task {" .claude/commands/coordinate.md
```

Expected Outcome:
- Complete list of line numbers requiring fixes
- Backup files created for rollback safety
- Clear understanding of scope (typically 8-10 locations across both files)

---

### Phase 1: Streamline /supervise Command [COMPLETED]
**Objective**: Remove all undermining disclaimers and convert to clean bullet-point patterns in `/supervise`
**Complexity**: Medium
**Estimated Time**: 45 minutes

Tasks:
- [x] Fix Phase 1 research agent invocation (lines ~1050-1072 in supervise.md)
  - **Remove** line 1072: "**Note**: The actual implementation will generate N Task calls..."
  - **Replace** `Task { }` block with bullet-point parameters
  - **Use** `[insert topic name]` placeholder syntax instead of `${TOPIC_NAME}`
  - **Add** clarifying phrase: "for each topic (1 to $RESEARCH_COMPLEXITY)"
- [x] Fix Phase 2 planning agent invocation (~line 1337)
  - Remove any undermining disclaimers after EXECUTE NOW
  - Convert to bullet-point pattern if needed
- [x] Fix Phase 3 implementation agent invocation (~line 1536)
  - Remove any undermining disclaimers
  - Convert to bullet-point pattern if needed
- [x] Fix Phase 4 testing agent invocation (~line 1669)
  - Remove any undermining disclaimers
  - Convert to bullet-point pattern if needed
- [x] Fix Phase 5 debug agent invocations (~lines 1810, 1942, 2015)
  - Remove any undermining disclaimers
  - Convert to bullet-point pattern if needed
- [x] Fix Phase 6 documentation agent invocation (~line 2109)
  - Remove any undermining disclaimers
  - Convert to bullet-point pattern if needed
- [x] **Overall streamlining**: Review entire file for clarity
  - Remove redundant explanations
  - Simplify overly complex instructions
  - Ensure consistent tone and structure

**Reference Pattern** (from `/research` command - proven to work):
```markdown
**EXECUTE NOW**: USE the Task tool for each subtopic with these parameters:

- subagent_type: "general-purpose"
- description: "Research [insert actual subtopic name] with mandatory artifact creation"
- timeout: 300000  # 5 minutes per research agent
- prompt: |
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [insert display-friendly subtopic name]
    - Report Path: [insert absolute path from REPORT_PATHS array]
    - Project Standards: /home/benjamin/.config/CLAUDE.md

    **YOUR ROLE**: You are a SUBAGENT executing research for ONE subtopic.

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [EXACT_ABSOLUTE_PATH]
```

Testing:
```bash
# Verify no undermining disclaimers remain
grep -n -A 25 "\*\*EXECUTE NOW\*\*" .claude/commands/supervise.md | grep -B 25 "\*\*Note\*\*"
# Should return empty (no matches)

# Verify bullet-point patterns present
grep -n -A 10 "\*\*EXECUTE NOW\*\*" .claude/commands/supervise.md | grep "^- subagent_type"
# Should return 6+ matches (one per agent invocation)

# Quick check for consistency
grep -c "^- subagent_type" .claude/commands/supervise.md
grep -c "^- description" .claude/commands/supervise.md
grep -c "^- prompt" .claude/commands/supervise.md
# All three counts should match
```

Expected Outcome:
- 0 undermining disclaimers in `/supervise`
- All agent invocations use consistent bullet-point pattern
- File is cleaner, more streamlined, easier to read
- Reduction in overall file complexity while maintaining functionality

---

### Phase 2: Streamline /coordinate Command [COMPLETED]
**Objective**: Remove all undermining disclaimers and convert to clean bullet-point patterns in `/coordinate`
**Complexity**: Medium
**Estimated Time**: 45 minutes

Tasks:
- [x] Apply same transformations as Phase 1 to all agent invocations:
  - Lines around 1072: Research agent invocation
  - Lines around 1382: Planning agent invocation
  - Lines around 1663: Implementation agent invocation
  - Lines around 1885: Testing agent invocation
  - Lines around 2018, 2091, 2122: Debug agent invocations
  - Lines around 2229: Documentation agent invocation
- [ ] For each invocation:
  - **Remove** all "**Note**:" disclaimers within 25 lines of "**EXECUTE NOW**"
  - **Convert** YAML-style `Task { }` blocks to bullet-point parameters
  - **Use** `[insert value]` placeholder syntax consistently
  - **Add** clarifying phrases like "for each [item]" where loops expected
- [ ] Ensure consistency with `/research` proven pattern
- [x] **Overall streamlining**: Review entire file for clarity
  - Remove redundant sections
  - Simplify complex explanations
  - Ensure consistent structure with `/supervise`

Testing:
```bash
# Verify no undermining disclaimers
grep -n -A 25 "\*\*EXECUTE NOW\*\*" .claude/commands/coordinate.md | grep -B 25 "\*\*Note\*\*"
# Should return empty

# Verify bullet-point patterns
grep -n -A 10 "\*\*EXECUTE NOW\*\*" .claude/commands/coordinate.md | grep "^- subagent_type"
# Should return 8+ matches

# Quick consistency check
grep -c "^- subagent_type" .claude/commands/coordinate.md
grep -c "^- description" .claude/commands/coordinate.md
grep -c "^- prompt" .claude/commands/coordinate.md
# All three counts should match
```

Expected Outcome:
- 0 undermining disclaimers in `/coordinate`
- All agent invocations use consistent bullet-point pattern
- File is cleaner and more streamlined
- Consistency between `/supervise` and `/coordinate` agent invocation patterns

---

### Phase 3: Update Documentation
**Objective**: Provide clear documentation on undermined imperative anti-pattern to prevent future occurrences
**Complexity**: Medium
**Estimated Time**: 40 minutes

**Focus**: Education and clear examples over enforcement tooling.

Tasks:
- [x] Update `.claude/docs/guides/imperative-language-guide.md`
  - Add new section: "### Pitfall 5: Undermining Disclaimers" after Pitfall 4 (~line 505)
  - **Bad example**: Show EXECUTE NOW followed by "**Note**: will generate"
  - **Good example**: Show EXECUTE NOW with bullet-point parameters, no disclaimer
  - **Explanation**: Why disclaimers create template assumption
  - **Detection**: Simple grep command to find the pattern
  - Add to Quick Reference checklist: "[ ] No template disclaimers after imperative directives"
- [x] Update `.claude/docs/concepts/patterns/behavioral-injection.md`
  - Add "Undermined Imperative Pattern" to anti-patterns section
  - Include concrete before/after example from `/supervise` fix
  - Reference Spec 502 root cause analysis for details
  - Emphasize simplicity: "The fix is removing the undermining text, not adding validation"
- [x] Update `.claude/docs/guides/orchestration-troubleshooting.md`
  - Add troubleshooting entry: "Agents not being invoked → Check for template disclaimers"
  - Include simple grep command: `grep -A 25 "EXECUTE NOW" command.md | grep "Note"`
  - Explain what to look for: future tense, template language, disclaimers
- [ ] Update `.claude/docs/reference/command_architecture_standards.md`
  - Add clarification to Standard 11 (Imperative Agent Invocation Pattern)
  - Explicitly state: "Imperative directives MUST NOT be followed by disclaimers suggesting template usage"
  - Add example showing undermined vs clean imperative
  - Keep it simple: One clear rule, one clear example

**Documentation Philosophy**:
- **Teach, don't enforce** - Clear examples prevent errors better than complex validation
- **Simple rules** - "Don't contradict your imperatives" is easier than multi-regex validation
- **Practical guidance** - Show what to do, not just what not to do
- **Minimal overhead** - Documentation should be easy to write and maintain

File Locations:
- `.claude/docs/guides/imperative-language-guide.md` (line ~505 for new pitfall)
- `.claude/docs/concepts/patterns/behavioral-injection.md` (anti-patterns section)
- `.claude/docs/guides/orchestration-troubleshooting.md` (troubleshooting section)
- `.claude/docs/reference/command_architecture_standards.md` (Standard 11)

Testing:
```bash
# Verify all sections added
grep -n "Pitfall 5: Undermining Disclaimers" .claude/docs/guides/imperative-language-guide.md
grep -n "Undermined Imperative Pattern" .claude/docs/concepts/patterns/behavioral-injection.md
grep -n "template disclaimers" .claude/docs/guides/orchestration-troubleshooting.md
grep -A 10 "Standard 11" .claude/docs/reference/command_architecture_standards.md | grep -i "disclaimer"

# All should return matches confirming documentation added
```

Expected Outcome:
- 4 documentation files updated with clear anti-pattern guidance
- Concrete examples showing the problem and solution
- Simple detection method (grep) documented
- Educational focus: help developers avoid the pattern, not just catch it

---

### Phase 4: Testing and Validation
**Objective**: Verify fixes work through manual testing and simple verification
**Complexity**: Low
**Estimated Time**: 30 minutes

Tasks:
- [ ] Run simple verification on both commands
  ```bash
  # Check for any remaining undermining disclaimers
  grep -A 25 "\*\*EXECUTE NOW\*\*" .claude/commands/supervise.md | grep -i "note.*generate\|template\|example only"
  grep -A 25 "\*\*EXECUTE NOW\*\*" .claude/commands/coordinate.md | grep -i "note.*generate\|template\|example only"
  # Both should return empty
  ```
- [ ] Verify bullet-point pattern consistency
  ```bash
  # Count agent invocations in each file
  echo "supervise invocations: $(grep -c '^- subagent_type' .claude/commands/supervise.md)"
  echo "coordinate invocations: $(grep -c '^- subagent_type' .claude/commands/coordinate.md)"
  # Expect 6+ for supervise, 8+ for coordinate
  ```
- [ ] Test `/supervise` command with simple workflow
  - **Test case**: `/supervise "research README.md patterns in .claude/docs/"`
  - **Verify**: Task tool invocations occur (not direct Bash commands)
  - **Verify**: Research files created in correct locations (specs/XXX_topic/reports/)
  - **Observe**: AI behavior during execution - does it delegate to agents?
- [ ] Test `/coordinate` command with simple workflow
  - **Test case**: `/coordinate "research and plan documentation improvements"`
  - **Verify**: Parallel research agent invocations
  - **Verify**: Plan creation via plan-architect agent
  - **Observe**: Delegation pattern matches expected behavior
- [ ] **Compare before/after**:
  - Review backup files to see what changed
  - Confirm changes improve clarity without losing functionality
  - Measure delegation rates: should be >90% for both commands
- [ ] Create brief validation summary:
  - Line numbers fixed in each file
  - Number of undermining disclaimers removed
  - Test workflow results
  - Delegation rate observations

**Simple Validation Approach**:
```bash
# Create a simple validation summary
cat > /tmp/validation-summary.txt << 'EOF'
# Validation Summary - Undermined Imperative Pattern Fix

## Changes Made
supervise.md:
- Removed X undermining disclaimers
- Converted Y YAML blocks to bullet-point patterns
- Lines modified: [list line numbers]

coordinate.md:
- Removed X undermining disclaimers
- Converted Y YAML blocks to bullet-point patterns
- Lines modified: [list line numbers]

## Verification Results
- Undermining disclaimers remaining: 0
- Agent invocations using bullet-point pattern: 100%
- Test workflows: Both commands delegate to agents successfully
- Delegation rate: >90%

## Documentation Updates
- imperative-language-guide.md: Added Pitfall 5
- behavioral-injection.md: Added anti-pattern entry
- orchestration-troubleshooting.md: Added troubleshooting entry
- command_architecture_standards.md: Updated Standard 11
EOF

cat /tmp/validation-summary.txt
```

Expected Outcome:
- Both commands pass simple verification (no undermining disclaimers)
- Manual testing confirms >90% delegation rates
- Commands are cleaner and easier to understand
- Documentation provides clear guidance for future development
- Validation summary documents successful fixes

---

## Optional: Validation Script Enhancement

**Only complete if straightforward to implement.**

If you choose to enhance the validation script:

**Tasks**:
- [ ] Add simple check to `.claude/lib/validate-agent-invocation-pattern.sh`
- [ ] Look for "**Note**:" within 10 lines after "**EXECUTE NOW**"
- [ ] Report line numbers where found
- [ ] Keep it simple - basic grep/sed, no complex regex

**Simple Implementation** (if chosen):
```bash
# Check 6: Detect undermining disclaimers (simple version)
echo "[Check 6] Detecting undermining disclaimers..."

# Find EXECUTE NOW followed by Note within 10 lines
FOUND=$(grep -n -A 10 "EXECUTE NOW" "$COMMAND_FILE" | grep -B 1 "Note:" || true)

if [[ -n "$FOUND" ]]; then
  echo "  ⚠️  WARNING: Found 'Note:' near EXECUTE NOW directives"
  echo "  This may create template assumption. Review manually."
else
  echo "  ✓ No obvious undermining disclaimers"
fi
```

**Don't implement if**:
- Requires complex regex patterns
- Adds significant code complexity
- Takes more than 15 minutes
- Creates maintenance burden

**Alternative**: Just document the grep command in troubleshooting guide. Developers can run it manually when needed.

---

## Testing Strategy

### Per-Phase Testing
- **Phase 0**: Grep searches to identify fix locations
- **Phase 1**: Grep verification after each edit to `/supervise`
- **Phase 2**: Grep verification after each edit to `/coordinate`
- **Phase 3**: Grep verification that documentation sections added
- **Phase 4**: Manual workflow testing + simple verification

### Integration Testing
- Run both commands with real workflows
- Observe delegation behavior
- Compare with backup files to ensure improvements

### Simplicity Focus
- No complex test frameworks needed
- Simple grep commands for verification
- Manual observation for behavior validation
- Backup files provide easy rollback if needed

## Documentation Requirements

### Files to Update (Phase 3)
1. `.claude/docs/guides/imperative-language-guide.md` - Add Pitfall 5
2. `.claude/docs/concepts/patterns/behavioral-injection.md` - Add anti-pattern
3. `.claude/docs/guides/orchestration-troubleshooting.md` - Add troubleshooting entry
4. `.claude/docs/reference/command_architecture_standards.md` - Update Standard 11

### Documentation Approach
- **Clear examples** over abstract rules
- **Simple detection methods** over complex validation
- **Educational tone** that explains why, not just what
- **Practical guidance** developers can apply immediately

## Dependencies

### Required Files
- `/home/benjamin/.config/.claude/commands/supervise.md` (exists)
- `/home/benjamin/.config/.claude/commands/coordinate.md` (exists)
- `/home/benjamin/.config/.claude/docs/guides/imperative-language-guide.md` (exists)
- `/home/benjamin/.config/.claude/commands/research.md` (reference for proven pattern)

### Optional Files
- `/home/benjamin/.config/.claude/lib/validate-agent-invocation-pattern.sh` (only if enhancement chosen)

### External Dependencies
None - all work is internal to .claude/ system

## Risk Assessment

### Low Risk
- **Backup files created** in Phase 0 before any edits
- **Simple transformations** - removing text and converting syntax
- **Reference pattern proven** - `/research` command shows pattern works (>90% delegation)
- **Incremental approach** - fix one file, test, then fix second file

### Mitigation
- Create backups before any changes
- Test after each phase
- Keep reference pattern (`/research` command) open while editing
- If anything goes wrong, restore from backup

## Notes

### Design Philosophy

**Simplicity First**:
- Clear command files prevent problems better than validation catches them
- Documentation teaches patterns, developers apply them
- Validation is helpful but optional - good design is mandatory

**Streamlining Over Feature Bloat**:
- Remove confusing disclaimers that undermine directives
- Consistent patterns across all orchestration commands
- Economical workflows that accomplish goals without complexity

**Education Over Enforcement**:
- Teach developers why the pattern is wrong
- Show clear before/after examples
- Provide simple detection methods
- Trust developers to apply the guidance

### Historical Context
This is the second regression of this anti-pattern:
- **First occurrence**: Fixed in Spec 438 (2025-10-24) - removed YAML code fences
- **Second occurrence**: Current issue - undermining disclaimers added
- **Root cause**: Manual edits without awareness of anti-pattern

**Prevention approach**:
- **Primary**: Clear documentation educating developers
- **Secondary**: Simple detection methods in troubleshooting guide
- **Optional**: Validation script enhancement (only if trivial)

### Reference Materials
- **Working pattern**: `/research` command (proven >90% delegation)
- **Root cause analysis**: Spec 502 report (001_root_cause_analysis.md)
- **Historical specs**: Spec 438, 495, 497 (agent delegation fixes)

### Why This Matters
- **0% delegation** when imperatives are undermined
- **>90% delegation** with clean imperatives
- **Simpler commands** are easier to maintain and debug
- **Clear documentation** prevents future regressions

## Success Metrics

### Quantitative
- Undermining disclaimers: 0 (both commands)
- Delegation rate: >90% (measured via manual testing)
- Documentation updates: 4 files
- Command file clarity: Subjective improvement (cleaner, more streamlined)

### Qualitative
- Commands are easier to read and understand
- Agent invocations follow consistent pattern
- Documentation clearly explains anti-pattern with examples
- Developers have clear guidance on avoiding this pattern
- No unnecessary complexity added to validation or commands

## Implementation Timeline

**Total Estimated Time**: 2 hours 20 minutes (reduced from 3:45)

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 0: Analysis | 20 min | None |
| Phase 1: Streamline /supervise | 45 min | Phase 0 complete |
| Phase 2: Streamline /coordinate | 45 min | Phase 1 complete |
| Phase 3: Documentation | 40 min | Phases 1-2 complete |
| Phase 4: Testing | 30 min | Phases 1-3 complete |

**Optional**: Validation enhancement (+15 min if chosen, only if straightforward)

**Recommended approach**: Complete phases sequentially, test after each phase, skip optional validation if it adds complexity.
