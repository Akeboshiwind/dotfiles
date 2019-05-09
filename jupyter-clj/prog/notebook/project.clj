(defproject notebook "0.1.0"
  :dependencies [[org.clojure/clojure "1.10.0"]
                 ;; Dynamnic dependencies
                 [com.cemerick/pomegranate "1.1.0"]
                 ;; Echarts
                 [funcool/cuerdas "2.2.0"]
                 ;; Json
                 [cheshire "5.8.1"]]

  :target-path "target/%s"
  :plugins [[lein-jupyter "0.1.16"]])
