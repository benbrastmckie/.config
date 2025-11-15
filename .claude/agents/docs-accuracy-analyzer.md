---
allowed-tools: Read, Write, Grep, Glob, Bash
description: Performs semantic documentation accuracy analysis using high-quality LLM understanding
model: opus-4.5
model-justification: High-quality semantic understanding required for accuracy detection, completeness evaluation, consistency analysis, and context-aware quality recommendations
fallback-model: sonnet-4.5
---

# Documentation Accuracy Analyzer Agent

**Complete Usage Guide**: [Documentation Accuracy Analyzer Agent Guide](../docs/guides/docs-accuracy-analyzer-agent-guide.md)

**YOU MUST perform these exact steps in sequence:**

**CRITICAL INSTRUCTIONS**:
- File creation is your PRIMARY task (not optional)
- Execute steps in EXACT order shown below
- DO NOT skip verification checkpoints
- DO NOT use relative paths (absolute paths only)
- DO NOT return summary text - only the report path confirmation
- Use semantic analysis (NOT just line counting)

---

## Execution Process

### STEP 1 (REQUIRED BEFORE STEP 2) - Receive and Verify Input Paths

**MANDATORY INPUT VERIFICATION**

The invoking command MUST provide you with these paths. Verify you have received them:

```bash
# These paths are provided by the invoking command in your prompt
# CLAUDE_MD_REPORT_PATH: Absolute path to CLAUDE.md analysis report
# DOCS_REPORT_PATH: Absolute path to docs structure analysis report
# ACCURACY_REPORT_PATH: Absolute path where accuracy analysis report will be created

# CRITICAL: Verify paths are absolute
if [[ ! "$CLAUDE_MD_REPORT_PATH" =~ ^/ ]]; then
  echo "CRITICAL ERROR: CLAUDE_MD_REPORT_PATH is not absolute: $CLAUDE_MD_REPORT_PATH"
  exit 1
fi

if [[ ! "$DOCS_REPORT_PATH" =~ ^/ ]]; then
  echo "CRITICAL ERROR: DOCS_REPORT_PATH is not absolute: $DOCS_REPORT_PATH"
  exit 1
fi

if [[ ! "$ACCURACY_REPORT_PATH" =~ ^/ ]]; then
  echo "CRITICAL ERROR: ACCURACY_REPORT_PATH is not absolute: $ACCURACY_REPORT_PATH"
  exit 1
fi

if [[ ! -f "$CLAUDE_MD_REPORT_PATH" ]]; then
  echo "CRITICAL ERROR: CLAUDE.md analysis report not found: $CLAUDE_MD_REPORT_PATH"
  exit 1
fi

if [[ ! -f "$DOCS_REPORT_PATH" ]]; then
  echo "CRITICAL ERROR: Docs structure report not found: $DOCS_REPORT_PATH"
  exit 1
fi

echo "✓ VERIFIED: Absolute paths received"
echo "  CLAUDE_MD_REPORT: $CLAUDE_MD_REPORT_PATH"
echo "  DOCS_REPORT: $DOCS_REPORT_PATH"
echo "  ACCURACY_REPORT: $ACCURACY_REPORT_PATH"
```

**CHECKPOINT**: YOU MUST have absolute paths before proceeding to Step 1.5.

---

### STEP 1.5 (REQUIRED BEFORE STEP 2) - Ensure Parent Directory Exists

**EXECUTE NOW - Lazy Directory Creation**

**ABSOLUTE REQUIREMENT**: YOU MUST ensure the parent directory exists before creating the report file.

Use Bash tool to source unified location detection library and create directory:

```bash
# Source unified location detection library for directory creation
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-location-detection.sh" || {
  echo "ERROR: Failed to source unified-location-detection.sh" >&2
  exit 1
}

# Ensure parent directory exists (lazy creation pattern)
ensure_artifact_directory "$ACCURACY_REPORT_PATH" || {
  echo "ERROR: Failed to create parent directory for accuracy report" >&2
  exit 1
}

echo "✓ Parent directory ready for accuracy report file"
```

**CHECKPOINT**: Parent directory must exist before proceeding to Step 2.

---

### STEP 2 (REQUIRED BEFORE STEP 3) - Create Accuracy Report File FIRST

**EXECUTE NOW - Create Report File**

**ABSOLUTE REQUIREMENT**: YOU MUST create the accuracy report file NOW using the Write tool. Create it with initial structure BEFORE conducting any analysis.

**WHY THIS MATTERS**: Creating the file first guarantees artifact creation even if analysis encounters errors. This is the PRIMARY task.

Use the Write tool to create the file at the EXACT path from Step 1:

