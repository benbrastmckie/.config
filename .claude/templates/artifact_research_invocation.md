# Research Artifact Invocation Template

This template is used to instruct research agents to write artifacts in the variable-length format.

## Usage

When invoking a research-specialist agent to write an artifact, include this guidance in the agent prompt:

```
OUTPUT MODE: Artifact

Write your research findings directly to an artifact file at:
{artifact_path}

ARTIFACT FORMAT REQUIREMENTS:

1. **Variable-Length Content**: Adapt the length to match research complexity:
   - Simple findings: 100-200 words
   - Moderate analysis: 200-500 words
   - Complex research: 500-1000+ words
   - Optimize for concision but preserve all essential findings and recommendations
   - No arbitrary length limits - use what the research needs

2. **Required Structure**:
   ```markdown
   # {Research Topic}

   ## Metadata
   - **Created**: {YYYY-MM-DD}
   - **Workflow**: {workflow_description}
   - **Agent**: research-specialist
   - **Focus**: {research_topic}
   - **Length**: {word_count} words

   ## Findings
   {Your research findings - variable length based on complexity}

   ## Recommendations
   {Actionable recommendations based on findings - variable length}
   ```

3. **Return Format**: After writing the artifact, return only:
   - Artifact ID: {artifact_id}
   - Path: {artifact_path}

   Do NOT include the full summary in your response - it's already in the artifact file.

ARTIFACT PATH: {artifact_path}
RESEARCH TOPIC: {research_topic}
WORKFLOW: {workflow_description}
```

## Template Variables

Replace these placeholders when invoking:

- `{artifact_path}` - Full path where artifact should be written (e.g., `specs/artifacts/user_auth/001_authentication_research.md`)
- `{research_topic}` - The specific research topic or question
- `{workflow_description}` - The broader workflow context (e.g., "Implement user authentication")
- `{artifact_id}` - Registry ID for the artifact (generated after creation)

## Example Invocation

```
OUTPUT MODE: Artifact

Write your research findings directly to an artifact file at:
specs/artifacts/user_auth/001_authentication_patterns.md

ARTIFACT FORMAT REQUIREMENTS:

1. **Variable-Length Content**: Adapt the length to match research complexity:
   - Simple findings: 100-200 words
   - Moderate analysis: 200-500 words
   - Complex research: 500-1000+ words
   - Optimize for concision but preserve all essential findings and recommendations
   - No arbitrary length limits - use what the research needs

2. **Required Structure**:
   ```markdown
   # Authentication Patterns Analysis

   ## Metadata
   - **Created**: 2025-10-09
   - **Workflow**: Implement user authentication
   - **Agent**: research-specialist
   - **Focus**: JWT vs session-based authentication patterns
   - **Length**: 487 words

   ## Findings
   [Detailed research findings about authentication patterns...]

   ## Recommendations
   [Specific recommendations for implementation...]
   ```

3. **Return Format**: After writing the artifact, return only:
   - Artifact ID: research_001_authentication_patterns_20251009_143052
   - Path: specs/artifacts/user_auth/001_authentication_patterns.md

   Do NOT include the full summary in your response - it's already in the artifact file.

ARTIFACT PATH: specs/artifacts/user_auth/001_authentication_patterns.md
RESEARCH TOPIC: JWT vs session-based authentication patterns
WORKFLOW: Implement user authentication
```

## Notes

- The template emphasizes variable-length content to avoid unnecessary truncation
- Word count is tracked in metadata for transparency
- Agents should write directly to the file, not return the content in their response
- The artifact registry will track the artifact after creation
