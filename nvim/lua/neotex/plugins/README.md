# Plugin Configuration

This directory contains plugin specifications and configurations managed by lazy.nvim.

## Organization Structure

Plugins are organized into the following categories:

- **coding**: Code editing enhancements (syntax, completion, etc.)
- **editor**: Core editor capabilities (navigation, search, etc.)
- **lsp**: Language server integration and configuration
- **tools**: External tool integration (git, terminal, etc.)
- **ui**: User interface components (statusline, colors, etc.)
- **extras**: Optional functionality that can be enabled/disabled

## Plugin Structure

Each plugin has its own configuration file in this directory. A typical plugin specification follows this pattern:

```lua
-- Example plugin configuration
return {
  "author/plugin-name",
  dependencies = {
    -- Dependencies listed here
  },
  config = function()
    -- Configuration code
  end,
  -- Additional options
}
```

## Plugin Loading

The `init.lua` file in this directory organizes and loads all plugin specifications. It:

1. Categorizes plugins into logical groups
2. Handles errors during plugin loading
3. Provides backward compatibility during the transition

## Special Subdirectories

- **lsp/**: Language server protocol related plugins
- **jupyter/**: Jupyter notebook integration

## Adding New Plugins

To add a new plugin:

1. Create a new file named after the plugin in this directory
2. Write the plugin specification following the pattern above
3. Add it to the appropriate category in `init.lua`

## Plugin Documentation

For detailed information about specific plugins, refer to their individual files or visit their GitHub repositories.