# Documentation Bloat Analysis Report

## Metadata
- Date: 2025-11-14
- Analyzer: docs-bloat-analyzer (Opus 4.5)
- Input Reports:
  - CLAUDE.md analysis: /home/benjamin/.config/.claude/specs/711_optimize_claudemd_structure/reports/001_claude_md_analysis.md
  - Docs structure analysis: /home/benjamin/.config/.claude/specs/711_optimize_claudemd_structure/reports/002_docs_structure_analysis.md

## Executive Summary

Analysis of CLAUDE.md and .claude/docs/ reveals 4 extraction candidates with significant bloat risk and 1 existing critical bloat case requiring immediate split. Of the 4 proposed CLAUDE.md extractions (437 total lines), only 1 poses high bloat risk (Directory Organization → existing 0-line file safe), while State-Based Orchestration should use link-only strategy to avoid duplication with massive 2,000+ line existing file. The .claude/docs/guides/command-development-guide.md at 3,980 lines represents critical bloat requiring 4-way split, with 7 additional guides exceeding 400-line threshold.

## Current Bloat State

### Bloated Files (>400 lines)

**Existing Documentation Files Exceeding Threshold**:

| File Path | Current Size | Severity | Bloat Factor | Recommendation |
|-----------|--------------|----------|--------------|----------------|
| .claude/docs/guides/command-development-guide.md | 3,980 lines | **CRITICAL** | 995% over threshold | Split into 4 specialized guides |
| .claude/docs/guides/coordinate-command-guide.md | 567 lines | BLOATED | 42% over threshold | Split into 2 files (architecture + usage) |
| .claude/docs/guides/implement-command-guide.md | 512 lines | BLOATED | 28% over threshold | Split into 2 files (core + advanced) |
| .claude/docs/guides/orchestrate-command-guide.md | 487 lines | BLOATED | 22% over threshold | Split into 2 files (basics + features) |
| .claude/docs/architecture/state-based-orchestration-overview.md | 2,000+ lines | **CRITICAL** | 500% over threshold | Split into 6 topic files |
| .claude/docs/guides/state-machine-migration-guide.md | 441 lines | BLOATED | 10% over threshold | Minor trim or accept (close to threshold) |
| .claude/docs/guides/state-machine-orchestrator-development.md | 423 lines | BLOATED | 6% over threshold | Minor trim or accept (close to threshold) |
| .claude/docs/guides/setup-command-guide.md | 418 lines | BLOATED | 5% over threshold | Minor trim or accept (close to threshold) |

**Total Bloated Files**: 8 files exceeding 400-line threshold
**Critical Files**: 2 files exceeding 800-line threshold (command-development-guide.md, state-based-orchestration-overview.md)

### Critical Files (>800 lines)

#### 1. command-development-guide.md (3,980 lines) - IMMEDIATE ACTION REQUIRED

**Severity**: CRITICAL (995% over threshold)
**Current Location**: `.claude/docs/guides/command-development-guide.md`
**Issue**: Comprehensive guide covering command creation, templates, patterns, architecture, troubleshooting, and examples in single monolithic file

**Recommended 4-Way Split**:

1. **command-development-basics.md** (600-800 lines)
   - Command structure fundamentals
   - File creation and naming
   - Basic execution patterns
   - Quick start examples

2. **command-architecture-patterns.md** (800-1,000 lines)
   - Executable/documentation separation pattern
   - Behavioral injection pattern
   - Verification and fallback pattern
   - Standard 11 (imperative agent invocation)

3. **command-template-guide.md** (500-700 lines)
   - Template structure
   - Variable substitution
   - Template categories
   - Creating custom templates

4. **command-troubleshooting-reference.md** (1,800-2,000 lines)
   - Common issues and solutions
   - Debug procedures
   - Anti-patterns
   - Case studies

**Projected Post-Split Sizes**: 600-1,000 lines each (all below critical threshold, 3 of 4 below bloat threshold)

#### 2. state-based-orchestration-overview.md (2,000+ lines) - IMMEDIATE ACTION REQUIRED

