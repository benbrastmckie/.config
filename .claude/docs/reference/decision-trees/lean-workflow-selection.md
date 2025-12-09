# Lean Workflow Selection Decision Tree

## Purpose

Guide users on when to use direct feature descriptions vs `--file` flag for `/lean-plan` command invocation.

## Decision Tree

```
START: "I want to create a Lean formalization plan"
│
├─ Is your formalization goal simple to state in one sentence?
│  ├─ YES → Use direct description
│  │         Example: /lean-plan "formalize group homomorphism properties"
│  │
│  └─ NO → Continue to next question
│
├─ Do you have formalization requirements in a file (>200 chars)?
│  ├─ YES → Use --file flag
│  │         Example: /lean-plan --file /path/to/requirements.md
│  │
│  └─ NO → Continue to next question
│
├─ Does your description contain meta-instructions?
│  │  Examples: "Use X to create...", "Read Y and generate..."
│  │
│  ├─ YES → WARNING: Use --file flag instead
│  │         • Meta-instructions confuse the orchestrator
│  │         • Put requirements in a file, then use --file flag
│  │         • Example: echo "formalize..." > req.md && /lean-plan --file req.md
│  │
│  └─ NO → Use direct description
│            Example: /lean-plan "prove soundness of modal logic K4"
│
END
```

## Usage Patterns

### Pattern 1: Direct Description (Recommended)

**When to use**:
- Formalization goal is clear and concise (<200 chars)
- No file-based requirements
- Direct statement of what to formalize

**Example**:
```bash
/lean-plan "formalize Cayley's theorem for finite groups"
```

**Advantages**:
- Immediate execution
- No file management overhead
- Clear invocation history

### Pattern 2: File-Based Requirements (Long Prompts)

**When to use**:
- Requirements exceed 200 characters
- Formalization involves multiple theorems/properties
- Need to preserve detailed specifications

**Example**:
```bash
# Create requirements file
cat > lean_formalization_req.md <<'EOF'
Formalize the fundamental theorem of algebra with the following components:
1. Every non-constant polynomial over ℂ has at least one root
2. Proof strategy using Liouville's theorem
3. Integration with Mathlib's complex analysis library
4. Include helper lemmas for polynomial degree properties
EOF

# Invoke with --file flag
/lean-plan --file lean_formalization_req.md
```

**Advantages**:
- Supports detailed specifications
- Requirements are version-controlled
- Can be reused across iterations

### Pattern 3: Meta-Instruction Detection (Anti-Pattern)

**What NOT to do**:
```bash
# WRONG - Meta-instruction confuses orchestrator
/lean-plan "Use requirements.md to create a plan for formalizing group theory"

# RIGHT - Use --file flag for file-based input
/lean-plan --file requirements.md
```

**Why this matters**:
- Meta-instructions ("Use X to...", "Read Y and...") suggest indirection
- The orchestrator expects direct formalization goals, not instructions
- Using --file flag makes the intent explicit

**Detection and warnings**:
The command now detects meta-instruction patterns and warns:
```
WARNING: Feature description appears to be a meta-instruction
Did you mean to use --file flag instead?
Example: /lean-plan --file /path/to/requirements.md
```

## Complexity Flag Usage

Add `--complexity` flag to control research depth (independent of direct vs file):

```bash
# Direct description with complexity
/lean-plan "formalize Sylow theorems" --complexity 4

# File-based with complexity
/lean-plan --file requirements.md --complexity 3
```

**Complexity levels**:
- `1-2`: Simple (2 research topics: Mathlib + Proof Strategies)
- `3`: Moderate (3 topics: + Project Structure) [DEFAULT]
- `4`: Complex (4 topics: + Style Guide)

## Project Path Detection

The `/lean-plan` command auto-detects Lean projects by searching for `lakefile.toml`:

```bash
# Auto-detection (searches upward from pwd)
cd ~/MyLeanProject/ProofChecker
/lean-plan "formalize correctness theorem"

# Explicit project path (if not in project directory)
/lean-plan "formalize theorems" --project ~/MyLeanProject/ProofChecker
```

## Common Mistakes

### Mistake 1: Using file path in description

**Wrong**:
```bash
/lean-plan "formalize using /path/to/spec.md"
```

**Right**:
```bash
/lean-plan --file /path/to/spec.md
```

### Mistake 2: Meta-instructions instead of goals

**Wrong**:
```bash
/lean-plan "Read the research reports and create a plan"
```

**Right**:
```bash
/lean-plan "formalize fundamental group properties"
```

### Mistake 3: Forgetting --project flag outside Lean directory

**Wrong** (if not in Lean project):
```bash
cd ~
/lean-plan "formalize theorems"
# ERROR: No Lean project found
```

**Right**:
```bash
cd ~
/lean-plan "formalize theorems" --project ~/MyLeanProject
```

## Summary

| Scenario | Command Pattern | Notes |
|----------|----------------|-------|
| Simple goal | `/lean-plan "<description>"` | Most common |
| Long requirements | `/lean-plan --file <path>` | Version-controlled specs |
| High complexity | Add `--complexity 4` | More research depth |
| Outside project | Add `--project <path>` | Manual project detection |
| Meta-instruction | Use `--file` instead | Avoid indirection |

## Related Documentation

- [Lean Plan Command Guide](.claude/docs/guides/commands/lean-plan-command-guide.md) - Complete usage guide
- [Lean Implement Command Guide](.claude/docs/guides/commands/lean-implement-command-guide.md) - Executing generated plans
- [Command Reference](.claude/docs/reference/standards/command-reference.md) - All slash commands

## See Also

- [Directory Protocols](.claude/docs/concepts/directory-protocols.md) - Topic naming and structure
- [Hierarchical Agents Examples](.claude/docs/concepts/hierarchical-agents-examples.md) - Example 8: Lean coordination patterns
