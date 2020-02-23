#lang typed/racket

(require (prefix-in cs: "c-syntax-defs.rkt")
         "utils.rkt")
(provide (all-defined-out))

(define-type ct:Type (U builtin-type))
(: ct:get-specifiers (-> ct:Type (Listof cs:declaration-specifier)))
(define (ct:get-specifiers type) (match type
    ((builtin-type specifiers) specifiers)))

(struct builtin-type
  ([specifiers : (Listof cs:type-specifier)])
  #:transparent)

; ISO 6.2.5.7
(define-type ct:integer-type (U ct:signed-integer-type ct:unsigned-integer-type))
(struct ct:signed-integer-type builtin-type () #:transparent)
(struct ct:unsigned-integer-type builtin-type () #:transparent)

; ISO 6.2.5.10
(struct ct:floating-type builtin-type () #:transparent)

; TODO
;(struct typedef
;  ([underlying : c-type]
;   [alias : String]))
;(struct function-type
;  ([parameters (Listof function-parameter)]
;   [returns c-type]))
;(struct pointer
;  ([target c-type]))

; ISO 6.2.5.2
(define ct:Boolean (builtin-type (list 'bool)))
; ISO 6.2.5.3
(define ct:Char (builtin-type (list 'char)))
; ISO 6.2.5.4
(define ct:Short (ct:signed-integer-type (list 'short)))
(define ct:Int (ct:signed-integer-type (list 'int)))
(define ct:Long (ct:signed-integer-type (list 'long 'int)))
(define ct:Long-Long (ct:signed-integer-type (list 'long 'int)))
; ISO 6.2.5.5
(define ct:Unsigned-Short (ct:unsigned-integer-type (list 'unsigned 'short)))
(define ct:Unsigned-Int (ct:unsigned-integer-type (list 'unsigned 'int)))
(define ct:Unsigned-Long (ct:unsigned-integer-type (list 'unsigned 'int)))
(define ct:Unsigned-Long-Long (ct:unsigned-integer-type (list 'unsigned 'int)))
; ISO 6.2.5.10
(define ct:Float (ct:floating-type (list 'float)))
(define ct:Double (ct:floating-type (list 'double)))
(define ct:Long-Double (ct:floating-type (list 'long 'double)))
; ISO 6.2.5.19
(define ct:Void (builtin-type (list 'void)))
; ISO 6.2.5.14
(define-type ct:basic-type (U Char ct:integer-type ct:floating-type))

; ISO 6.2.5.21
(define-type ct:scalar-type (U ct:integer-type ct:floating-type)); ct:Pointer))


; TODO
;(define-type ct:aggregate-type (U ct:Array))

; ISO 6.2.5.20
; TODO
;(struct ct:Array
;  ([member-type]
;   [size (U Int #f)]))

; TODO
;(struct ct:Pointer
;  ([referenced-type]))

; TODO
;(struct ct:Function
;  ([parameter-types (Listof )]
;   [return-type ]))

; TODO
;(: ct:is-signed? (-> integer-type Boolean))

; TODO
; (: ct:floating-tower (Listof (Listof floating-type)))
; (define ct:floating-tower
;  (list
;    (list Float)
;    (list Double)
;    (list Long-double)))
;(: floating-type-rank (-> floating-type Int))

(: ct:integer-tower (Listof (Listof ct:integer-type)))
(define ct:integer-tower
  (list
    ;(list Signed-Char)
    (list ct:Short ct:Unsigned-Short)
    (list ct:Int ct:Unsigned-Int)
    (list ct:Long ct:Unsigned-Long)
    (list ct:Long-Long ct:Unsigned-Long-Long)))

(: ct:is-lower-integer? (-> ct:integer-type ct:integer-type Boolean))
(define ct:is-lower-integer? (lower-in-tower ct:integer-tower))

;(struct qualified-type
;  ([raw-type : c-type]
;   [qualifiers : (Listof cs:type-qualifier)]))
