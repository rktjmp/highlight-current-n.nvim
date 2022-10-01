




 local config = {highlight_group = "IncSearch"}

 local function setup(opts)
 for k, v in pairs(opts) do
 config[k] = v end return nil end

 local function highlight_group_name()
 return config.highlight_group end

 local function highlight_current(buf, pos_row, pos_col)


 local query = vim.fn.getreg("/")
 local line = (vim.api.nvim_buf_get_lines(buf, (pos_row - 1), pos_row, false))[1]

 local matched_text = vim.fn.matchstr(line, query)
 local ext_mark_opts = {virt_text = {{matched_text, highlight_group_name()}}, virt_text_pos = "overlay", end_line = (pos_row - 1), end_col = (pos_col + #matched_text)} local ns_id = vim.api.nvim_create_namespace("")




 local clear_ns_cmd = string.format((":lua" .. "  if vim.fn.bufexists(%d) == 1 then" .. "    vim.api.nvim_buf_clear_namespace(%d, %d, 0, -1)" .. "  end"), buf, buf, ns_id)







 local augroup_cmds = table.concat({"augroup HighlightCurrentN", ("autocmd CursorMoved * ++once " .. clear_ns_cmd), ("autocmd InsertEnter * ++once " .. clear_ns_cmd), ("autocmd CmdlineEnter * ++once " .. clear_ns_cmd), "augroup END"}, "\n") vim.api.nvim_buf_set_extmark(buf, ns_id, (pos_row - 1), pos_col, ext_mark_opts)















 return vim.cmd(augroup_cmds) end

 local function feedkey(key) local win = vim.api.nvim_get_current_win() local buf = vim.api.nvim_get_current_buf()









 local before_err = vim.v.errmsg local maybe_highlight
 local function _1_() if (before_err == vim.v.errmsg) then
 local _let_2_ = vim.api.nvim_win_get_cursor(win) local row = _let_2_[1] local col = _let_2_[2]
 return highlight_current(buf, row, col) else return nil end end maybe_highlight = _1_ vim.api.nvim_feedkeys(key, "ni", false)

 return vim.schedule(maybe_highlight) end

 local function searched() local win = vim.api.nvim_get_current_win() local buf = vim.api.nvim_get_current_buf()


 local _let_4_ = vim.api.nvim_win_get_cursor(win) local before_row = _let_4_[1] local before_col = _let_4_[2] local maybe_highlight







 local function _5_() local _let_6_ = vim.api.nvim_win_get_cursor(win) local after_row = _let_6_[1] local after_col = _let_6_[2]
 if ((before_row ~= after_row) or (before_col ~= after_col)) then

 return highlight_current(buf, after_row, after_col) else return nil end end maybe_highlight = _5_
 return vim.schedule(maybe_highlight) end

 local function _8_() return feedkey("n") end
 local function _9_() return feedkey("N") end
 local function _10_() return searched() end return {n = _8_, N = _9_, ["/,?"] = _10_, setup = setup}