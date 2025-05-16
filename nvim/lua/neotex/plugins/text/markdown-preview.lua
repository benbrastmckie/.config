return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  ft = { "markdown" },
  build = "sh -c 'cd app && NODE_ENV=production npx --yes yarn install'",
  init = function()
    -- set to 1, echo preview page url in command line when opening preview page
    vim.g.mkdp_echo_preview_url = 1

    -- custom browser function
    vim.g.mkdp_browserfunc = 'OpenMarkdownPreview'

    -- create the custom open function
    vim.cmd([[
      function! OpenMarkdownPreview(url)
        execute "silent! !brave " . a:url . " &"
      endfunction
    ]])

    -- set to 1, auto open preview page when entering markdown buffer
    vim.g.mkdp_auto_start = 0

    -- preview page title
    vim.g.mkdp_page_title = '「${name}」'

    -- set default theme (dark or light)
    vim.g.mkdp_theme = 'dark'

    -- set to 1, the vim will refresh markdown when save the buffer or
    -- leave from insert mode, default 0 is auto refresh markdown as you edit or
    -- move the cursor
    vim.g.mkdp_refresh_slow = 1

    -- specify browser path
    vim.g.mkdp_path_to_chrome = "brave"

    -- set log level (debug, info, warn, error)
    vim.g.mkdp_log_level = 'debug'
  end,
}