**Severity**: CRITICAL (500% over threshold)
**Current Location**: `.claude/docs/architecture/state-based-orchestration-overview.md`
**Issue**: Massive architectural overview covering state machines, persistence, supervisors, performance metrics, migration guides, and testing in single file

**Recommended 6-Way Split**:

1. **state-based-orchestration-intro.md** (200-300 lines)
   - Overview and motivation
   - Key architectural principles
   - When to use state-based orchestration

2. **workflow-state-machine-design.md** (300-400 lines)
   - State machine library design
   - State definitions and transitions
   - Transition validation

3. **state-persistence-patterns.md** (300-400 lines)
   - Selective persistence strategy
   - File-based state management
   - Graceful degradation

4. **hierarchical-supervisor-coordination.md** (300-400 lines)
   - Supervisor architecture
   - Context reduction techniques
   - Parallel execution patterns

5. **state-based-performance-metrics.md** (400-500 lines)
   - Code reduction achievements
   - Performance benchmarks
   - Context reduction metrics
   - Time savings analysis

6. **state-machine-testing-guide.md** (400-500 lines)
   - Test suite structure
   - Checkpoint schema tests
   - Integration testing
   - Validation procedures

**Projected Post-Split Sizes**: 200-500 lines each (all below bloat threshold)

## Extraction Risk Analysis

### High-Risk Extractions (projected bloat)

**NONE IDENTIFIED** - All CLAUDE.md extraction candidates target either non-existent files (safe creation) or use link-only strategy to avoid bloat.

### Safe Extractions

Analysis of all 4 extraction candidates from CLAUDE.md shows LOW to MEDIUM risk with proper implementation:

| Extraction Source | Lines | Target File | Current Size | Projected Size | Risk Level | Strategy |
|-------------------|-------|-------------|--------------|----------------|------------|----------|
| Code Standards (CLAUDE.md) | 84 | .claude/docs/reference/code-standards.md | 0 (new file) | 84 lines | **LOW** | Create new file |
| Directory Organization (CLAUDE.md) | 231 | .claude/docs/concepts/directory-organization.md | 0 (new file) | 231 lines | **LOW** | Create new file |
| Hierarchical Agent Architecture (CLAUDE.md) | 93 | .claude/docs/concepts/hierarchical_agents.md | Unknown (exists) | Unknown | **MEDIUM** | Merge unique content only |
| State-Based Orchestration (CLAUDE.md) | 108 | .claude/docs/architecture/state-based-orchestration-overview.md | 2,000+ lines | 2,000+ lines (no merge) | **ZERO** | Link-only (no extraction) |

**Risk Analysis Details**:

#### 1. Code Standards → reference/code-standards.md (LOW RISK)
- **Extraction Size**: 84 lines
- **Target Status**: New file (does not exist)
- **Projected Post-Creation Size**: 84 lines
- **Bloat Risk**: None (well below 400-line threshold)
- **Strategy**: Direct extraction with 5-10 line summary in CLAUDE.md
- **Content**: Indentation rules, naming conventions, error handling, language-specific standards, link conventions

#### 2. Directory Organization → concepts/directory-organization.md (LOW RISK)
- **Extraction Size**: 231 lines
- **Target Status**: New file (does not exist)
- **Projected Post-Creation Size**: 231 lines
- **Bloat Risk**: None (well below 400-line threshold)
- **Strategy**: Direct extraction with 5-10 line summary in CLAUDE.md
- **Content**: Directory structure tree, scripts/ vs lib/ vs utils/, decision matrix, anti-patterns, README requirements, verification steps

#### 3. Hierarchical Agent Architecture → concepts/hierarchical_agents.md (MEDIUM RISK - Merge Required)
- **Extraction Size**: 93 lines
- **Target Status**: File exists (unknown current size, estimated 500-800 lines based on comprehensiveness note)
- **Projected Post-Merge Size**: Unknown (depends on overlap detection)
- **Bloat Risk**: Medium (requires careful merge to avoid duplication)
- **Strategy**:
  1. Read existing concepts/hierarchical_agents.md
  2. Identify unique content in CLAUDE.md section
  3. Merge only non-duplicate content
  4. Replace CLAUDE.md section with 5-10 line summary + link
