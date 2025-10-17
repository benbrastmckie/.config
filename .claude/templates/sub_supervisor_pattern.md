# Sub-Supervisor Pattern

## Role
Coordinate {N} specialized subagents for {task_domain}

## Responsibilities
1. Delegate focused tasks to specialized subagents
2. Collect subagent outputs (artifacts created)
3. Synthesize findings into {max_words}-word summary
4. Return metadata references to parent supervisor

## Invocation Pattern

Use the Task tool to invoke subagents:

```
subagent_type: general-purpose
description: "Coordinate {task_domain} research"
prompt: |
  You are a sub-supervisor for {task_domain} research.

  Delegate these tasks to specialized subagents:
  {task_list}

  For each task:
  1. Invoke subagent via Task tool
  2. Subagent writes research to artifact file
  3. Extract metadata from artifact (title, 50-word summary, path)

  After all subagents complete:
  - Synthesize findings into {max_words}-word summary
  - Return JSON:
    {
      "summary": "{synthesis}",
      "artifacts": [{"path": "...", "metadata": {...}}, ...]
    }
```

## Output Format

Return ONLY:
- Synthesis summary ({max_words} words max)
- Artifact metadata array (paths + 50-word summaries)

DO NOT return full subagent outputs to parent supervisor.

## Example Usage

### Security Research Sub-Supervisor

```
Task tool:
subagent_type: general-purpose
description: "Coordinate security research"
prompt: |
  You are a sub-supervisor for security research.

  Delegate these tasks to specialized subagents:
  1. Authentication patterns research
  2. Security best practices analysis

  For each task:
  1. Invoke subagent via Task tool
  2. Subagent writes research to artifact file in specs/{topic}/reports/
  3. Extract metadata from artifact

  After all subagents complete:
  - Synthesize findings into 100-word summary
  - Return JSON with summary and artifact metadata
```

## Template Variables

- `{N}`: Number of specialized subagents
- `{task_domain}`: Domain/area being supervised (e.g., "security", "architecture")
- `{max_words}`: Maximum words for synthesis summary
- `{task_list}`: Numbered list of tasks to delegate
- `{topic}`: Topic directory for artifact storage

## Integration with Hierarchical Architecture

Sub-supervisors fit into the hierarchy as:

```
Parent Supervisor (Primary Agent)
├── Sub-Supervisor 1 (manages 2-3 specialized agents)
│   ├── Specialist Agent 1 → artifact
│   ├── Specialist Agent 2 → artifact
│   └── Specialist Agent 3 → artifact
├── Sub-Supervisor 2 (manages 2-3 specialized agents)
│   ├── Specialist Agent 4 → artifact
│   └── Specialist Agent 5 → artifact
└── Sub-Supervisor 3 (manages 2-3 specialized agents)
    ├── Specialist Agent 6 → artifact
    └── Specialist Agent 7 → artifact
```

Each sub-supervisor returns minimal metadata to parent, achieving:
- 92-97% context reduction vs. full content passing
- Parallel execution within each sub-supervisor
- Hierarchical aggregation of results

## Context Preservation

Sub-supervisors use metadata extraction to preserve parent context:

1. **Subagents create artifacts**: Write full research to files
2. **Sub-supervisor extracts metadata**: Title + 50-word summary per artifact
3. **Parent receives metadata only**: No full content in parent's context
4. **On-demand loading**: Parent loads full artifacts only when needed

This pattern enables 10+ research topics (vs. 4 with flat structure).
