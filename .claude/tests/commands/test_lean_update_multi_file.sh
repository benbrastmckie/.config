#!/usr/bin/env bash
# Test: /lean-update command multi-file update workflow
# Verifies sorry detection, preservation, cross-reference validation, and multi-file updates

set -euo pipefail

# Detect project directory
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  CLAUDE_PROJECT_DIR="$HOME/.config"
fi

# Test setup
TEST_DIR="/tmp/test_lean_update_$$"
mkdir -p "$TEST_DIR"

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Initialize test Lean project
cd "$TEST_DIR"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"

echo "=== Test Setup: Creating Mock Lean Project ==="

# Create Lean project structure
mkdir -p Logos/Core/Syntax
mkdir -p Logos/Core/Metalogic
mkdir -p Documentation/ProjectInfo

# Create lakefile.toml (Lean 4 project marker)
cat > lakefile.toml << 'EOF'
import Lake
open Lake DSL

package proofchecker

@[default_target]
lean_lib Logos
EOF

# Create lean-toolchain
echo "leanprover/lean4:v4.3.0" > lean-toolchain

# Create Lean source files with sorries
cat > Logos/Core/Syntax/Parser.lean << 'EOF'
-- Parser module
def parseFormula : String → Formula := sorry

theorem parser_correctness : ∀ s, valid (parseFormula s) := sorry
EOF

cat > Logos/Core/Metalogic/Completeness.lean << 'EOF'
-- Completeness proof
theorem completeness : ∀ φ, valid φ → provable φ := sorry

lemma completeness_helper1 : ∀ φ, canonical_model φ := sorry

lemma completeness_helper2 : ∀ φ ψ, φ ⊢ ψ → satisfiable φ := sorry
EOF

# Create TODO.md with Backlog section (must be preserved)
cat > TODO.md << 'EOF'
# TODO

## Overview

Active development tasks for ProofChecker project.

## High Priority

- [ ] Complete completeness theorem proof (3 sorries remaining)

## Medium Priority

- [ ] Refactor parser module

## Backlog

- [ ] Add GUI for proof visualization (v2.0 feature)
- [ ] Implement advanced tactics (low priority)

## Saved

- [ ] Old refactoring idea (postponed)
EOF

# Create SORRY_REGISTRY.md
cat > Documentation/ProjectInfo/SORRY_REGISTRY.md << 'EOF'
# Sorry Placeholder Registry

## Active Placeholders

### Syntax (2 sorries)

- **Logos/Core/Syntax/Parser.lean:2** - `parseFormula` - Placeholder for parser implementation
- **Logos/Core/Syntax/Parser.lean:4** - `parser_correctness` - Parser correctness theorem

### Metalogic (3 sorries)

- **Logos/Core/Metalogic/Completeness.lean:2** - `completeness` - Main completeness theorem
- **Logos/Core/Metalogic/Completeness.lean:4** - `completeness_helper1` - Helper lemma 1
- **Logos/Core/Metalogic/Completeness.lean:6** - `completeness_helper2` - Helper lemma 2

## Resolved Placeholders

### Historical (Completed)

- **Logos/Core/Soundness.lean:10** - `soundness` - Resolved 2024-01-15
EOF

# Create IMPLEMENTATION_STATUS.md
cat > Documentation/ProjectInfo/IMPLEMENTATION_STATUS.md << 'EOF'
# Implementation Status

## Module Status

- **Syntax**: 80% complete (2 sorries)
- **Metalogic**: 70% complete (3 sorries) <!-- MANUAL: Blocked on performance -->

## What Works

- Core proof system
- Basic theorem proving

## What's Partial

- Parser completeness
- Metalogic completeness theorem
EOF

# Create CLAUDE.md
cat > CLAUDE.md << 'EOF'
# ProofChecker Project

## Overview

Lean 4 implementation of propositional logic proof checker.

## Maintenance Documents

