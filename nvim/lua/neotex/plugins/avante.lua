return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  lazy = false,
  version = false, -- set this to "*" for latest changes, false for releases
  init = function()
    -- Create autocmd for Avante buffer-specific mappings
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "AvanteInput", "Avante" },
      callback = function()
        -- Create buffer-local insert mode mapping for toggle
        vim.api.nvim_buf_set_keymap(0, "i", "<C-t>", "<cmd>AvanteToggle<CR>", { noremap = true, silent = true })
      end
    })
  end,
  opts = {
    provider = "claude",
    auto_suggestions_provider = "claude",
    claude = {
      endpoint = "https://api.anthropic.com",
      model = "claude-3-5-sonnet-20241022",
      temperature = 0,
      max_tokens = 4096,
    },
    dual_boost = {
      enabled = false,
      first_provider = "claude",
      second_provider = "openai",
      prompt = "Based on the two reference outputs below, generate a response that incorporates elements from both but reflects your own judgment and unique perspective. Do not provide any explanation, just give the response directly. Reference Output 1: [{{provider1_output}}], Reference Output 2: [{{provider2_output}}]",
      timeout = 60000,
    },
    behaviour = {
      auto_suggestions = false,
      auto_set_highlight_group = true,
      auto_set_keymaps = false,
      auto_apply_diff_after_generation = false,
      support_paste_from_clipboard = true,
      minimize_diff = true,
    },
    mappings = {
      diff = {
        ours = "o",
        theirs = "t",
        all_theirs = "a",
        both = "b",
        cursor = "c",
        next = "<C-j>",
        prev = "<C-k>",
      },
      suggestion = {
        accept = "<C-y>",
        next = "<C-j>",
        prev = "<C-k>",
        dismiss = "<ESC>",
      },
      jump = {
        next = "n",
        prev = "N",
      },
      submit = {
        normal = "<CR>",
        insert = "<C-l>",
      },
      sidebar = {
        apply_all = "A",
        apply_cursor = "a",
        switch_windows = "<Tab>",
        reverse_switch_windows = "<S-Tab>",
      },
    },
    hints = { enabled = false },
    windows = {
      position = "right",
      wrap = true,
      width = 40,
      sidebar_header = {
        enabled = true,
        align = "left",
        rounded = false,
      },
      input = {
        rounded = true,
        prefix = "󰭹 ",
        height = 8,
      },
      edit = {
        border = "rounded",
        start_insert = true,
      },
      ask = {
        floating = false,
        start_insert = true,
        border = "rounded",
        focus_on_apply = "ours",
      },
    },
    highlights = {
      diff = {
        current = "DiffText",
        incoming = "DiffAdd",
      },
    },
    diff = {
      autojump = true,
      list_opener = "copen",
      override_timeoutlen = 500,
    },
  },
  build = "make",
  dependencies = {
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "hrsh7th/nvim-cmp",
    "nvim-tree/nvim-web-devicons",
    -- "zbirenbaum/copilot.lua",
    {
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          use_absolute_path = true,
        },
      },
    },
    {
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}
