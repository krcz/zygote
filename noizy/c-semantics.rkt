#lang typed/racket

(require
 "c-types.rkt"
 (prefix-in cs: "c-syntax-defs.rkt"))
(provide (all-defined-out))

(struct (Repr) processing-result
  ([ctx : Context]
   [repr : Repr])
  #:transparent)

(struct (Repr) exp-processing-result
  ([ctx : Context]
   [type : ct:Type]
   [repr : Repr])
  #:transparent)

(define-type Context Void)

(struct variable
  ([name : String]
   [type : ct:Type])
  #:transparent)

(: variable-process (->  variable Context (exp-processing-result cs:var-name)))
; TODO: verify the variable is in context
(define (variable-process v ctx)
  (exp-processing-result ctx (variable-type v) (cs:var-name (variable-name v))))

(define-type lvalue (U variable))

(: literal-process (-> expression Context (exp-processing-result cs:primary-expression)))
(define (literal-process value ctx)
  (match value
    [(? integer? v) (exp-processing-result ctx ct:Int (cs:integer-literal v))]))

(define-type literal (U Integer))

(define-type expression (U binary-expression assignment-expression lvalue literal))
(: expression-process (-> expression Context (exp-processing-result cs:expression+)))
(define (expression-process ex ctx)
  (match ex
    [(? (make-predicate variable) exx) (variable-process exx ctx)]
    [(? (make-predicate literal) exx) (literal-process exx ctx)]
    [(? (make-predicate assignment-expression) exx) (assignment-expression-process exx ctx)]
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

(: binary-expression-process (-> binary-expression Context (exp-processing-result cs:binary-expression)))
(define (binary-expression-process bop ctx)
  (match-let*
      ([(binary-expression left right find-type op) bop]
       [(exp-processing-result lctx ltype lrepr) (expression-process left ctx)]
       [(exp-processing-result rctx rtype rrepr) (expression-process right lctx)]
       [result-type (find-type ltype rtype)]
       [lop (lesser-operator op)]
       [lbrepr (binary-bracketify-ex lop lrepr)]
       [rbrepr (binary-bracketify-ex lop rrepr)])
    (exp-processing-result rctx result-type (cs:binary-expression op lbrepr rbrepr))))

(: + (-> expression expression expression))
(define (+ left right)
  (binary-expression left right common-arithmetic-type '+))

(: - (-> expression expression expression))
(define (- left right)
  (binary-expression left right common-arithmetic-type '-))

(: * (-> expression expression expression))
(define (* left right)
  (binary-expression left right common-arithmetic-type '*))

(: comparison-type (-> ct:Type ct:Type ct:Type))
(define (comparison-type left right) ct:Boolean)

(: == (-> expression expression expression))
(define (== left right)
  (binary-expression left right comparison-type '==))

(: < (-> expression expression expression))
(define (< left right)
  (binary-expression left right comparison-type '<))

(: <= (-> expression expression expression))
(define (<= left right)
  (binary-expression left right comparison-type '<=))

(: > (-> expression expression expression))
(define (> left right)
  (binary-expression left right comparison-type '>))

(: >= (-> expression expression expression))
(define (>= left right)
  (binary-expression left right comparison-type '>=))

(struct assignment-expression
  ([left : lvalue]
   [right : expression]
   ; [find-type : (-> ct:Type ct:Type ct:Type)]
   ; introduce some kind of type checking instead
   [op : cs:assignment-operator])
  #:transparent)

(: unarize-cs (-> cs:expression+ cs:unary-expression+))
(define (unarize-cs ex)
  (if ((make-predicate cs:unary-expression+) ex) ex (cs:bracketed-expression ex)))

(: assignize-cs (-> cs:expression+ cs:assignment-expression+))
(define (assignize-cs ex)
  (if ((make-predicate cs:assignment-expression+) ex) ex (cs:bracketed-expression ex)))

(: assignment-expression-process (-> assignment-expression Context (exp-processing-result cs:assignment-expression)))
(define (assignment-expression-process bop ctx)
  (match-let*
      ([(assignment-expression left right op) bop]
       [(exp-processing-result lctx ltype lrepr) (expression-process left ctx)]
       [(exp-processing-result rctx rtype rrepr) (expression-process right lctx)]
       [lbrepr (unarize-cs lrepr)]
       [rbrepr (assignize-cs rrepr)])
    (exp-processing-result rctx ltype (cs:assignment-expression op lbrepr rbrepr))))

(struct var-declaration
  ([var : variable])
  #:transparent)

(: set! (-> lvalue expression expression))
(define (set! left right)
  (assignment-expression left right '=))

(: var-declaration-process (-> var-declaration Context (processing-result cs:var-declaration)))
(define (var-declaration-process decl ctx)
  (match decl
    [(var-declaration (variable name type))
     (processing-result ctx (cs:var-declaration (ct:get-specifiers type) (list (cs:var-name name))))]))

(struct while-loop
  ([pred : expression]
   [body : statement])
  #:transparent)

(: while-loop-process (-> while-loop Context (processing-result cs:while-statement)))
(define (while-loop-process loop ctx)
  (match-let*
   ([(exp-processing-result ctx1 _ pred-repr) (expression-process (while-loop-pred loop) ctx)]
    [(processing-result ctx2 body-repr) (statement-process (while-loop-body loop) ctx1)])
   (processing-result ctx2 (cs:while-statement pred-repr body-repr))))

(struct do-while-loop
  ([body : statement]
   [pred : expression])
  #:transparent)

(: do-while-loop-process (-> do-while-loop Context (processing-result cs:do-while-statement)))
(define (do-while-loop-process loop ctx)
  (match-let*
    ([(processing-result ctx1 body-repr) (statement-process (do-while-loop-body loop) ctx)]
     [(exp-processing-result ctx2 _ pred-repr) (expression-process (do-while-loop-pred loop) ctx1)])
   (processing-result ctx2 (cs:do-while-statement body-repr pred-repr))))

(struct for-loop
  ([init : expression]
   [pred : expression]
   [update : expression]
   [body : statement])
  #:transparent)
(: for-loop-process (-> for-loop Context (processing-result cs:for-statement)))
(define (for-loop-process loop ctx)
  (match-let*
      ([(exp-processing-result ctx1 _ init-repr) (expression-process (for-loop-init loop) ctx)]
       [(exp-processing-result ctx2 _ pred-repr) (expression-process (for-loop-pred loop) ctx1)]
       [(exp-processing-result ctx3 _ update-repr) (expression-process (for-loop-update loop) ctx2)]
       [(processing-result ctx4 body-repr) (statement-process (for-loop-body loop) ctx3)])
    (processing-result ctx4 (cs:for-statement init-repr pred-repr update-repr body-repr))))

(define-type loop-statement (U while-loop do-while-loop for-loop))

(define-type statement (U block expression loop-statement))
(: statement-process (-> statement Context (processing-result cs:statement)))
(define (statement-process st ctx)
  (match st
    [(? (make-predicate expression) ex)
      (match-let ([(exp-processing-result ctx _ repr) (expression-process ex ctx)])
        (processing-result ctx (cs:expression-statement repr)))]
    [(? (make-predicate block) blk) (block-process blk ctx)]
    [(? (make-predicate while-loop) loop) (while-loop-process loop ctx)]
    [(? (make-predicate do-while-loop) loop) (do-while-loop-process loop ctx)]
    [(? (make-predicate for-loop) loop) (for-loop-process loop ctx)]))

(define-type block-item (U statement var-declaration))
(: block-item-process (-> block-item Context (processing-result cs:block-item)))
(define (block-item-process bi ctx)
  (match bi
    [(? (make-predicate statement) st) (statement-process st ctx)]
    [(? (make-predicate var-declaration) vd) (var-declaration-process vd ctx)]))

(struct block
  ([items : (Listof block-item)])
  #:transparent)
(: block-process (-> block Context (processing-result cs:compound-statement)))
; typed/racked doesn't seem to support for/fold with #:result, so ugly hacks are required
(define (block-process blk ctx)
  (match-let
    ([(cons rctx ritems)
      (for/fold
        ([acc : (Pair Context (Listof cs:block-item)) (cons ctx (list))])
        ([item (block-items blk)])
        (match-let
          ([(cons lctx litems) acc])
          (match (block-item-process item lctx)
            [(processing-result prctx repr) (cons prctx (cons repr litems))])))])
    (processing-result rctx (cs:compound-statement (reverse ritems)))))

(struct function-definition
  ([name : String]
   [return-type : ct:Type]
   [parameters : (Listof variable)]
   [body : block])
  #:transparent)

(: function-definition-process (-> function-definition Context (processing-result cs:function-definition)))
(define (function-definition-process fdef ctx)
  (match-let*
    ([(function-definition name return-type parameters body) fdef]
     [par-decls (map (lambda ([v : variable]) (cs:parameter-declaration (ct:get-specifiers (variable-type v)) (cs:var-name (variable-name v)))) parameters)]
     [(processing-result ctx2 body-repr) (block-process body ctx)])
    (processing-result ctx2
      (cs:function-definition
        (ct:get-specifiers return-type)
        (cs:fun-declarator (cs:var-name name) par-decls #f)
        (list)
        body-repr))))

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
