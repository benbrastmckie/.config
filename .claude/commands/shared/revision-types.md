# Revision Types and Operation Modes

This document describes the different operation modes and revision types supported by the /revise command.

**Referenced by**: [revise.md](../revise.md)

**Contents**:
- Interactive Mode vs Auto-Mode
- Mode Comparison
- When to Use Each Mode

---

## Operation Modes

### Interactive Mode (Default)

**Purpose**: User-driven plan revisions with full context and explanation

**Behavior**:
- User provides natural language revision description
- Command infers which plan to revise from conversation context
- Presents changes and asks for confirmation
- Creates detailed revision history with rationale
- Suitable for major strategic changes

**Use When**:
- Changing project scope or requirements
- Incorporating new research findings
- Restructuring phases based on lessons learned
- User wants visibility and control over changes

### Automated Mode (`--auto-mode`)

**Purpose**: Programmatic plan revision triggered by `/implement` during execution

**Behavior**:
- Accepts structured JSON context with specific revision parameters
- Executes deterministic revision logic based on `revision_type`
- Returns machine-readable success/failure status
- Creates concise revision history for audit trail
- Designed for /implement integration (no user interaction)

**Use When**:
- `/implement` detects complexity threshold exceeded
- Multiple test failures indicate missing prerequisites
- Scope drift detected (missing phases discovered)
- Automated expansion of phases is needed

**Not Suitable For**:
- Strategic plan changes requiring human judgment
- Incorporating new requirements from stakeholders
- Major scope changes or pivots

## Important Notes

### What This Command Does
- **Modifies plans or reports** with your requested changes
- **Preserves completion status** of already-executed phases (plans only)
- **Adds revision history** to track changes
- **Creates a backup** of the original artifact
- **Updates phase details** (plans) or findings/recommendations (reports)
- **Evaluates structure optimization** opportunities after revision (plans only)
- **Displays recommendations** for collapsing simple phases or expanding complex phases (plans only)
- **Section targeting** for reports (focuses on specific sections when requested)
- **Auto-mode**: Returns structured success/failure response for /implement (plans only)

### What This Command Does NOT Do
- **Does NOT execute any code changes**
- **Does NOT run tests**
- **Does NOT create commits**
- **Does NOT implement the plan**
- **Auto-mode does NOT ask for user confirmation** (deterministic logic only)

To implement the revised plan after revision, use `/implement [plan-file]`

## Mode Comparison

| Aspect | Interactive Mode | Auto-Mode |
|--------|------------------|-----------|
| **Trigger** | User explicitly calls `/revise` | `/implement` detects trigger condition |
| **Input** | Natural language description | Structured JSON context |
| **Confirmation** | Presents changes, asks confirmation (optional) | No confirmation, deterministic execution |
| **Use Case** | User-driven plan/report changes | Automated plan adjustments during implementation |
| **Revision Types** | Any content change | Specific types: expand_phase, add_phase, split_phase, update_tasks, collapse_phase |
| **History Format** | Detailed rationale and context | Concise audit trail with trigger info |
| **Artifact Support** | Plans and reports | Plans only |
| **Context** | Research reports (optional) | JSON context with metrics |

### When to Use Each Mode

**Use Interactive Mode When**:
- Incorporating new requirements from stakeholders
- Revising based on research findings
- Making strategic plan changes
- Updating reports with new findings
- You want visibility and control over changes

**Use Auto-Mode When**:
- `/implement` detects complexity threshold exceeded
- Multiple test failures indicate missing prerequisites
- Automated structure optimization needed
- You're building automated workflows

**Auto-Mode is NOT Suitable For**:
- Strategic plan changes requiring human judgment
- Major scope changes or pivots
- Report modifications
- Initial plan creation
