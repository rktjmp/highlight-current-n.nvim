;; get current search from "/
;; note, has particular form for * searches

;; clear highlight
;; get current cursor pos
;; feed key n
;; get current cursor pos, did change?
;; apply highlight this?

;;; TODO: should have a "no feedkeys" version that can be called after /,? cmdleave
(macro api  [call ...]
  (let [call (.. :nvim_ (string.gsub (tostring call) "-" "_"))]
    `((. vim.api ,call) ,...)))

(fn highlight-current [pos-row pos-col]
  ; * searches add word bounds to query but make length wrong
  (local query (-> (vim.fn.getreg "/")
                   (string.gsub "\\<" "")
                   (string.gsub "\\>" "")
                   (string.gsub "\\." "."))) ;; maybe over zealous
  (local opts {:virt_text [[query "IncSearch"]]
               :virt_text_pos :overlay
               :end_line (- pos-row 1)
               :end_col (+ pos-col (length query))})
  (local ns-id (api create-namespace ""))
  (api buf-set-extmark 0 ns-id (- pos-row 1) pos-col opts)
  (local clear-cmd (string.format 
                     ":lua vim.api.nvim_buf_clear_namespace(0, %d, 0, -1)"
                     ns-id))
  (local cmds ["augroup HighlightEn"
               ; Don't ! clear existing autocmds
               ; One of these will fire, clear the highlight then the rest will remain
               ; until the event. This doesn't really seem to matter as clearing a cleared
               ; namespace has no effect.
               ; The namespace could be pingpong'd between a few values so stop anonymous
               ; spawning but that might end up causing issues in some mappings?
               (.. "autocmd CursorMoved * ++once " clear-cmd)
               (.. "autocmd InsertEnter * ++once " clear-cmd)
               (.. "autocmd CmdlineEnter * ++once " clear-cmd)
               "augroup END"])
  (vim.cmd (table.concat cmds "\n")))

(fn feedkey [key]
  (local [before-row before-col] (api win-get-cursor 0))
  (api feedkeys key :ni false)
  (vim.schedule
    (fn []
      ;; only when we've moved, so we don't lay previous match string over
      ;; "no match found" errors
      (local [after-row after-col] (api win-get-cursor 0))
      (if (or (~= before-row after-row) (~= before-col after-col))
        (highlight-current after-row after-col)))))

(fn searched []
  (local [before-row before-col] (api win-get-cursor 0))
  (vim.schedule
    (fn []
      ;; this does make executing /key, / (repeat search) for "|key" at |, wont
      ;; highlight. searching /key for "|key" at | will work.
      (local [after-row after-col] (api win-get-cursor 0))
      (if (or (~= before-row after-row) (~= before-col after-col))
        (highlight-current after-row after-col)))))

{:n #(feedkey :n)
 :N #(feedkey :N)
 "/,?" #(searched)}