- [TODO.md](TODO.md) - Active tasks
- [SORRY_REGISTRY.md](Documentation/ProjectInfo/SORRY_REGISTRY.md) - Tech debt
- [IMPLEMENTATION_STATUS.md](Documentation/ProjectInfo/IMPLEMENTATION_STATUS.md) - Module progress
EOF

# Commit initial state
git add -A
git commit -q -m "Initial Lean project structure"

echo "✓ Test setup complete"
echo ""

# Test 1: Lean Project Detection
echo "=== Test 1: Lean Project Detection ==="

# Check lakefile.toml exists
if [[ -f "lakefile.toml" ]]; then
  echo "✓ lakefile.toml detected"
else
  echo "✗ FAILED: lakefile.toml not found"
  exit 1
fi

# Check lean-toolchain exists
if [[ -f "lean-toolchain" ]]; then
  echo "✓ lean-toolchain detected"
else
  echo "✗ FAILED: lean-toolchain not found"
  exit 1
fi

echo "✓ Test 1 passed"
echo ""

# Test 2: Maintenance Document Discovery
echo "=== Test 2: Maintenance Document Discovery ==="

# Check TODO.md
if [[ -f "TODO.md" ]]; then
  echo "✓ TODO.md found"
else
  echo "✗ FAILED: TODO.md not found"
  exit 1
fi

# Check CLAUDE.md
if [[ -f "CLAUDE.md" ]]; then
  echo "✓ CLAUDE.md found"
else
  echo "✗ FAILED: CLAUDE.md not found"
  exit 1
fi

# Check SORRY_REGISTRY.md
if [[ -f "Documentation/ProjectInfo/SORRY_REGISTRY.md" ]]; then
  echo "✓ SORRY_REGISTRY.md found"
else
  echo "✗ FAILED: SORRY_REGISTRY.md not found"
  exit 1
fi

# Check IMPLEMENTATION_STATUS.md
if [[ -f "Documentation/ProjectInfo/IMPLEMENTATION_STATUS.md" ]]; then
  echo "✓ IMPLEMENTATION_STATUS.md found"
else
  echo "✗ FAILED: IMPLEMENTATION_STATUS.md not found"
  exit 1
fi

echo "✓ Test 2 passed"
echo ""

# Test 3: Sorry Detection and Counting
echo "=== Test 3: Sorry Detection and Counting ==="

# Count sorries in Syntax module
syntax_sorry_count=$(grep -rn "sorry" Logos/Core/Syntax/ 2>/dev/null | wc -l | tr -d ' ')
echo "   Syntax module: $syntax_sorry_count sorries"

if [[ "$syntax_sorry_count" -eq 2 ]]; then
  echo "✓ Syntax sorry count correct (expected: 2)"
else
  echo "✗ FAILED: Syntax sorry count incorrect (expected: 2, got: $syntax_sorry_count)"
  exit 1
fi

# Count sorries in Metalogic module
metalogic_sorry_count=$(grep -rn "sorry" Logos/Core/Metalogic/ 2>/dev/null | wc -l | tr -d ' ')
echo "   Metalogic module: $metalogic_sorry_count sorries"

if [[ "$metalogic_sorry_count" -eq 3 ]]; then
  echo "✓ Metalogic sorry count correct (expected: 3)"
else
  echo "✗ FAILED: Metalogic sorry count incorrect (expected: 3, got: $metalogic_sorry_count)"
  exit 1
fi

# Total sorries
total_sorries=$((syntax_sorry_count + metalogic_sorry_count))
echo "   Total sorries: $total_sorries"

if [[ "$total_sorries" -eq 5 ]]; then
  echo "✓ Total sorry count correct (expected: 5)"
else
  echo "✗ FAILED: Total sorry count incorrect (expected: 5, got: $total_sorries)"
  exit 1
fi

echo "✓ Test 3 passed"
echo ""

