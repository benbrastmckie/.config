# Execution Enforcement: Migration

**Related Documents**:
- [Overview](execution-enforcement-overview.md) - Introduction and standards
- [Patterns](execution-enforcement-patterns.md) - Language patterns
- [Validation](execution-enforcement-validation.md) - Validation and troubleshooting

---

## Migration Process

### Phase 1: Audit Existing File

1. **Identify weak language**:
   - "should", "may", "can"
   - Passive voice
   - Vague instructions

2. **Find missing patterns**:
   - No STEP dependencies
   - No verification checkpoints
   - No completion criteria

3. **Score current state**:
   - Count weak language instances
   - Count missing patterns
   - Calculate initial score

### Phase 2: Apply Transformations

1. **Replace role declarations**
2. **Add step dependencies**
3. **Add verification checkpoints**
4. **Add template enforcement**
5. **Add completion criteria**

### Phase 3: Validate

1. **Run checklist**
2. **Test execution**
3. **Verify file creation**
4. **Check output format**

## Migration Checklist

### Before Migration

- [ ] Read entire file
- [ ] Identify all weak language
- [ ] List missing patterns
- [ ] Note output requirements
- [ ] Understand dependencies

### During Migration

- [ ] Transform role declarations
- [ ] Add STEP dependencies
- [ ] Add EXECUTE NOW blocks
- [ ] Add MANDATORY VERIFICATION
- [ ] Add template enforcement
- [ ] Add completion criteria
- [ ] Add WHY THIS MATTERS

### After Migration

- [ ] Run validation checklist
- [ ] Score reaches 95+
- [ ] Test with real invocation
- [ ] Verify file created
- [ ] Verify format correct

## Common Migration Patterns

### Pattern A: Role Declaration

```markdown
# Before
I am a specialized agent focused on research and analysis.

My role is to:
- Investigate patterns
- Create reports
- Emit progress markers

# After
**YOU MUST perform these exact steps in sequence:**

**ROLE**: You are a research specialist with ABSOLUTE REQUIREMENT to create report files.

**PRIMARY OBLIGATION**: File creation is NOT optional.
```

### Pattern B: Task List to Steps

```markdown
# Before
Steps to complete:
- Research the topic
- Organize findings
- Create report
- Verify links

# After
**STEP 1 (REQUIRED BEFORE STEP 2)** - Research Topic

YOU MUST investigate using Grep, Glob, Read tools.

**STEP 2 (REQUIRED BEFORE STEP 3)** - Organize Findings

Structure findings into sections.

**STEP 3 (ABSOLUTE REQUIREMENT)** - Create Report

**EXECUTE NOW**: Create report file.
**THIS IS NON-NEGOTIABLE**

**STEP 4 (MANDATORY VERIFICATION)** - Verify

```bash
test -f "$REPORT_PATH" || echo "CRITICAL: Not created"
```
```

### Pattern C: Output Format

```markdown
# Before
Include these sections:
- Overview
- Findings
- Recommendations

# After
**OUTPUT FORMAT - Use THIS EXACT TEMPLATE**

```markdown
# [Title]

## Overview
[REQUIRED - 2-3 sentences]

## Findings
[REQUIRED - Minimum 5 bullet points]

## Recommendations
[REQUIRED - Minimum 3 items]
```

**ENFORCEMENT**: REQUIRED sections are NON-NEGOTIABLE.
```

### Pattern D: Completion Criteria

```markdown
# Before
Return your findings when complete.

# After
**COMPLETION CRITERIA - ALL REQUIRED**:
- [x] Report file exists at exact path
- [x] All mandatory sections present
- [x] Internal links verified
- [x] Checkpoint emitted
- [x] Path returned: "CREATED: /path/file.md"

**NON-COMPLIANCE**: Returning summary without file is UNACCEPTABLE.
```

## Migration Examples

### Example 1: Research Specialist

**Before**: 150 lines, weak language, no enforcement

**After**: 180 lines, strong enforcement, all patterns

**Changes**:
- +15 lines: Step dependencies
- +10 lines: Verification blocks
- +5 lines: Template enforcement

**Result**: 100% file creation rate

### Example 2: Plan Architect

**Before**: 100 lines, implicit requirements

**After**: 130 lines, explicit enforcement

**Changes**:
- Role transformation
- Output template
- Completion criteria

**Result**: Consistent plan format

## Incremental Migration

For large files, migrate incrementally:

### Week 1: Critical Paths

- Role declaration
- Primary obligation
- Output format

### Week 2: Dependencies

- STEP sequences
- Verification checkpoints

### Week 3: Completion

- Completion criteria
- WHY THIS MATTERS
- Fallback integration

## Priority Order

Migrate in this order for maximum impact:

1. **research-specialist.md** - Most used agent
2. **plan-architect.md** - Plan quality critical
3. **implementation-agent.md** - Code changes
4. **test-specialist.md** - Test reliability
5. **doc-writer.md** - Documentation consistency

## Time Estimates

| File Size | Migration Time | Validation Time |
|-----------|----------------|-----------------|
| <100 lines | 30 min | 15 min |
| 100-200 lines | 1 hour | 30 min |
| 200-400 lines | 2 hours | 1 hour |
| >400 lines | 3+ hours | 1.5 hours |

---

## Related Documentation

- [Overview](execution-enforcement-overview.md)
- [Patterns](execution-enforcement-patterns.md)
- [Validation](execution-enforcement-validation.md)
