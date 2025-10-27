# Execution Enforcement Audit Checklist

## Audit Metadata
- **File Audited**: [command or agent file name]
- **Audit Date**: [YYYY-MM-DD]
- **Auditor**: [human or automated]
- **Score**: [0-100]
- **Grade**: [A/B/C/D/F]

---

## Pattern 1: Imperative Language (20 points)

### YOU MUST Markers (10 points)
- [ ] **+10**: File uses "YOU MUST" for mandatory actions
- [ ] **0**: Missing "YOU MUST" markers

**Found**: [count] instances
**Score**: __/10

### EXECUTE NOW Markers (10 points)
- [ ] **+10**: File uses "EXECUTE NOW" for immediate actions
- [ ] **0**: Missing "EXECUTE NOW" markers

**Found**: [count] instances
**Score**: __/10

**Pattern 1 Total**: __/20

---

## Pattern 2: Step Dependencies (15 points)

### Sequential Steps (15 points)
- [ ] **+15**: File has ≥3 sequential steps with dependencies
- [ ] **+7**: File has <3 steps
- [ ] **0**: No sequential step structure

**Found**: [count] steps
**Score**: __/15

**Pattern 2 Total**: __/15

---

## Pattern 3: Verification Checkpoints (20 points)

### MANDATORY VERIFICATION Markers (15 points)
- [ ] **+15**: File uses "MANDATORY VERIFICATION" for checks
- [ ] **0**: Missing mandatory verification

**Found**: [count] instances
**Score**: __/15

### CHECKPOINT Markers (5 points)
- [ ] **+5**: File uses "CHECKPOINT" markers
- [ ] **0**: Missing checkpoint markers

**Found**: [count] instances
**Score**: __/5

**Pattern 3 Total**: __/20

---

## Pattern 4: Fallback Mechanisms (10 points)

### Fallback for Failures (10 points)
- [ ] **+10**: File includes fallback mechanism for failures
- [ ] **0**: No fallback mechanism

**Found**: [yes/no]
**Score**: __/10

**Pattern 4 Total**: __/10

---

## Pattern 5: Critical Requirements (10 points)

### CRITICAL/ABSOLUTE REQUIREMENT Markers (10 points)
- [ ] **+10**: File has ≥3 critical requirement markers
- [ ] **+5**: File has 1-2 critical markers
- [ ] **0**: No critical markers

**Found**: [count] instances
**Score**: __/10

**Pattern 5 Total**: __/10

---

## Pattern 6: Path Verification (10 points)

### Absolute Path Checks (10 points)
- [ ] **+10**: File verifies paths are absolute
- [ ] **0**: No path verification

**Found**: [yes/no]
**Score**: __/10

**Pattern 6 Total**: __/10

---

## Pattern 7: File Creation Enforcement (10 points)

### File-First Pattern (10 points)
- [ ] **+10**: File enforces creation BEFORE other operations
- [ ] **+5**: Mentions file creation but doesn't enforce
- [ ] **0**: No file creation enforcement

**Found**: [enforced/mentioned/absent]
**Score**: __/10

**Pattern 7 Total**: __/10

---

## Pattern 8: Return Format Specification (5 points)

### Explicit Return Format (5 points)
- [ ] **+5**: File specifies exact return format ("return ONLY")
- [ ] **0**: No explicit return format

**Found**: [yes/no]
**Score**: __/5

**Pattern 8 Total**: __/5

---

## Pattern 9: Passive Voice Detection (Anti-Pattern)

### Passive/Descriptive Language (negative points)
- [ ] **-10**: File has >10 instances of "should/may/can/I am"
- [ ] **-5**: File has 5-10 instances
- [ ] **0**: Minimal passive voice (<5)

**Found**: [count] instances
**Score**: __/0

**Pattern 9 Total**: __/0

---

## Pattern 10: Error Handling (10 points)

### Explicit Error Handling (10 points)
- [ ] **+10**: File includes error handling (exit 1, ERROR messages)
- [ ] **0**: No explicit error handling

**Found**: [yes/no]
**Score**: __/10

**Pattern 10 Total**: __/10

---

## FINAL SCORE

**Total Score**: __/100
**Grade**: __

### Grade Scale
- **A**: 90-100 (Excellent enforcement)
- **B**: 80-89 (Good enforcement, minor gaps)
- **C**: 70-79 (Adequate enforcement, some gaps)
- **D**: 60-69 (Weak enforcement, major gaps)
- **F**: <60 (Insufficient enforcement)

---

## Findings

List all enforcement gaps and recommendations:

1. [Finding 1]
2. [Finding 2]
3. [Finding 3]

---

## Recommendations

Priority actions to improve score:

### High Priority
- [Recommendation 1]

### Medium Priority
- [Recommendation 2]

### Low Priority
- [Recommendation 3]

---

## Notes

Additional observations or context:

[Notes]
