return {
  'tzachar/local-highlight.nvim',
  config = function()
    require('local-highlight').setup({
      -- file_types = {'python', 'cpp'}, -- If this is given only attach to this
      -- OR attach to every filetype except:
      disable_file_types = {},
      -- hlgroup = 'Visual', -- change highlight color to value given in table found by running :highlight
      -- hlgroup = 'Question', -- change highlight color to value given in table found by running :highlight
      hlgroup = 'Pmenu', -- change highlight color to value given in table found by running :highlight
      cw_hlgroup = nil,
      insert_mode = false,
    })
  end
}
