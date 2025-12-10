--- Unit test suite for Goose recipe execution module (execution.lua only)
--- Tests core functionality without telescope dependencies

describe("Goose Execution Module Unit Tests", function()
  local execution

  before_each(function()
    -- Reset module to ensure clean state
    package.loaded['neotex.plugins.ai.goose.picker.execution'] = nil
    execution = require('neotex.plugins.ai.goose.picker.execution')
  end)

  describe("Module Structure", function()
    it("should export run_recipe_in_terminal function", function()
      assert.is_function(execution.run_recipe_in_terminal)
    end)

    it("should export run_recipe_in_sidebar function", function()
      assert.is_function(execution.run_recipe_in_sidebar)
    end)

    it("should export prompt_for_parameters function", function()
      assert.is_function(execution.prompt_for_parameters)
    end)

    it("should export validate_param function", function()
      assert.is_function(execution.validate_param)
    end)

    it("should export validate_recipe function", function()
      assert.is_function(execution.validate_recipe)
    end)
  end)

  describe("Parameter Validation", function()
    describe("String parameters", function()
      it("should validate non-empty strings", function()
        local valid, converted = execution.validate_param('test', 'string')
        assert.is_true(valid)
        assert.equals('test', converted)
      end)

      it("should reject empty strings", function()
        local valid, converted = execution.validate_param('', 'string')
        assert.is_false(valid)
        assert.is_nil(converted)
      end)
    end)

    describe("Number parameters", function()
      it("should validate integer strings", function()
        local valid, converted = execution.validate_param('42', 'number')
        assert.is_true(valid)
        assert.equals(42, converted)
      end)

      it("should validate float strings", function()
        local valid, converted = execution.validate_param('3.14', 'number')
        assert.is_true(valid)
        assert.equals(3.14, converted)
      end)

      it("should reject non-numeric strings", function()
        local valid, converted = execution.validate_param('not_a_number', 'number')
        assert.is_false(valid)
        assert.is_nil(converted)
      end)
    end)

    describe("Boolean parameters", function()
      it("should accept 'true' as boolean true", function()
        local valid, converted = execution.validate_param('true', 'boolean')
        assert.is_true(valid)
        assert.equals(true, converted)
      end)

      it("should accept 'false' as boolean false", function()
        local valid, converted = execution.validate_param('false', 'boolean')
        assert.is_true(valid)
        assert.equals(false, converted)
      end)

      it("should accept 'yes' as boolean true", function()
        local valid, converted = execution.validate_param('yes', 'boolean')
        assert.is_true(valid)
        assert.equals(true, converted)
      end)

      it("should accept 'no' as boolean false", function()
        local valid, converted = execution.validate_param('no', 'boolean')
        assert.is_true(valid)
        assert.equals(false, converted)
      end)

      it("should accept '1' as boolean true", function()
        local valid, converted = execution.validate_param('1', 'boolean')
        assert.is_true(valid)
        assert.equals(true, converted)
      end)

      it("should accept '0' as boolean false", function()
        local valid, converted = execution.validate_param('0', 'boolean')
        assert.is_true(valid)
        assert.equals(false, converted)
      end)

      it("should reject invalid boolean strings", function()
        local valid, converted = execution.validate_param('maybe', 'boolean')
        assert.is_false(valid)
        assert.is_nil(converted)
      end)
    end)

    describe("Unknown parameter types", function()
      it("should accept any value as string", function()
        local valid, converted = execution.validate_param('anything', 'unknown_type')
        assert.is_true(valid)
        assert.equals('anything', converted)
      end)
    end)
  end)

  describe("Parameter Serialization", function()
    it("should serialize empty params table", function()
      local result = execution._serialize_params({})
      assert.equals('', result)
    end)

    it("should serialize single parameter", function()
      local result = execution._serialize_params({ key = 'value' })
      assert.is_not_nil(result:match('key=value'))
    end)

    it("should serialize multiple parameters", function()
      local result = execution._serialize_params({
        key1 = 'value1',
        key2 = 'value2'
      })
      assert.is_not_nil(result:match('key1=value1'))
      assert.is_not_nil(result:match('key2=value2'))
    end)

    it("should handle numeric values", function()
      local result = execution._serialize_params({ count = 42 })
      assert.is_not_nil(result:match('count=42'))
    end)

    it("should handle boolean values", function()
      local result = execution._serialize_params({ enabled = true })
      assert.is_not_nil(result:match('enabled=true'))
    end)
  end)

  describe("Error Handling", function()
    it("should handle nil recipe path gracefully", function()
      local called = false
      local original_notify = vim.notify
      vim.notify = function(msg, level)
        if msg:match("Recipe file not found") and level == vim.log.levels.ERROR then
          called = true
        end
      end

      execution.run_recipe_in_terminal(nil, {})

      vim.notify = original_notify
      assert.is_true(called)
    end)

    it("should handle non-existent recipe file", function()
      local called = false
      local original_notify = vim.notify
      vim.notify = function(msg, level)
        if msg:match("Recipe file not found") and level == vim.log.levels.ERROR then
          called = true
        end
      end

      execution.run_recipe_in_terminal('/nonexistent/path.yaml', {})

      vim.notify = original_notify
      assert.is_true(called)
    end)
  end)

  describe("Integration Points", function()
    it("should accept metadata with no parameters", function()
      local metadata = {
        name = 'test-recipe',
        parameters = {}
      }

      -- This should not error
      local ok = pcall(function()
        local params = execution.prompt_for_parameters(metadata.parameters)
        assert.is_table(params)
        assert.equals(0, vim.tbl_count(params))
      end)

      assert.is_true(ok)
    end)

    it("should handle nil parameters array", function()
      local ok = pcall(function()
        local params = execution.prompt_for_parameters(nil)
        assert.is_table(params)
        assert.equals(0, vim.tbl_count(params))
      end)

      assert.is_true(ok)
    end)
  end)
end)