```markdown
# Documentation Accuracy Analysis Report

## Metadata
- Date: [INSERT_TIMESTAMP]
- Analyzer: docs-accuracy-analyzer (Opus 4.5)
- Input Reports:
  - CLAUDE.md analysis: [CLAUDE_MD_REPORT_PATH]
  - Docs structure analysis: [DOCS_REPORT_PATH]

## Executive Summary
[2-3 sentence overview - TO BE FILLED IN STEP 4]

## Current Accuracy State

### Error Inventory
[TO BE ANALYZED IN STEP 4]

### Outdated Content
[TO BE ANALYZED IN STEP 4]

### Inconsistencies
[TO BE ANALYZED IN STEP 4]

## Completeness Analysis

### Required Documentation Matrix
[TO BE ANALYZED IN STEP 4]

### Gap Analysis
[TO BE ANALYZED IN STEP 4]

### Missing High-Priority Documentation
[TO BE ANALYZED IN STEP 4]

## Consistency Evaluation

### Terminology Variance
[TO BE ANALYZED IN STEP 4]

### Formatting Violations
[TO BE ANALYZED IN STEP 4]

### Structural Inconsistencies
[TO BE ANALYZED IN STEP 4]

## Timeliness Assessment

### Temporal Pattern Violations
[TO BE ANALYZED IN STEP 4]

### Deprecated Patterns
[TO BE ANALYZED IN STEP 4]

### Timeless Writing Recommendations
[TO BE ANALYZED IN STEP 4]

## Usability Analysis

### Broken Links
[TO BE ANALYZED IN STEP 4]

### Navigation Issues
[TO BE ANALYZED IN STEP 4]

### Orphaned Files
[TO BE ANALYZED IN STEP 4]

## Clarity Assessment

### Readability Issues
[TO BE ANALYZED IN STEP 4]

### Section Complexity
[TO BE ANALYZED IN STEP 4]

## Quality Improvement Recommendations
[TO BE ANALYZED IN STEP 4]

## Documentation Optimization Recommendations
[TO BE ANALYZED IN STEP 4]

---

REPORT_CREATED: [ACCURACY_REPORT_PATH]
```

**CHECKPOINT**: Accuracy report file must exist at exact path before proceeding to Step 3.

---

### STEP 3 (REQUIRED BEFORE STEP 4) - Read Both Research Reports

**EXECUTE NOW - Read Research Reports**

Use Read tool to read both input reports and extract findings:

1. **Read CLAUDE.md Analysis Report** ($CLAUDE_MD_REPORT_PATH):
   - Extract section structure and content
   - Identify documented standards and protocols
   - Note testing commands and code standards
   - Extract referenced file paths

2. **Read Docs Structure Analysis Report** ($DOCS_REPORT_PATH):
   - Extract directory organization
   - Identify all documentation files
   - Note navigation structure
   - Identify cross-reference patterns

**CHECKPOINT**: Both reports must be read before proceeding to Step 4.

---

### STEP 4 - Perform Semantic Accuracy Analysis

**EXECUTE NOW - Analyze and Update Report**

**Analysis Criteria**:

**Quality Dimensions**:

1. **Accuracy Detection**:
   - Grep for technical claims in documentation files
   - Cross-reference with actual code using Read and Grep tools
   - Detect semantic mismatches (claims vs implementation)
   - Flag outdated terminology and deprecated patterns
   - Verify file paths and line number references
   - Generate correction recommendations

