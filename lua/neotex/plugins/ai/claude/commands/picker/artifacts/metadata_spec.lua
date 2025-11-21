-- Test suite for artifacts.metadata module
-- Run with: :TestFile

describe("picker.artifacts.metadata", function()
  local metadata
  local temp_dir

  before_each(function()
    metadata = require("neotex.plugins.ai.claude.commands.picker.artifacts.metadata")

    -- Create temp directory for test files
    temp_dir = vim.fn.tempname()
    vim.fn.mkdir(temp_dir, "p")
  end)

  after_each(function()
    -- Clean up temp directory
    if temp_dir and vim.fn.isdirectory(temp_dir) == 1 then
      vim.fn.delete(temp_dir, "rf")
    end
  end)

  describe("parse_template_description", function()
    it("extracts description from YAML file with double quotes", function()
      local test_file = temp_dir .. "/test.yaml"
      local content = {
        "---",
        'description: "Test template description"',
        "field: value",
      }
      vim.fn.writefile(content, test_file)

      local result = metadata.parse_template_description(test_file)
      assert.equals("Test template description", result)
    end)

    it("extracts description from YAML file with single quotes", function()
      local test_file = temp_dir .. "/test.yaml"
      local content = {
        "---",
        "description: 'Single quoted description'",
        "field: value",
      }
      vim.fn.writefile(content, test_file)

      local result = metadata.parse_template_description(test_file)
      assert.equals("Single quoted description", result)
    end)

    it("extracts description from YAML file without quotes", function()
      local test_file = temp_dir .. "/test.yaml"
      local content = {
        "---",
        "description: No quotes description",
        "field: value",
      }
      vim.fn.writefile(content, test_file)

      local result = metadata.parse_template_description(test_file)
      assert.equals("No quotes description", result)
    end)

    it("truncates description to 40 characters", function()
      local test_file = temp_dir .. "/test.yaml"
      local content = {
        "---",
        'description: "This is a very long description that should be truncated to forty characters"',
      }
      vim.fn.writefile(content, test_file)

      local result = metadata.parse_template_description(test_file)
      assert.equals(40, #result)
    end)

    it("returns empty string for file without description", function()
      local test_file = temp_dir .. "/test.yaml"
      local content = {
        "---",
        "field: value",
        "other: data",
      }
      vim.fn.writefile(content, test_file)

      local result = metadata.parse_template_description(test_file)
      assert.equals("", result)
    end)

    it("returns empty string for non-existent file", function()
      local result = metadata.parse_template_description("/nonexistent/file.yaml")
      assert.equals("", result)
    end)
  end)

  describe("parse_script_description", function()
    it("extracts description from Purpose header", function()
      local test_file = temp_dir .. "/test.sh"
      local content = {
        "#!/bin/bash",
        "# Purpose: Script purpose description",
        "echo 'test'",
      }
      vim.fn.writefile(content, test_file)

      local result = metadata.parse_script_description(test_file)
      assert.equals("Script purpose description", result)
    end)

    it("extracts description from Description header", function()
      local test_file = temp_dir .. "/test.sh"
      local content = {
        "#!/bin/bash",
        "# Description: Script description text",
        "echo 'test'",
      }
      vim.fn.writefile(content, test_file)

      local result = metadata.parse_script_description(test_file)
      assert.equals("Script description text", result)
    end)

    it("extracts first non-shebang comment if no Purpose/Description", function()
      local test_file = temp_dir .. "/test.sh"
      local content = {
        "#!/bin/bash",
        "# First comment line",
        "# Second comment",
        "echo 'test'",
      }
      vim.fn.writefile(content, test_file)

      local result = metadata.parse_script_description(test_file)
      assert.equals("First comment line", result)
    end)

    it("truncates description to 40 characters", function()
      local test_file = temp_dir .. "/test.sh"
      local content = {
        "#!/bin/bash",
        "# Purpose: This is a very long purpose description that should be truncated",
      }
      vim.fn.writefile(content, test_file)

      local result = metadata.parse_script_description(test_file)
      assert.equals(40, #result)
    end)

    it("ignores shebang line", function()
      local test_file = temp_dir .. "/test.sh"
      local content = {
        "#!/bin/bash",
        "# Actual comment",
      }
      vim.fn.writefile(content, test_file)

      local result = metadata.parse_script_description(test_file)
      assert.equals("Actual comment", result)
    end)

    it("returns empty string for non-existent file", function()
      local result = metadata.parse_script_description("/nonexistent/file.sh")
      assert.equals("", result)
    end)
  end)

  describe("parse_doc_description", function()
    it("extracts description from YAML frontmatter", function()
      local test_file = temp_dir .. "/test.md"
      local content = {
        "---",
        "title: Test Doc",
        "description: Doc description from frontmatter",
        "---",
        "# Title",
        "Content here",
      }
      vim.fn.writefile(content, test_file)

      local result = metadata.parse_doc_description(test_file)
      assert.equals("Doc description from frontmatter", result)
    end)

    it("extracts first paragraph after title when no frontmatter", function()
      local test_file = temp_dir .. "/test.md"
      local content = {
        "# Main Title",
        "",
        "This is the first paragraph description",
        "",
        "## Subheading",
      }
      vim.fn.writefile(content, test_file)

      local result = metadata.parse_doc_description(test_file)
      assert.equals("This is the first paragraph description", result)
    end)

    it("truncates description to 40 characters", function()
      local test_file = temp_dir .. "/test.md"
      local content = {
        "---",
        "description: This is a very long description that should be truncated to forty characters",
        "---",
      }
      vim.fn.writefile(content, test_file)

      local result = metadata.parse_doc_description(test_file)
      assert.equals(40, #result)
    end)

    it("ignores subheadings when looking for paragraph", function()
      local test_file = temp_dir .. "/test.md"
      local content = {
        "# Main Title",
        "",
        "## Subheading",
        "This should not be extracted",
      }
      vim.fn.writefile(content, test_file)

      local result = metadata.parse_doc_description(test_file)
      assert.equals("", result)
    end)

    it("returns empty string for non-existent file", function()
      local result = metadata.parse_doc_description("/nonexistent/file.md")
      assert.equals("", result)
    end)
  end)

  describe("get_parser_for_type", function()
    it("returns correct parser for template type", function()
      local parser = metadata.get_parser_for_type("template")
      assert.equals(metadata.parse_template_description, parser)
    end)

    it("returns correct parser for script types", function()
      local tts_parser = metadata.get_parser_for_type("tts_file")
      local lib_parser = metadata.get_parser_for_type("lib")
      local hook_parser = metadata.get_parser_for_type("hook_event")

      assert.equals(metadata.parse_script_description, tts_parser)
      assert.equals(metadata.parse_script_description, lib_parser)
      assert.equals(metadata.parse_script_description, hook_parser)
    end)

    it("returns correct parser for doc type", function()
      local parser = metadata.get_parser_for_type("doc")
      assert.equals(metadata.parse_doc_description, parser)
    end)

    it("returns nil for types without specific parser", function()
      local parser = metadata.get_parser_for_type("command")
      assert.is_nil(parser)
    end)

    it("returns nil for invalid type", function()
      local parser = metadata.get_parser_for_type("nonexistent")
      assert.is_nil(parser)
    end)
  end)
end)
