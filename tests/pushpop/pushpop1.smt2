(declare-const x Int)
(declare-const y Int)
(declare-const z Int)
(push 1)
(assert (= (+ x y) 10))
(assert (= (+ x (* 2 y)) 20))
(check-sat)
(pop 1)
(push 1)
(assert (= (+ (* 3 x) y) 10))
(assert (= (+ (* 2 x) (* 2 y)) 21))
(check-sat)
(declare-const p Bool)
(pop 1)
(assert p)