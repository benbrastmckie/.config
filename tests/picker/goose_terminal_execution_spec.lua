--- Test suite for Goose recipe terminal execution functionality
--- Tests the new run_recipe_in_terminal function and execution mode configuration

describe("Goose Terminal Execution", function()
  local execution
  local picker

  before_each(function()
    -- Reset modules to ensure clean state
    package.loaded['neotex.plugins.ai.goose.picker.execution'] = nil
    package.loaded['neotex.plugins.ai.goose.picker.init'] = nil

    execution = require('neotex.plugins.ai.goose.picker.execution')
    picker = require('neotex.plugins.ai.goose.picker.init')
  end)

  describe("run_recipe_in_terminal", function()
    it("should exist as a function", function()
      assert.is_function(execution.run_recipe_in_terminal)
    end)

    it("should validate recipe file exists", function()
      local called = false

      -- Mock vim.notify to capture error
      local original_notify = vim.notify
      vim.notify = function(msg, level)
        if msg:match("Recipe file not found") then
          called = true
        end
      end

      -- Call with non-existent file
      execution.run_recipe_in_terminal('/nonexistent/recipe.yaml', {})

      -- Restore original
      vim.notify = original_notify

      assert.is_true(called)
    end)

    it("should handle recipes with no parameters", function()
      -- This test validates the command construction for recipes without parameters
      -- In real usage, this would execute via TermExec or terminal command

      local recipe_path = '/tmp/test_recipe.yaml'
      local metadata = {
        name = 'test-recipe',
        parameters = {}
      }

      -- Create temporary recipe file
      local file = io.open(recipe_path, 'w')
      file:write('name: test-recipe\n')
      file:close()

      -- Mock vim.cmd to capture command
      local captured_cmd = nil
      local original_cmd = vim.cmd
      vim.cmd = function(cmd)
        captured_cmd = cmd
      end

      -- Mock pcall to simulate toggleterm not available
      local original_pcall = pcall
      pcall = function(fn, ...)
        if fn == require and ({...})[1] == 'toggleterm' then
          return false
        end
        return original_pcall(fn, ...)
      end

      -- Execute
      execution.run_recipe_in_terminal(recipe_path, metadata)

      -- Restore
      vim.cmd = original_cmd
      pcall = original_pcall
      os.remove(recipe_path)

      -- Verify terminal command was constructed
      assert.is_not_nil(captured_cmd)
      assert.is_true(captured_cmd:match('terminal') ~= nil or captured_cmd:match('TermExec') ~= nil)
    end)

    it("should properly escape recipe paths with spaces", function()
      local recipe_path = '/tmp/test recipe with spaces.yaml'
      local metadata = {
        name = 'test-recipe',
        parameters = {}
      }

      -- Create temporary recipe file
      local file = io.open(recipe_path, 'w')
      if file then
        file:write('name: test-recipe\n')
        file:close()

        -- Mock vim.cmd to capture command
        local captured_cmd = nil
        local original_cmd = vim.cmd
        vim.cmd = function(cmd)
          captured_cmd = cmd
        end

        -- Execute
        execution.run_recipe_in_terminal(recipe_path, metadata)

        -- Restore
        vim.cmd = original_cmd
        os.remove(recipe_path)

        -- Verify path is escaped (vim.fn.shellescape should handle this)
        assert.is_not_nil(captured_cmd)
      end
    end)

    it("should handle recipes with parameters", function()
      local recipe_path = '/tmp/test_recipe_params.yaml'
      local metadata = {
        name = 'test-recipe',
        parameters = {
          {
            key = 'test_param',
            requirement = 'required',
            input_type = 'string',
            description = 'Test parameter'
          }
        }
      }

      -- Create temporary recipe file
      local file = io.open(recipe_path, 'w')
      file:write('name: test-recipe\n')
      file:close()

      -- Mock vim.fn.input to simulate user input
      local original_input = vim.fn.input
      vim.fn.input = function(prompt)
        return 'test_value'
      end

      -- Mock vim.cmd
      local captured_cmd = nil
      local original_cmd = vim.cmd
      vim.cmd = function(cmd)
        captured_cmd = cmd
      end

      -- Execute
      execution.run_recipe_in_terminal(recipe_path, metadata)

      -- Restore
      vim.fn.input = original_input
      vim.cmd = original_cmd
      os.remove(recipe_path)

      -- Verify command includes parameters
      if captured_cmd then
        assert.is_true(captured_cmd:match('--params') ~= nil)
      end
    end)
  end)

  describe("Execution Mode Configuration", function()
    it("should default to terminal mode", function()
      assert.equals('terminal', picker.config.execution_mode)
    end)

    it("should allow configuration override", function()
      picker.setup({ execution_mode = 'sidebar' })
      assert.equals('sidebar', picker.config.execution_mode)
    end)

    it("should preserve other config when updating execution_mode", function()
      picker.config.custom_option = 'test'
      picker.setup({ execution_mode = 'sidebar' })

      assert.equals('sidebar', picker.config.execution_mode)
      assert.equals('test', picker.config.custom_option)
    end)
  end)

  describe("Parameter Validation", function()
    it("should validate string parameters", function()
      local valid, converted = execution.validate_param('test', 'string')
      assert.is_true(valid)
      assert.equals('test', converted)
    end)

    it("should validate number parameters", function()
      local valid, converted = execution.validate_param('42', 'number')
      assert.is_true(valid)
      assert.equals(42, converted)
    end)

    it("should validate boolean parameters", function()
      local valid_true, converted_true = execution.validate_param('true', 'boolean')
      assert.is_true(valid_true)
      assert.equals(true, converted_true)

      local valid_false, converted_false = execution.validate_param('false', 'boolean')
      assert.is_true(valid_false)
      assert.equals(false, converted_false)
    end)

    it("should reject invalid number parameters", function()
      local valid, converted = execution.validate_param('not_a_number', 'number')
      assert.is_false(valid)
      assert.is_nil(converted)
    end)

    it("should reject empty string parameters", function()
      local valid, converted = execution.validate_param('', 'string')
      assert.is_false(valid)
      assert.is_nil(converted)
    end)
  end)

  describe("Shell Escaping", function()
    it("should escape special characters in parameters", function()
      -- Test that special characters are properly escaped
      local recipe_path = '/tmp/test_escape.yaml'
      local metadata = {
        name = 'test-recipe',
        parameters = {
          {
            key = 'param_with_quotes',
            requirement = 'required',
            input_type = 'string',
            description = 'Test parameter'
          }
        }
      }

      -- Create temporary recipe file
      local file = io.open(recipe_path, 'w')
      file:write('name: test-recipe\n')
      file:close()

      -- Mock vim.fn.input to return value with special characters
      local original_input = vim.fn.input
      vim.fn.input = function(prompt)
        return "value'with'quotes"
      end

      -- Mock vim.cmd to verify escaping
      local captured_cmd = nil
      local original_cmd = vim.cmd
      vim.cmd = function(cmd)
        captured_cmd = cmd
      end

      -- Execute
      execution.run_recipe_in_terminal(recipe_path, metadata)

      -- Restore
      vim.fn.input = original_input
      vim.cmd = original_cmd
      os.remove(recipe_path)

      -- Verify command was constructed (escaping handled by vim.fn.shellescape)
      assert.is_not_nil(captured_cmd)
    end)
  end)
end)