- **Mitigation**: Pre-merge size check required (Implementation Plan Phase 3 task)
- **Rollback Trigger**: If post-merge size exceeds 400 lines, keep CLAUDE.md section inline and add cross-reference only

#### 4. State-Based Orchestration → state-based-orchestration-overview.md (ZERO RISK - Link Only)
- **Extraction Size**: 108 lines (but NOT extracting)
- **Target Status**: File exists (2,000+ lines comprehensive)
- **Projected Post-Merge Size**: N/A (no merge planned)
- **Bloat Risk**: Zero (using link-only strategy)
- **Strategy**:
  1. Replace entire CLAUDE.md section (108 lines) with 5-10 line summary
  2. Add link to existing architecture/state-based-orchestration-overview.md
  3. NO content extraction or merge
- **Rationale**: Existing file is already comprehensive and massive. Adding CLAUDE.md content would worsen critical bloat (2,000+ → 2,100+ lines). Summary + link achieves goal without duplication.

**Total Safe Extractions**: 2 new files (315 combined lines), 1 careful merge, 1 link-only replacement
**Total CLAUDE.md Reduction**: 437 lines → 527 target size (45.3% reduction from current 964 lines)

## Consolidation Opportunities

### High-Value Consolidations

**LIMITED OPPORTUNITIES** - Most documentation is well-separated by purpose. 3 potential consolidations identified:

#### 1. development-workflow.md Duplication (MEDIUM PRIORITY)

**Issue**: Two files exist with same name in different directories
- `concepts/development-workflow.md` - Explanatory architectural documentation
- `workflows/development-workflow.md` - Step-by-step tutorial

**Content Overlap**: Unknown (requires semantic analysis of both files)

**Recommended Strategy**:
1. Read both files to assess overlap
2. If >60% overlap: Merge into workflows/development-workflow.md (tutorial is more actionable)
3. If <60% overlap: Rename for clarity
   - concepts/development-workflow.md → concepts/development-workflow-architecture.md
   - workflows/development-workflow.md → workflows/development-workflow-tutorial.md
4. Add cross-references between files
5. Update CLAUDE.md to link to canonical location

**Projected Size**: Unknown (depends on overlap analysis)
**Bloat Risk**: LOW (CLAUDE.md only has 15-line section, existing files likely <400 lines each)

#### 2. writing-standards.md + Development Philosophy Merge (LOW PRIORITY)

**Source**: CLAUDE.md Development Philosophy section (49 lines)
**Target**: concepts/writing-standards.md (unknown current size)
**Content Relationship**: Development philosophy and writing standards are semantically related

**Recommended Strategy**:
1. Check current size of concepts/writing-standards.md
2. If current size <350 lines: Merge CLAUDE.md Development Philosophy content
3. If current size ≥350 lines: Keep separate or trim before merge
4. Pre-merge size validation required

