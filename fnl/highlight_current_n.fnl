(macro api  [call ...]
  (let [call (.. :nvim_ (string.gsub (tostring call) "-" "_"))]
    `((. vim.api ,call) ,...)))

(macro schedule [...]
  `(vim.schedule (fn [] ,...)))

(local config {:highlight_group "IncSearch"})

(fn setup [opts]
  (each [k v (pairs opts)]
         (tset config k v)))

(fn highlight-group-name []
  config.highlight_group)

(fn highlight-current [buf pos-row pos-col]
  ; Applies a ext-mark highlight to mimic the current match text
  ; and sets up autocommands to clear that ext-mark on some conditions.

  ; get matched text
  (local query (vim.fn.getreg "/"))
  (local line (. (api buf-get-lines buf (- pos-row 1) pos-row false) 1))
  (local matched-text (vim.fn.matchstr line query))

  ; apply highlight mask
  (local opts {:virt_text [[matched-text (highlight-group-name)]]
               :virt_text_pos :overlay
               :end_line (- pos-row 1)
               :end_col (+ pos-col (length matched-text))})
  (local ns-id (api create-namespace ""))
  (api buf-set-extmark buf ns-id (- pos-row 1) pos-col opts)

  ; setup automatic clearing
  (local clear-cmd (string.format 
                     ":lua vim.api.nvim_buf_clear_namespace(%d, %d, 0, -1)"
                     buf ns-id))
  (local cmds ["augroup HighlightCurrentN"
               ; Don't ! clear existing autocmds One of these will fire, clear
               ; the highlight then the rest will remain until the event. This
               ; doesn't really seem to matter as clearing a cleared namespace
               ; has no effect.  The namespace could be pingpong'd between a
               ; few values so stop anonymous spawning but that might end up
               ; causing issues in some mappings?
               (.. "autocmd CursorMoved * ++once " clear-cmd)
               (.. "autocmd InsertEnter * ++once " clear-cmd)
               (.. "autocmd CmdlineEnter * ++once " clear-cmd)
               "augroup END"])
  (vim.cmd (table.concat cmds "\n")))

(fn feedkey [key]
  (local win (api get-current-win))
  (local buf (api get-current-buf))
  ; We track the error message before and after we execute a search, otherwise
  ; "/nomatch" "n" will output "nomatch" at the cursor.
  ;
  ; Tracking cursor-position changes *would* avoid this too, save for "*" on a
  ; word with one match (being the current word), which causes no cursor change
  ; (well, it does, but it seems to be after or before our schedule, probably
  ; before with "*" shifting the cursor to the start of the cword). 
  (local before-err vim.v.errmsg)
  (api feedkeys key :ni false)
  (schedule 
    (when (= before-err vim.v.errmsg)
      (local [row col] (api win-get-cursor win))
      (highlight-current buf row col))))

(fn searched []
  (local win (api get-current-win))
  (local buf (api get-current-buf))
  (local [before-row before-col] (api win-get-cursor win))
  (schedule
    ; this does make executing /key, / (repeat search) for "|key" at |, not
    ; highlight. searching /key for "|key" at | will work.  probably there is
    ; some way to get the last command argument, check for "/" with no args
    ; and force the highlight (only if current pos = start of last search
    ; register...?) Lot of work for probably a 0.1% pain point.
    (local [after-row after-col] (api win-get-cursor win))
    (if (or (~= before-row after-row)
            (~= before-col after-col))
      (highlight-current buf after-row after-col))))

{:n #(feedkey :n)
 :N #(feedkey :N)
 "/,?" #(searched)
 : setup}
