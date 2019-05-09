(ns clojupyter.echarts
  (:require [clojupyter.misc.display :as display]
            [cheshire.core :as json]
            [cuerdas.core :as str]))


(defn init []
  (let [code "
require.config({
  paths: {
    echarts: 'https://cdnjs.cloudflare.com/ajax/libs/echarts/4.0.4/echarts-en'
  }
});"]
    (display/hiccup-html
     [:div [:script code]])))


(defn plot [{:keys [width height]
             :or   {width 900 height 400}
             :as   opts}]
  (let [id (str (java.util.UUID/randomUUID))
        code (str/format "
require(['echarts'], function(echarts) {
    var chart = echarts.init(document.getElementById('$id'));
    chart.setOption($opts)
});"
                         {:id id :opts (json/generate-string (-> opts (dissoc :width) (dissoc :height))
                                                             {:key-fn str/camel})})]
    (display/hiccup-html
     [:div [:div {:id id :style (str/format "width:%spx; height:%spx"
                                            width height)}]
      [:script code]])))
