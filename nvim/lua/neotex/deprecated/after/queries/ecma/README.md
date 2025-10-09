# Deprecated ECMAScript Queries

Legacy tree-sitter queries for JavaScript and TypeScript.

## Purpose

This directory contains deprecated tree-sitter query files for ECMAScript languages (JavaScript, TypeScript) that have been superseded by updated query definitions.

## Historical Context

These queries provided custom syntax highlighting, indentation, and folding for JavaScript and TypeScript. They have been replaced by:

- Improved upstream tree-sitter queries
- Plugin-provided queries
- Updated custom queries in active configuration

## Contents

Query files may include:
- `highlights.scm` - Syntax highlighting queries
- `injections.scm` - Language injection queries (e.g., JSX, template strings)
- `locals.scm` - Local scope definition queries
- `folds.scm` - Code folding queries
- `indents.scm` - Indentation queries

## Migration

To use updated ECMAScript queries:

1. Check NeoVim's built-in queries: `:echo stdpath('data') . '/lazy/nvim-treesitter/queries/'`
2. Review plugin-provided queries: nvim-treesitter or language-specific plugins
3. Add custom queries to: `~/.config/nvim/after/queries/{language}/`

## Related Documentation

- [Tree-Sitter Queries](https://tree-sitter.github.io/tree-sitter/using-parsers#query-syntax) - Query language reference
- [Deprecated Queries](../README.md) - Parent query directory
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) - Tree-sitter integration

## Navigation

- **Parent**: [nvim/lua/neotex/deprecated/after/queries/](../README.md)
- **Grandparent**: [nvim/lua/neotex/deprecated/after/](../../README.md)
