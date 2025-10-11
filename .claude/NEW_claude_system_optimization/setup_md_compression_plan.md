# Setup.md Compression Plan

## Current State
- **File**: `.claude/commands/setup.md`
- **Current Size**: 2,198 lines (after minimal compression)
- **Original Size**: 2,230 lines
- **Target Size**: 600-800 lines
- **Reduction Needed**: ~1,400-1,600 lines (64-73% compression)

## Compression Opportunities

### High-Impact Sections (Priority Order)

#### 1. Report Template Duplication (~395 lines)
**Location**: Lines 1548-1943
**Issue**: Massive report generation template with verbose examples
**Strategy**:
- Replace detailed template with concise structure outline
- Reference report format in command-patterns.md
- Keep only setup-specific template variations
**Expected Savings**: ~350 lines

#### 2. Argument Parsing Error Messages (~202 lines)
**Location**: Lines 108-310
**Issue**: Verbose error message examples for every flag combination
**Strategy**:
- Compress to table format: Flag combo → Error type → Brief message
- Remove all verbose "Output:" examples
- Keep only implementation logic pseudocode
**Expected Savings**: ~170 lines

#### 3. Extraction Preferences (~188 lines)
**Location**: Lines 535-723
**Issue**: Detailed config examples and explanations
**Strategy**:
- Compress threshold descriptions to table
- Remove verbose examples for each preference
- Keep only preference names and default values
**Expected Savings**: ~140 lines

#### 4. Bloat Detection Algorithm (~147 lines)
**Location**: Lines 792-939
**Issue**: Verbose workflow diagrams and response handling
**Strategy**:
- Compress thresholds to one-line descriptions
- Remove ASCII art prompt box
- Compress user response handling to bullet points
**Expected Savings**: ~110 lines

#### 5. Usage Examples (~144 lines)
**Location**: Lines 1944-2088
**Issue**: 6 verbose scenario walkthroughs
**Strategy**:
- Compress to 2-3 essential examples only
- Remove "What Happens:" step-by-step narratives
- Keep only command + brief outcome
**Expected Savings**: ~100 lines

#### 6. Extraction Preview Format (~136 lines)
**Location**: Lines 940-1076
**Issue**: Verbose ASCII art preview format and details
**Strategy**:
- Remove ASCII box example
- Compress preview details to bullet points
- Keep only essential format description
**Expected Savings**: ~100 lines

#### 7. Standards Analysis Report Template (~600 lines)
**Location**: Lines 1077-1680 (approximately)
**Issue**: Massive duplicate report template sections
**Strategy**:
- Extract report structure to command-patterns.md
- Keep only 5-type discrepancy table
- Remove all verbose algorithm pseudocode
**Expected Savings**: ~500 lines

#### 8. Report Application Mode (~400 lines)
**Location**: Lines 1555-1950 (approximately)
**Issue**: Verbose parsing algorithms and edge cases
**Strategy**:
- Compress parsing steps to workflow diagram
- Compress 10 edge cases to summary table
- Remove verbose bash examples
**Expected Savings**: ~320 lines

## Total Expected Savings
- High-impact sections: ~1,790 lines
- **Target achieved**: Yes (exceeds 1,400-1,600 target)

## Compression Strategy

### Phase 1: Major Template Extraction (~850 lines)
1. Compress Standards Analysis Report Template (lines 1077-1680)
2. Compress Report Application Mode (lines 1555-1950)
3. Compress Report Template sections (lines 1548-1943)

### Phase 2: Workflow Simplification (~490 lines)
4. Compress Argument Parsing errors (lines 108-310)
5. Compress Extraction Preferences (lines 535-723)
6. Compress Bloat Detection (lines 792-939)

### Phase 3: Example Reduction (~200 lines)
7. Compress Usage Examples (lines 1944-2088)
8. Compress Extraction Preview (lines 940-1076)

### Phase 4: Final Polish (~60 lines)
9. Remove any remaining duplication
10. Verify all essential information preserved

## Pattern References to Create

Add to `command-patterns.md`:
- **Standards Analysis Report Structure**: Template for analysis report generation
- **Report Parsing Workflow**: Generic report parsing algorithm
- **Error Message Patterns**: Standard error message format
- **Configuration Preference Patterns**: Common preference structure

## Validation Checklist

After compression:
- [ ] All 5 modes still described (Standard, Cleanup, Validation, Analysis, Report Application)
- [ ] Essential workflows preserved
- [ ] Flag combinations documented
- [ ] Report structure documented
- [ ] Integration with other commands documented
- [ ] File size: 600-800 lines

## Implementation Notes

**Approach**: Unlike implement.md which had extractable patterns, setup.md has massive template duplication that requires aggressive condensing rather than extraction.

**Key Principle**: Remove ALL verbose examples and templates. Keep only:
- Mode descriptions
- Flag combinations
- Workflow summaries
- Essential integration points

**Risk**: Setup.md contains report generation templates that may be referenced by implementation. Need to verify templates aren't hard-coded dependencies.

## Next Steps

1. Start fresh session with full context
2. Execute Phase 1 (Major Template Extraction)
3. Execute Phase 2 (Workflow Simplification)
4. Execute Phase 3 (Example Reduction)
5. Validate and commit
6. Update Phase 4 main document

## Success Criteria

- File size: 600-800 lines (64-73% reduction)
- All modes functional
- No information loss
- Improved readability
- Reduced duplication
