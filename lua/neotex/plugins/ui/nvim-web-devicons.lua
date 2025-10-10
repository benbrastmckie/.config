return {
  "nvim-tree/nvim-web-devicons",
  config = function()
    require("nvim-web-devicons").setup({
      override = {
        -- Existing
        gql = {
          icon = "",
          color = "#e535ab",
          cterm_color = "199",
          name = "GraphQL",
        },
        -- Enhanced: Common filetype icons
        ts = {
          icon = "",
          color = "#519aba",
          name = "TypeScript",
        },
        tsx = {
          icon = "",
          color = "#519aba",
          name = "TypeScriptReact",
        },
        rs = {
          icon = "",
          color = "#dea584",
          name = "Rust",
        },
        go = {
          icon = "",
          color = "#519aba",
          name = "Go",
        },
        yaml = {
          icon = "",
          color = "#6d8086",
          name = "Yaml",
        },
        toml = {
          icon = "",
          color = "#6d8086",
          name = "Toml",
        },
        dockerfile = {
          icon = "",
          color = "#458ee6",
          name = "Dockerfile",
        },
        [".env"] = {
          icon = "",
          color = "#faf743",
          name = "DotEnv",
        },
      },
    })
  end,
}
