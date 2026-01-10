# Command Template

This template provides a standard structure for creating new commands in the .opencode system.

---

## Frontmatter Structure

```yaml
---
name: {command_name}
agent: orchestrator
description: "{Brief description of command purpose}"
context_level: 2
language: {markdown|lean|python|varies}
routing:
  language_based: {true|false}
  target_agent: {agent_name}  # Only if language_based: false
  lean: {lean_agent_name}      # Only if language_based: true
  default: {default_agent_name} # Only if language_based: true
context_loading:
  strategy: lazy
  index: ".claude/context/index.md"
  required:
    - "core/standards/subagent-return-format.md"
    - "core/workflows/status-transitions.md"
    - "core/system/routing-guide.md"
  optional:
    - "{domain-specific context files}"
  max_context_size: 50000
---
```

## Command Body Structure

```markdown
**Task Input (required):** $ARGUMENTS (description; e.g., `/{command} 197`)

<context>
  <system_context>
    Brief description of what this command does and its role in the workflow.
  </system_context>
</context>

<workflow_setup>
  <stage_1_parse_arguments>
    Parse command arguments:
    - Extract task_number from $ARGUMENTS
    - Extract optional parameters (flags, prompts, etc.)
    - Validate argument format
  </stage_1_parse_arguments>

  <stage_2_delegate_to_agent>
    Delegate to target agent:
    - If routing.language_based: true
      * Extract language from state.json (fast lookup)
      * Route to appropriate agent based on language
    - Else
      * Route to routing.target_agent
    
    **Fast Task Lookup** (use state.json, not TODO.md):
    ```bash
    # Validate and lookup task (8x faster than TODO.md parsing)
    task_data=$(jq -r --arg num "$task_number" \
      '.active_projects[] | select(.project_number == ($num | tonumber))' \
      .claude/specs/state.json)
    
    if [ -z "$task_data" ]; then
      echo "Error: Task $task_number not found"
      exit 1
    fi
    
    # Extract all metadata at once
    language=$(echo "$task_data" | jq -r '.language // "general"')
    status=$(echo "$task_data" | jq -r '.status')
    project_name=$(echo "$task_data" | jq -r '.project_name')
    ```
    
    Delegation context:
    ```json
    {
      "task_number": {task_number},
      "session_id": "{generated_session_id}",
      "delegation_depth": 1,
      "delegation_path": ["orchestrator", "{command}", "{agent}"],
      "timeout": {timeout_seconds}
    }
    ```
  </stage_2_delegate_to_agent>

  <stage_3_return_result>
    Return agent result to user:
    - Validate return format (subagent-return-format.md)
    - Format output for user
    - Include next steps if applicable
  </stage_3_return_result>
</workflow_setup>

<notes>
  - Command delegates all workflow logic to specialized agent
  - Orchestrator handles routing, validation, and return formatting
  - Agent owns complete workflow including status updates and git commits
  - See `.claude/context/core/system/routing-guide.md` for routing details
  - See `.claude/context/core/workflows/delegation-guide.md` for delegation patterns
</notes>
```

---

## Example: Simple Direct-Routing Command

```markdown
---
name: plan
agent: orchestrator
description: "Create implementation plans with [PLANNED] status"
context_level: 2
language: markdown
routing:
  language_based: false
  target_agent: planner
context_loading:
  strategy: lazy
  index: ".claude/context/index.md"
  required:
    - "core/standards/subagent-return-format.md"
    - "core/workflows/status-transitions.md"
    - "core/system/routing-guide.md"
  optional:
    - "project/lean4/processes/end-to-end-proof-workflow.md"
  max_context_size: 50000
---

**Task Input (required):** $ARGUMENTS (task number; e.g., `/plan 197`)

<context>
  <system_context>
    Planning command that creates implementation plans with phased breakdown,
    effort estimates, and research integration. Updates task status to [PLANNED].
  </system_context>
</context>

<workflow_setup>
  <stage_1_parse_arguments>
    Parse task number from $ARGUMENTS
  </stage_1_parse_arguments>

  <stage_2_delegate_to_planner>
    Delegate to planner agent with task context
  </stage_2_delegate_to_planner>

  <stage_3_return_result>
    Return plan artifact path and next steps
  </stage_3_return_result>
</workflow_setup>

<notes>
  - Planner agent owns complete workflow
  - Planner handles status updates via status-sync-manager
  - Planner creates git commit via git-workflow-manager
</notes>
```

