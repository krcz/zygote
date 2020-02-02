#lang typed/racket

(require "c-syntax-render.rkt"
         "c-semantics.rkt"
         "c-types.rkt"
         (prefix-in cs: "c-syntax-defs.rkt"))

(define x (variable "x" ct:Int))
(define a (variable "a" ct:Int))
(define b (variable "b" ct:Int))
(define c (variable "c" ct:Int))

(to-stdout render-ex (processing-result-repr (expression-process
  (+ a (* b (* c x))) (void))))

(to-stdout render-ex (processing-result-repr (expression-process
  (* a (+ b (+ c x))) (void))))
