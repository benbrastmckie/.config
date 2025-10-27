# Agent Tool Descriptions

Standard tool descriptions and usage patterns for agents. Reference this file instead of repeating tool documentation in each agent.

## Available Tools

### Read
Read files from the filesystem.

**Capabilities**:
- Read any file directly
- Specify line offset and limit for large files
- Read images (PNG, JPG, etc.)
- Read PDFs with text/visual extraction
- Read Jupyter notebooks with outputs

**Usage**:
```
Read {
  file_path: "/absolute/path/to/file.ext"
  offset: [line-number]  # Optional
  limit: [line-count]    # Optional
}
```

**Best Practices**:
- Use absolute paths
- Read whole files when possible (no offset/limit)
- Check file exists before reading
- Handle read errors gracefully

### Write
Write or overwrite files.

**Capabilities**:
- Create new files
- Overwrite existing files
- Write UTF-8 content only

**Usage**:
```
Write {
  file_path: "/absolute/path/to/file.ext"
  content: "File content here..."
}
```

**Best Practices**:
- Always use absolute paths
- Read existing files before overwriting
- Prefer Edit over Write for existing files
- No emojis in file content

### Edit
Make exact string replacements in files.

**Capabilities**:
- Replace specific strings
- Replace all occurrences
- Preserve file formatting

**Usage**:
```
Edit {
  file_path: "/absolute/path/to/file.ext"
  old_string: "exact string to replace"
  new_string: "replacement string"
  replace_all: false  # Optional, default false
}
```

**Best Practices**:
- Must Read file before Edit
- Preserve exact indentation
- Make unique replacements (or use replace_all)
- Don't include line number prefixes in strings

### Bash
Execute bash commands.

**Capabilities**:
- Run shell commands
- Chain commands with &&
- Set timeout (max 10 minutes)
- Run in background

**Usage**:
```
Bash {
  command: "ls -la /path"
  description: "Brief description"
  timeout: 120000  # Optional, milliseconds
  run_in_background: false  # Optional
}
```

**Best Practices**:
- Use double quotes for paths with spaces
- Chain dependent commands with &&
- Set appropriate timeouts
- Provide clear descriptions
- Avoid interactive commands

### Grep
Search file contents using ripgrep.

**Capabilities**:
- Full regex support
- Filter by file type or glob pattern
- Show context lines (-A, -B, -C)
- Case-insensitive search (-i)
- Multiline matching

**Usage**:
```
Grep {
  pattern: "search pattern"
  path: "/path/to/search"  # Optional
  output_mode: "content"   # content|files_with_matches|count
  glob: "*.ext"            # Optional
  type: "js"               # Optional
  -i: true                 # Optional
  -n: true                 # Optional (line numbers)
  -A: 3                    # Optional (after context)
  -B: 3                    # Optional (before context)
}
```

**Best Practices**:
- Use for content search, not file finding
- Use glob or type for filtering
- Escape special regex characters
- Use multiline: true for cross-line patterns

### Glob
Find files by pattern.

**Capabilities**:
- Glob patterns (**, *, ?)
- Recursive search
- Results sorted by modification time

**Usage**:
```
Glob {
  pattern: "**/*.js"
  path: "/path/to/search"  # Optional
}
```

**Best Practices**:
- Use for finding files by name
- Use ** for recursive search
- Prefer Glob over 'find' command

### TodoWrite
Manage task list for current session.

**Capabilities**:
- Create task list with statuses
- Track progress through complex operations
- Only one task "in_progress" at a time

**Usage**:
```
TodoWrite {
  todos: [
    {
      content: "Task description (imperative)"
      status: "pending"|"in_progress"|"completed"
      activeForm: "Task description (present continuous)"
    }
  ]
}
```

**Best Practices**:
- Use for complex multi-step tasks (3+ steps)
- Update immediately after completing task
- Only one task in_progress at a time
- Don't use for simple single-step operations

### Task
Invoke subagents with specific roles.

**Capabilities**:
- Delegate to specialized agents
- Pass context and requirements
- Receive structured responses

**Usage**:
```
Task {
  subagent_type: "general-purpose"
  description: "Brief task description"
  prompt: "Read and follow guidelines from: [agent-path.md]\n\n[Task context]"
}
```

**Best Practices**:
- Always reference agent file path
- Keep prompts under 500 tokens
- Provide task-specific context
- Set clear output expectations
- Use for specialized subtasks only

