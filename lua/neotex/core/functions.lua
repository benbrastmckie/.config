function SearchWordUnderCursor()
    local word = vim.fn.expand('<cword>')
    require('telescope.builtin').live_grep({ default_text = word })
end
