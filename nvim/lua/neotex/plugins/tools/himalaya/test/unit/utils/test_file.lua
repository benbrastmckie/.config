-- Unit tests for file utilities

local test_framework = require('neotex.plugins.tools.himalaya.test.utils.test_framework')
local assert = test_framework.assert
local file_utils = require('neotex.plugins.tools.himalaya.utils.file')

local M = {}

-- Test metadata
M.test_metadata = {
  name = "File Utility Tests",
  description = "Tests for file system operations and utilities",
  count = 9,
  category = "unit",
  tags = {"utils", "filesystem", "io"},
  estimated_duration_ms = 400
}

-- Test temp directory for tests
local test_dir = vim.fn.tempname() .. '/himalaya_file_tests'

function M.setup()
  vim.fn.mkdir(test_dir, 'p')
end

function M.teardown()
  vim.fn.delete(test_dir, 'rf')
end

function M.test_ensure_dir()
  local test_path = test_dir .. '/sub/dir/file.txt'
  file_utils.ensure_dir(test_path)
  
  assert.truthy(
    file_utils.is_dir(test_dir .. '/sub/dir'),
    'Should create directory structure'
  )
end

function M.test_read_write_file()
  local test_file = test_dir .. '/test.txt'
  local content = 'Test content\nLine 2'
  
  -- Write file
  local ok, err = file_utils.write_file(test_file, content)
  assert.truthy(ok, 'Should write file successfully')
  
  -- Read file
  local read_content, read_err = file_utils.read_file(test_file)
  assert.equals(read_content, content, 'Should read same content')
  
  -- Read non-existent file
  local missing_content, missing_err = file_utils.read_file(test_dir .. '/missing.txt')
  assert.falsy(missing_content, 'Should return nil for missing file')
  assert.truthy(missing_err, 'Should return error for missing file')
end

function M.test_append_file()
  local test_file = test_dir .. '/append.txt'
  
  file_utils.write_file(test_file, 'Line 1\n')
  file_utils.append_file(test_file, 'Line 2\n')
  
  local content = file_utils.read_file(test_file)
  assert.equals(content, 'Line 1\nLine 2\n', 'Should append content')
end

function M.test_exists()
  local test_file = test_dir .. '/exists.txt'
  
  assert.falsy(
    file_utils.exists(test_file),
    'Should not exist initially'
  )
  
  file_utils.write_file(test_file, 'content')
  
  assert.truthy(
    file_utils.exists(test_file),
    'Should exist after writing'
  )
end

function M.test_file_operations()
  local src = test_dir .. '/source.txt'
  local dest = test_dir .. '/dest.txt'
  local content = 'Test content'
  
  -- Write source file
  file_utils.write_file(src, content)
  
  -- Copy file
  local ok = file_utils.copy_file(src, dest)
  assert.truthy(ok, 'Should copy file')
  assert.equals(
    file_utils.read_file(dest),
    content,
    'Copied file should have same content'
  )
  
  -- Move file
  local moved = test_dir .. '/moved.txt'
  ok = file_utils.move_file(dest, moved)
  assert.truthy(ok, 'Should move file')
  assert.falsy(file_utils.exists(dest), 'Original should not exist')
  assert.truthy(file_utils.exists(moved), 'Moved file should exist')
  
  -- Delete file
  ok = file_utils.delete_file(moved)
  assert.truthy(ok, 'Should delete file')
  assert.falsy(file_utils.exists(moved), 'File should not exist after delete')
end

function M.test_list_dir()
  -- Clean the test directory first to ensure consistent state
  local list_test_dir = test_dir .. '/list_test'
  vim.fn.mkdir(list_test_dir, 'p')
  
  -- Create test files in isolated subdirectory
  file_utils.write_file(list_test_dir .. '/file1.txt', 'content')
  file_utils.write_file(list_test_dir .. '/file2.lua', 'content')
  vim.fn.mkdir(list_test_dir .. '/subdir', 'p')
  
  -- List all
  local files = file_utils.list_dir(list_test_dir)
  assert.equals(#files, 3, 'Should list all items')
  
  -- List with filter
  files = file_utils.list_dir(list_test_dir, function(name, type)
    return type == 'file' and name:match('%.txt$')
  end)
  assert.equals(#files, 1, 'Should filter txt files')
  assert.equals(files[1].name, 'file1.txt', 'Should find txt file')
end

function M.test_path_operations()
  -- Join paths
  assert.equals(
    file_utils.join('path', 'to', 'file.txt'),
    'path/to/file.txt',
    'Should join paths'
  )
  
  -- Dirname
  assert.equals(
    file_utils.dirname('/path/to/file.txt'),
    '/path/to',
    'Should get directory name'
  )
  
  -- Basename
  assert.equals(
    file_utils.basename('/path/to/file.txt'),
    'file.txt',
    'Should get base name'
  )
  
  -- Extension
  assert.equals(
    file_utils.extension('file.txt'),
    'txt',
    'Should get extension'
  )
  
  -- Remove extension
  assert.equals(
    file_utils.remove_extension('file.txt'),
    'file',
    'Should remove extension'
  )
  
  -- Is absolute
  assert.truthy(
    file_utils.is_absolute('/path/to/file'),
    'Should detect absolute path'
  )
  assert.truthy(
    file_utils.is_absolute('~/file'),
    'Should detect home path as absolute'
  )
  assert.falsy(
    file_utils.is_absolute('relative/path'),
    'Should detect relative path'
  )
end

function M.test_temp_file()
  local temp = file_utils.temp_file('test', '.txt')
  assert.matches(temp, 'test_.*%.txt$', 'Should create temp filename')
  
  -- Write to temp file
  file_utils.write_file(temp, 'temp content')
  assert.truthy(file_utils.exists(temp), 'Temp file should exist')
  
  -- Clean up
  file_utils.delete_file(temp)
end

function M.test_home_and_expand()
  local home = file_utils.home()
  assert.truthy(home, 'Should get home directory')
  assert.matches(home, '^/', 'Home should be absolute path')
  
  -- Expand tilde
  local expanded = file_utils.expand('~/test')
  assert.matches(expanded, '^/', 'Should expand to absolute path')
  assert.falsy(expanded:match('~'), 'Should not contain tilde')
end

-- Add standardized interface

return M