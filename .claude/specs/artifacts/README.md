# Artifacts Directory

Intermediate research outputs and cached data generated during multi-agent workflows.

## Purpose

This directory stores artifact files created by specialized agents during workflow execution. Artifacts are lightweight, reusable research outputs that can be referenced by ID instead of passing full content between agents.

## Directory Structure

```
artifacts/
├── {project_name}/        # Project-specific artifacts
│   ├── existing_patterns.md
│   ├── best_practices.md
│   └── alternatives.md
└── {another_project}/
    └── api_research.md
```

## Artifact Organization

### Naming Convention
- **Path Format**: `artifacts/{project_name}/{artifact_name}.md`
- **Project Name**: Derived from feature/workflow description (e.g., "auth_system", "payment_flow")
- **Artifact Name**: Descriptive filename (e.g., "existing_patterns", "best_practices", "alternatives")

### Project Names
Project names should be:
- Lowercase with underscores (snake_case)
- Descriptive of the feature area
- Consistent across related artifacts

Examples:
- `auth_system/` - Authentication-related research
- `payment_flow/` - Payment processing research
- `user_profile/` - User profile management research

## Usage Patterns

### Creation
Artifacts are created by:
- Research agents during `/orchestrate` workflows
- Specialized investigation commands
- Manual creation for complex research

### Referencing
Artifacts can be referenced by:
- Plans (instead of duplicating research content)
- Reports (cross-referencing related research)
- Summaries (documenting research used)
- Other artifacts (building on previous research)

### Reference Format
```markdown
## Related Artifacts
- [Existing Patterns](../artifacts/auth_system/existing_patterns.md)
- [Best Practices](../artifacts/auth_system/best_practices.md)
```

## Lifecycle

### Persistence
- Artifacts persist after workflow completion
- Reusable across multiple plans and implementations
- Serve as institutional knowledge base

### Cleanup
- Archive old artifacts when feature is deprecated
- Keep artifacts for active/recent features
- Consider archival after 6-12 months of inactivity

## Benefits

### Context Reduction
- Pass artifact references (lightweight IDs) instead of full content
- 60-80% reduction in context size for multi-agent workflows
- Agents retrieve only needed information

### Separation of Concerns
- **Artifacts**: Intermediate research outputs
- **Reports**: Final comprehensive research documents
- **Plans**: Implementation roadmaps
- **Summaries**: Implementation records

### Reusability
- Same artifact used by multiple plans
- Build on previous research
- Avoid duplicate research effort

## Examples

### Artifact File Structure

```markdown
# Existing Authentication Patterns

## Metadata
- **Created**: 2025-10-03
- **Workflow**: Implement user authentication system
- **Agent**: research-specialist
- **Focus**: Existing auth patterns in codebase

## Findings

### Session-Based Authentication
Found in `auth/sessions.lua`:
- Uses HTTP-only cookies
- 24-hour expiration
- Redis for session storage

### Token-Based Authentication
Found in `api/auth.lua`:
- JWT tokens with 1-hour expiration
- Refresh token pattern
- RSA-256 signing

## Recommendations
- Prefer session-based for web UI
- Use tokens for API endpoints
- Implement refresh token rotation
```

### Artifact Registry (in workflow state)

```yaml
artifact_registry:
  auth_patterns: specs/artifacts/auth_system/existing_patterns.md
  auth_security: specs/artifacts/auth_system/best_practices.md
  auth_alternatives: specs/artifacts/auth_system/alternatives.md
```

### Agent Prompt with References

```markdown
Research artifacts available:
- Existing patterns: Read auth_patterns if needed
- Security best practices: Read auth_security if needed
- Alternative approaches: Read auth_alternatives if needed

Create implementation plan incorporating relevant findings.
```

## Standards Compliance

- **No emojis** in artifact content (UTF-8 encoding issues)
- **Unicode box-drawing** for diagrams (┌ ┐ └ ┘ ─ │)
- **CommonMark** specification compliance
- **2-space indentation** for nested lists
- **~100 character** line length (soft limit)

## Navigation

### Related Directories
- [reports/](../reports/README.md) - Final research reports
- [plans/](../plans/README.md) - Implementation plans
- [summaries/](../summaries/README.md) - Implementation records
- [standards/](../standards/README.md) - Project standards

### Parent
- [← specs/](../README.md) - Specifications directory