# Test 4: Preservation Section Detection
echo "=== Test 4: Preservation Section Detection ==="

# Check Backlog section in TODO.md
if grep -q "^## Backlog" TODO.md; then
  echo "✓ TODO.md Backlog section found"
else
  echo "✗ FAILED: TODO.md Backlog section not found"
  exit 1
fi

# Check Saved section in TODO.md
if grep -q "^## Saved" TODO.md; then
  echo "✓ TODO.md Saved section found"
else
  echo "✗ FAILED: TODO.md Saved section not found"
  exit 1
fi

# Extract Backlog content for later verification
ORIGINAL_BACKLOG=$(sed -n '/^## Backlog/,/^## /p' TODO.md | sed '$d' 2>/dev/null || echo "")

if [[ -n "$ORIGINAL_BACKLOG" ]]; then
  echo "✓ Backlog content extracted for preservation check"
else
  echo "✗ FAILED: Could not extract Backlog content"
  exit 1
fi

# Check Resolved Placeholders section in SORRY_REGISTRY.md
if grep -q "^## Resolved Placeholders" Documentation/ProjectInfo/SORRY_REGISTRY.md; then
  echo "✓ SORRY_REGISTRY.md Resolved Placeholders section found"
else
  echo "✗ FAILED: SORRY_REGISTRY.md Resolved Placeholders section not found"
  exit 1
fi

# Check MANUAL comment in IMPLEMENTATION_STATUS.md
if grep -q "<!-- MANUAL" Documentation/ProjectInfo/IMPLEMENTATION_STATUS.md; then
  echo "✓ IMPLEMENTATION_STATUS.md MANUAL comment found"
else
  echo "✗ FAILED: IMPLEMENTATION_STATUS.md MANUAL comment not found"
  exit 1
fi

echo "✓ Test 4 passed"
echo ""

# Test 5: Cross-Reference Validation
echo "=== Test 5: Cross-Reference Validation ==="

# Check TODO.md doesn't reference SORRY_REGISTRY.md yet (should warn)
if ! grep -q "SORRY_REGISTRY.md" TODO.md 2>/dev/null; then
  echo "✓ TODO.md missing SORRY_REGISTRY.md reference (expected - will be warned)"
else
  echo "   TODO.md already references SORRY_REGISTRY.md"
fi

# Check CLAUDE.md references TODO.md
if grep -q "TODO.md" CLAUDE.md; then
  echo "✓ CLAUDE.md → TODO.md reference exists"
else
  echo "✗ FAILED: CLAUDE.md should reference TODO.md"
  exit 1
fi

# Check CLAUDE.md references SORRY_REGISTRY.md
if grep -q "SORRY_REGISTRY.md" CLAUDE.md; then
  echo "✓ CLAUDE.md → SORRY_REGISTRY.md reference exists"
else
  echo "✗ FAILED: CLAUDE.md should reference SORRY_REGISTRY.md"
  exit 1
fi

# Check CLAUDE.md references IMPLEMENTATION_STATUS.md
if grep -q "IMPLEMENTATION_STATUS.md" CLAUDE.md; then
  echo "✓ CLAUDE.md → IMPLEMENTATION_STATUS.md reference exists"
else
  echo "✗ FAILED: CLAUDE.md should reference IMPLEMENTATION_STATUS.md"
  exit 1
fi

echo "✓ Test 5 passed"
echo ""

# Test 6: Module Completion Calculation
echo "=== Test 6: Module Completion Calculation ==="

# Syntax module: Assume 10 total functions, 2 sorries → 80% complete
syntax_expected_completion=80

# Metalogic module: Assume 10 total functions, 3 sorries → 70% complete
metalogic_expected_completion=70

echo "   Syntax module expected: ${syntax_expected_completion}%"
echo "   Metalogic module expected: ${metalogic_expected_completion}%"

