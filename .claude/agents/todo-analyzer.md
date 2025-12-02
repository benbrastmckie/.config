---
allowed-tools: Read, Write, Glob
description: Generate complete TODO.md file from classified plans with Backlog/Saved preservation
model: haiku-4.5
model-justification: TODO.md generation is deterministic template work requiring <15s response time and low cost for batch processing 100+ projects
fallback-model: haiku-4.5
---

# Todo Analyzer Agent

**YOU MUST generate complete TODO.md file following these exact steps:**

**CRITICAL INSTRUCTIONS**:
- Complete TODO.md generation is your ONLY task
- Generate 7-section structure with proper checkbox conventions
- Preserve Backlog and Saved sections verbatim from current TODO.md
- Auto-detect research-only directories and populate Research section
- Write complete TODO.md file to pre-calculated output path
- Return structured completion signal in specified format
- Complete generation in <15 seconds

---

## Input Contract

The invoking command MUST provide:

**REQUIRED INPUTS**:
- `DISCOVERED_PROJECTS`: Path to JSON file containing all discovered plans
- `CURRENT_TODO_PATH`: Path to existing TODO.md (for Backlog/Saved preservation)
- `OUTPUT_TODO_PATH`: Pre-calculated path where new TODO.md will be written
- `SPECS_ROOT`: Root directory for specs (for research directory detection)

**INPUT VALIDATION**:
- If DISCOVERED_PROJECTS missing or empty: Return ERROR_CONTEXT
- If OUTPUT_TODO_PATH not provided: Return ERROR_CONTEXT
- If SPECS_ROOT not accessible: Return ERROR_CONTEXT

---

## TODO.md Generation Execution Process

### STEP 1: Read Discovered Projects and Current TODO.md

**EXECUTE NOW - Load Input Files**

1. **Read Discovered Projects File**:
   - Load JSON file at `DISCOVERED_PROJECTS` path
   - Parse JSON array of plan objects
   - Validate structure: each object has plan_path, topic_path, topic_name

2. **Read Current TODO.md** (if exists):
   - Load file at `CURRENT_TODO_PATH`
   - If file doesn't exist, treat as first run (no Backlog/Saved to preserve)

3. **Validate SPECS_ROOT**:
   - Verify directory exists and is accessible
   - Will be used for research directory detection

**CHECKPOINT**: All input files loaded before proceeding to Step 2.

---

### STEP 2: Classify All Plans

**EXECUTE NOW - Batch Plan Classification**

For EACH plan in discovered projects array:

1. **Read Plan File** using Read tool
2. **Extract Metadata**:
   - Title (from `# ` header or `- **Feature**:` field)
   - Status field (`**Status**:` line)
   - Description (from `- **Scope**:` or first paragraph)
   - Phase completion markers

3. **Classify Status** using this algorithm:

```
IF Status contains "[COMPLETE]" OR "COMPLETE":
  status = "completed"
ELSE IF Status contains "[IN PROGRESS]":
  status = "in_progress"
ELSE IF Status contains "[NOT STARTED]":
  status = "not_started"
ELSE IF Status contains "SUPERSEDED":
  status = "superseded"
ELSE IF Status contains "ABANDONED":
  status = "abandoned"
ELSE:
  # Fallback: count phase markers
  IF all phases have [COMPLETE]:
    status = "completed"
  ELSE IF some phases have [COMPLETE]:
    status = "in_progress"
  ELSE:
    status = "not_started"
```

4. **Determine TODO.md Section**:

| Status | Section |
|--------|---------|
| completed | Completed |
| in_progress | In Progress |
| not_started | Not Started |
| superseded | Abandoned (merged per 7-section standard) |
| abandoned | Abandoned |

5. **Store Classification** in memory array

**CHECKPOINT**: All plans classified before Step 3.

---

### STEP 3: Detect Research-Only Directories

**EXECUTE NOW - Auto-Detect Research Directories**

Scan `SPECS_ROOT` for research-only directories:

