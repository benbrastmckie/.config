#\!/bin/bash

# Define the list of files to be deprecated
FILES=(
  "autolist.lua"
  "autopairs.lua"
  "avante.lua"
  "bufferline.lua"
  "colorscheme.lua"
  "comment.lua"
  "firenvim.lua"
  "gitsigns.lua"
  "lean.lua"
  "lectic.lua"
  "local-highlight.lua"
  "lualine.lua"
  "luasnip.lua"
  "markdown-preview.lua"
  "mini.lua"
  "nvim-tree.lua"
  "nvim-web-devicons.lua"
  "sessions.lua"
  "snacks.lua"
  "surround.lua"
  "telescope.lua"
  "toggleterm.lua"
  "treesitter.lua"
  "vimtex.lua"
  "which-key.lua"
  "yanky.lua"
)

# Ensure deprecated directory exists
mkdir -p ./lua/neotex/deprecated

# Move each file to deprecated directory
for file in "${FILES[@]}"; do
  if [ -f "./lua/neotex/plugins/$file" ]; then
    echo "Moving $file to deprecated directory..."
    mv "./lua/neotex/plugins/$file" "./lua/neotex/deprecated/"
  else
    echo "File $file not found, skipping..."
  fi
done

echo "File movement complete."