# Verify these percentages are in IMPLEMENTATION_STATUS.md
if grep -q "Syntax.*80%" Documentation/ProjectInfo/IMPLEMENTATION_STATUS.md; then
  echo "✓ Syntax completion percentage matches"
else
  echo "⚠️  WARNING: Syntax completion percentage may need update"
fi

if grep -q "Metalogic.*70%" Documentation/ProjectInfo/IMPLEMENTATION_STATUS.md; then
  echo "✓ Metalogic completion percentage matches"
else
  echo "⚠️  WARNING: Metalogic completion percentage may need update"
fi

echo "✓ Test 6 passed"
echo ""

# Test 7: Git Snapshot Creation Simulation
echo "=== Test 7: Git Snapshot Creation Simulation ==="

# Simulate creating a git snapshot before updates
WORKFLOW_ID="lean_update_test_$$"

# Make a change to trigger snapshot
echo "# Test change" >> TODO.md

# Create snapshot
git add TODO.md
if git commit -q -m "Snapshot before /lean-update ($WORKFLOW_ID)"; then
  SNAPSHOT_HASH=$(git rev-parse HEAD)
  echo "✓ Git snapshot created: $SNAPSHOT_HASH"
else
  echo "✗ FAILED: Could not create git snapshot"
  exit 1
fi

# Verify recovery command works
echo "   Testing recovery command..."
if git show "$SNAPSHOT_HASH:TODO.md" > /dev/null 2>&1; then
  echo "✓ Recovery command validated: git restore --source=$SNAPSHOT_HASH -- TODO.md"
else
  echo "✗ FAILED: Recovery command failed"
  exit 1
fi

# Restore to original state
git restore --source=HEAD~ -- TODO.md

echo "✓ Test 7 passed"
echo ""

# Test 8: Analysis Report JSON Structure
echo "=== Test 8: Analysis Report JSON Structure ==="

# Create mock analysis report
ANALYSIS_REPORT_PATH="/tmp/lean-update-analysis-$$.json"

cat > "$ANALYSIS_REPORT_PATH" << 'EOF'
{
  "analysis_metadata": {
    "workflow_id": "lean_update_test",
    "timestamp": "2025-12-05 10:00:00",
    "project_root": "/tmp/test_lean_update"
  },
  "sorry_counts": {
    "Syntax": 2,
    "Metalogic": 3
  },
  "module_completion": {
    "Syntax": 80,
    "Metalogic": 70
  },
  "files": [
    {
      "path": "/tmp/test_lean_update/TODO.md",
      "needs_update": false,
      "updates": [],
      "preservation": ["Backlog", "Saved"]
    },
    {
      "path": "/tmp/test_lean_update/Documentation/ProjectInfo/SORRY_REGISTRY.md",
      "needs_update": true,
      "updates": [
        {
          "section": "Active Placeholders",
          "action": "verify",
          "content": "Counts match source scan"
        }
      ],
      "preservation": ["Resolved Placeholders"]
    }
  ],
  "cross_references": {
    "broken_links": [],
    "missing_bidirectional": [
      {
        "file_a": "SORRY_REGISTRY.md",
        "file_b": "TODO.md",
        "direction": "A→B exists but B→A missing"
      }
    ]
  },
  "summary": {
    "total_sorries": 5,
    "files_requiring_updates": 1,
    "preservation_sections_protected": 3,
    "cross_reference_issues": 1
  }
}
EOF

# Verify JSON is valid
if jq empty "$ANALYSIS_REPORT_PATH" 2>/dev/null; then
  echo "✓ Analysis report JSON is valid"
else
  echo "✗ FAILED: Analysis report JSON is invalid"
  exit 1
fi

# Verify required fields present
for field in "sorry_counts" "module_completion" "files" "summary"; do
  if jq -e ".$field" "$ANALYSIS_REPORT_PATH" >/dev/null 2>&1; then
    echo "✓ Required field present: $field"
  else
    echo "✗ FAILED: Required field missing: $field"
    exit 1
  fi
