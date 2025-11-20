# Bloat Detection Algorithm

This document describes the automatic bloat detection system used in Standard Mode to identify when CLAUDE.md optimization is beneficial.

**Referenced by**: [setup.md](../../../commands/setup.md)

**Contents**:
- Detection Thresholds
- User Interaction
- Opt-Out Mechanisms
- Detection Examples
- Integration with Cleanup Mode
- Threshold Rationale

---

## Bloat Detection Algorithm

Runs in **Standard Mode** when `/setup` is invoked with no flags and CLAUDE.md exists.

### Detection Thresholds

**Combined Logic**: `bloat_detected = (total_lines > 200) OR (any section > 30 lines)`

| Threshold | Condition | Example |
|-----------|-----------|---------|
| Total line count | File >200 lines | CLAUDE.md is 248 lines (threshold: 200) |
| Oversized sections | Any section >30 lines | Testing Standards: 52 lines (threshold: 30) |

### User Prompt and Response

When bloat detected, prompts: "CLAUDE.md is 248 lines. Optimize first? [Y/n/c]"

| Response | Action | Result |
|----------|--------|--------|
| [Y]es | Run cleanup extraction | Extract sections → Update links → Continue setup |
| [N]o | Skip optimization | Continue standard setup (can run /setup --cleanup later) |
| [C]ustomize | Show all oversized sections | User selects specific sections → Extract → Continue setup |

### Opt-Out Mechanisms

```bash
# Environment variable (global disable)
export SKIP_CLEANUP_PROMPT=1

# Command flag (single invocation)
/setup --no-cleanup-prompt

# Configuration file (future)
# .claude/config.yml
# cleanup:
#   auto_detect: false
```

After cleanup: Original setup goal continues, extraction committed, user sees both cleanup and setup results.

---

## Detection Examples

### Example 1: Total Line Count Trigger

**Scenario**: CLAUDE.md is 248 lines, all sections <30 lines

**Detection**: Total lines (248) > threshold (200)

**Prompt**: "CLAUDE.md is 248 lines. Optimize first? [Y/n/c]"

**Recommendation**: [Y]es - Even with smaller sections, the file is becoming unwieldy

### Example 2: Section Size Trigger

**Scenario**: CLAUDE.md is 180 lines, but Testing Standards section is 52 lines

**Detection**: Section size (52) > threshold (30)

**Prompt**: "CLAUDE.md is 180 lines with 1 oversized section. Optimize first? [Y/n/c]"

**Recommendation**: [Y]es - Extract the detailed Testing Standards to docs/TESTING.md

### Example 3: Combined Triggers

**Scenario**: CLAUDE.md is 310 lines with 3 sections >30 lines

**Detection**: Both total lines and section sizes exceed thresholds

**Prompt**: "CLAUDE.md is 310 lines with 3 oversized sections. Optimize first? [Y/n/c]"

**Recommendation**: [Y]es or [C]ustomize - Multiple optimization opportunities

### Example 4: No Bloat

**Scenario**: CLAUDE.md is 150 lines, all sections <30 lines

**Detection**: No bloat detected

**Behavior**: Standard mode proceeds without cleanup prompt

---

## Integration with Cleanup Mode

### Automatic Transition

When user responds [Y]es to bloat prompt:

1. **Setup pauses**: Current setup operation suspended
2. **Cleanup runs**: Full cleanup workflow executes (see [setup-modes-detailed.md](setup-modes-detailed.md#cleanup-workflow))
3. **Setup resumes**: Original setup goal continues with optimized CLAUDE.md
4. **Results shown**: Both cleanup impact and setup completion reported

### Manual Cleanup Later

When user responds [N]o to bloat prompt:

1. **Setup continues**: No cleanup performed
2. **User informed**: "You can optimize later with /setup --cleanup"
3. **No impact**: Standard setup completes normally

### Customize Option

When user responds [C]ustomize to bloat prompt:

1. **List sections**: Display all sections >30 lines with line counts
2. **Interactive selection**: User chooses which to extract
3. **Partial cleanup**: Extract only selected sections
4. **Setup continues**: Resume with partially optimized CLAUDE.md

---

## Threshold Rationale

### Why 200 Lines?

Based on research and practical experience:
- **Readability**: Files >200 lines require scrolling in most editors
- **Cognitive load**: Quick scanning becomes difficult beyond this size
- **Industry standard**: Many style guides recommend similar thresholds
- **Claude efficiency**: Smaller context files are easier to parse

### Why 30 Lines Per Section?

Balanced threshold for section-level bloat:
- **Screen height**: Most sections >30 lines don't fit on one screen
- **Extraction value**: Sections <30 lines rarely benefit from extraction
- **Context preservation**: Small sections are better kept inline
- **Quick reference**: Detailed documentation should be separate

### Customization (Future)

Planned configuration options:
```yaml
# .claude/config/bloat-detection.yml
thresholds:
  total_lines: 200        # Current default
  section_lines: 30       # Current default
  auto_prompt: true       # Show prompt automatically
```

---

## See Also

- [Setup Command Guide](../../commands/setup-command-guide.md) - Main setup documentation
- [Setup Modes](setup-modes-detailed.md) - Command mode details
- [Extraction Strategies](extraction-strategies.md) - Optimization techniques
- [Standards Analysis](standards-analysis.md) - Analysis and report application
