-- Unit tests for file utilities

local test_framework = require('neotex.plugins.tools.himalaya.test.utils.test_framework')
local file_utils = require('neotex.plugins.tools.himalaya.utils.file')

local M = {}

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
  
  test_framework.assert_true(
    file_utils.is_dir(test_dir .. '/sub/dir'),
    'Should create directory structure'
  )
end

function M.test_read_write_file()
  local test_file = test_dir .. '/test.txt'
  local content = 'Test content\nLine 2'
  
  -- Write file
  local ok, err = file_utils.write_file(test_file, content)
  test_framework.assert_true(ok, 'Should write file successfully')
  
  -- Read file
  local read_content, read_err = file_utils.read_file(test_file)
  test_framework.assert_equals(read_content, content, 'Should read same content')
  
  -- Read non-existent file
  local missing_content, missing_err = file_utils.read_file(test_dir .. '/missing.txt')
  test_framework.assert_nil(missing_content, 'Should return nil for missing file')
  test_framework.assert_not_nil(missing_err, 'Should return error for missing file')
end

function M.test_append_file()
  local test_file = test_dir .. '/append.txt'
  
  file_utils.write_file(test_file, 'Line 1\n')
  file_utils.append_file(test_file, 'Line 2\n')
  
  local content = file_utils.read_file(test_file)
  test_framework.assert_equals(content, 'Line 1\nLine 2\n', 'Should append content')
end

function M.test_exists()
  local test_file = test_dir .. '/exists.txt'
  
  test_framework.assert_false(
    file_utils.exists(test_file),
    'Should not exist initially'
  )
  
  file_utils.write_file(test_file, 'content')
  
  test_framework.assert_true(
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
  test_framework.assert_true(ok, 'Should copy file')
  test_framework.assert_equals(
    file_utils.read_file(dest),
    content,
    'Copied file should have same content'
  )
  
  -- Move file
  local moved = test_dir .. '/moved.txt'
  ok = file_utils.move_file(dest, moved)
  test_framework.assert_true(ok, 'Should move file')
  test_framework.assert_false(file_utils.exists(dest), 'Original should not exist')
  test_framework.assert_true(file_utils.exists(moved), 'Moved file should exist')
  
  -- Delete file
  ok = file_utils.delete_file(moved)
  test_framework.assert_true(ok, 'Should delete file')
  test_framework.assert_false(file_utils.exists(moved), 'File should not exist after delete')
end

function M.test_list_dir()
  -- Create test files
  file_utils.write_file(test_dir .. '/file1.txt', 'content')
  file_utils.write_file(test_dir .. '/file2.lua', 'content')
  vim.fn.mkdir(test_dir .. '/subdir', 'p')
  
  -- List all
  local files = file_utils.list_dir(test_dir)
  test_framework.assert_equals(#files, 3, 'Should list all items')
  
  -- List with filter
  files = file_utils.list_dir(test_dir, function(name, type)
    return type == 'file' and name:match('%.txt$')
  end)
  test_framework.assert_equals(#files, 1, 'Should filter txt files')
  test_framework.assert_equals(files[1].name, 'file1.txt', 'Should find txt file')
end

function M.test_path_operations()
  -- Join paths
  test_framework.assert_equals(
    file_utils.join('path', 'to', 'file.txt'),
    'path/to/file.txt',
    'Should join paths'
  )
  
  -- Dirname
  test_framework.assert_equals(
    file_utils.dirname('/path/to/file.txt'),
    '/path/to',
    'Should get directory name'
  )
  
  -- Basename
  test_framework.assert_equals(
    file_utils.basename('/path/to/file.txt'),
    'file.txt',
    'Should get base name'
  )
  
  -- Extension
  test_framework.assert_equals(
    file_utils.extension('file.txt'),
    'txt',
    'Should get extension'
  )
  
  -- Remove extension
  test_framework.assert_equals(
    file_utils.remove_extension('file.txt'),
    'file',
    'Should remove extension'
  )
  
  -- Is absolute
  test_framework.assert_true(
    file_utils.is_absolute('/path/to/file'),
    'Should detect absolute path'
  )
  test_framework.assert_true(
    file_utils.is_absolute('~/file'),
    'Should detect home path as absolute'
  )
  test_framework.assert_false(
    file_utils.is_absolute('relative/path'),
    'Should detect relative path'
  )
end

function M.test_temp_file()
  local temp = file_utils.temp_file('test', '.txt')
  test_framework.assert_match(temp, 'test_.*%.txt$', 'Should create temp filename')
  
  -- Write to temp file
  file_utils.write_file(temp, 'temp content')
  test_framework.assert_true(file_utils.exists(temp), 'Temp file should exist')
  
  -- Clean up
  file_utils.delete_file(temp)
end

function M.test_home_and_expand()
  local home = file_utils.home()
  test_framework.assert_not_nil(home, 'Should get home directory')
  test_framework.assert_match(home, '^/', 'Home should be absolute path')
  
  -- Expand tilde
  local expanded = file_utils.expand('~/test')
  test_framework.assert_match(expanded, '^/', 'Should expand to absolute path')
  test_framework.assert_not_match(expanded, '~', 'Should not contain tilde')
end

return M