local status_ok, configs = pcall(require, "nvim-treesitter.configs")
if not status_ok then
	return
end

configs.setup({
  ensure_installed = {  -- list "all" or a list of languages
    "markdown_inline", 
    "markdown", 
    "lua", 
    "python", 
    "vim", 
    "yaml", 
    "perl", 
    "json", 
    "html", 
    "help", 
    "haskell", 
    "gitignore", 
    "bibtex" 
  },
	ignore_install = { "latex" }, -- List of parsers to ignore installing
	highlight = {
		enable = true, -- false will disable the whole extension
		disable = { "css", "latex" }, -- list of language that will be disabled
    -- additional_vim_regex_highlighting = { "latex", "markdown" },
	},
	autopairs = {
		enable = true,
	},
	indent = { enable = true, disable = { "latex", "python", "css" } },
})
