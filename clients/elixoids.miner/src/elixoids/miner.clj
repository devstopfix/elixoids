(ns elixoids.miner)

; Record returned by ship websocket
; id, theta, radius, distance
; [3, 0.4822331855160187, 120.0, 1867.3]
(defstruct AsteroidRecord :id :theta :radius :distance )

; Vectors are stored as a vector [x y]

(defn sub [& vectors]
  "Subtract two or more vectors of equal size, right to left"
  {:pre [(apply == (map count vectors))]}
  (->
    (apply map - vectors)
    vec))

(defn dot-product [& matrix]
  "Calculate the dot-product of two or more equal size vectors"
  {:pre [(apply == (map count matrix))]}
  (apply + (apply map * matrix)))

(def negative
  "Negate a number"
  (partial * -1))

(defn reverse-vector [v]
  "e.g. East [1 0] -> West [-1 0]"
  (map negative v))

; Polar

(defn polar-to-cartesian [theta d]
  "Convert polar vector to (theta, d) to cartesian vector [x y]"
  [(* d (Math/cos theta))
   (* d (Math/sin theta))])

; Asteroids

(defn asteroid-position [a]
  (let [pos (polar-to-cartesian (:theta a) (:distance a))]
    (assoc a :position pos)))

(defn watch [as1 as2]
  "Watch asteroids that appear in both states,
   and return a list of them.
   Input is two maps of id -> asteroid"
  (reduce-kv
    (fn [results id a1]
      (if-let [a2 (get as2 id)]
        (->>
          (sub (:position a1) (:position a2))
          (assoc a2 :velocity)
          (conj results))
        results))
    []
    as1))

; Does vector intersect a circle?
; http://stackoverflow.com/a/1084899

(defn discriminant [d f r]
  "Calculate the discriminant of vector d to vector f,
   where f is a vector to the centre of a circle of
   radius r"
  (let [f (reverse-vector f)
        a (dot-product d d)
        b (* 2 (dot-product f d))
        c (- (dot-product f f) (* r r))]
    (- (* b b) (* 4 a c))))

; TODO test the ray f in one direction only
(defn intersects? [d f r]
  "Return true if vector d intersects a circle of radius r
   whose centre is given by vector f"
  (>= (discriminant d f r) 0))

(defn vector-intersects? [d as]
  "Return true if there is an asteroid in list as which lies along the vector d"
  (some
    (fn [a] (intersects? d (:position a) (:radius a)))
    as ))

; Frames

; API

(defn asteroid-records [state]
  "Convert the asteroid game state into a list of asteroid records"
  (->> state
       (:rocks)
       (map #(apply struct AsteroidRecord %))
       (map asteroid-position)))

(defn map-asteroids [xs]
  "Convert a list of Asteroid records into a map of id to record"
  (reduce
    (fn [m a] (assoc m (:id a) a))
    {}
    xs))

(def asteroids-state (comp map-asteroids asteroid-records))

(defn frame-delta [frame1 frame2]
  (let [as1 (asteroids-state frame1)
        as2 (asteroids-state frame2)]
    (watch as1 as2)))
