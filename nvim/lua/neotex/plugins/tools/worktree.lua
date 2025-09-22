-----------------------------------------------------------
-- Git Worktree Plugin Configuration
-- 
-- Provides git worktree management with Telescope integration
-- for managing multiple Claude Code sessions in isolated branches
-----------------------------------------------------------

return {
  "ThePrimeagen/git-worktree.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  -- No keys defined - this plugin is used by claude-worktree.lua
  keys = {},
  config = function()
    local Worktree = require("git-worktree")
    local notify = require("neotex.util.notifications")
    
    -- Configure worktree behavior
    Worktree.setup({
      change_directory_command = "tcd",  -- Tab-local directory change
      update_on_change = true,           -- Update NvimTree/neo-tree
      update_on_change_command = "e .",  -- Refresh explorer
      clearjumps_on_change = true,       -- Clear jump list on switch
      autopush = false,                  -- Don't auto-push branches
    })
    
    -- Load Telescope extension first (but we'll override the picker)
    require("telescope").load_extension("git_worktree")
    
    -- Create our own worktree picker with proper error handling
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local Job = require("plenary.job")
    
    -- Custom function to list worktrees
    local function get_worktrees()
      local result = vim.fn.systemlist("git worktree list")
      local worktrees = {}
      
      for _, line in ipairs(result) do
        local path, commit, branch = line:match("^(.-)%s+(%S+)%s+%[(.+)%]")
        -- Exclude main worktree (ones without feature/bugfix/etc prefix)
        if path and branch and not branch:match("^master$") and not branch:match("^main$") and branch:match("/") then
          -- Debug output to messages
          print(string.format("Found worktree: path='%s', branch='%s'", path, branch))
          
          table.insert(worktrees, {
            path = path,
            sha = commit,
            branch = branch,
            display = string.format("%-30s %s", branch, path)
          })
        end
      end
      
      return worktrees
    end
    
    -- Custom create worktree action (matching <leader>aw interface)
    local function create_worktree_action(prompt_bufnr)
      actions.close(prompt_bufnr)
      
      -- Use vim.fn.input for name (command line at bottom)
      local name = vim.fn.input("Feature name: ")
      if name == "" then
        notify.editor("Cancelled", notify.categories.WARNING, {})
        return
      end
      
      -- Use vim.ui.select for type (picker in middle of screen)
      local worktree_types = { "feature", "bugfix", "hotfix", "refactor", "experiment", "docs" }
      
      vim.ui.select(worktree_types, {
        prompt = "Select type:",
        format_item = function(item)
          -- Capitalize first letter like <leader>aw does
          return item:sub(1,1):upper() .. item:sub(2)
        end,
      }, function(choice_type)
        if not choice_type then
          notify.editor("Cancelled", notify.categories.WARNING, {})
          return
        end
        
        local branch = choice_type .. "/" .. name
        local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
        local worktree_path = vim.fn.getcwd():match("(.*/)[^/]+$") .. project_name .. "-" .. choice_type .. "-" .. name
        
        -- Check if worktree already exists (like <leader>aw does)
        local existing = vim.fn.system("git worktree list | grep " .. branch)
        if existing ~= "" then
          notify.editor("Worktree already exists: " .. branch, notify.categories.ERROR, {})
          return
        end
        
        -- Create the worktree
        notify.editor("Creating worktree: " .. worktree_path, notify.categories.STATUS, {})
        local args = { "worktree", "add", worktree_path, "-b", branch }
        
        Job:new({
          command = "git",
          args = args,
          on_exit = function(j, return_val)
            vim.schedule(function()
              if return_val == 0 then
                -- Create CLAUDE.md file
                local context_file = worktree_path .. "/CLAUDE.md"
                local content = {
                  "# Task: " .. name,
                  "",
                  "## Metadata",
                  "- **Type**: " .. choice_type,
                  "- **Branch**: " .. branch,
                  "- **Created**: " .. os.date("%Y-%m-%d %H:%M"),
                  "- **Worktree**: " .. worktree_path,
                  "",
                  "## Objective",
                  "[Describe the main goal of this " .. choice_type .. "]",
                  "",
                  "## Acceptance Criteria",
                  "- [ ] Implementation complete",
                  "- [ ] Tests passing",
                  "- [ ] Documentation updated",
                  "",
                  "## Notes",
                  "[Any relevant notes or links]",
                }
                
                vim.fn.writefile(content, context_file)
                
                -- Spawn WezTerm tab for the new worktree (like <leader>aw does)
                local wezterm_cmd = string.format(
                  "wezterm cli spawn --cwd '%s' -- nvim CLAUDE.md",
                  worktree_path
                )
                local wezterm_result = vim.fn.system(wezterm_cmd)
                local pane_id = wezterm_result:match("(%d+)")
                
                if pane_id then
                  -- Activate the new pane
                  vim.fn.system("wezterm cli activate-pane --pane-id " .. pane_id)
                  notify.editor(
                    string.format("Created %s worktree: %s", choice_type, name),
                    notify.categories.USER_ACTION,
                    { worktree_path = worktree_path, branch = branch, type = choice_type }
                  )
                else
                  -- Fallback: switch in current nvim
                  Worktree.switch_worktree(worktree_path)
                  notify.editor("Switched to worktree: " .. name, notify.categories.STATUS, {})
                end
              else
                local stderr = table.concat(j:stderr_result(), "\n")
                notify.editor(
                  string.format("Failed to create worktree: %s", stderr:match("fatal: (.+)") or stderr),
                  notify.categories.ERROR,
                  { branch = branch, stderr = stderr }
                )
              end
            end)
          end,
        }):start()
      end)
    end
    
    -- Custom delete action with graceful error handling
    local function delete_worktree_action(prompt_bufnr, force)
      local selection = action_state.get_selected_entry()
      if not selection then return end
      
      actions.close(prompt_bufnr)
      
      local worktree_path = selection.path
      local branch_name = selection.branch
      
      -- Close all buffers from the worktree before deletion to prevent GitSigns errors
      local buffers = vim.api.nvim_list_bufs()
      for _, buf in ipairs(buffers) do
        if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
          local bufname = vim.api.nvim_buf_get_name(buf)
          -- Check if buffer belongs to the worktree being deleted
          if bufname ~= "" and bufname:match("^" .. vim.pesc(worktree_path)) then
            -- Try to detach gitsigns first
            pcall(function()
              require('gitsigns').detach(buf)
            end)
            -- Delete the buffer
            pcall(vim.api.nvim_buf_delete, buf, { force = true })
          end
        end
      end
      
      -- Small delay to ensure buffers are closed
      vim.defer_fn(function()
        -- IMPORTANT: Get the main directory BEFORE deleting the worktree
        -- Otherwise git commands will fail with getcwd errors
        local parent_dir = vim.fn.fnamemodify(worktree_path, ':h')
        print(string.format("Debug: Parent directory of worktree: '%s'", parent_dir))
        
        -- Change to parent directory if we're currently in the worktree being deleted
        local current_dir = vim.fn.getcwd()
        if current_dir:match("^" .. vim.pesc(worktree_path)) then
          print(string.format("Debug: Currently in worktree being deleted, changing to parent dir: '%s'", parent_dir))
          vim.cmd("cd " .. vim.fn.fnameescape(parent_dir))
        end
        
        -- Use git worktree remove directly
        local args = { "worktree", "remove", worktree_path }
        if force then
          table.insert(args, 3, "--force")
        end
        
        Job:new({
          command = "git",
          args = args,
          cwd = parent_dir,  -- Execute from parent directory to avoid getcwd errors
          on_exit = function(j, return_val)
          vim.schedule(function()
            if return_val == 0 then
              -- Successfully deleted worktree, now delete the branch
              if branch_name and branch_name ~= "" then
                -- Clean up branch name (remove any potential formatting from git worktree list)
                local clean_branch = branch_name:gsub("^%[", ""):gsub("%]$", "")
                
                -- Since we're already in parent_dir, we can use it directly for branch deletion
                print(string.format("Debug: Deleting branch '%s' from directory '%s'", clean_branch, parent_dir))
                
                -- Delete the branch (with explicit cwd to parent directory)
                Job:new({
                  command = "git",
                  args = { "branch", "-D", clean_branch },
                  cwd = parent_dir,  -- Use parent directory where the main git repo should be
                  on_exit = function(branch_job, branch_return_val)
                    vim.schedule(function()
                      if branch_return_val == 0 then
                        notify.editor(
                          string.format("Deleted worktree and branch: %s", clean_branch),
                          notify.categories.USER_ACTION,
                          { worktree_path = worktree_path, branch = clean_branch }
                        )
                      else
                        local stderr = table.concat(branch_job:stderr_result(), "\n")
                        -- Debug output to messages
                        print(string.format("Debug: Branch deletion failed - branch='%s', stderr='%s', cwd='%s'", 
                          clean_branch, stderr, parent_dir))
                        
                        -- User-facing warning
                        notify.editor(
                          string.format("Deleted worktree, but couldn't delete branch '%s': %s", clean_branch, stderr),
                          notify.categories.WARNING,
                          { branch = clean_branch }
                        )
                      end
                    end)
                  end,
                }):start()
              else
                notify.editor(
                  string.format("Worktree deleted: %s", worktree_path),
                  notify.categories.USER_ACTION,
                  { worktree_path = worktree_path }
                )
              end
              -- Refresh the list if needed
              Worktree.on_tree_change(Worktree.Operations.Delete, { path = worktree_path })
            else
              local stderr = table.concat(j:stderr_result(), "\n")
              if stderr:match("contains modified or untracked files") then
                notify.editor(
                  "Worktree has uncommitted changes. Use <C-f> to force delete, or save/stash changes first.",
                  notify.categories.WARNING,
                  { worktree_path = worktree_path, branch = branch_name }
                )
              elseif stderr:match("is a main working tree") then
                notify.editor(
                  "Cannot delete the main working tree",
                  notify.categories.ERROR,
                  { worktree_path = worktree_path }
                )
              else
                local msg = stderr:match("fatal: (.+)") or stderr
                notify.editor(
                  string.format("Failed to delete worktree: %s", msg),
                  notify.categories.ERROR,
                  { worktree_path = worktree_path, stderr = stderr }
                )
              end
            end
          end)
        end,
      }):start()
      end, 100)  -- 100ms delay to ensure buffers are closed
    end
    
    -- Custom worktree picker
    _G.custom_git_worktree_picker = function()
      local worktrees = get_worktrees()
      
      pickers.new({}, {
        prompt_title = "Worktrees | <CR>: Switch | <C-n>: New | <C-d>: Delete | <C-f>: Force",
        finder = finders.new_table({
          results = worktrees,
          entry_maker = function(entry)
            return {
              value = entry,
              display = entry.display,
              ordinal = entry.branch,
              path = entry.path,
              branch = entry.branch
            }
          end,
        }),
        sorter = conf.generic_sorter({}),
        previewer = false,
        layout_config = {
          width = 0.7,
          height = 0.5,
        },
        attach_mappings = function(_, map)
          -- Switch to worktree on select
          actions.select_default:replace(function(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if selection then
              Worktree.switch_worktree(selection.path)
            end
          end)
          
          -- Create new worktree with C-n
          map("i", "<C-n>", function(prompt_bufnr)
            create_worktree_action(prompt_bufnr)
          end)
          map("n", "<C-n>", function(prompt_bufnr)
            create_worktree_action(prompt_bufnr)
          end)
          
          -- Delete worktree with C-d
          map("i", "<C-d>", function(prompt_bufnr)
            delete_worktree_action(prompt_bufnr, false)
          end)
          map("n", "<C-d>", function(prompt_bufnr)
            delete_worktree_action(prompt_bufnr, false)
          end)
          
          -- Force delete with C-f
          map("i", "<C-f>", function(prompt_bufnr)
            delete_worktree_action(prompt_bufnr, true)
          end)
          map("n", "<C-f>", function(prompt_bufnr)
            delete_worktree_action(prompt_bufnr, true)
          end)
          
          return true
        end,
      }):find()
    end
    
    -- Hook: Auto-create CLAUDE.md on new worktree
    Worktree.on_tree_change(function(op, metadata)
      if op == Worktree.Operations.Create then
        local context_file = metadata.path .. "/CLAUDE.md"
        if vim.fn.filereadable(context_file) == 0 then
          -- Parse branch type and name
          local branch = metadata.branch
          local type = branch:match("^(%w+)/") or "feature"
          local name = branch:match("/(.+)$") or branch
          
          -- Create context content
          local content = {
            "# Task: " .. name,
            "",
            "## Metadata",
            "- **Type**: " .. type,
            "- **Branch**: " .. branch,
            "- **Created**: " .. os.date("%Y-%m-%d %H:%M"),
            "- **Worktree**: " .. metadata.path,
            "",
            "## Objective",
            "[Describe the main goal of this work]",
            "",
            "## Context",
            "- Parent project: " .. metadata.upstream,
            "- Working in isolated worktree",
            "",
            "## Acceptance Criteria",
            "- [ ] Implementation complete",
            "- [ ] Tests passing",
            "- [ ] Documentation updated",
            "",
            "## Notes",
            "[Any relevant notes or links]",
          }
          
          vim.fn.writefile(content, context_file)
          notify.editor("Created worktree context file: CLAUDE.md", notify.categories.USER_ACTION, {
            file = context_file,
            worktree = metadata.path,
            branch = metadata.branch
          })
        end
      end
    end)
  end,
}