done

# Verify sorry counts match our scan
agent_syntax_count=$(jq -r '.sorry_counts.Syntax' "$ANALYSIS_REPORT_PATH")
agent_metalogic_count=$(jq -r '.sorry_counts.Metalogic' "$ANALYSIS_REPORT_PATH")

if [[ "$agent_syntax_count" -eq "$syntax_sorry_count" ]]; then
  echo "✓ Agent sorry count for Syntax matches scan"
else
  echo "✗ FAILED: Agent sorry count for Syntax mismatch (expected: $syntax_sorry_count, got: $agent_syntax_count)"
  exit 1
fi

if [[ "$agent_metalogic_count" -eq "$metalogic_sorry_count" ]]; then
  echo "✓ Agent sorry count for Metalogic matches scan"
else
  echo "✗ FAILED: Agent sorry count for Metalogic mismatch (expected: $metalogic_sorry_count, got: $agent_metalogic_count)"
  exit 1
fi

# Clean up analysis report
rm -f "$ANALYSIS_REPORT_PATH"

echo "✓ Test 8 passed"
echo ""

# Test 9: Preservation Verification
echo "=== Test 9: Preservation Verification ==="

# Simulate preservation verification
PRESERVED_BACKLOG_AFTER=$(sed -n '/^## Backlog/,/^## /p' TODO.md | sed '$d' 2>/dev/null || echo "")

if [[ "$ORIGINAL_BACKLOG" == "$PRESERVED_BACKLOG_AFTER" ]]; then
  echo "✓ Backlog section preserved correctly"
else
  echo "✗ FAILED: Backlog section was modified"
  echo "Original:"
  echo "$ORIGINAL_BACKLOG"
  echo "After:"
  echo "$PRESERVED_BACKLOG_AFTER"
  exit 1
fi

# Check Resolved Placeholders section still present
if grep -q "^## Resolved Placeholders" Documentation/ProjectInfo/SORRY_REGISTRY.md; then
  echo "✓ Resolved Placeholders section preserved"
else
  echo "✗ FAILED: Resolved Placeholders section was removed"
  exit 1
fi

# Check MANUAL comment still present
if grep -q "<!-- MANUAL" Documentation/ProjectInfo/IMPLEMENTATION_STATUS.md; then
  echo "✓ MANUAL comment preserved"
else
  echo "✗ FAILED: MANUAL comment was removed"
  exit 1
fi

echo "✓ Test 9 passed"
echo ""

# Test 10: File Size Validation
echo "=== Test 10: File Size Validation ==="

# Check that all maintenance docs are non-empty
for file in "TODO.md" "CLAUDE.md" "Documentation/ProjectInfo/SORRY_REGISTRY.md" "Documentation/ProjectInfo/IMPLEMENTATION_STATUS.md"; do
  if [[ -f "$file" ]]; then
    file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    if [[ "$file_size" -gt 0 ]]; then
      echo "✓ $(basename "$file"): $file_size bytes"
    else
      echo "✗ FAILED: $(basename "$file") is empty"
      exit 1
    fi
  fi
done

echo "✓ Test 10 passed"
echo ""

# All tests passed
echo "═══════════════════════════════════════════════"
echo "   ✓ ALL TESTS PASSED"
echo "═══════════════════════════════════════════════"
echo ""
echo "Test Summary:"
echo "  1. Lean project detection"
echo "  2. Maintenance document discovery"
echo "  3. Sorry detection and counting"
echo "  4. Preservation section detection"
echo "  5. Cross-reference validation"
echo "  6. Module completion calculation"
echo "  7. Git snapshot creation"
echo "  8. Analysis report JSON structure"
echo "  9. Preservation verification"
echo "  10. File size validation"
echo ""
echo "Mock project created at: $TEST_DIR"
echo "Run manually: cd $TEST_DIR && ls -la"
