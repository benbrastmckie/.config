# Project Configuration Index

This CLAUDE.md serves as the central configuration and standards index for this project.

## Project Standards and Guidelines

### Core Documentation
- [Neovim Configuration Guidelines](nvim/CLAUDE.md) - Coding standards, style guide, and architecture documentation for Neovim configuration
- [Development Guidelines](nvim/docs/GUIDELINES.md) - Comprehensive development principles, migration strategy, and quality standards
- [Specifications Directory](nvim/specs/) - Implementation plans, research reports, and technical specifications

### Directory Protocols

#### Specifications Structure (`nvim/specs/`)
The specifications directory follows this structure:
- `plans/` - Implementation plans (format: `NNN_plan_name.md`)
- `reports/` - Research reports (format: `NNN_report_name.md`)
- `summaries/` - Implementation summaries linking plans to executed code

All specification documents use incremental three-digit numbering (001, 002, 003...).

## Testing Protocols

### Neovim Testing
- **Test Commands**: `:TestNearest`, `:TestFile`, `:TestSuite`, `:TestLast`
- **Linting**: `<leader>l` to run linter
- **Formatting**: `<leader>mp` to format code
- **Custom Tests**: See individual project documentation

## Code Style Standards

### General Principles
- **Indentation**: 2 spaces, expandtab
- **Line length**: ~100 characters (soft limit)
- **Naming**: snake_case for variables/functions, PascalCase for module tables
- **Documentation**: Every directory must have a README.md
- **Character Encoding**: UTF-8 only, no emojis in file content

### Language-Specific Standards
- **Lua**: See [Neovim Configuration Guidelines](nvim/CLAUDE.md)
- **Markdown**: Use Unicode box-drawing for diagrams, follow CommonMark spec

## Development Workflow

### Planning and Implementation
1. Create research reports in `specs/reports/` for complex topics
2. Generate implementation plans in `specs/plans/` based on research
3. Execute plans phase-by-phase with testing and commits
4. Generate summaries in `specs/summaries/` linking plans to code

### Git Workflow
- Feature branches for new development
- Clean, atomic commits with descriptive messages
- Test before committing
- Document breaking changes

## Project-Specific Commands

### Claude Code Commands
Located in `.claude/commands/`:
- `/implement [plan-file]` - Execute implementation plans
- `/report <topic>` - Generate research documentation
- `/plan <feature>` - Create implementation plans
- `/test <target>` - Run project-specific tests
- `/setup` - Configure or update this CLAUDE.md file

## Quick Reference

### Common Tasks
- **Run Tests**: `:TestSuite` or `/test-all`
- **Format Code**: `<leader>mp`
- **Check Linting**: `<leader>l`
- **Find Files**: `<C-p>` (Telescope)
- **Search Project**: `<leader>sg` (Telescope grep)

### Navigation
- [Neovim Configuration](nvim/)
- [Specifications](nvim/specs/)
- [Commands](.claude/commands/)

## Notes
This CLAUDE.md was automatically configured with the `/setup` command.
For updates or improvements, run `/setup` again or edit manually following the established patterns.

