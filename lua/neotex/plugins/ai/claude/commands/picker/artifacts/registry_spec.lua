-- Test suite for artifacts.registry module
-- Run with: :TestFile

describe("picker.artifacts.registry", function()
  local registry

  before_each(function()
    registry = require("neotex.plugins.ai.claude.commands.picker.artifacts.registry")
  end)

  describe("get_type", function()
    it("returns configuration for valid command type", function()
      local config = registry.get_type("command")
      assert.is_not_nil(config)
      assert.equals("command", config.name)
      assert.equals(".md", config.extension)
      assert.equals("Commands", config.plural)
    end)

    it("returns configuration for valid agent type", function()
      local config = registry.get_type("agent")
      assert.is_not_nil(config)
      assert.equals("agent", config.name)
      assert.equals(".md", config.extension)
      assert.is_true(config.picker_visible)
    end)

    it("returns nil for invalid type", function()
      local config = registry.get_type("nonexistent_type")
      assert.is_nil(config)
    end)
  end)

  describe("should_preserve_permissions", function()
    it("returns true for executable script types", function()
      assert.is_true(registry.should_preserve_permissions("hook_event"))
      assert.is_true(registry.should_preserve_permissions("lib"))
      assert.is_true(registry.should_preserve_permissions("tts_file"))
    end)

    it("returns false for non-executable types", function()
      assert.is_false(registry.should_preserve_permissions("command"))
      assert.is_false(registry.should_preserve_permissions("agent"))
      assert.is_false(registry.should_preserve_permissions("template"))
      assert.is_false(registry.should_preserve_permissions("doc"))
    end)

    it("returns false for invalid type", function()
      assert.is_false(registry.should_preserve_permissions("invalid_type"))
    end)
  end)

  describe("get_visible_types", function()
    it("returns only picker-visible types", function()
      local visible = registry.get_visible_types()
      assert.is_not_nil(visible)
      assert.is_true(#visible > 0)

      -- Check that all returned types have picker_visible = true
      for _, config in ipairs(visible) do
        assert.is_true(config.picker_visible)
      end
    end)

    it("excludes agent_protocol, standard, data_doc, settings", function()
      local visible = registry.get_visible_types()
      local names = {}
      for _, config in ipairs(visible) do
        names[config.name] = true
      end

      -- These should not be visible
      assert.is_nil(names["agent_protocol"])
      assert.is_nil(names["standard"])
      assert.is_nil(names["data_doc"])
      assert.is_nil(names["settings"])
    end)

    it("includes command, agent, hook_event, tts_file, template, lib, doc", function()
      local visible = registry.get_visible_types()
      local names = {}
      for _, config in ipairs(visible) do
        names[config.name] = true
      end

      assert.is_true(names["command"])
      assert.is_true(names["agent"])
      assert.is_true(names["hook_event"])
      assert.is_true(names["tts_file"])
      assert.is_true(names["template"])
      assert.is_true(names["lib"])
      assert.is_true(names["doc"])
    end)
  end)

  describe("get_sync_types", function()
    it("returns sync-enabled types", function()
      local sync_types = registry.get_sync_types()
      assert.is_not_nil(sync_types)
      assert.is_true(#sync_types > 0)

      -- Check that all returned types have sync_enabled = true
      for _, config in ipairs(sync_types) do
        assert.is_true(config.sync_enabled)
      end
    end)

    it("includes all 13 artifact types", function()
      local sync_types = registry.get_sync_types()
      -- Should have 13 types: command, agent, hook_event, tts_file, template,
      -- lib, doc, agent_protocol, standard, data_doc, settings, script, test
      -- Now includes script and test types (Phase 3)
      assert.equals(13, #sync_types)
    end)
  end)

  describe("format_heading", function()
    it("formats command heading correctly", function()
      local heading = registry.format_heading("command")
      assert.is_not_nil(heading)
      assert.is_not_nil(heading:match("%[Commands%]"))
      assert.is_not_nil(heading:match("Slash commands"))
    end)

    it("formats agent heading correctly", function()
      local heading = registry.format_heading("agent")
      assert.is_not_nil(heading)
      assert.is_not_nil(heading:match("%[Agents%]"))
      assert.is_not_nil(heading:match("AI assistants"))
    end)

    it("returns empty string for invalid type", function()
      local heading = registry.format_heading("invalid_type")
      assert.equals("", heading)
    end)
  end)

  describe("format_artifact", function()
    it("formats artifact with local marker", function()
      local artifact = {
        name = "test-command",
        description = "Test description",
        is_local = true,
      }
      local result = registry.format_artifact(artifact, "command", "├─")
      assert.is_not_nil(result)
      assert.is_not_nil(result:match("^%*"))  -- Starts with * for local
      assert.is_not_nil(result:match("test%-command"))
      assert.is_not_nil(result:match("Test description"))
    end)

    it("formats artifact without local marker", function()
      local artifact = {
        name = "global-command",
        description = "Global description",
        is_local = false,
      }
      local result = registry.format_artifact(artifact, "command", "└─")
      assert.is_not_nil(result)
      assert.is_nil(result:match("^%*"))  -- Does not start with *
      assert.is_not_nil(result:match("global%-command"))
      assert.is_not_nil(result:match("Global description"))
    end)

    it("uses 2-space indent for hook_event", function()
      local artifact = {
        name = "pre-commit",
        description = "Hook description",
        is_local = false,
      }
      local result = registry.format_artifact(artifact, "hook_event", "├─")
      assert.is_not_nil(result)
      -- Hook events should have 2-space indent
      assert.is_not_nil(result:match("%s%s├─"))  -- Two spaces before tree char
    end)

    it("uses 1-space indent for commands", function()
      local artifact = {
        name = "test",
        description = "Test",
        is_local = false,
      }
      local result = registry.format_artifact(artifact, "command", "├─")
      assert.is_not_nil(result)
      -- Commands should have 1-space indent
      assert.is_not_nil(result:match("%s├─"))  -- One space before tree char
    end)

    it("strips 'Specialized in' prefix from agent descriptions", function()
      local artifact = {
        name = "test-agent",
        description = "Specialized in testing",
        is_local = false,
      }
      local result = registry.format_artifact(artifact, "agent", "├─")
      assert.is_not_nil(result)
      assert.is_nil(result:match("Specialized in"))
      assert.is_not_nil(result:match("testing"))
    end)
  end)

  describe("get_tree_indent", function()
    it("returns single space for commands", function()
      local indent = registry.get_tree_indent("command")
      assert.equals(" ", indent)
    end)

    it("returns double space for hook_event", function()
      local indent = registry.get_tree_indent("hook_event")
      assert.equals("  ", indent)
    end)

    it("returns single space for agents", function()
      local indent = registry.get_tree_indent("agent")
      assert.equals(" ", indent)
    end)

    it("returns single space as default for invalid type", function()
      local indent = registry.get_tree_indent("invalid_type")
      assert.equals(" ", indent)
    end)
  end)
end)
