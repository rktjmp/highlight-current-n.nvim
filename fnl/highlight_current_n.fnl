(macro api  [call ...]
  ;; vanity api access because i cant help myself
  (let [call (.. :nvim_ (string.gsub (tostring call) "-" "_"))]
    `((. vim.api ,call) ,...)))

(local config {:highlight_group "IncSearch"})

(fn setup [opts]
  (each [k v (pairs opts)]
    (tset config k v)))

(fn highlight-group-name []
  config.highlight_group)

(fn highlight-current [buf pos-row pos-col]
  ;; Applies a ext-mark highlight to mimic the current match text
  ;; and sets up autocommands to clear that ext-mark on some conditions.
  (let [query (vim.fn.getreg "/")
        line (-> (api buf-get-lines buf (- pos-row 1) pos-row false)
                 (. 1))
        matched-text (vim.fn.matchstr line query)
        ext-mark-opts {:virt_text [[matched-text (highlight-group-name)]]
                       :virt_text_pos :overlay
                       :end_line (- pos-row 1)
                       :end_col (+ pos-col (length matched-text))}
        ns-id (api create-namespace "")
        clear-ns-cmd (-> (.. ":lua"
                             ;; :PackerSync -> /search -> q "invalid buf id", so check
                             ;; it exists before we run possibly revisit this with a
                             ;; nicer solution at some point...
                             "  if vim.fn.bufexists(%d) == 1 then"
                             "    vim.api.nvim_buf_clear_namespace(%d, %d, 0, -1)"
                             "  end")
                         (string.format buf buf ns-id))
        augroup-cmds (-> ["augroup HighlightCurrentN"
                          ;; Don't `!` clear existing autocmds.
                          ;; One of these will fire, clear the highlight then
                          ;; the rest will remain until the event.
                          ;; This doesn't really seem to matter as clearing a
                          ;; cleared namespace has no effect. The namespace
                          ;; could be pingpong'd between a few values so stop
                          ;; anonymous spawning but that might end up causing
                          ;; issues in some mappings?
                          (.. "autocmd CursorMoved * ++once " clear-ns-cmd)
                          (.. "autocmd InsertEnter * ++once " clear-ns-cmd)
                          (.. "autocmd CmdlineEnter * ++once " clear-ns-cmd)
                          "augroup END"]
                         (table.concat "\n"))]
    ;; apply highlight mask and enable autoclear
    (api buf-set-extmark buf ns-id (- pos-row 1) pos-col ext-mark-opts)
    (vim.cmd augroup-cmds)))

(fn feedkey [key]
  (let [win (api get-current-win)
        buf (api get-current-buf)
        ;; We track the error message before and after we execute a search, otherwise
        ;; "/nomatch" "n" will output "nomatch" at the cursor.
        ;;
        ;; Tracking cursor-position changes *would* avoid this too, save for "*" on a
        ;; word with one match (being the current word), which causes no cursor change
        ;; (well, it does, but it seems to be after or before our schedule, probably
        ;; before with "*" shifting the cursor to the start of the cword).
        before-err vim.v.errmsg
        maybe-highlight #(when (= before-err vim.v.errmsg)
                           (let [[row col] (api win-get-cursor win)]
                             (highlight-current buf row col)))]
    (api feedkeys key :ni false)
    (vim.schedule maybe-highlight)))

(fn searched []
  (let [win (api get-current-win)
        buf (api get-current-buf)
        [before-row before-col] (api win-get-cursor win)
        ;; This does make executing `/key`, `/` (repeat search) for "|key" at | (cursor)
        ;; fail to highlight.
        ;; Highlight searching `/key` for "|key" at | will work.
        ;; Probably there is some way to get the last command argument, check for
        ;; "/" with no args and force the highlight, only if current pos = start
        ;; of last search register...? Lot of work for probably a 0.1% pain
        ;; point.
        maybe-highlight #(let [[after-row after-col] (api win-get-cursor win)]
                           (if (or (~= before-row after-row)
                                   (~= before-col after-col))
                             (highlight-current buf after-row after-col)))]
    (vim.schedule maybe-highlight)))

{:n #(feedkey :n)
 :N #(feedkey :N)
 "/,?" #(searched)
 : setup}
