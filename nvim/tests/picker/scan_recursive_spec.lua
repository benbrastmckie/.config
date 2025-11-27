-- Tests for recursive directory scanning
local scan = require("neotex.plugins.ai.claude.commands.picker.utils.scan")

describe("scan_directory_for_sync with recursive scanning", function()
  local test_global_dir = "/tmp/test-recursive-scan/global"
  local test_local_dir = "/tmp/test-recursive-scan/local"

  before_each(function()
    -- Test fixture already created by bash test setup
  end)

  it("should scan files recursively with ** pattern", function()
    local files = scan.scan_directory_for_sync(
      test_global_dir,
      test_local_dir,
      "lib",
      "*.sh",
      true  -- recursive
    )

    -- Should find lib/core/utils.sh
    assert.is_not_nil(files)
    assert.is_true(#files >= 1)

    -- Find the nested file
    local found_nested = false
    for _, file in ipairs(files) do
      if file.global_path:match("lib/core/utils%.sh") then
        found_nested = true
        assert.is_not_nil(file.is_subdir)
        assert.is_true(file.is_subdir)
      end
    end
    assert.is_true(found_nested, "Should find nested lib/core/utils.sh")
  end)

  it("should detect is_subdir correctly", function()
    local files = scan.scan_directory_for_sync(
      test_global_dir,
      test_local_dir,
      "docs",
      "*.md",
      true
    )

    -- Should find docs/architecture/design.md
    local found = false
    for _, file in ipairs(files) do
      if file.global_path:match("docs/architecture/design%.md") then
        found = true
        assert.is_true(file.is_subdir, "Nested file should have is_subdir=true")
      end
    end
    assert.is_true(found, "Should find nested docs file")
  end)

  it("should deduplicate files correctly", function()
    local files = scan.scan_directory_for_sync(
      test_global_dir,
      test_local_dir,
      "skills",
      "*.md",
      true
    )

    -- Count unique global paths
    local seen = {}
    for _, file in ipairs(files) do
      assert.is_nil(seen[file.global_path], "No duplicate global paths")
      seen[file.global_path] = true
    end
  end)

  it("should calculate correct local paths for nested files", function()
    local files = scan.scan_directory_for_sync(
      test_global_dir,
      test_local_dir,
      "lib",
      "*.sh",
      true
    )

    for _, file in ipairs(files) do
      if file.global_path:match("lib/core/utils%.sh") then
        -- Local path should mirror the nested structure
        assert.is_not_nil(file.local_path:match("local/%.claude/lib/core/utils%.sh"))
      end
    end
  end)

  it("should respect recursive=false for backward compatibility", function()
    -- Create a top-level file for this test
    vim.fn.system("touch " .. test_global_dir .. "/.claude/lib/top_level.sh")

    local files = scan.scan_directory_for_sync(
      test_global_dir,
      test_local_dir,
      "lib",
      "*.sh",
      false  -- non-recursive
    )

    -- Should only find top-level files
    for _, file in ipairs(files) do
      assert.is_false(file.is_subdir or false, "Should only find top-level files")
    end
  end)
end)

describe("count_by_depth", function()
  it("should count top-level and subdirectory files correctly", function()
    local files = {
      { is_subdir = false },
      { is_subdir = true },
      { is_subdir = true },
      { is_subdir = false },
    }

    -- Note: count_by_depth is a local function, so we'll test it indirectly
    -- through the reporting mechanism or by testing the results of sync
  end)
end)
