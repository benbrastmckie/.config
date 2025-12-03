# Lean Command Guide

## Overview

The `/lean` command provides AI-assisted Lean 4 theorem proving through integration with the lean-lsp-mcp MCP server. It automates proof discovery, tactic generation, and verification using the lean-implementer specialized agent.

## Syntax

```bash
/lean [lean-file | plan-file] [--prove-all | --verify] [--max-attempts=N]
```

**Arguments**:
- `lean-file` - Path to .lean file with theorems to prove
- `plan-file` - Path to plan file with Lean proof tasks
- `--prove-all` - Prove all theorems with sorry markers (default)
- `--verify` - Verify existing proofs without modification
- `--max-attempts=N` - Maximum proof attempts per theorem (default: 3)

## When to Use

Use `/lean` when you need to:
- Complete proof stubs (`sorry` markers) in Lean files
- Search Mathlib for applicable theorems
- Generate and test tactic sequences automatically
- Verify proof compilation and diagnostics
- Document proof strategies with summaries

## Lean File Discovery

When using plan-based mode, the `/lean` command uses a **3-tier fallback discovery** mechanism to locate the Lean file:

### Tier 1: Plan Metadata (Optional)

Specify the Lean file explicitly in plan metadata:

```markdown
**Lean File**: /absolute/path/to/file.lean
```

**Example**:
```markdown
## Metadata
- **Date**: 2025-12-03
- **Feature**: TM Modal Axioms
- **Lean File**: /home/user/lean-project/Axioms.lean
```

### Tier 2: Task Scanning

If metadata is not present, the command scans phase tasks for `.lean` file references:

```markdown
### Phase 1: Axiom MT [NOT STARTED]
- [ ] Prove MT axiom in /home/user/lean-project/Axioms.lean
```

The command extracts `/home/user/lean-project/Axioms.lean` from the task description.

### Tier 3: Directory Search

If no file is found via metadata or tasks, the command searches the topic directory:

```bash
# Finds first .lean file in topic directory
find /path/to/specs/NNN_topic/ -name "*.lean" -type f | head -1
```

### Discovery Output

The command displays which method was used:

```
Lean File: /path/to/file.lean (discovered via metadata)
Lean File: /path/to/file.lean (discovered via task_scan)
Lean File: /path/to/file.lean (discovered via directory_search)
```

### Backward Compatibility

Plans with existing `**Lean File**` metadata continue to work unchanged. The metadata approach is still recommended for explicit clarity.

## Real-Time Progress Tracking

The `/lean` command now provides **real-time progress visibility** through plan file markers:

### Progress Markers

During theorem proving, phase status markers update automatically:

1. **Before proving**: `### Phase 1: Axiom MT [NOT STARTED]`
2. **During proving**: `### Phase 1: Axiom MT [IN PROGRESS]`
3. **After completion**: `### Phase 1: Axiom MT [COMPLETE]`

### Monitoring Progress

Watch progress in real-time using `cat` or `watch`:

```bash
# Terminal 1: Run /lean command
/lean plan.md --prove-all

# Terminal 2: Monitor progress markers
watch -n 1 "grep -E '^### Phase.*\[' plan.md"
```

**Output**:
```
### Phase 1: Axiom MT [IN PROGRESS]
### Phase 2: Axiom M4 [NOT STARTED]
### Phase 3: Axiom M5 [NOT STARTED]
```

### Graceful Degradation

Progress tracking requires the `checkbox-utils.sh` library. If unavailable:
- Warning logged: `"Progress tracking unavailable"`
- Theorem proving continues normally (non-fatal)
- No progress markers updated

## Workflow Integration

### /plan → /lean → /test Pattern

1. **Create Lean formalization plan**:
   ```bash
   /plan "Formalize TM modal axioms in Lean 4"
   ```

2. **Prove theorems**:
   ```bash
   /lean .claude/specs/027_tm_formalization/plans/001-tm-axioms.md --prove-all
   ```

3. **Verify compilation**:
   ```bash
   cd lean-project && lake build
   ```

## MCP Tool Usage

The lean-implementer agent uses these lean-lsp-mcp tools:

### Core LSP Operations
- **lean_goal** - Extracts proof goal type and hypotheses at cursor position
- **lean_diagnostic_messages** - Checks for compilation errors and warnings
- **lean_build** - Compiles entire Lean project

### Search Tools (Rate Limited: 3 requests/30s combined)
- **lean_leansearch** - Natural language theorem search (`"commutativity addition"`)
- **lean_loogle** - Type-based search (`"Nat → Nat → Nat"`)
- **lean_state_search** - Goal-based applicable theorem search
- **lean_local_search** - Local ripgrep search (**no rate limit, preferred**)