### WebSearch
Search the web for current information.

**Capabilities**:
- Search web for current events
- Filter by domain (allowed/blocked)
- Returns formatted search results

**Usage**:
```
WebSearch {
  query: "search query"
  allowed_domains: ["example.com"]  # Optional
  blocked_domains: ["spam.com"]     # Optional
}
```

**Best Practices**:
- Use for information beyond cutoff date
- Be specific with queries
- Account for current date in queries
- Filter domains when appropriate

### WebFetch
Fetch and process web content.

**Capabilities**:
- Fetch URL content
- Convert HTML to markdown
- Process with AI model

**Usage**:
```
WebFetch {
  url: "https://example.com/page"
  prompt: "What information to extract"
}
```

**Best Practices**:
- Use fully-formed URLs
- Describe what to extract in prompt
- Handle redirects appropriately
- Read-only operation

## Tool Combinations

### Code Analysis
```
Glob { pattern: "**/*.js" }  # Find files
Read { file_path: "..." }    # Read each file
Grep { pattern: "..." }      # Search patterns
```

### File Modification
```
Read { file_path: "..." }    # Read first
Edit { file_path: "..." }    # Then edit
# OR
Write { file_path: "..." }   # Overwrite
```

### Test Execution
```
Bash { command: "npm test" }  # Run tests
Read { file_path: "test.log" }  # Read results
```

### Agent Delegation
```
Task { /* Delegate to specialist */ }
Read { file_path: "artifact.md" }  # Read agent output
```

## Common Patterns

### Batch File Processing
```
1. Glob to find files
2. Read each file
3. Process/transform content
4. Write or Edit results
```

### Investigation Workflow
```
1. Grep to find patterns
2. Read relevant files
3. Analyze code
4. WebSearch for context (if needed)
5. Write report
```

### Implementation Workflow
```
1. Read plan file
2. Read existing files
3. Edit or Write changes
4. Bash to run tests
5. TodoWrite to track progress
```

### Orchestration Workflow
```
1. Task to delegate research
2. Task to delegate planning
3. Task to delegate implementation
4. Task to delegate documentation
```

## Tool Constraints

### Read-Only Agents
Some agents should only use read-only tools:
- **Research Specialist**: Read, Grep, Glob, WebSearch, WebFetch
- **Code Reviewer**: Read, Grep, Glob, Bash (read-only commands)
- **Debug Specialist**: Read, Grep, Glob, Bash (diagnostic commands)

### Write Agents
Some agents need write capabilities:
- **Code Writer**: Read, Write, Edit, Bash
- **Doc Writer**: Read, Write, Edit
- **Spec Updater**: Read, Write, Edit
- **Plan Architect**: Read, Write, Bash

### No TodoWrite Agents
Most agents should NOT use TodoWrite (orchestrator manages tasks):
- **Research Specialist**: No TodoWrite (single-focus research)
- **Code Writer**: No TodoWrite (phase-level tasks)
- **Debug Specialist**: No TodoWrite (investigation only)

### TodoWrite Agents
Only orchestration-level agents use TodoWrite:
- **Plan Architect**: May use for complex planning
- **Doc Writer**: May use for large doc updates

## Error Handling Patterns

### File Not Found
```
# Check existence first
if Read fails with "file not found":
  - Log error
  - Try alternative paths
  - Report to user if critical
```

### Command Failures
```
# Bash command errors
if Bash fails:
  - Check exit code
  - Read error output
  - Retry once if transient
  - Report failure
```

### Search No Results
```
# Grep or Glob finds nothing
if no results:
  - Try alternative patterns
  - Widen search scope
  - Report "not found" clearly
```

## Output Patterns

### Progress Updates
```
Bash { command: "echo 'PROGRESS: [stage] - [status]'" }
```

### Success Messages
```
"✓ [Operation] Complete
Artifact: [path]
Summary: [1-2 lines]"
```

### Error Messages
```
"✗ [Operation] Failed
Error: [brief message]
Details: [path-to-log]"
```

## Notes

- All file paths should be absolute, not relative
- Commands should be atomic and focused
- Avoid interactive commands (no user input)
- Use appropriate timeouts for long operations
- Handle errors gracefully and report clearly
- Follow output patterns from `.claude/templates/output-patterns.md`
