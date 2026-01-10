# Testing Standards for Neovim

## Testing Framework

### busted
Primary Lua testing framework with BDD-style syntax.

```lua
describe("module_name", function()
  describe("function_name", function()
    it("should do expected behavior", function()
      local result = module.function_name()
      assert.equals(expected, result)
    end)
  end)
end)
```

### plenary.nvim
Neovim-specific testing utilities built on busted.

```lua
local plenary = require("plenary")

describe("buffer operations", function()
  before_each(function()
    -- Create test buffer
    vim.cmd("enew")
  end)

  after_each(function()
    -- Cleanup
    vim.cmd("bdelete!")
  end)

  it("should modify buffer", function()
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "test" })
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    assert.same({ "test" }, lines)
  end)
end)
```

## Assertion Patterns

### Standard Assertions
```lua
-- Equality
assert.equals(expected, actual)
assert.same(expected_table, actual_table)  -- Deep equality

-- Boolean
assert.is_true(value)
assert.is_false(value)

-- Nil
assert.is_nil(value)
assert.is_not_nil(value)

-- Type
assert.is_string(value)
assert.is_table(value)
assert.is_function(value)
```

### String Pattern Matching
**CRITICAL**: `string:match()` returns string or nil, NOT boolean.

```lua
-- CORRECT: Use is_nil/is_not_nil
local result = "test string"
assert.is_not_nil(result:match("test"))    -- Match found
assert.is_nil(result:match("missing"))     -- Match not found

-- WRONG: match() returns string/nil, not boolean
-- assert.is_true(result:match("test"))    -- FAILS
-- assert.is_false(result:match("missing")) -- FAILS
```

### Error Testing
```lua
-- Assert error is thrown
assert.has_error(function()
  error("expected error")
end)

-- Assert specific error message
assert.error_matches(function()
  error("validation failed")
end, "validation")
```

## Test Organization

### File Location
```
project/
├── lua/
│   └── module/
│       └── feature.lua
└── tests/
    └── module/
        └── feature_spec.lua
```

### File Naming
- Test files: `*_spec.lua` or `test_*.lua`
- Match source file structure in tests/

### Test Structure
```lua
-- tests/module/feature_spec.lua

-- Imports
local feature = require("module.feature")

-- Optional: setup/teardown
local function setup()
  -- common setup
end

local function teardown()
  -- common cleanup
end

-- Test suite
describe("feature", function()
  before_each(setup)
  after_each(teardown)

  describe("public_function", function()
    it("handles normal input", function()
      -- test
    end)

    it("handles edge cases", function()
      -- test
    end)

    it("returns error for invalid input", function()
      -- test
    end)
  end)
end)
```

## Running Tests

### Commands
```bash
# Run all tests with plenary
nvim --headless -c "PlenaryBustedDirectory tests/"

# Run specific test file
nvim --headless -c "PlenaryBustedFile tests/module/feature_spec.lua"

# Run with minimal init
nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"
```

### Vim Commands (in Neovim)
```vim
:TestNearest       " Test under cursor
:TestFile          " Current file
:TestSuite         " All tests
:TestLast          " Repeat last test
```

## Test Quality Standards

### Coverage Requirements
- All new public functions MUST have tests
- Edge cases and error conditions MUST be tested
- Integration tests for complex interactions

### What to Test
- Public API functions
- Error handling paths
- Edge cases (empty input, nil, etc.)
- Integration between modules

### What NOT to Test
- Private implementation details
- Simple getters/setters
- Third-party plugin internals

## Mocking and Stubs

### Mock vim.api
```lua
local original_api = vim.api

before_each(function()
  vim.api = {
    nvim_get_current_buf = function()
      return 1
    end,
    -- other mocked functions
  }
end)

after_each(function()
  vim.api = original_api
end)
```

### Mock External Modules
```lua
-- Using package.loaded
local original = package.loaded["external-module"]

before_each(function()
  package.loaded["external-module"] = {
    method = function()
      return "mocked"
    end,
  }
end)

after_each(function()
  package.loaded["external-module"] = original
end)
```

### Using pcall for Optional Dependencies
```lua
it("works without optional dependency", function()
  -- Force module to not be available
  package.loaded["optional-dep"] = nil

  local ok, result = pcall(function()
    return require("module").function_needing_optional_dep()
  end)

  assert.is_true(ok)
  assert.equals(expected_fallback, result)
end)
```

## Test Isolation

### Buffer Isolation
```lua
local test_bufnr

before_each(function()
  vim.cmd("enew")
  test_bufnr = vim.api.nvim_get_current_buf()
end)

after_each(function()
  if vim.api.nvim_buf_is_valid(test_bufnr) then
    vim.api.nvim_buf_delete(test_bufnr, { force = true })
  end
end)
```

### Global State Cleanup
```lua
local original_options = {}

before_each(function()
  original_options.number = vim.opt.number:get()
end)

after_each(function()
  vim.opt.number = original_options.number
end)
```

## Debugging Tests

### Print Debugging
```lua
it("debug output", function()
  local result = complex_function()
  print(vim.inspect(result))  -- Will show in test output
  assert.is_table(result)
end)
```

### Async Testing
```lua
local async = require("plenary.async")

describe("async operations", function()
  async.it("handles async code", function()
    local result = async.wrap(function(callback)
      vim.defer_fn(function()
        callback("done")
      end, 100)
    end, 1)()

    assert.equals("done", result)
  end)
end)
```