### Advanced
- **lean_multi_attempt** - Tests multiple tactic sequences in parallel
- **lean_hammer_premise** - Premise search based on proof state

**Rate Limit Strategy**:
1. Start with `lean_local_search` (no limit)
2. Fall back to `lean_leansearch` for Mathlib search
3. Use `lean_loogle` for type-based search
4. Wait 30 seconds if rate limit exceeded

## Proof Summaries

After completion, `/lean` creates proof summaries in `summaries/` directory with:

**Summary Structure**:
```markdown
# Proof Summary: [Theorem Name]

## Metadata
- Date, File, Theorem, Status, Attempts

## Proof Strategy
- Goal description
- Hypotheses
- Solution tactics

## Tactics Used
- Tactic explanations with reasoning

## Mathlib Theorems Referenced
- Links to Mathlib documentation

## Diagnostics
- Compilation errors/warnings (if any)
```

**Example Summary Output**:
```
summaries/lean_proof_20251202_143045.md
```

## Examples

### Example 1: Prove Simple Theorems

```bash
/lean ~/lean-project/Test.lean --prove-all
```

**Input File** (`Test.lean`):
```lean
theorem add_comm (a b : Nat) : a + b = b + a := by
  sorry

theorem mul_comm (a b : Nat) : a * b = b * a := by
  sorry
```

**Output**:
- Replaces `sorry` with `exact Nat.add_comm a b`
- Replaces `sorry` with `exact Nat.mul_comm a b`
- Creates `summaries/lean_proof_TIMESTAMP.md`
- Reports: "2 theorems proven, 0 partial"

### Example 2: Verification Mode

```bash
/lean ~/lean-project/Complete.lean --verify
```

**Behavior**:
- Checks for `sorry` markers (should be none)
- Runs `lean_build` to verify compilation
- Checks `lean_diagnostic_messages` for errors
- Creates verification summary
- No modifications to file

### Example 3: Plan-Based Proving (With Metadata)

```bash
/lean .claude/specs/027_tm_logic/plans/001-tm-axioms.md --max-attempts=5
```

**Plan File Structure**:
```markdown
## Metadata
- **Date**: 2025-12-03
- **Feature**: TM Modal Axioms
- **Lean File**: /home/user/ProofChecker/TM/Axioms.lean

### Phase 1: Axiom MT [NOT STARTED]
- [ ] Prove MT axiom: □(φ → ψ) → (◇φ → ◇ψ)

### Phase 2: Axiom M4 [NOT STARTED]
- [ ] Prove M4 axiom: □□φ → □φ
```

**Behavior**:
- Lean file discovered via metadata
- Processes each phase sequentially
- Updates plan markers: [NOT STARTED] → [IN PROGRESS] → [COMPLETE]
- Creates aggregated summary
- Allows up to 5 proof attempts per theorem

### Example 4: Plan-Based Proving (Without Metadata)

```bash
/lean .claude/specs/028_logic/plans/001-modal.md --prove-all
```

**Plan File Structure** (no Lean File metadata):
```markdown
## Metadata
- **Date**: 2025-12-03
- **Feature**: Modal Logic Proofs

### Phase 1: Necessitation [NOT STARTED]
- [ ] Prove necessitation rule in /home/user/Modal.lean

### Phase 2: Distribution [NOT STARTED]
- [ ] Prove distribution axiom in /home/user/Modal.lean
```

**Behavior**:
- Lean file discovered via task scanning: `/home/user/Modal.lean`
- Display: `Lean File: /home/user/Modal.lean (discovered via task_scan)`
- Real-time progress markers update during proving
- Works identically to metadata-based plans

## Troubleshooting

### MCP Server Not Found

**Error**:
```
ERROR: lean-lsp-mcp MCP server not available
  Install with: uvx --from lean-lsp-mcp
```

**Solution**:
```bash
# Install lean-lsp-mcp via uv
uvx --from lean-lsp-mcp --help

# Verify installation
which lean-lsp-mcp
```

### Not a Lean Project

**Error**:
```
ERROR: Not a Lean 4 project (no lakefile.toml or lakefile.lean found)
```

**Solution**:
- Create `lakefile.toml` in project root:
  ```toml
  name = "my-project"
  defaultTargets = ["MyProject"]
  ```
- Or create `lakefile.lean`:
  ```lean
  import Lake
  open Lake DSL

  package myProject
  ```

### Rate Limit Exceeded

**Error**:
```
WARNING: Rate limit exceeded, falling back to local search
```

**Solution**:
- Automatic: Agent falls back to `lean_local_search`
- Manual: Wait 30 seconds before re-running
- Optimization: Use `--max-attempts=1` to reduce search tool usage

### Proof Verification Failed

**Error**:
```
WARNING: 2 sorry markers remain in file
Diagnostics: 1 issues
```