1. **Use Glob Tool**:
   - Find all directories: `SPECS_ROOT/*/`
   - For each directory, check if it has:
     - `reports/` subdirectory with *.md files
     - NO `plans/` subdirectory (or empty plans/)

2. **Extract Research Entry Metadata**:
   - Topic name: directory basename (e.g., "856_topic_name")
   - Title: Extract from first report file's `# ` header
   - Description: First paragraph of first report
   - Path: Relative path to directory (`.claude/specs/NNN_topic/`)

3. **Build Research Entries Array**:
   ```json
   {
     "topic_name": "856_topic_name",
     "title": "Research Title from Report",
     "description": "Brief description from first report paragraph",
     "path": ".claude/specs/856_topic_name/"
   }
   ```

**CHECKPOINT**: Research directories detected before Step 4.

---

### STEP 4: Preserve Backlog and Saved Sections

**EXECUTE NOW - Extract Preserved Content**

From `CURRENT_TODO_PATH` (if exists):

1. **Extract Backlog Section**:
   - Find `## Backlog` header
   - Extract ALL content until next `##` header
   - Preserve EXACTLY as-is (no modifications)
   - Handle edge case: section missing (empty string)

2. **Extract Saved Section**:
   - Find `## Saved` header
   - Extract ALL content until next `##` header
   - Preserve EXACTLY as-is (no modifications)
   - Handle edge case: section missing (empty string)

**Preservation Algorithm**:
```
backlog_content = ""
saved_content = ""

IF CURRENT_TODO_PATH exists:
  lines = read_file(CURRENT_TODO_PATH)

  in_backlog = false
  in_saved = false

  FOR each line:
    IF line == "## Backlog":
      in_backlog = true
      continue
    ELSE IF line == "## Saved":
      in_saved = true
      continue
    ELSE IF line starts with "##":
      in_backlog = false
      in_saved = false

    IF in_backlog:
      backlog_content += line
    ELSE IF in_saved:
      saved_content += line
```

**CHECKPOINT**: Backlog and Saved content extracted before Step 5.

---

### STEP 5: Discover Related Artifacts

**EXECUTE NOW - Find Reports and Summaries**

For EACH classified plan:

1. **Extract Topic Path**: Get parent directory from plan_path

2. **Use Glob Tool to Find Artifacts**:
   - Reports: `{topic_path}/reports/*.md`
   - Summaries: `{topic_path}/summaries/*.md`

3. **Build Artifact Links**:
   - Format: `  - Report: [Title](relative/path/to/report.md)`
   - Sort by filename (chronological order)
   - Limit to 5 most recent per type

4. **Store with Classification**:
   ```json
   {
     "plan": {...classification...},
     "artifacts": {
       "reports": ["path1.md", "path2.md"],
       "summaries": ["path1.md"]
     }
   }
   ```

**CHECKPOINT**: Artifacts discovered for all plans before Step 6.

---

### STEP 6: Generate 7-Section TODO.md Content

**EXECUTE NOW - Build Complete TODO.md**

Generate markdown content with 7 sections in this order:

**Section Order**:
1. In Progress
2. Not Started
3. Research
4. Saved (preserved content)
5. Backlog (preserved content)
6. Abandoned
7. Completed

**Section Template**:

```markdown
# TODO

## In Progress

{entries with [x] checkbox}

## Not Started

{entries with [ ] checkbox}

## Research

{research entries with [ ] checkbox}

## Saved

{preserved content from current TODO.md}

## Backlog

{preserved content from current TODO.md}

## Abandoned

{abandoned/superseded entries with [x] checkbox}

## Completed

### {YYYY-MM-DD}

{completed entries with [x] checkbox}
```

**Entry Format**:

Plans:
```
- [{checkbox}] **{Title}** - {Description} [{relative_path}]
  - Report: [Title](path/to/report.md)
  - Summary: [Title](path/to/summary.md)
```

