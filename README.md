# *highlight-current-n*

![](../assets/images/demo.gif)

*[See demo configuration.](#demo-configuration)*

*highlight-current-n* highlights the current `/`, `?` or `*` match
under your cursor when pressing `n` or `N` and gets out of the way afterwards.

## Neovim 0.9+

You may not need this plugin any more if you are using Neovim 0.9+, as it
includes an `CurSearch` highlight group, and a `:nohlsearch` command.

You can replicate something similar to *highlight-current-n* with:

```fennel
;; See https://fennel-lang.org/see to convert from fennel to lua

;; Copy search highlight group definition so we can clear and re-link to it
;; when in different states of searching.
(vim.api.nvim_create_autocmd
  :ColorScheme
  {:callback #(let [search (vim.api.nvim_get_hl 0 {:name :Search})]
                (vim.api.nvim_set_hl 0 :CurSearch {:link :IncSearch})
                (vim.api.nvim_set_hl 0 :SearchCurrentN search)
                (vim.api.nvim_set_hl 0 :Search {:link :SearchCurrentN}))})

(vim.api.nvim_create_autocmd
  :CmdlineEnter
  {:pattern "/,\\?"
   :callback (fn []
               ;; When searching via :/, enable all search highlights
               (set vim.opt.hlsearch true)
               (set vim.opt.incsearch true)
               (vim.api.nvim_set_hl 0 :Search {:link :SearchCurrentN}))})

(vim.api.nvim_create_autocmd
  :CmdlineLeave
  {:pattern "/,\\?"
   :callback (fn []
               ;; When leaving after :/, clear Search highlights (NOT CurSearch).
               ;; May have side effects if plugins link to Search
               (vim.api.nvim_set_hl 0 :Search {})
               ;; turn on hlsearch after the cursor move runs nohlsearch
               ;; Could also use a shared guard flag variable
               (vim.defer_fn #(set vim.opt.hlsearch true) 5))})

(vim.api.nvim_create_autocmd
  [:InsertEnter :CursorMoved]
  ;; Must run :nohlsearch outside of autocmd, see :h autocmd-searchpat
  {:callback #(vim.schedule #(vim.cmd :nohlsearch))})

(fn handle-n-N [key]
  (let [other #(case $1 :n :N :N :n)
        feed #(vim.api.nvim_feedkeys $1 :n true)]
    (case vim.v.searchforward
      0 (feed (other key))
      1 (feed key)))
  ;; Wait a moment, so the cursor moves, the CursorMoved autocmd triggers, then
  ;; we flip hlsearch back on.
  ;; You may prefer to use a flag var instead of defer_fn.
  (vim.defer_fn #(set vim.opt.hlsearch true) 5))

(vim.keymap.set [:n] :n #(handle-n-N :n))
(vim.keymap.set [:n] :N #(handle-n-N :N))
```

## Installation

**Requirements**

- Neovim 0.5

```lua
your_package_manager "rktjmp/highlight-current-n.nvim"
```

## Setup & Usage

**Configuration**

Default options are shown, calling setup is **not** required unless you are
changing an option.

```lua
require("highlight_current_n").setup({
  highlight_group = "IncSearch" -- highlight group name to use for highlight
})
```

See also [demo configuration](#demo-configuration) for important information
regarding highlighting `/` and `?` searches.

**Maps**

*highlight-current-n* provides 2 `<Plug>` keymaps for your use.

*Note: You want to use `nmap`, not `nnoremap` for `<Plug>` mappings.*

**`<Plug>(highlight-current-n-n)`** should be mapped to `n`.

```viml
nmap n <Plug>(highlight-current-n-n)
```

**`<Plug>(highlight-current-n-N)`** should be mapped to `N`.

```viml
nmap N <Plug>(highlight-current-n-N)
```

**Consistent Search Direction** 

To always search "up and down" vs "ahead and back" (as dictated by `/` and
`?`), you can use these mappings:

```lua
local function _1_()
  local hcn = require("highlight_current_n")
  local feedkeys = vim.api.nvim_feedkeys
  local _2_ = vim.v.searchforward
  if (_2_ == 0) then
    return hcn.N()
  elseif (_2_ == 1) then
    return hcn.n()
  else
    return nil
  end
end
vim.keymap.set("n", "n", _1_)

local function _4_()
  local hcn = require("highlight_current_n")
  local feedkeys = vim.api.nvim_feedkeys
  local _5_ = vim.v.searchforward
  if (_5_ == 0) then
    return hcn.n()
  elseif (_5_ == 1) then
    return hcn.N()
  else
    return nil
  end
end
return vim.keymap.set("n", "N", _4_)
```

**Functions**

*highlight-current-n* provides 3 functions, but probably only 1 is useful.

**`require("highlight_current_n").n()`**

Executes `feedkeys(n)` and applies highlight when appropriate. Normally best
run via the provided `<Plug>` mapping.

**`require("highlight_current_n").N()`**

Executes `feedkeys(N)` and applies highlight when appropriate. Normally best
run via the provided `<Plug>` mapping.

**`require("highlight_current_n")["/,?"]()`**

Applies highlight at cursor, most useful when used in combination with the
following autocommand, be careful when escaping `\?` in lua configurations.

```viml
autocmd CmdlineLeave /,\? lua require('highlight_current_n')['/,?']()
```

## Demo Configuration

*highlight-current-n* only provides two maps to show highlights, but the
following configuration may be preferred in real world use, especially the last
`CmdlineLeave` autocommand.

```viml
" Map keys
nmap n <Plug>(highlight-current-n-n)
nmap N <Plug>(highlight-current-n-N)

" If you want the highlighting to take effect in other maps they must
" also be nmaps (or rather, not "nore").
"
" * will search <cword> ahead, but it can be more ergonomic to have *
" simply fill the / register with the current <cword>, which makes future
" commands like cgn "feel better". This effectively does that by performing
" "search ahead <cword> (*), go back to last match (N)".
nmap * *N

" Some QOL autocommands
augroup ClearSearchHL
  autocmd!
  " You may only want to see hlsearch /while/ searching, you can automatically
  " toggle hlsearch with the following autocommands
  autocmd CmdlineEnter /,\? set hlsearch
  autocmd CmdlineLeave /,\? set nohlsearch
  " this will apply similar n|N highlighting to the first search result
  " careful with escaping ? in lua, you may need \\?
  autocmd CmdlineLeave /,\? lua require('highlight_current_n')['/,?']()
augroup END
```

## Issues

*highlight-current-n* works by setting a highlight group at your cursor position
after searching.  This highlight is not "wrap aware", it begins at the start of
the match and extends for `length(search_string)` characters. Sometimes you
may see the the highlight "stick out" past the edge of a wrapped line. This is 
pretty uncommon in my experience but it probably depends on your typical terminal 
and content size
