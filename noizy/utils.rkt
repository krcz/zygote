#lang typed/racket

(provide (all-defined-out))

(: lower-in-tower (All (T) (-> (Listof (Listof T)) (-> T T Boolean))))
(define (lower-in-tower tower)
  (lambda (left right)
      (let rec : Boolean ([layers tower])
           (let
             ([member-left? (member left (car layers))]
              [member-right? (member right (car layers))])
             (if (or member-left? member-right?) (and member-left? (not member-right?)) (rec (cdr layers)))))))