**Solution**:
1. Check summary for failed proof attempts
2. Review diagnostic messages in summary
3. Manually inspect proof goals: `uvx lean-goal File.lean LINE COL`
4. Retry with higher attempts: `/lean file.lean --max-attempts=5`

### File Not Found

**Error**:
```
ERROR: File not found: Test.lean
```

**Solution**:
- Use absolute paths: `/lean /home/user/project/Test.lean`
- Or relative to project: `/lean src/Test.lean`
- Verify file exists: `ls -la path/to/file.lean`

### Lean File Discovery Failed

**Error**:
```
ERROR: No Lean file found via any discovery method
Please specify the Lean file using one of these methods:
  1. Plan metadata: **Lean File**: /path/to/file.lean
  2. Task description: - [ ] Prove theorem in /path/to/file.lean
  3. Place .lean file in topic directory: /path/to/specs/NNN_topic/
```

**Solution (Option 1 - Add Metadata)**:
```markdown
## Metadata
- **Lean File**: /absolute/path/to/file.lean
```

**Solution (Option 2 - Add Task Reference)**:
```markdown
### Phase 1: Prove Theorems [NOT STARTED]
- [ ] Prove commutativity in /absolute/path/to/file.lean
```

**Solution (Option 3 - Place File in Topic)**:
```bash
# Copy .lean file to topic directory
cp MyTheorems.lean /path/to/specs/028_logic/
```

## Best Practices

### 1. Start with Local Search

Prefer `lean_local_search` (no rate limit) over external search tools:
```lean
-- Good: Local project has relevant theorems
theorem my_add_comm (a b : Nat) : a + b = b + a := by
  -- Agent finds Nat.add_comm via local search
  exact Nat.add_comm a b
```

### 2. Incremental Proving

Prove simple theorems first, then build on them:
```bash
# Phase 1: Basic properties
/lean Basic.lean --prove-all

# Phase 2: Derived properties (uses Phase 1 theorems)
/lean Derived.lean --prove-all
```

### 3. Use Verification Mode

Before committing proofs, verify compilation:
```bash
/lean Complete.lean --verify
```

### 4. Review Summaries

Check proof summaries for:
- Tactic reasoning (understand proof strategy)
- Mathlib references (learn applicable theorems)
- Diagnostics (catch warnings early)

### 5. Combine with /plan

For complex formalizations:
1. Create plan with `/plan`
2. Prove with `/lean plan-file.md`
3. Document with proof summaries

## Advanced Usage

### Custom Max Attempts

For complex proofs requiring extensive search:
```bash
/lean ComplexTheorem.lean --max-attempts=10
```

### Batch Proving with Plans

Create hierarchical proof plans:
```markdown
### Phase 1: Foundation [NOT STARTED]
- [ ] Prove basic properties
- [ ] File: Basic.lean

### Phase 2: Derived [NOT STARTED]
- [ ] Prove derived theorems using Phase 1
- [ ] File: Derived.lean
- [ ] Dependencies: Phase 1
```

Then run:
```bash
/lean plan.md --prove-all
```

## Integration with Other Commands

### /research → /plan → /lean

Full workflow from concept to proof:
```bash
# 1. Research modal logic formalization
/research "TM modal logic Lean 4 formalization strategies"

# 2. Create implementation plan
/plan "Formalize TM axioms based on research"

# 3. Prove theorems
/lean specs/027_tm/plans/001-axioms.md --prove-all
```

### /lean → /test

After proving, verify with tests:
```bash
# Prove theorems
/lean Axioms.lean --prove-all

# Run test suite
cd lean-project && lake build && lake test
```

## Error Logging

All errors logged to `.claude/data/logs/errors.jsonl`:

**Query recent errors**:
```bash
/errors --command /lean --since 1h
```

**Analyze error patterns**:
```bash
/repair --command /lean --type agent_error
```

## Performance Tips

1. **Use local search first**: Reduces rate limit issues
2. **Limit max attempts**: Start with 3, increase if needed
3. **Batch similar theorems**: Process related proofs together
4. **Verify incrementally**: Use `--verify` after each batch

## Related Documentation

- [lean-implementer Agent Reference](../../agents/lean-implementer.md)
- [MCP Integration Guide](../../concepts/mcp-integration.md)
- [Lean Style Guide](../../../LEAN_STYLE_GUIDE.md) (if available)
- [Error Handling Pattern](../../concepts/patterns/error-handling.md)

## Success Criteria

Workflow succeeds if:
- ✅ All `sorry` markers replaced with valid tactics
- ✅ `lean_build` succeeds (exit code 0)
- ✅ `lean_diagnostic_messages` shows no errors
- ✅ Proof summary created in summaries/ directory
- ✅ Mathlib theorems documented with references
- ✅ Lean Style Guide conventions followed