---

## Example: Language-Based Routing Command

```markdown
---
name: research
agent: orchestrator
description: "Conduct research and create reports with [RESEARCHED] status"
context_level: 2
language: markdown
routing:
  language_based: true
  lean: lean-research-agent
  default: researcher
context_loading:
  strategy: lazy
  index: ".claude/context/index.md"
  required:
    - "core/standards/subagent-return-format.md"
    - "core/workflows/status-transitions.md"
    - "core/system/routing-guide.md"
  optional:
    - "project/lean4/tools/leansearch-api.md"
    - "project/lean4/tools/loogle-api.md"
  max_context_size: 50000
---

**Task Input (required):** $ARGUMENTS (task number; e.g., `/research 197`)

<context>
  <system_context>
    Research command that conducts domain-specific research and creates reports.
    Routes to lean-research-agent for Lean tasks, researcher for others.
    Updates task status to [RESEARCHED].
  </system_context>
</context>

<workflow_setup>
  <stage_1_parse_arguments>
    Parse task number and optional prompt from $ARGUMENTS
  </stage_1_parse_arguments>

  <stage_2_extract_language>
    Extract language from state.json (fast lookup):
    ```bash
    # Lookup task in state.json (8x faster than TODO.md)
    task_data=$(jq -r --arg num "$task_number" \
      '.active_projects[] | select(.project_number == ($num | tonumber))' \
      .claude/specs/state.json)
    
    # Extract language with default fallback
    language=$(echo "$task_data" | jq -r '.language // "general"')
    ```
    
    See `.claude/context/core/system/state-lookup.md` for patterns.
  </stage_2_extract_language>

  <stage_3_route_to_agent>
    Route based on language:
    - lean → lean-research-agent
    - default → researcher
  </stage_3_route_to_agent>

  <stage_4_return_result>
    Return research report path and next steps
  </stage_4_return_result>
</workflow_setup>

<notes>
  - Language-based routing enables domain-specific research tools
  - Lean tasks use LeanSearch, Loogle, LSP integration
  - Other tasks use web search, documentation analysis
  - Research agent owns complete workflow
</notes>
```

---

## Guidelines

### When to Use Direct Routing
- Command always uses same agent regardless of task
- Examples: /plan, /revise, /review, /todo, /task

### When to Use Language-Based Routing
- Command needs different agents for different languages
- Examples: /research, /implement

### Context Loading
- **Tier 2 (Commands)**: 10-20% context window (~20-40KB)
- Load only what's needed for routing and validation
- Agents load domain-specific context (Tier 3)

### Workflow Ownership
- Commands are thin routing layers
- Agents own complete workflows
- Agents handle status updates, git commits, artifact creation

### Validation
- Orchestrator validates: task exists, delegation safety, return format
- Agents validate: business logic, domain rules, artifact correctness
- See `core/system/validation-strategy.md` for details

### Performance Optimization
- **Use state.json for task lookups**: 25-50x faster than TODO.md parsing
- **Extract all metadata at once**: Avoid multiple jq calls
- **Validate state.json exists**: Check file exists before reading
- See `.claude/context/core/system/state-lookup.md` for comprehensive patterns

**Performance Comparison**:
- TODO.md parsing: ~100ms per lookup
- state.json lookup: ~4ms per lookup
- Improvement: 25-50x faster

### Documentation Standards
- **NO VERSION HISTORY**: Never add "Version History" sections to commands or agents
- Version history is useless cruft that clutters documentation
- Git history already tracks all changes comprehensively
- Document current behavior only, not past versions
- See `.claude/context/core/standards/documentation.md` for full standards
