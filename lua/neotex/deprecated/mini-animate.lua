return {
  "echasnovski/mini.animate",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    draw = {
      -- Delay (in ms) between event and start of drawing scope indicator
      delay = 100,
      priority = 2,
    },
    options = {
      -- Type of scope's border: which line(s) with smaller indent to
      -- categorize as border. Can be one of: 'both', 'top', 'bottom', 'none'.
      border = 'both',

      -- Whether to use cursor column when computing reference indent.
      -- Useful to see incremental scopes with horizontal cursor movements.
      indent_at_cursor = true,

      -- Whether to first check input line to be a border of adjacent scope.
      -- Use it if you want to place cursor on function header to get scope of
      -- its body.
      try_as_border = true,
    },
    -- Which character to use for drawing scope indicator
    symbol = '╎',
  end

  -- opts = function()
  --   -- don't use animate when scrolling with the mouse
  --   local mouse_scrolled = false
  --   for _, scroll in ipairs({ "Up", "Down" }) do
  --     local key = "<ScrollWheel" .. scroll .. ">"
  --     vim.keymap.set({ "", "i" }, key, function()
  --       mouse_scrolled = true
  --       return key
  --     end, { expr = true })
  --   end
  --
  --   local animate = require("mini.animate")
  --   return {
  --     resize = {
  --       timing = animate.gen_timing.linear({ duration = 100, unit = "total" }),
  --     },
  --     scroll = {
  --       timing = animate.gen_timing.linear({ duration = 150, unit = "total" }),
  --       subscroll = animate.gen_subscroll.equal({
  --         predicate = function(total_scroll)
  --           if mouse_scrolled then
  --             mouse_scrolled = false
  --             return false
  --           end
  --           return total_scroll > 1
  --         end,
  --       }),
  --     },
  --   }
  -- end,
}
