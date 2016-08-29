(ns elixoids.ship
  (:require [gniazdo.core :as ws]
            [clojure.core.async :as a :refer [chan <! >! put! close! sliding-buffer]]
            [clojure.data.json :as js])
  (:use [elixoids.miner :only [frame-delta vector-intersects? polar-to-cartesian]]))


(defn parse-json-str [s]
  "Return string s containing a JSON object as a map,
   or a map with a parser error if not JSON"
  (try
    (js/read-str s :key-fn keyword)
     (catch Exception e
       {:err e})))

(defn save-time-received [state]
  "Append the time that the message was received to the map"
  (assoc state :t_ms (System/currentTimeMillis)))

(def receive-state (comp save-time-received parse-json-str))

;(ws/send-msg socket "hello")

(defn ship-socket [ship-name]
  (let [url (clojure.string/join "/" ["ws://localhost:8065" "ship" ship-name])
        transmit (chan 8)
        out (a/chan (a/sliding-buffer 1) )
        socket (ws/connect url
                           :on-receive #(a/put! out (receive-state %))
                           :on-close #(a/close! out)
                           :on-error #(a/close! out))]
    (a/go-loop []
      (if-let [m (<! transmit)]
        (do
          (ws/send-msg socket (js/write-str m))
          (recur))
        (ws/close socket)))
    [out transmit]))


(defn empty-state []
  (-> {}
      (assoc :rocks [])
      (save-time-received)))

(defn echo-state [ship-name]
  (let [[out transmit] (elixoids.ship/ship-socket ship-name)]
   (a/go-loop []
     (when-let [e (a/<! out)]
       (clojure.pprint/pprint e)
       (clojure.core.async/close! transmit)))))

(defn turn-ship [ch ^Double theta]
  "Instruct the ship on given channel to turn towards the given angle"
  (a/put! ch {:theta theta}))

(defn fire [ch]
  (a/put! ch {:fire true}))

(defn smallest-theta [as]
  (->> as
       (map :theta)
       (sort-by :radius)
       (last)))

(defn echo-state-fire [ship-name]
  (let [[out transmit] (elixoids.ship/ship-socket ship-name)]
    (a/go-loop [prev-state (empty-state)]
      (when-let [e (a/<! out)]
        (let [delta (frame-delta prev-state e)
              los (polar-to-cartesian (:theta e) 100)]
          (when (vector-intersects? los delta)
              (clojure.pprint/pprint los)
              (fire transmit)
              (println "Fires"))
          (when-let [theta (smallest-theta delta)]
            (println theta)
            (turn-ship transmit theta))
          (clojure.pprint/pprint delta)
          (recur e))))))
        ;(clojure.core.async/close! transmit)))))
