# All Command References in /supervise Command

## Executive Summary

Total command references found: **15 distinct slash command mentions** across 38 occurrences in `/supervise` command file.

**Breakdown by Command Type:**
- `/plan`: 8 occurrences (architectural prohibition + documentation)
- `/implement`: 10 occurrences (architectural prohibition + usage suggestions)
- `/debug`: 7 occurrences (architectural prohibition + workflow references)
- `/document`: 3 occurrences (architectural prohibition only)
- `/orchestrate`: 5 occurrences (comparison and relationship documentation)

**Reference Categories:**
1. **Architectural Prohibitions (Required)**: 5 critical references defining what NOT to do
2. **Documentation/Comparison**: 10 references explaining relationships and differences
3. **Usage Suggestions**: 3 references suggesting next steps (e.g., "run /implement after planning")
4. **Internal Pattern References**: 15 references describing internal implementation patterns (e.g., "uses /implement pattern internally")

## Detailed Analysis by Line Number

### Category 1: Architectural Prohibitions (MUST REMAIN)

These references define core architectural constraints and should NOT be removed:

**Line 21**: `/plan, /implement, /debug, /document` prohibition
- Context: "2. Invoke other commands via SlashCommand tool (/plan, /implement, /debug, /document)"
- Status: **CRITICAL - MUST REMAIN**
- Purpose: Defines prohibited SlashCommand invocations in "YOU MUST NEVER" section
- Recommendation: Keep as-is (architectural constraint)

**Line 38**: `/plan, /implement, /debug` prohibition enforcement
- Context: "SlashCommand: NEVER invoke /plan, /implement, /debug, or any command"
- Status: **CRITICAL - MUST REMAIN**
- Purpose: Explicit tool usage prohibition in "TOOLS PROHIBITED" section
- Recommendation: Keep as-is (enforcement statement)

**Line 52**: `/plan` in wrong pattern example
- Context: `command: "/plan create auth feature"` (in ❌ INCORRECT example)
- Status: **REQUIRED - MUST REMAIN**
- Purpose: Shows anti-pattern for command chaining
- Recommendation: Keep as-is (pedagogical example of what not to do)

**Line 57-58**: `/plan` context bloat explanation
- Context: "1. **Context Bloat**: Entire /plan command prompt injected (~2000 lines)" and "2. **Broken Behavioral Injection**: /plan's behavior not customizable"
- Status: **REQUIRED - MUST REMAIN**
- Purpose: Explains technical reasons for prohibition
- Recommendation: Keep as-is (architectural justification)

**Line 102**: `/plan, /implement, /debug, /document` enforcement check
- Context: "If you find yourself wanting to invoke /plan, /implement, /debug, or /document:"
- Status: **CRITICAL - MUST REMAIN**
- Purpose: Enforcement checkpoint with remediation steps
- Recommendation: Keep as-is (behavioral enforcement)

### Category 2: Documentation and Comparisons (REVIEW FOR REMOVAL)

These references explain relationships between commands and may be candidates for removal:

**Line 166-184**: `/orchestrate` comparison section
- Context: "### Relationship with /orchestrate" - entire section comparing /supervise vs /orchestrate
- Status: **REVIEW - CANDIDATE FOR REMOVAL**
- Purpose: Explains when to use each command
- Recommendation: **REMOVE or significantly reduce**
- Rationale: Violates "no cross-command references" principle; users should discover command capabilities independently

**Line 610**: `/debug` usage suggestion
- Context: "3. Use /debug for detailed investigation"
- Status: **REVIEW - CANDIDATE FOR REMOVAL**
- Purpose: Error recovery suggestion
- Recommendation: **REMOVE or replace with generic guidance**
- Rationale: Should not suggest other commands; provide inline guidance instead

### Category 3: Usage Suggestions (REVIEW FOR REMOVAL)

These references suggest running other commands as next steps:

**Line 788**: `/implement` next steps suggestion
- Context: `echo "    /implement $PLAN_PATH"`
- Status: **REVIEW - CANDIDATE FOR REMOVAL**
- Purpose: Suggests next step after research-and-plan workflow
- Recommendation: **REMOVE or replace with generic guidance**
- Rationale: Command should focus on its own responsibilities, not suggest other commands

**Line 1508**: `/implement` next steps suggestion (duplicate)
- Context: `echo "    /implement $PLAN_PATH"`
- Status: **REVIEW - CANDIDATE FOR REMOVAL**
- Purpose: Same as line 788 (appears in different workflow completion context)
- Recommendation: **REMOVE or replace with generic guidance**
- Rationale: Same rationale as line 788

**Line 2057**: `/implement` suggestion in example
- Context: "# - Suggests: /implement <plan-path>"
- Status: **REVIEW - CANDIDATE FOR REMOVAL**
- Purpose: Documents expected behavior in usage example
- Recommendation: **REMOVE or replace with generic statement**
- Rationale: Consistent with removal of actual suggestion code

### Category 4: Internal Pattern References (REVIEW FOR CONTEXT)

These references describe internal implementation patterns (e.g., "uses /implement pattern internally"):

**Line 1520**: `/implement` pattern reference
- Context: "**Critical**: Code-writer agent uses /implement pattern internally (phase-by-phase execution)"
- Status: **AMBIGUOUS - NEEDS CLARIFICATION**
- Purpose: Describes that code-writer agent follows /implement's execution pattern
- Recommendation: **REPHRASE to describe pattern directly**
- Alternative: "Code-writer agent uses phase-by-phase execution with testing and commits"
- Rationale: Can describe the pattern without naming the command

**Line 1548**: `/implement` pattern reference
- Context: "STEP 2: Execute plan using /implement pattern:"
- Status: **AMBIGUOUS - NEEDS CLARIFICATION**
- Purpose: Instructs code-writer agent to follow /implement's pattern
- Recommendation: **REPHRASE to describe pattern directly**
- Alternative: "STEP 2: Execute plan using phase-by-phase pattern:"
- Rationale: Pattern can be described without command name

## Summary of Recommendations

### KEEP (5 references - Architectural Prohibitions)
- Lines 21, 38, 52, 57-58, 102: Core architectural constraints defining prohibited behavior

### REMOVE (5 references - Cross-Command Suggestions)
- Lines 166-184: /orchestrate comparison section
- Line 610: /debug suggestion in error recovery
- Lines 788, 1508, 2057: /implement next steps suggestions

### REPHRASE (2 references - Pattern Descriptions)
- Lines 1520, 1548: Replace "/implement pattern" with direct pattern description ("phase-by-phase execution pattern")

### TOTAL IMPACT
- **Keep**: 5 references (33%)
- **Remove**: 5 references (33%)
- **Rephrase**: 2 references (13%)
- **Other occurrences**: 3 references are path strings (e.g., `.claude/lib/error-handling.sh`) not slash commands

## Compliance Assessment

**Architectural Prohibition Compliance**: ✅ STRONG
- Clear, explicit prohibition statements in multiple sections
- Technical justification provided (context bloat, behavioral injection)
- Enforcement checkpoints with remediation steps

**No Cross-Command Reference Compliance**: ❌ WEAK
- Multiple suggestions to run other commands (/implement, /debug)
- Extensive comparison with /orchestrate command
- Pattern references that could be made command-agnostic

**Recommended Priority**: Remove cross-command suggestions and /orchestrate comparison to achieve full compliance with "no command chaining" principle while preserving critical architectural prohibitions.

