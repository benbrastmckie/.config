return {
  'aspeddro/slides.nvim',
  config = function()
    require('slides').setup({
      bin = '/run/current-system/sw/bin/slides', -- path to binary
      fullscreen = true, -- open in fullscreen
    })
  end
}



