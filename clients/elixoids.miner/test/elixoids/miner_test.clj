(ns elixoids.miner-test
  (:require [clojure.test :refer :all]
            [elixoids.miner :refer :all]))


(def state_1 { :rocks [[3, 0.4822331855160187, 120.0, 1867.3], [6, 0.451579384683733,  120.0, 1986.3], [8, -0.7088572391889082, 120.0, 1737.6]], :theta 0.0})

(def state_2 { :rocks [[3, 0.4775823032592002, 120.0, 1848.6], [6, 0.4469885447613649, 120.0, 1967.8]], :theta 2.08182873})


(deftest test-parse-rocks-in-state
  (testing "Parsing Asteroid struct"
    (is
      (= 3 (count (asteroid-records state_1))))
    (is
      (= 1867.3 (:distance (first (asteroid-records state_1)))))))

(deftest test-polar-to-cartesian
  (testing "Conversions"
    (is
      (=
        [1656.2856193057573 862.280254488611]
        (polar-to-cartesian 0.48 1867.3)))))

(deftest test-map-asteroids
  (testing "Index Asteroids by their ID"
    (is
      (= [3 6 8]
         (keys (map-asteroids (asteroid-records state_1)))))))

(deftest test-calculate-path
  (testing "Calulate velocity from two polar positions"
    (is
      (= [12.5979843814589
          16.298695921285685]
         (calculate-velocity
           {:theta 0.4822331855160187 :d 1867.3}
           {:theta 0.4775823032592002 :d 1848.6}
           )))))

(deftest test-vectors
  (testing "Subtract two vectors"
    (is
      (= [2 3]
         (sub
           [5 7]
           [3 4]))))
  (testing "Dot products"
    (is
      (= 66 (dot-product [-6 8] [5 12])))))

(deftest test-intersections
  (testing "Unit vector intersects circle ahead of it"
    (is (intersects? [1 0] [3 0] 1)))
  (testing "Unit diagonal vector intersects circle ahead of it"
    (is (intersects? [1 1] [8 8] 1)))
  (testing "Unit diagonal vector does not intersect circle on x-axis"
    (is (not (intersects? [1 1] [8 0] 1))))
  (testing "Unit diagonal vector intersects circle behind"
    (is (intersects? [1 1] [-8 -8] 1)))
  (testing "Vector [2 2] misses unit circle at [3 1]"
    (is (not (intersects? [2 2] [3 1] 1))))
  (testing "Vector [2 2] clips larger circle at [3 1]"
    (is (intersects? [2 2] [3 1] 2)))
  (testing "Vector [2 2] clips unit circle at [2 3]"
    (is (intersects? [2 2] [2 3] 1))))