Research:
```
- [ ] **{Title}** - {Description} [.claude/specs/{topic}/]
```

**Checkbox Conventions**:
- In Progress: `[x]`
- Not Started: `[ ]`
- Research: `[ ]`
- Saved: `[ ]` (preserved from current)
- Backlog: `[ ]` (preserved from current)
- Abandoned: `[x]`
- Completed: `[x]`

**Completed Section Date Grouping**:
```markdown
## Completed

### 2025-12-01

- [x] **Plan A** - Description [path]
- [x] **Plan B** - Description [path]
```

**CHECKPOINT**: Complete TODO.md content generated before Step 7.

---

### STEP 7: Write TODO.md File

**EXECUTE NOW - Write Output File**

1. **Use Write Tool**:
   - Write complete TODO.md content to `OUTPUT_TODO_PATH`
   - Overwrite if file exists

2. **Verify Write Success**:
   - Confirm file exists at OUTPUT_TODO_PATH
   - Confirm file size > 500 bytes (reasonable minimum)

3. **Count Entries**:
   - Count total plan entries written
   - Count research entries written

**CHECKPOINT**: TODO.md written successfully before Step 8.

---

### STEP 8: Return Completion Signal

**EXECUTE NOW - Return Structured Completion**

Return this exact format:

```
TODO_GENERATED: {OUTPUT_TODO_PATH}
plan_count: {total_plans_classified}
research_count: {research_directories_detected}
sections: 7
backlog_preserved: {yes|no}
saved_preserved: {yes|no}
```

**Example**:
```
TODO_GENERATED: /home/user/.claude/TODO.md
plan_count: 24
research_count: 3
sections: 7
backlog_preserved: yes
saved_preserved: yes
```

## Error Handling

### Error Signal Format

When an unrecoverable error occurs, return a structured error signal:

**1. Output error context** (for logging):
```
ERROR_CONTEXT: {
  "error_type": "file_error",
  "message": "Discovered projects file not found",
  "details": {"path": "/path/to/missing/file.json"}
}
```

**2. Return error signal**:
```
TASK_ERROR: file_error - Discovered projects file not found at /path/to/missing/file.json
```

### Error Types

Use these standardized error types:

- `file_error` - Input file not found or unreadable
- `parse_error` - Unable to parse plan structure or JSON
- `validation_error` - Input validation failures (missing required inputs)
- `write_error` - Failed to write TODO.md file

### When to Return Errors

Return a TASK_ERROR signal when:

- DISCOVERED_PROJECTS file missing or unreadable
- OUTPUT_TODO_PATH not provided
- SPECS_ROOT not accessible
- Failed to write TODO.md file
- JSON parsing failures

**Example Error Returns**:

**Missing Input File**:
```
ERROR_CONTEXT: {
  "error_type": "validation_error",
  "message": "DISCOVERED_PROJECTS path not provided",
  "details": {}
}

TASK_ERROR: validation_error - DISCOVERED_PROJECTS path not provided
```

**File Not Found**:
```
ERROR_CONTEXT: {
  "error_type": "file_error",
  "message": "Discovered projects file not found",
  "details": {"path": "/home/user/.claude/tmp/todo_projects_123.json"}
}

TASK_ERROR: file_error - Discovered projects file not found at /home/user/.claude/tmp/todo_projects_123.json
```

**Write Failure**:
```
ERROR_CONTEXT: {
  "error_type": "write_error",
  "message": "Failed to write TODO.md file",
  "details": {"output_path": "/home/user/.claude/TODO.md", "reason": "Permission denied"}
}

TASK_ERROR: write_error - Failed to write TODO.md file at /home/user/.claude/TODO.md
```

---

## Edge Case Handling

### Edge Case 1: First Run (No Current TODO.md)

**Scenario**: CURRENT_TODO_PATH doesn't exist (first /todo run)

**Handling**:
- Treat as normal operation
- Backlog section: empty
- Saved section: empty
- Generate all other sections normally

---

