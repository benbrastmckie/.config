# Research Report: Goose.nvim Recipe Configuration

**Date**: 2025-12-10
**Topic**: How to use goose recipes in goose.nvim
**Status**: Complete

## Research Focus
- goose.nvim plugin documentation and recipe configuration
- Goose CLI recipe system (as goose.nvim wraps the CLI)
- Recipe YAML format and required fields
- Common issues and troubleshooting when recipes don't work
- GitHub issues related to goose.nvim recipe problems
- Example recipes that work successfully

## Executive Summary

**Critical Finding**: goose.nvim does NOT support Goose recipes directly. The plugin is a Neovim UI wrapper for Goose sessions but does not expose recipe functionality. To use recipes with goose.nvim, you must run recipes through the Goose CLI separately.

**Key Insights**:
1. goose.nvim focuses on session management, context capture, and chat interface
2. Goose CLI has a robust recipe system with YAML configuration
3. Recipes must be run via `goose run --recipe <file>` command
4. No integration exists for launching goose.nvim sessions with recipes

## Findings

### 1. goose.nvim Plugin Architecture

**What goose.nvim Provides**:
- Chat interface integrated into Neovim
- Persistent workspace-tied sessions
- Editor context capture (current file, selections, diagnostics)
- File mentions using `@` trigger in input window
- Provider/model switching via `<leader>gp`
- Session management: `<leader>gs` (select session), `<leader>gI` (new session)
- Diff view for modified files

**What goose.nvim Does NOT Provide**:
- Recipe selection or execution
- Recipe configuration in setup
- Integration with Goose CLI recipe system
- Custom session launch with recipe templates

**Technical Details**:
- Plugin wraps the Goose AI agent CLI
- Uses picker frameworks (telescope, fzf, mini.pick, snacks) for file/session selection
- Configuration via `require('goose').setup({})` but no recipe-related options
- Requires running `goose configure` separately for LLM provider setup

