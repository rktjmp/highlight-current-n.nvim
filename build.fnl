(let [{: build} (require :hotpot.api.make)]
  (build "./fnl"
    "(.+)/fnl/(.+)" (fn [r p {: join-path}]
                      (join-path r :lua p))))
