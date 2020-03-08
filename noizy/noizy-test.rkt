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

(to-stdout render (processing-result-repr (function-definition-process
  (function-definition "testFun" ct:Void
    (list a b c x)
    (block (list
      (var-declaration i)
      (for-loop (set! i 0) (< i 10) (set! i (+ i 1)) (+ a (* b (* c x))))))) (void))))
