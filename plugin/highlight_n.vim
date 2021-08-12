nnoremap <Plug>(highlight-match-under-cursor-n)
      \ :lua require("highlight_n").n()<cr>

nnoremap <Plug>(highlight-match-under-cursor-N)
      \ :lua require("highlight_n").N()<cr>

nnoremap <Plug>(highlight-match-under-cursor-search)
      \ :lua require("highlight_n")["/,?"]()<cr>