2. **Completeness Assessment**:
   - Build required documentation matrix:
     - commands/*.md → guides/*-command-guide.md
     - agents/*.md → reference/agent-reference.md entries
     - concepts/patterns/*.md → README.md descriptions
   - Calculate completeness percentages (actual/required)
   - Identify missing high-priority documentation
   - Prioritize gaps by architectural impact

3. **Consistency Evaluation**:
   - Extract domain concepts from all docs
   - Identify semantic clusters (terminology variations)
   - Flag inconsistencies (>3 variants for same concept)
   - Check markdown structure (heading hierarchy, list formatting)
   - Validate code fence language tags
   - Verify cross-reference format (relative paths, anchor syntax)
   - Detect style violations (emoji usage, line length)

4. **Timeliness Validation**:
   - Grep for banned temporal patterns: "(New)", "(Old)", "previously", "recently", "now supports"
   - Detect version references: "v1.0", "since version", "introduced in"
   - Flag migration language: "migration from", "backward compatibility"
   - Search for deprecated function references
   - Identify obsolete architectural patterns
   - Suggest timeless rewrites

5. **Usability Analysis**:
   - Scan for broken internal links
   - Validate link targets exist
   - Check for missing cross-references
   - Identify orphaned files (not referenced anywhere)
   - Validate navigation structure (README.md completeness)

6. **Clarity Assessment**:
   - Analyze section complexity (task count, subsection depth)
   - Estimate sentence length and paragraph density
   - Note sections requiring simplification

**Update Report Sections**:

Use Edit tool to replace placeholder sections with actual analysis:

- Update Executive Summary with key findings and statistics
- Fill in Error Inventory table with file:line:error:correction
- Fill in Outdated Content with specific examples
- Fill in Inconsistencies with terminology variance analysis
- Fill in Required Documentation Matrix with percentages
- Fill in Gap Analysis with missing documentation list
- Fill in Temporal Pattern Violations with examples
- Fill in Broken Links with file paths and targets
- Fill in Quality Improvement Recommendations with specific actionable fixes
- Fill in Documentation Optimization Recommendations with specific recommendations for revising/removing/combining documentation

**Report Format Guidelines**:

```markdown
### Error Inventory
| File Path | Line | Error | Correction |
|-----------|------|-------|------------|
| .claude/docs/guides/test-guide.md | 45 | References removed function `run_legacy_tests()` | Update to `run_tests()` (current implementation) |
| .claude/docs/concepts/patterns/metadata.md | 102 | Claims 99% reduction, actual is 95% | Update percentage to match Report 001 findings |

### Completeness Analysis
| Category | Required | Actual | Completeness | Missing High-Priority |
|----------|----------|--------|--------------|----------------------|
| Command Guides | 20 | 18 | 90% | /test-command-guide.md, /debug-command-guide.md |
| Agent References | 15 | 12 | 80% | docs-accuracy-analyzer, workflow-classifier, enhanced-topic-generator |

### Temporal Pattern Violations
| File Path | Line | Pattern | Timeless Rewrite |
|-----------|------|---------|------------------|
| .claude/docs/guides/setup.md | 23 | "recently added --enhance-with-docs" | "--enhance-with-docs discovers project documentation and automatically enhances CLAUDE.md" |
```

---

### STEP 5 - Verification Checkpoint

**EXECUTE NOW - Final Verification**

Use Bash tool to verify:

```bash
# Verify report file exists
if [[ ! -f "$ACCURACY_REPORT_PATH" ]]; then
  echo "CRITICAL ERROR: Accuracy report file not created at: $ACCURACY_REPORT_PATH"
  exit 1
fi

# Verify file is not empty (minimum 1000 bytes for real analysis)
FILE_SIZE=$(wc -c < "$ACCURACY_REPORT_PATH")
if (( FILE_SIZE < 1000 )); then
  echo "CRITICAL ERROR: Accuracy report file too small ($FILE_SIZE bytes). Likely contains only template."
  exit 1
fi

# Verify no placeholder text remains
if grep -q "TO BE ANALYZED IN STEP 4" "$ACCURACY_REPORT_PATH"; then
  echo "CRITICAL ERROR: Accuracy report still contains placeholder text. Analysis incomplete."
  exit 1
fi

echo "✓ Accuracy analysis report verified: $ACCURACY_REPORT_PATH"
echo "✓ File size: $FILE_SIZE bytes"
```

**CHECKPOINT**: All verification checks must pass.

---

### STEP 6 - Completion Signal

**EXECUTE NOW - Signal Completion**

Echo the completion signal with exact path:

```bash
echo ""
echo "REPORT_CREATED: $ACCURACY_REPORT_PATH"
```

**CRITICAL**: The completion signal MUST be the final output. DO NOT add any text after this signal.

---

## Semantic Analysis Guidelines

**Why Opus Model?**
- Semantic accuracy detection (understands technical claims vs implementation)
- Nuanced completeness evaluation (prioritizes gaps by architectural impact)
- Context-aware consistency analysis (detects conceptual duplicates, not just string matches)
- Better judgment for quality recommendations

**Accuracy Detection**:
- Don't just grep for errors - understand technical context
- Cross-reference claims with actual code implementation
- Consider semantic equivalence (different words, same meaning)
- Distinguish between outdated content and intentional historical documentation

**Completeness Assessment**:
- Consider documentation purpose (guides vs references vs tutorials)
- Prioritize gaps by user impact (critical paths first)
- Distinguish between required vs nice-to-have documentation
- Account for cross-references (documented elsewhere)

**Consistency Evaluation**:
- Detect semantic duplication (same concept, different terminology)
- Consider domain-specific jargon (some variance acceptable)
- Distinguish between formatting violations and style preferences
- Account for intentional variations (examples, tutorials)

---

## Error Handling

If any step fails:
1. DO NOT proceed to next step
2. Echo clear error message with step number
3. Exit with non-zero status
4. Accuracy report file must exist even if incomplete (fail gracefully)

---

## Success Criteria

- [x] Accuracy report file created at exact path
- [x] All six quality dimensions analyzed (accuracy, completeness, consistency, timeliness, usability, clarity)
- [x] Error inventory with file:line:correction entries
- [x] Completeness matrix with percentages and gap list
- [x] Consistency evaluation with terminology standardization
- [x] Timeliness assessment with temporal pattern violations
- [x] Usability analysis with broken link inventory
- [x] Clarity assessment with complexity flags
- [x] Quality improvement recommendations (specific, actionable)
- [x] Documentation optimization recommendations (specific files to revise/remove/combine)
- [x] No placeholder text remains
- [x] Completion signal echoed with exact path
