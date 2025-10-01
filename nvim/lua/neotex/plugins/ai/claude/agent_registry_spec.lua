-- Test suite for agent_registry module
-- Run with: nvim --headless -c "luafile lua/neotex/plugins/ai/claude/agent_registry_spec.lua" -c "qa"

local registry = require('neotex.plugins.ai.claude.agent_registry')

local tests_passed = 0
local tests_failed = 0

local function test(name, fn)
  io.write('[TEST] ' .. name .. ' ... ')
  local success, err = pcall(fn)
  if success then
    io.write('✓ PASS\n')
    tests_passed = tests_passed + 1
  else
    io.write('✗ FAIL\n')
    io.write('  Error: ' .. tostring(err) .. '\n')
    tests_failed = tests_failed + 1
  end
end

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or 'Assertion failed') .. ': expected ' .. tostring(expected) .. ', got ' .. tostring(actual))
  end
end

local function assert_true(value, message)
  if not value then
    error(message or 'Expected true, got false')
  end
end

local function assert_not_nil(value, message)
  if value == nil then
    error(message or 'Expected non-nil value')
  end
end

local function assert_nil(value, message)
  if value ~= nil then
    error(message or 'Expected nil value')
  end
end

-- Test Suite
print('==================================================')
print('Agent Registry Test Suite')
print('==================================================\n')

test('list_agents returns expected count', function()
  local agents = registry.list_agents()
  assert_equal(#agents, 8, 'Should have 8 agents')
end)

test('list_agents returns sorted list', function()
  local agents = registry.list_agents()
  local prev = nil
  for _, name in ipairs(agents) do
    if prev then
      assert_true(name > prev, 'Agents should be alphabetically sorted')
    end
    prev = name
  end
end)

test('get_agent returns valid agent', function()
  local agent = registry.get_agent('code-writer')
  assert_not_nil(agent, 'Should return agent')
  assert_equal(agent.name, 'code-writer')
  assert_not_nil(agent.description)
  assert_not_nil(agent.allowed_tools)
  assert_not_nil(agent.system_prompt)
  assert_not_nil(agent.filepath)
end)

test('get_agent returns nil for nonexistent agent', function()
  local agent = registry.get_agent('nonexistent')
  assert_nil(agent, 'Should return nil for nonexistent agent')
end)

test('validate_agent returns true for existing agent', function()
  assert_true(registry.validate_agent('code-writer'))
end)

test('validate_agent returns false for nonexistent agent', function()
  assert_true(not registry.validate_agent('nonexistent'))
end)

test('get_agent_prompt returns string', function()
  local prompt = registry.get_agent_prompt('doc-writer')
  assert_not_nil(prompt, 'Should return prompt')
  assert_true(type(prompt) == 'string', 'Prompt should be string')
  assert_true(#prompt > 0, 'Prompt should not be empty')
end)

test('get_agent_prompt returns nil for nonexistent agent', function()
  local prompt = registry.get_agent_prompt('nonexistent')
  assert_nil(prompt, 'Should return nil for nonexistent agent')
end)

test('get_agent_tools returns array', function()
  local tools = registry.get_agent_tools('test-specialist')
  assert_not_nil(tools, 'Should return tools')
  assert_true(type(tools) == 'table', 'Tools should be table')
  assert_true(#tools > 0, 'Should have at least one tool')
end)

test('get_agent_tools returns nil for nonexistent agent', function()
  local tools = registry.get_agent_tools('nonexistent')
  assert_nil(tools, 'Should return nil for nonexistent agent')
end)

test('get_agent_info returns metadata', function()
  local info = registry.get_agent_info('plan-architect')
  assert_not_nil(info, 'Should return info')
  assert_equal(info.name, 'plan-architect')
  assert_not_nil(info.description)
  assert_not_nil(info.allowed_tools)
  assert_not_nil(info.filepath)
end)

test('get_agent_info returns nil for nonexistent agent', function()
  local info = registry.get_agent_info('nonexistent')
  assert_nil(info, 'Should return nil for nonexistent agent')
end)

test('format_task_prompt combines agent and task', function()
  local prompt = registry.format_task_prompt(
    'code-writer',
    'Implement feature X',
    'Files: foo.lua'
  )
  assert_not_nil(prompt, 'Should return prompt')
  assert_true(prompt:find('Task: Implement feature X'), 'Should include task')
  assert_true(prompt:find('foo.lua'), 'Should include context')
end)

test('format_task_prompt works without context', function()
  local prompt = registry.format_task_prompt(
    'code-writer',
    'Implement feature X'
  )
  assert_not_nil(prompt, 'Should return prompt')
  assert_true(prompt:find('Task: Implement feature X'), 'Should include task')
end)

test('format_task_prompt returns nil for nonexistent agent', function()
  local prompt = registry.format_task_prompt('nonexistent', 'Task')
  assert_nil(prompt, 'Should return nil for nonexistent agent')
end)

test('create_task_config returns valid config', function()
  local config = registry.create_task_config(
    'debug-specialist',
    'Investigate bug',
    'Error: validation failing'
  )
  assert_not_nil(config, 'Should return config')
  assert_equal(config.subagent_type, 'general-purpose')
  assert_not_nil(config.description)
  assert_not_nil(config.prompt)
  assert_true(#config.prompt > 0, 'Prompt should not be empty')
end)

test('create_task_config shortens description to 5 words', function()
  local config = registry.create_task_config(
    'code-writer',
    'Implement a very long feature description that exceeds five words',
    'Context'
  )
  assert_not_nil(config)
  local word_count = 0
  for _ in config.description:gmatch('%S+') do
    word_count = word_count + 1
  end
  assert_true(word_count <= 5, 'Description should be 5 words or less, got ' .. word_count)
end)

test('create_task_config returns nil for nonexistent agent', function()
  local config = registry.create_task_config('nonexistent', 'Task', 'Context')
  assert_nil(config, 'Should return nil for nonexistent agent')
end)

test('reload_registry clears cache', function()
  registry.reload_registry()
  local agents = registry.list_agents()
  assert_equal(#agents, 8, 'Should have 8 agents after reload')
end)

test('all agents parse correctly', function()
  local agents = registry.list_agents()
  for _, agent_name in ipairs(agents) do
    local agent = registry.get_agent(agent_name)
    assert_not_nil(agent, 'Agent ' .. agent_name .. ' should load')
    assert_equal(agent.name, agent_name, 'Name should match')
    assert_true(#agent.system_prompt > 0, 'Prompt should not be empty')
    assert_true(type(agent.allowed_tools) == 'table', 'Tools should be table')
  end
end)

test('agents have required frontmatter fields', function()
  local agents = registry.list_agents()
  for _, agent_name in ipairs(agents) do
    local agent = registry.get_agent(agent_name)
    assert_not_nil(agent.description, agent_name .. ' should have description')
    assert_not_nil(agent.allowed_tools, agent_name .. ' should have allowed_tools')
  end
end)

test('project agents take priority over global', function()
  -- All current agents are in project .claude/agents/
  local agent = registry.get_agent('code-writer')
  assert_not_nil(agent)
  assert_true(agent.filepath:find('.config/.claude/agents'),
             'Should load from project directory')
end)

-- Summary
print('\n==================================================')
print('Test Results')
print('==================================================')
print('Passed: ' .. tests_passed)
print('Failed: ' .. tests_failed)
print('Total:  ' .. (tests_passed + tests_failed))

if tests_failed > 0 then
  print('\n✗ SOME TESTS FAILED')
  os.exit(1)
else
  print('\n✓ ALL TESTS PASSED')
  os.exit(0)
end