**Source**: [azorng/goose.nvim GitHub](https://github.com/azorng/goose.nvim)

### 2. Goose CLI Recipe System

#### Recipe File Format (YAML)

**Required Fields**:
```yaml
version: "1.0.0"          # Format version
title: "Recipe Name"       # Short descriptive name
description: "Details"     # Explanation of functionality
```

At least one of `instructions` or `prompt` must be present.

**Key Optional Fields**:
- `instructions`: Template with `{{ parameter_name }}` placeholders
- `prompt`: Required for headless/non-interactive mode
- `parameters`: Array of dynamic inputs (string, number, boolean, date, file, select)
- `extensions`: MCP servers and tools (type, name, cmd, args, timeout)
- `settings`: Model provider, model name, temperature
- `sub_recipes`: References to other recipe files
- `retry`: Automated retry logic with success validation
- `response`: JSON schema for structured output

**Minimal Working Example**:
```yaml
version: "1.0.0"
title: "Sample Recipe"
description: "A basic working recipe"
prompt: "Your task here"
```

**Complete Example with Extensions**:
```yaml
version: "1.0.0"
title: "Code Review Assistant"
description: "Automated code review with best practices"
instructions: "You are a code reviewer for {{ language }} projects..."
prompt: "Review the code in {{ project_path }}"
parameters:
  - key: language
    input_type: string
    requirement: required
    description: "Programming language"
  - key: project_path
    input_type: string
    requirement: required
    description: "Path to project"
extensions:
  - type: stdio
    name: developer
    timeout: 300
settings:
  goose_provider: "anthropic"
  goose_model: "claude-sonnet-4-20250514"
  temperature: 0.7
```

**Sources**:
- [Recipe Reference Guide](https://block.github.io/goose/docs/guides/recipes/recipe-reference/)
- [Shareable Recipes Documentation](https://block.github.io/goose/docs/guides/recipes/session-recipes/)

#### Recipe Storage and Discovery

**Storage Locations**:
1. **Global**: `~/.config/goose/recipes/` - Available across all projects
2. **Local**: `.goose/recipes/` in project directory - Project-specific, team-shareable

**Discovery Order** (via `goose recipe list`):
1. Current directory (`.yaml` and `.json` files)
2. Custom paths via `GOOSE_RECIPE_PATH` environment variable
3. Global recipe library (`~/.config/goose/recipes/`)
4. Local project recipes (`.goose/recipes/`)
5. GitHub repository (if `GOOSE_RECIPE_GITHUB_REPO` is set)

**Key Commands**:
```bash
# List all available recipes
goose recipe list

# Run a recipe with parameters
goose run --recipe my-recipe.yaml --params key1="value1" key2="value2"

# Validate recipe syntax
goose recipe validate my-recipe.yaml

# Generate shareable link
goose recipe deeplink my-recipe.yaml

# Explain recipe details
goose run --recipe my-recipe.yaml --explain

# Show rendered recipe without running
goose run --recipe my-recipe.yaml --render-recipe

# Debug mode for troubleshooting
goose run --debug --recipe my-recipe.yaml
```

**Source**: [Storing Recipes Documentation](https://block.github.io/goose/docs/guides/recipes/storing-recipes/)

#### Sub-Recipes for Complex Workflows

Sub-recipes allow modular workflow composition. Main recipe delegates to specialized sub-recipes that run in separate sessions.

**Configuration**:
```yaml
sub_recipes:
  - name: "security_scan"
    path: "./subrecipes/security-analysis.yaml"
    values:
      scan_level: "comprehensive"
      include_dependencies: "true"
```

**Key Points**:
- Each sub-recipe executes in isolated session with own context
- Main recipe receives structured output from sub-recipes
- Use `{{ recipe_dir }}` for portable file paths within recipes
- Test sub-recipes individually before integration

**Sources**:
- [Sub-Recipes Documentation](https://block.github.io/goose/docs/guides/recipes/sub-recipes/)
- [Automate Complex Workflows Blog](https://dev.to/blockopensource/automate-your-complex-workflows-with-sub-recipes-in-goose-23bd)

#### Retry Logic and Error Handling

**Configuration Example**:
```yaml
retry:
  max_retries: 3
  checks:
    - type: shell
      command: test -f "expected_output.txt"
      on_failure: rm -f "partial_output.txt"
      timeout_seconds: 60
```

**Best Practice**: Always include retry logic for network calls, file operations, and API interactions.

### 3. Common Issues and Troubleshooting

#### Issue 1: Recipes Not Being Read (Windows)

**Problem**: Windows users could not add or display recipes in Goose desktop app v1.8.0, even with manually created YAML files.

**Root Cause**: File path handling bug specific to Windows platform.

**Solution**:
- Upgrade to Goose v1.9.3 or later (fix merged in commit b0b378e)
- Workaround for v1.8.0: Use desktop app's import feature which creates correct metadata format

**Required Metadata Structure**:
```yaml
name: "recipe_name"
recipe: <recipe_content>
isGlobal: false
lastModified: "2025-12-10"
isArchived: false
```

**Source**: [GitHub Issue #3636](https://github.com/block/goose/issues/3636)

#### Issue 2: Recipe File Discovery

**Problem**: Recipes not found when running `goose run --recipe <name>`

**Troubleshooting Steps**:
1. Verify file exists in search path (current dir, `GOOSE_RECIPE_PATH`, global/local recipe dirs)
2. Check file extension is `.yaml` or `.json`
3. Use `goose recipe list` to see all discoverable recipes
4. Set `GOOSE_RECIPE_PATH` if recipes are in non-standard location:
   ```bash
   export GOOSE_RECIPE_PATH="/path/to/recipes:/another/path"
   ```
5. Use absolute paths as fallback: `goose run --recipe /full/path/to/recipe.yaml`

**Source**: [GitHub Issue #2560](https://github.com/block/goose/issues/2560)

#### Issue 3: Recipe Fails to Save in Desktop App

**Problem**: Recipe creation dialog doesn't save new recipes in working directory.

**Status**: Reported in multiple issues (#4814, #4452), fix involves moving recipe logic server-side.

**Workaround**: Create recipe YAML files manually and import via desktop app or use CLI exclusively.

**Sources**:
- [GitHub Issue #4814](https://github.com/block/goose/issues/4814)
- [GitHub Issue #4452](https://github.com/block/goose/issues/4452)

#### Issue 4: Extension Configuration Failures

**Problem**: Scheduled recipes fail to initialize required extensions; Extension Manager not available in scheduled job context.

**Solution**:
- Ensure extensions are explicitly defined in recipe `extensions` field
- Verify environment variables for extensions are set globally, not just in interactive shell
- Test recipe manually before scheduling: `goose run --recipe recipe.yaml`

**Source**: [GitHub Issue #5696](https://github.com/block/goose/issues/5696)

#### Issue 5: Missing Environment Variables/Secrets

**Problem**: Recipes fail when extensions require secrets not in keyring.

**Behavior**: Goose prompts for missing secrets interactively, but fails in non-interactive contexts (scheduled jobs, CI/CD).

**Solution**:
- Pre-configure secrets using `goose configure`
- For scheduled jobs, ensure all required secrets are in secure keyring before scheduling
- Use `env_keys` field in extension config to document required variables

### 4. Best Practices and Practical Tips

#### Recipe Development Workflow

**1. Use "Ultrathink" Prompting Pattern**:
When creating recipe prompts with LLMs, request comprehensive thinking before output:
```
"ultrathink on this and here is the full context to help you create the prompt..."
```
This produces more systematic, thorough prompts (example: 49,537 tokens in 12 minutes for production recipe).

**Source**: [Advent of AI 2025 - Day 7](https://dev.to/nickytonline/advent-of-ai-2025-day-7-goose-recipes-5d1c)

**2. Encode Domain Knowledge Explicitly**:
Don't assume AI "just knows" domain specifics. Document:
- Normalization rules (e.g., "All locations use format: Building-Floor-Room")
- Categorization hierarchies (9-category system for item classification)
- Priority frameworks (urgent vs normal criteria)
- Duplicate detection logic (multi-factor matching rules)

**3. Write Idempotent Recipes**:
Check current state before acting so recipes can run multiple times without errors:
```yaml
instructions: |
  Before creating files, check if they exist.
  Before installing dependencies, verify they're not already installed.
  Log each step clearly for debugging.
```

**4. Test with Realistic Data**:
Create test datasets with:
- Duplicates with variations (typos, abbreviations)
- Edge cases (empty fields, unusual formats)
- Different scales (small, medium, large datasets)
- Multiple input formats

**5. Use Portable Path References**:
Always use `{{ recipe_dir }}` for file paths within recipes:
```yaml
sub_recipes:
  - name: "analysis"
    path: "{{ recipe_dir }}/subrecipes/analyze.yaml"
```

**6. Enable Debug Mode During Development**:
```bash
goose run --debug --recipe recipe.yaml
```
Provides detailed execution logs for troubleshooting.

**7. Validate Before Deployment**:
```bash
goose recipe validate my-recipe.yaml
```

**8. Version Control Recipe Files**:
Store recipes in project `.goose/recipes/` directory and commit to version control for team sharing.

#### Real-World Example: Lost & Found Detective

**Use Case**: Event coordinators processing messy lost & found data (sticky notes with inconsistent formatting).

**Recipe Structure**:
```yaml
name: lost-found-detective
description: Transform messy lost & found data into organized web apps
prompt_file: ./lost-found-detective-prompt.md
extensions: [developer]
```

**Prompt Encodes**:
- Duplicate detection (multi-factor matching)
- Standardization rules
- 9-category item classification
- Urgency assessment frameworks
- 8-step workflow (ingest, clean, dedupe, categorize, match, stats, generate web app, document)

**Results from Testing**:
| Dataset | Entries | Unique Items | Duplicates Merged | Urgent Items |
|---------|---------|--------------|-------------------|--------------|
| Opening Day | 20 | 19 | 1 | 1 |
| Peak Crowd | 35 | 28 | 7 | 7 |
| Family Frenzy | 45 | 35 | 10 | 9 |

Each generated complete web application with search, filters, mobile responsive design, zero external dependencies.

**Investment Model**:
- One-time cost: ~50,000 tokens (~$0.15)
- Reusable: Process unlimited datasets indefinitely
- Shareable: Team members use without setup

**Source**: [Advent of AI 2025 - Day 7](https://dev.to/nickytonline/advent-of-ai-2025-day-7-goose-recipes-5d1c)

### 5. Scheduling Recipes

**Add Scheduled Recipe**:
```bash
goose schedule add \
  --schedule-id daily-report \
  --cron "0 0 9 * * *" \
  --recipe-source ./recipes/daily-report.yaml
```

**Important Considerations**:
- Recipes must be fully non-interactive (no prompts for input)
- All required secrets must be pre-configured in keyring
- Use `prompt` field (not just `instructions`) for headless execution
- Test manually before scheduling: `goose run --recipe recipe.yaml`

**Source**: [Advent of AI 2025 - Day 7](https://dev.to/nickytonline/advent-of-ai-2025-day-7-goose-recipes-5d1c)

### 6. Advanced Features

#### Structured Output with JSON Schema

Force specific output format for automation:
```yaml
response:
  type: object
  properties:
    status:
      type: string
      enum: ["success", "failure"]
    items_processed:
      type: number
    errors:
      type: array
  required: ["status", "items_processed"]
```

#### Parameter Types

**Select Type** (dropdown options):
```yaml
parameters:
  - key: environment
    input_type: select
    requirement: required
    description: "Deployment environment"
    options:
      - value: "dev"
        label: "Development"
      - value: "prod"
        label: "Production"
```

**File Type** (cannot have default):
```yaml
parameters:
  - key: input_file
    input_type: file
    requirement: required
    description: "Data file to process"
```

#### JSON Output for Automation

For CI/CD integration:
```bash
goose run --output-format json --recipe recipe.yaml
```

**Sources**: [Recipe Reference Guide](https://block.github.io/goose/docs/guides/recipes/recipe-reference/)

## Recommendations

### For Users Wanting Recipes in goose.nvim

Since goose.nvim does not support recipes directly:

**Option 1: Separate CLI Execution**
1. Develop and test recipes using Goose CLI: `goose run --recipe recipe.yaml`
2. Use goose.nvim for interactive coding sessions
3. Keep recipes in `.goose/recipes/` for project-specific workflows
4. Document recipe usage in project README

**Option 2: Hybrid Workflow**
1. Create recipes for repeatable tasks (code review, data processing, refactoring)
2. Run recipe via CLI to perform bulk work
3. Open goose.nvim session to refine/customize results interactively
4. Use goose.nvim's diff view to review recipe-generated changes

**Option 3: Feature Request**
Consider opening feature request on [azorng/goose.nvim](https://github.com/azorng/goose.nvim/issues) for:
- Recipe picker integration (similar to session picker `<leader>gs`)
- Configuration option to launch sessions with recipe context
- Recipe template management from within Neovim

### Recipe Development Checklist

Before deploying recipes:
- [ ] Validate syntax: `goose recipe validate recipe.yaml`
- [ ] Test with debug mode: `goose run --debug --recipe recipe.yaml`
- [ ] Test with realistic data (including edge cases)
- [ ] Verify idempotency (safe to run multiple times)
- [ ] Document parameters clearly
- [ ] Use `{{ recipe_dir }}` for portable paths
- [ ] Configure retry logic for network/file operations
- [ ] Test scheduled execution if applicable (non-interactive mode)
- [ ] Version control recipe files
- [ ] Share via `goose recipe deeplink` or commit to `.goose/recipes/`

### Common Pitfalls to Avoid

1. **Assuming goose.nvim supports recipes** - It doesn't; use CLI
2. **Using relative paths without `{{ recipe_dir }}`** - Breaks portability
3. **Forgetting to validate** - Catches syntax errors early
4. **Not testing idempotency** - Leads to duplicate work/errors on retry
5. **Omitting parameter descriptions** - Confusing for users
6. **No retry logic for fragile operations** - Fails on transient errors
7. **Using interactive prompts in scheduled recipes** - Fails in non-interactive context
8. **Not pre-configuring secrets for scheduled jobs** - Execution fails silently

## Conclusion

The Goose ecosystem has two separate components:

1. **Goose CLI**: Robust recipe system for automation, scheduling, and complex workflows
2. **goose.nvim**: Neovim UI for interactive sessions with editor context

These components do not integrate for recipe functionality. Users must run recipes via Goose CLI separately from goose.nvim sessions. For teams wanting reproducible AI workflows in Neovim projects, the recommended approach is maintaining recipes in `.goose/recipes/` and documenting CLI usage while using goose.nvim for ad-hoc interactive development.

## Sources

### Official Documentation
- [Goose Recipe Reference Guide](https://block.github.io/goose/docs/guides/recipes/recipe-reference/)
- [Shareable Recipes Documentation](https://block.github.io/goose/docs/guides/recipes/session-recipes/)
- [Sub-Recipes Documentation](https://block.github.io/goose/docs/guides/recipes/sub-recipes/)
- [Storing Recipes Documentation](https://block.github.io/goose/docs/guides/recipes/storing-recipes/)
- [Goose CLI Commands](https://block.github.io/goose/docs/guides/goose-cli-commands/)
- [Goose Configuration File](https://block.github.io/goose/docs/guides/config-file/)
- [Goose Troubleshooting](https://block.github.io/goose/docs/troubleshooting/)

### goose.nvim Plugin
- [azorng/goose.nvim GitHub](https://github.com/azorng/goose.nvim)
- [goose.nvim README](https://github.com/azorng/goose.nvim/blob/main/README.md)
- [goose.nvim on Neovimcraft](https://neovimcraft.com/plugin/azorng/goose.nvim/)

### Community Resources
- [Advent of AI 2025 - Day 7: Goose Recipes](https://dev.to/nickytonline/advent-of-ai-2025-day-7-goose-recipes-5d1c)
- [Automate Complex Workflows with Sub-Recipes](https://dev.to/blockopensource/automate-your-complex-workflows-with-sub-recipes-in-goose-23bd)
- [Build Your Own Recipe Cookbook Generator](https://block.github.io/goose/blog/2025/10/08/recipe-cookbook-generator/)

### GitHub Issues
- [Issue #3636: Windows - Recipes Not Being Read](https://github.com/block/goose/issues/3636)
- [Issue #2560: Discover Goose Recipe via GOOSE_RECIPE_PATH](https://github.com/block/goose/issues/2560)
- [Issue #4814: Windows Recipes Page Cannot Save New Recipe](https://github.com/block/goose/issues/4814)
- [Issue #4452: Goose Desktop Fails to Save Recipe in Working Directory](https://github.com/block/goose/issues/4452)
- [Issue #5696: Extension Configuration Failure](https://github.com/block/goose/issues/5696)

