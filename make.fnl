(let [{: build} (require :hotpot.api.make)]
  (build "./fnl" {:force? true}
    "fnl/(.+)" (fn [p {: join-path}]
                 (join-path "./lua" p)))
  (values ""))
