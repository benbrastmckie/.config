-- Test suite for utils.scan module
-- Run with: :TestFile

describe("picker.utils.scan", function()
  local scan
  local temp_dir

  before_each(function()
    scan = require("neotex.plugins.ai.claude.commands.picker.utils.scan")

    -- Create temp directory structure for testing
    temp_dir = vim.fn.tempname()
    vim.fn.mkdir(temp_dir, "p")
  end)

  after_each(function()
    -- Clean up temp directory
    if temp_dir and vim.fn.isdirectory(temp_dir) == 1 then
      vim.fn.delete(temp_dir, "rf")
    end
  end)

  describe("scan_directory", function()
    it("scans directory and returns file info", function()
      local test_dir = temp_dir .. "/test"
      vim.fn.mkdir(test_dir, "p")

      -- Create test files
      vim.fn.writefile({}, test_dir .. "/file1.md")
      vim.fn.writefile({}, test_dir .. "/file2.md")

      local results = scan.scan_directory(test_dir, "*.md")

      assert.equals(2, #results)
      assert.equals("file1", results[1].name)
      assert.equals("file2", results[2].name)
    end)

    it("excludes README.md files", function()
      local test_dir = temp_dir .. "/test"
      vim.fn.mkdir(test_dir, "p")

      vim.fn.writefile({}, test_dir .. "/README.md")
      vim.fn.writefile({}, test_dir .. "/other.md")

      local results = scan.scan_directory(test_dir, "*.md")

      assert.equals(1, #results)
      assert.equals("other", results[1].name)
    end)

    it("returns empty array for non-existent directory", function()
      local results = scan.scan_directory("/nonexistent/path", "*.md")
      assert.equals(0, #results)
    end)

    it("returns empty array when no files match pattern", function()
      local test_dir = temp_dir .. "/empty"
      vim.fn.mkdir(test_dir, "p")

      local results = scan.scan_directory(test_dir, "*.md")
      assert.equals(0, #results)
    end)
  end)

  describe("scan_directory_for_sync", function()
    it("identifies new files for copying", function()
      local global_dir = temp_dir .. "/global"
      local local_dir = temp_dir .. "/local"

      vim.fn.mkdir(global_dir .. "/.claude/commands", "p")
      vim.fn.mkdir(local_dir .. "/.claude/commands", "p")

      -- Create file only in global
      vim.fn.writefile({}, global_dir .. "/.claude/commands/new.md")

      local results = scan.scan_directory_for_sync(global_dir, local_dir, "commands", "*.md")

      assert.equals(1, #results)
      assert.equals("new.md", results[1].name)
      assert.equals("copy", results[1].action)
    end)

    it("identifies existing files for replacement", function()
      local global_dir = temp_dir .. "/global"
      local local_dir = temp_dir .. "/local"

      vim.fn.mkdir(global_dir .. "/.claude/commands", "p")
      vim.fn.mkdir(local_dir .. "/.claude/commands", "p")

      -- Create file in both locations
      vim.fn.writefile({"global content"}, global_dir .. "/.claude/commands/existing.md")
      vim.fn.writefile({"local content"}, local_dir .. "/.claude/commands/existing.md")

      local results = scan.scan_directory_for_sync(global_dir, local_dir, "commands", "*.md")

      assert.equals(1, #results)
      assert.equals("existing.md", results[1].name)
      assert.equals("replace", results[1].action)
    end)

    it("returns empty array when no global files exist", function()
      local global_dir = temp_dir .. "/global"
      local local_dir = temp_dir .. "/local"

      vim.fn.mkdir(global_dir .. "/.claude/commands", "p")
      vim.fn.mkdir(local_dir .. "/.claude/commands", "p")

      local results = scan.scan_directory_for_sync(global_dir, local_dir, "commands", "*.md")

      assert.equals(0, #results)
    end)
  end)

  describe("merge_artifacts", function()
    it("merges local and global artifacts with local override", function()
      local local_arts = {
        {name = "local-only", filepath = "/local/file1"},
        {name = "shared", filepath = "/local/shared"},
      }
      local global_arts = {
        {name = "shared", filepath = "/global/shared"},
        {name = "global-only", filepath = "/global/file2"},
      }

      local merged = scan.merge_artifacts(local_arts, global_arts)

      assert.equals(3, #merged)

      -- Check local artifacts are marked correctly
      assert.is_true(merged[1].is_local)
      assert.equals("local-only", merged[1].name)

      assert.is_true(merged[2].is_local)
      assert.equals("shared", merged[2].name)

      -- Check global artifact is added
      assert.is_false(merged[3].is_local)
      assert.equals("global-only", merged[3].name)
    end)

    it("handles empty local artifacts", function()
      local local_arts = {}
      local global_arts = {
        {name = "global", filepath = "/global/file"},
      }

      local merged = scan.merge_artifacts(local_arts, global_arts)

      assert.equals(1, #merged)
      assert.is_false(merged[1].is_local)
    end)

    it("handles empty global artifacts", function()
      local local_arts = {
        {name = "local", filepath = "/local/file"},
      }
      local global_arts = {}

      local merged = scan.merge_artifacts(local_arts, global_arts)

      assert.equals(1, #merged)
      assert.is_true(merged[1].is_local)
    end)
  end)

  describe("filter_by_pattern", function()
    it("filters artifacts by name pattern", function()
      local artifacts = {
        {name = "tts-config", filepath = "/path/1"},
        {name = "tts-library", filepath = "/path/2"},
        {name = "other-file", filepath = "/path/3"},
      }

      local filtered = scan.filter_by_pattern(artifacts, "^tts%-")

      assert.equals(2, #filtered)
      assert.equals("tts-config", filtered[1].name)
      assert.equals("tts-library", filtered[2].name)
    end)

    it("returns empty array when no matches", function()
      local artifacts = {
        {name = "file1", filepath = "/path/1"},
        {name = "file2", filepath = "/path/2"},
      }

      local filtered = scan.filter_by_pattern(artifacts, "^tts%-")

      assert.equals(0, #filtered)
    end)

    it("handles empty input", function()
      local filtered = scan.filter_by_pattern({}, "^tts%-")
      assert.equals(0, #filtered)
    end)
  end)

  describe("get_directories", function()
    it("returns current project and global config directories", function()
      local dirs = scan.get_directories()

      assert.is_not_nil(dirs.project_dir)
      assert.is_not_nil(dirs.global_dir)
      assert.equals(vim.fn.getcwd(), dirs.project_dir)
      assert.equals(vim.fn.expand("~/.config/nvim"), dirs.global_dir)
    end)
  end)
end)
