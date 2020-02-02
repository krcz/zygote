#lang typed/racket

(require
 "c-types.rkt"
 (prefix-in cs: "c-syntax-defs.rkt"))
(provide (all-defined-out))

(struct (Repr) processing-result
  ([ctx : Context]
   [type : ct:Type]
   [repr : Repr])
  #:transparent)

(define-type Context Void)

(struct variable
  ([name : String]
   [type : ct:Type])
  #:transparent)
(: variable-process (->  variable Context (processing-result cs:var-name)))
; TODO: verify the variable is in context
(define (variable-process v ctx)
  (processing-result ctx (variable-type v) (cs:var-name (variable-name v))))

; TODO
;(define-type lvalue)

(define-type expression (U binary-expression variable))
(: expression-process (-> expression Context (processing-result cs:expression+)))
(define (expression-process ex ctx)
  (match ex
    [(? (make-predicate variable) exx) (variable-process exx ctx)]
    [(? (make-predicate binary-expression) exx) (binary-expression-process exx ctx)]))

(: common-arithmetic-type (-> ct:Type ct:Type ct:Type))
(define (common-arithmetic-type ltype rtype)
  (match (cons ltype rtype)
    ;[((make-predicate floating-type) . (make-predicate integer-type)) ltype]
    ;[((make-predicate integer-type) . (make-predicate floating-type)) rtype]
    ;[((make-predicate floating-type) . (make-predicate floating-type))]
    [(cons (? (make-predicate ct:integer-type) lt) (? (make-predicate ct:integer-type) rt))
      (if (ct:is-lower-integer? lt rt) lt rt)]))

; type problems: it would be nice to be express it more generally
; but it might require generic thing
; : (bracketify-ex T) (-> T Boolean) cs:expression+ T
(: binary-bracketify-ex (-> (-> cs:expression+ Boolean) cs:expression+ cs:binary-expression+))
(define (binary-bracketify-ex check ex)
  (if ((make-predicate cs:binary-expression+) ex)
    (if (check ex) ex (cs:bracketed-expression ex))
    (cs:bracketed-expression ex)))

(: lesser-operator (-> cs:binary-operator (-> cs:expression+ Boolean)))
(define (lesser-operator op)
  (lambda (ex) (match ex
    [(? (make-predicate cs:cast-expression+) _) #t]
    [(cs:binary-expression bop _ _) (cs:stronger-operator? bop op)]
    [_ #f])))

; DEPRECATED
;(: get-type (-> expression ct:type))
;(define (get-type ex)
;  (match ex
;    [(? (make-predicate unary-expression) exx) (unary-expression-get-type exx)]
;    [(? (make-predicate binary-expression) exx) (binary-expression-get-type exx)]
;    [(? (make-predicate function-call) exx) (function-call-get-type exx)]
;    [(? (make-predicate array-access) exx) (array-access-get-type exx)]
;    [(? (make-predicate cast) exx) (cast-get-type exx)]))

; DEPRECATED
;(: function-call-get-type (-> function-call ct:type)
;(define (function-call-get-type ex)
;  (function-call (ct:Function-return-type ())))

(struct binary-expression
  ([left : expression]
   [right : expression]
   [find-type : (-> ct:Type ct:Type ct:Type)]
   [op : cs:binary-operator])
  #:transparent)

(: binary-expression-process (-> binary-expression Context (processing-result cs:binary-expression)))
(define (binary-expression-process bop ctx)
  (match-let*
      ([(binary-expression left right find-type op) bop]
       [(processing-result lctx ltype lrepr) (expression-process left ctx)]
       [(processing-result rctx rtype rrepr) (expression-process right lctx)]
       [result-type (find-type ltype rtype)]
       [lop (lesser-operator op)]
       [lbrepr (binary-bracketify-ex lop lrepr)]
       [rbrepr (binary-bracketify-ex lop rrepr)])
    (processing-result rctx result-type (cs:binary-expression op lbrepr rbrepr))))

(: + (-> expression expression expression))
(define (+ left right)
  (binary-expression left right common-arithmetic-type '+))

(: - (-> expression expression expression))
(define (- left right)
  (binary-expression left right common-arithmetic-type '-))

(: * (-> expression expression expression))
(define (* left right)
  (binary-expression left right common-arithmetic-type '*))

;(define + (case lambda
;  [([a : expression])]
;  [([a : expression] [b : expression])]

; (: set! (-> variable expression))
; (: update! (-> variable (-> expression expression)))
; (: update-op! (-> variable binary-operator expression))
; (: declare! (-> variable declaration))
; (: declare-set!)

; (: if (-> expression statement statement statement))
; (: when (-> expression statement statement))