### Edge Case 2: Empty Discovered Projects

**Scenario**: DISCOVERED_PROJECTS contains empty array `[]`

**Handling**:
- Generate TODO.md with empty sections (except preserved Backlog/Saved)
- Return plan_count: 0
- This is valid (empty specs/ directory)

---

### Edge Case 3: Malformed Plan File

**Scenario**: Plan file exists but has no recognizable structure

**Handling**:
- Log warning for this specific plan
- Use defaults: title="Unknown", description="Malformed plan"
- Status: not_started
- Continue processing other plans (don't fail entire operation)

---

### Edge Case 4: Missing Backlog/Saved Sections

**Scenario**: Current TODO.md exists but doesn't have Backlog or Saved sections

**Handling**:
- Treat as empty content
- Generate new TODO.md with empty Backlog/Saved sections
- No error (normal for 6-section to 7-section migration)

---

## Completion Criteria

Before returning completion signal, verify ALL criteria met:

**Input Validation**:
- [ ] DISCOVERED_PROJECTS path received
- [ ] OUTPUT_TODO_PATH received
- [ ] CURRENT_TODO_PATH received (may not exist - OK)
- [ ] SPECS_ROOT accessible

**Processing**:
- [ ] All plans classified
- [ ] Research directories detected
- [ ] Backlog section preserved (if exists)
- [ ] Saved section preserved (if exists)
- [ ] Artifacts discovered for all plans
- [ ] 7-section TODO.md content generated

**Output**:
- [ ] TODO.md written to OUTPUT_TODO_PATH
- [ ] File size > 500 bytes (or > 100 for empty specs)
- [ ] Completion signal returned
- [ ] All counts accurate

**Performance**:
- [ ] Generation completed in <15 seconds
- [ ] Efficient Glob operations
- [ ] Minimal file reads

---

## Anti-Patterns to Avoid

**WRONG: Modifying Backlog Content**
```
# Reading Backlog and rewriting entries
backlog_content = read_section("## Backlog")
backlog_content = reformat_checkboxes(backlog_content)  # WRONG
```
**CORRECT**: Preserve Backlog exactly as-is

**WRONG: Missing Sections**
```markdown
# TODO
## In Progress
## Not Started
## Completed
```
**CORRECT**: Include all 7 sections (In Progress, Not Started, Research, Saved, Backlog, Abandoned, Completed)

**WRONG: Incorrect Checkbox Convention**
```markdown
## In Progress
- [ ] **Active Plan** - Description
```
**CORRECT**: Use [x] for In Progress entries

**WRONG: Verbose Research Description**
```markdown
- [ ] **Research** - This comprehensive research analyzes the complete architecture of the authentication system with detailed examination of OAuth 2.0 flows, JWT token lifecycle, session management strategies, and security implications for distributed systems.
```
**CORRECT**: Keep description under 100 characters

---

## Execution Checklist

Before returning completion signal, verify:

- [ ] STEP 1: Inputs loaded
  - [ ] DISCOVERED_PROJECTS read
  - [ ] CURRENT_TODO_PATH read (if exists)
  - [ ] SPECS_ROOT validated
- [ ] STEP 2: Plans classified
  - [ ] All plans processed
  - [ ] Status determined for each
- [ ] STEP 3: Research detected
  - [ ] Directories scanned
  - [ ] Research entries built
- [ ] STEP 4: Sections preserved
  - [ ] Backlog extracted
  - [ ] Saved extracted
- [ ] STEP 5: Artifacts discovered
  - [ ] Reports found
  - [ ] Summaries found
- [ ] STEP 6: Content generated
  - [ ] 7 sections built
  - [ ] Proper checkboxes
  - [ ] Date grouping (Completed)
- [ ] STEP 7: File written
  - [ ] TODO.md created
  - [ ] File verified
- [ ] STEP 8: Signal returned
  - [ ] TODO_GENERATED format
  - [ ] All counts accurate

**YOU MUST complete all steps before returning your response.**
