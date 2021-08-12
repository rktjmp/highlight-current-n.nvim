# Highlight Current N

![](../assets/images/demo.gif)

*[See demo configuration.](#demo-configuration)*

*highlight-current-n* highlights the current `/`, `?` or `*` match
under your cursor when pressing `n` or `N` and gets out of the way afterwards.

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
