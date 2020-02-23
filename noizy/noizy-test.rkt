#lang typed/racket

(require "c-syntax-render.rkt"
         "c-semantics.rkt"
         "c-types.rkt"
         (prefix-in cs: "c-syntax-defs.rkt"))

(define i (variable "i" ct:Int))
(define x (variable "x" ct:Int))
(define a (variable "a" ct:Int))
(define b (variable "b" ct:Int))
(define c (variable "c" ct:Int))

(to-stdout render-stat (processing-result-repr (block-process
  (block (list
    (var-declaration i)
    (var-declaration x)
    (var-declaration a)
    (var-declaration b)
    (var-declaration c)
    (for-loop (set! i 0) (< i 10) (set! i (+ i 1)) (+ a (* b (* c x)))))) (void))))

(to-stdout render-stat (processing-result-repr (block-process
  (block (list
    (var-declaration x)
    (var-declaration a)
    (var-declaration b)
    (var-declaration c)
  (* a (+ b (+ c x))))) (void))))