**Projected Post-Merge Size**: Unknown (requires reading target file)
**Bloat Risk**: MEDIUM (depends on target file's current state)
**Rollback Trigger**: If post-merge size exceeds 400 lines, keep separate

#### 3. testing-protocols.md + test-command-guide.md Cross-Reference (LOW VALUE)

**Files**:
- reference/testing-protocols.md (proposed extraction from CLAUDE.md, 39 lines)
- guides/test-command-guide.md (existing file, unknown size)

**Opportunity**: NOT consolidation, but ensure strong cross-references
- testing-protocols.md should link to test-command-guide.md for implementation details
- test-command-guide.md should link to testing-protocols.md for standards reference

**Action**: Add bidirectional links during extraction (Implementation Plan Phase 2)
**Bloat Risk**: None (cross-references don't increase file sizes)

### Merge Analysis

**Merge Risk Matrix**:

| Source | Target | Overlap % | Current Target Size | Projected Merge Size | Risk | Recommendation |
|--------|--------|-----------|---------------------|----------------------|------|----------------|
| CLAUDE.md Development Philosophy (49 lines) | concepts/writing-standards.md | Unknown | Unknown | Unknown | MEDIUM | Pre-merge validation required |
| concepts/development-workflow.md | workflows/development-workflow.md | Unknown | Unknown | Unknown | LOW | Assess overlap first |
| CLAUDE.md Hierarchical Agents (93 lines) | concepts/hierarchical_agents.md | Unknown | Est. 500-800 | Unknown | MEDIUM | Merge unique content only |

**Consolidation Guidelines**:

1. **Pre-Merge Size Check** (MANDATORY):
   ```bash
   wc -l target_file.md
   if (( lines > 350 )); then
     echo "WARNING: Target approaching threshold. Careful merge required."
   fi
   ```

2. **Overlap Detection**:
   - Read both files completely
   - Identify duplicate sections (same concepts, different wording)
   - Preserve best-written version, discard duplicates
   - Do NOT merge if overlap <40% (keep separate for different audiences)

3. **Post-Merge Validation**:
   ```bash
   wc -l merged_file.md
   if (( lines > 400 )); then
     echo "BLOAT ALERT: Merged file exceeds threshold. Rollback required."
     git checkout HEAD -- merged_file.md
   fi
   ```

4. **Bloat Prevention**:
   - If projected merge size >400 lines: DO NOT MERGE
   - If projected merge size 350-400 lines: Trim content before merge
   - If projected merge size <350 lines: Safe to merge

**No High-Value Consolidations Identified**: Most documentation is appropriately separated by Diataxis framework (guides vs concepts vs reference vs workflows). Forced consolidation would reduce navigability and mix different documentation types.

## Split Recommendations

### Critical Splits (>800 lines)

**2 FILES REQUIRE IMMEDIATE SPLITS**:

#### 1. command-development-guide.md (3,980 lines) - 4-WAY SPLIT

**Current Location**: `.claude/docs/guides/command-development-guide.md`
**Severity**: CRITICAL (995% over threshold)
**Implementation Priority**: IMMEDIATE

**Split Plan**:

| New File | Projected Size | Content Focus | Audience |
|----------|----------------|---------------|----------|
| command-development-basics.md | 600-800 lines | Fundamentals, quick start, file structure | Beginners creating first command |
| command-architecture-patterns.md | 800-1,000 lines | Executable/doc separation, behavioral injection, Standard 11 | Intermediate developers learning patterns |
| command-template-guide.md | 500-700 lines | Template structure, variable substitution, custom templates | Developers using template system |
| command-troubleshooting-reference.md | 1,800-2,000 lines | Issues, solutions, anti-patterns, case studies | Debugging failing commands |

**Split Strategy**:
1. Create 4 new files with appropriate content distribution
2. Add navigation links between related sections
3. Update main guides/README.md with links to all 4 files
4. Create command-development-index.md as landing page linking to all 4 guides
5. Archive original command-development-guide.md to archive/guides/
6. Update all references in CLAUDE.md and other docs

**Post-Split Verification**:
```bash
for file in command-development-basics.md command-architecture-patterns.md \
            command-template-guide.md command-troubleshooting-reference.md; do
  lines=$(wc -l < ".claude/docs/guides/$file")
  if (( lines > 400 )); then
    echo "WARNING: $file has $lines lines (bloated)"
  fi
done
```

**Cross-Reference Updates Required**:
- CLAUDE.md → Update references to point to new split files
- guides/README.md → Update command development section
- All command guides referencing development guide → Update links

#### 2. state-based-orchestration-overview.md (2,000+ lines) - 6-WAY SPLIT

**Current Location**: `.claude/docs/architecture/state-based-orchestration-overview.md`
**Severity**: CRITICAL (500% over threshold)
**Implementation Priority**: IMMEDIATE

**Split Plan**:

| New File | Projected Size | Content Focus | Directory |
|----------|----------------|---------------|-----------|
| state-based-orchestration-intro.md | 200-300 lines | Overview, motivation, when to use | architecture/ |
| workflow-state-machine-design.md | 300-400 lines | State definitions, transitions, validation | architecture/ |
| state-persistence-patterns.md | 300-400 lines | Selective persistence, file-based state | concepts/patterns/ |
| hierarchical-supervisor-coordination.md | 300-400 lines | Supervisor architecture, context reduction | architecture/ (already exists - merge) |
| state-based-performance-metrics.md | 400-500 lines | Benchmarks, achievements, metrics | reference/ |
| state-machine-testing-guide.md | 400-500 lines | Test suite, validation, integration tests | guides/ |

**Split Strategy**:
1. Create 5 new files (hierarchical-supervisor-coordination.md already exists in architecture/)
2. Check if existing hierarchical-supervisor-coordination.md has overlap, merge carefully
3. Distribute content based on Diataxis framework:
   - Architecture docs (intro, design, coordinator) → architecture/
   - Patterns → concepts/patterns/
   - Metrics → reference/
   - Testing guide → guides/
4. Create state-based-orchestration-index.md as landing page
5. Archive original state-based-orchestration-overview.md
6. Update all references in CLAUDE.md and orchestration commands

**Post-Split Verification**:
```bash
for file in state-based-orchestration-intro.md workflow-state-machine-design.md \
            state-persistence-patterns.md state-based-performance-metrics.md \
            state-machine-testing-guide.md; do
  # Note: Files in different directories
  find .claude/docs -name "$file" -exec sh -c 'lines=$(wc -l < "$1"); \
    if (( lines > 400 )); then echo "WARNING: $1 has $lines lines (bloated)"; fi' _ {} \;
done
```

**Cross-Reference Updates Required**:
- CLAUDE.md → Update state-based orchestration section to link to index
- All orchestration command guides → Update architecture references
- All state machine guides → Update cross-references

### Suggested Splits (400-600 lines)

**6 FILES RECOMMENDED FOR SPLITS** (non-critical but beneficial):

| File | Current Size | Bloat Factor | Split Recommendation |
|------|--------------|--------------|---------------------|
| coordinate-command-guide.md | 567 lines | 42% over | 2-way: architecture + usage examples |
| implement-command-guide.md | 512 lines | 28% over | 2-way: core implementation + advanced features |
| orchestrate-command-guide.md | 487 lines | 22% over | 2-way: basic usage + advanced features |
| state-machine-migration-guide.md | 441 lines | 10% over | Accept or minor trim (close to threshold) |
| state-machine-orchestrator-development.md | 423 lines | 6% over | Accept or minor trim (close to threshold) |
| setup-command-guide.md | 418 lines | 5% over | Accept or minor trim (close to threshold) |

**Split Strategy for Command Guides** (567, 512, 487 lines):

**Pattern**: Split each command guide into:
1. **{command}-architecture.md** - Design, state management, patterns, internals
2. **{command}-usage-guide.md** - Practical examples, common workflows, troubleshooting

**Example: coordinate-command-guide.md (567 lines)**:
- coordinate-architecture.md (300-350 lines): State management, subprocess isolation, wave-based execution, performance optimization
- coordinate-usage-guide.md (217-267 lines): Basic usage, examples, common workflows, troubleshooting

**Benefits**:
- Separates "how it works" from "how to use it"
- Reduces cognitive load (users choose relevant guide)
- Each file stays well below 400-line threshold
- Aligns with Diataxis framework (explanation vs how-to)

**Accept-as-is Strategy for Near-Threshold Files** (441, 423, 418 lines):

Files within 10% of threshold can remain unchanged IF:
- Content is cohesive and well-organized
- Splitting would harm readability
- File serves single clear purpose
- No natural split boundaries exist

**Recommendation**: ACCEPT these 3 files without splits, monitor for future growth

## Size Validation Tasks

### Implementation Plan Requirements

**MANDATORY BLOAT PREVENTION CHECKPOINTS** for cleanup-plan-architect to integrate into implementation plan:

#### Phase 1: Pre-Extraction Validation

**Task 1.1: Baseline Size Inventory**
```bash
# Record current sizes before any changes
echo "=== BASELINE SIZES ===" > /tmp/bloat_baseline.txt
wc -l CLAUDE.md >> /tmp/bloat_baseline.txt
wc -l .claude/docs/concepts/hierarchical_agents.md >> /tmp/bloat_baseline.txt 2>&1
wc -l .claude/docs/concepts/writing-standards.md >> /tmp/bloat_baseline.txt 2>&1
wc -l .claude/docs/architecture/state-based-orchestration-overview.md >> /tmp/bloat_baseline.txt 2>&1

cat /tmp/bloat_baseline.txt
```

**Task 1.2: Verify Target Files Don't Exist (for new file creations)**
```bash
# Ensure we're creating new files, not overwriting existing ones
test ! -f .claude/docs/reference/code-standards.md || \
  { echo "ERROR: code-standards.md already exists!"; exit 1; }
test ! -f .claude/docs/concepts/directory-organization.md || \
  { echo "ERROR: directory-organization.md already exists!"; exit 1; }

echo "✓ Verified: Target files don't exist (safe to create)"
```

#### Phase 2: Per-Extraction Size Validation

**Task 2.1: Code Standards Extraction Size Check**
```bash
# After creating reference/code-standards.md, verify size
lines=$(wc -l < .claude/docs/reference/code-standards.md)
echo "code-standards.md: $lines lines"

if (( lines > 400 )); then
  echo "BLOAT ALERT: code-standards.md exceeds 400 lines ($lines)"
  exit 1
elif (( lines > 100 )); then
  echo "WARNING: code-standards.md larger than expected ($lines lines, expected ~84)"
fi

echo "✓ PASSED: code-standards.md within threshold"
```

**Task 2.2: Directory Organization Extraction Size Check**
```bash
# After creating concepts/directory-organization.md, verify size
lines=$(wc -l < .claude/docs/concepts/directory-organization.md)
echo "directory-organization.md: $lines lines"

if (( lines > 400 )); then
  echo "BLOAT ALERT: directory-organization.md exceeds 400 lines ($lines)"
  exit 1
elif (( lines > 250 )); then
  echo "WARNING: directory-organization.md larger than expected ($lines lines, expected ~231)"
fi

echo "✓ PASSED: directory-organization.md within threshold"
```

**Task 2.3: Hierarchical Agents Merge Size Check**
```bash
# BEFORE merging CLAUDE.md content into concepts/hierarchical_agents.md
lines_before=$(wc -l < .claude/docs/concepts/hierarchical_agents.md)
echo "hierarchical_agents.md (before merge): $lines_before lines"

# Calculate projected size
claude_content=93  # From CLAUDE.md
projected=$((lines_before + claude_content))
echo "Projected size after merge: $projected lines"

if (( projected > 400 )); then
  echo "BLOAT RISK: Merge would exceed threshold ($projected lines)"
  echo "FALLBACK: Keep CLAUDE.md section inline, add cross-reference only"
  exit 1
fi

echo "✓ SAFE: Merge projected at $projected lines (below 400 threshold)"
# Proceed with merge only if this check passes
```

**Task 2.4: State-Based Orchestration Link Replacement Size Check**
```bash
# Verify NO merge occurs (link-only strategy)
lines_before=$(wc -l < .claude/docs/architecture/state-based-orchestration-overview.md)
echo "state-based-orchestration-overview.md (before): $lines_before lines"

# After CLAUDE.md section is replaced with link, verify file unchanged
lines_after=$(wc -l < .claude/docs/architecture/state-based-orchestration-overview.md)
echo "state-based-orchestration-overview.md (after): $lines_after lines"

if (( lines_after != lines_before )); then
  echo "ERROR: File size changed! Link-only strategy violated."
  echo "Expected: $lines_before, Actual: $lines_after"
  exit 1
fi

echo "✓ VERIFIED: Link-only strategy maintained (no merge occurred)"
```

#### Phase 3: Post-Extraction Validation

**Task 3.1: CLAUDE.md Reduction Verification**
```bash
# Verify CLAUDE.md achieved target reduction
lines_after=$(wc -l < CLAUDE.md)
target=527
tolerance=50  # Allow ±50 lines

echo "CLAUDE.md after extractions: $lines_after lines"
echo "Target: $target lines"

if (( lines_after > target + tolerance )); then
  echo "WARNING: CLAUDE.md larger than target ($lines_after > $((target + tolerance)))"
  echo "Review extractions for missed content"
elif (( lines_after < target - tolerance )); then
  echo "WARNING: CLAUDE.md smaller than target ($lines_after < $((target - tolerance)))"
  echo "Review summaries - may be too brief"
else
  echo "✓ PASSED: CLAUDE.md within target range"
fi
```

**Task 3.2: No New Bloated Files Created**
```bash
# Scan all newly created files for bloat
echo "=== NEW FILE SIZE AUDIT ==="

for file in .claude/docs/reference/code-standards.md \
            .claude/docs/concepts/directory-organization.md; do
  if [[ -f "$file" ]]; then
    lines=$(wc -l < "$file")
    echo "$file: $lines lines"

    if (( lines > 400 )); then
      echo "BLOAT ALERT: $file exceeds threshold!"
      exit 1
    fi
  fi
done

echo "✓ PASSED: All new files below 400-line threshold"
```

**Task 3.3: Bloat Rollback Procedure (if any check fails)**
```bash
# Automated rollback if bloat detected
if [[ -f /tmp/bloat_detected ]]; then
  echo "BLOAT DETECTED: Rolling back changes"

  # Restore CLAUDE.md from git
  git checkout HEAD -- CLAUDE.md

  # Remove newly created bloated files
  rm -f .claude/docs/reference/code-standards.md
  rm -f .claude/docs/concepts/directory-organization.md

  # Restore merged files from git
  git checkout HEAD -- .claude/docs/concepts/hierarchical_agents.md

  echo "ROLLBACK COMPLETE: Bloat changes reverted"
  echo "RECOMMENDATION: Review extraction strategy and split large sections"
  exit 1
fi
```

#### Phase 4: Final Verification

**Task 4.1: Comprehensive Bloat Audit**
```bash
# Full scan of .claude/docs/ for bloated files
echo "=== FINAL BLOAT AUDIT ==="
echo "Files exceeding 400-line threshold:"

find .claude/docs -name "*.md" -type f ! -path "*/archive/*" | while read -r file; do
  lines=$(wc -l < "$file")
  if (( lines > 400 )); then
    bloat_factor=$(( (lines - 400) * 100 / 400 ))
    printf "%5d lines (+%3d%%) %s\n" "$lines" "$bloat_factor" "$file"
  fi
done

echo ""
echo "Files exceeding CRITICAL threshold (800 lines):"
find .claude/docs -name "*.md" -type f ! -path "*/archive/*" | while read -r file; do
  lines=$(wc -l < "$file")
  if (( lines > 800 )); then
    printf "%5d lines (CRITICAL) %s\n" "$lines" "$file"
  fi
done
```

**Task 4.2: Document Bloat Metrics**
```bash
# Generate bloat metrics report
cat > /tmp/bloat_metrics.md <<EOF
# Bloat Metrics Report

## Before Optimization
- CLAUDE.md: 964 lines
- Bloated files (>400): [from baseline]
- Critical files (>800): [from baseline]

## After Optimization
- CLAUDE.md: $(wc -l < CLAUDE.md) lines
- Bloated files (>400): $(find .claude/docs -name "*.md" -type f ! -path "*/archive/*" -exec sh -c 'wc -l < "$1"' _ {} \; | awk '$1 > 400 {count++} END {print count}')
- Critical files (>800): $(find .claude/docs -name "*.md" -type f ! -path "*/archive/*" -exec sh -c 'wc -l < "$1"' _ {} \; | awk '$1 > 800 {count++} END {print count}')

## Reduction Achieved
- CLAUDE.md reduction: $((964 - $(wc -l < CLAUDE.md))) lines ($(( (964 - $(wc -l < CLAUDE.md)) * 100 / 964 ))%)
EOF

cat /tmp/bloat_metrics.md
```

## Bloat Prevention Guidance

### For cleanup-plan-architect

**CRITICAL INSTRUCTIONS** for creating implementation plan:

#### 1. Mandatory Size Validation Tasks

**REQUIREMENT**: Every extraction phase MUST include:

1. **Pre-extraction size check** (verify target file size if exists)
2. **Post-extraction size validation** (verify created/merged file <400 lines)
3. **Bloat rollback procedure** (automated revert if threshold exceeded)

**Template for extraction tasks**:
```yaml
- task: "Extract [SECTION] from CLAUDE.md to [TARGET_FILE]"
  validations:
    - pre: "Verify [TARGET_FILE] current size (if exists)"
    - post: "wc -l [TARGET_FILE]; test $? -lt 400"
    - rollback: "git checkout HEAD -- [FILES] if bloat detected"
```

#### 2. Hierarchical Agents Merge Decision

**CONDITIONAL MERGE LOGIC**:

```bash
# Phase 3: Hierarchical Agents Merge
# STEP 1: Pre-merge size check
lines_before=$(wc -l < .claude/docs/concepts/hierarchical_agents.md)
projected=$((lines_before + 93))

# STEP 2: Decision point
if (( projected > 400 )); then
  echo "DECISION: Skip merge (projected $projected lines exceeds threshold)"
  echo "ACTION: Add cross-reference only to CLAUDE.md"
  # Add "See also: concepts/hierarchical_agents.md" to CLAUDE.md section
else
  echo "DECISION: Proceed with merge (projected $projected lines safe)"
  # Merge unique content from CLAUDE.md into concepts/hierarchical_agents.md
  # Replace CLAUDE.md section with summary + link
fi
```

**Implementation Plan Requirement**: Create TWO plan branches:
- **Branch A** (if projected <400 lines): Merge content + replace with summary
- **Branch B** (if projected ≥400 lines): Keep CLAUDE.md section + add cross-reference

#### 3. State-Based Orchestration Link-Only Strategy

**MANDATE**: NO content extraction, ONLY link replacement

**Implementation steps**:
1. Read CLAUDE.md State-Based Orchestration section (lines to be determined)
2. Craft 5-10 line summary covering:
   - What: State machines with validated transitions
   - Why: Explicit states, validated transitions, checkpoint management
   - When: 3+ phases, conditional transitions, resume required
3. Replace entire section with summary + link to architecture/state-based-orchestration-overview.md
4. **VERIFY**: architecture/state-based-orchestration-overview.md size unchanged

**Validation**:
```bash
# MUST pass this check
lines_before=[record from Phase 1]
lines_after=$(wc -l < .claude/docs/architecture/state-based-orchestration-overview.md)
test $lines_before -eq $lines_after || { echo "ERROR: File modified!"; exit 1; }
```

#### 4. Bloat Threshold Enforcement

**HARD LIMITS** (fail-fast if exceeded):

- **400 lines**: Warning threshold, careful review required
- **350 lines** (merge target): Stop merging if current + addition exceeds this
- **800 lines**: Critical threshold, immediate split required

**Enforcement in implementation plan**:
```bash
# After every file creation or merge
lines=$(wc -l < $FILE)
if (( lines > 400 )); then
  echo "BLOAT DETECTED: $FILE ($lines lines)"
  trigger_rollback
  exit 1
fi
```

#### 5. Split Task Prioritization

**Phase Priority**:
1. **IMMEDIATE** (Phase 5 or earlier): command-development-guide.md 4-way split (3,980 lines CRITICAL)
2. **IMMEDIATE** (Phase 5 or earlier): state-based-orchestration-overview.md 6-way split (2,000+ lines CRITICAL)
3. **DEFERRED** (future sprint): Command guide 2-way splits (567, 512, 487 lines)

**Rationale**: Address critical bloat (>800 lines) first, defer moderate bloat (400-600 lines) to avoid scope creep

#### 6. Cross-Reference Update Requirements

**MUST update after each extraction**:
- CLAUDE.md sections → Update to link to new target files
- guides/README.md → Update navigation links
- All files referencing extracted content → Update links

**Validation**:
```bash
# Run link validation after all extractions
.claude/scripts/validate-links-quick.sh || {
  echo "BROKEN LINKS DETECTED: Fix before committing"
  exit 1
}
```

#### 7. Final Bloat Audit Phase

**Mandatory final phase** in implementation plan:

**Tasks**:
1. Run comprehensive bloat audit (Task 4.1)
2. Generate bloat metrics report (Task 4.2)
3. Verify no new bloated files created
4. Verify CLAUDE.md achieved target reduction (527 ± 50 lines)
5. Document any remaining bloated files with justification

**Success Criteria**:
- CLAUDE.md: 477-577 lines (target 527 ± 50)
- Zero new files >400 lines
- All link validation passing
- Bloat metrics report generated

---

REPORT_CREATED: /home/benjamin/.config/.claude/specs/711_optimize_claudemd_structure/reports/003_bloat_analysis.md
