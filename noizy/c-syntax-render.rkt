#lang typed/racket

(require "c-syntax-defs.rkt")
(require threading)

(provide (all-defined-out))

(define-type token (U Symbol String integer-literal))

(struct Renderer
  ([output : Output-Port]
   [needs-separation? : Boolean])
  #:transparent)

(: ro-one (-> Renderer token Renderer))
(define (ro-one r t) (let*-values
  ([(o) (values (Renderer-output r))]
   [(str needs-separation?) (cond
      [(eq? t 'lparen) (values "(" #f)]
      [(eq? t 'rparen) (values ")" #f)]
      [(eq? t 'lbracket) (values "[" #f)]
      [(eq? t 'rbracket) (values "]" #f)]
      [(eq? t 'lbrace) (values "{" #f)]
      [(eq? t 'rbrace) (values "}" #f)]
      [(eq? t 'semicolon) (values ";" #t)]
      [(eq? t 'colon) (values "," #t)]
      [(eq? t 'comma) (values "." #f)]
      [(eq? t 'newline) (values "\n" #f)]
      [(integer-literal? t) (values (number->string (integer-literal-value t)) #t)]
      [(symbol? t) (values (symbol->string t) #t)]
      [(string? t) (values t #t)])]
  [(_) (if (and needs-separation? (Renderer-needs-separation? r)) (display " " o) '())])
  (display str o)
  (struct-copy Renderer r [needs-separation? needs-separation?])))

(: ro (-> Renderer token * Renderer))
(: ro-list (-> Renderer (Listof token) Renderer))
(define (ro-list r tokens)
  (for/fold ([rr r]) ([t tokens]) (ro-one rr t)))

(: ro (-> Renderer token * Renderer))
(define (ro r . tokens)
  (ro-list r tokens))

(: render-list-with (All (T) (-> Renderer (-> Renderer T Renderer) (Listof T) Renderer)))
(define (render-list-with r f l)
  (for/fold ([rr r]) ([arg l])
    (f rr arg)))

(: render-list-with-sep (All (T) (-> Renderer (-> Renderer T Renderer) token (Listof T) Renderer)))
(define (render-list-with-sep r f sep l)
  (if (empty? l) r 
    (for/fold ([rr (f r (car l))]) ([arg (cdr l)])
      (~> r (ro sep) (f arg)))))

(: render-ex (-> Renderer expression+ Renderer))
(define (render-ex r ex) (match ex
  [(call-expression ex arguments) (~> r (render-ex ex) (ro 'lparen) (render-list-with-sep render-ex 'colon arguments) (ro 'rparen))]
  [(indexing-expression ex index) (~> r (render-ex ex) (ro 'lbracket) (render-ex index) (ro 'rbracket))]
  [(access-expression ex field) (~> r (render-ex ex) (ro 'comma) (render-ex field))]
  [(postfix-expression ex op) (~> r (render-ex ex) (ro op))]
  [(assignment-expression op left right) (~> r (render-ex left) (ro (assignment-operator-op op)) (render-ex right))]
  [(conditional-expression condition left right) (~> r (render-ex condition) (ro '?) (render-ex left) (ro ':) (render-ex right))] 
  [(binary-expression op left right) (~> r (render-ex left) (ro (binary-operator-op op)) (render-ex right))] 
  [(cast-expression type exx) (~> r (ro 'lparen) (ro (type-name-name type)) (ro 'rparen) (render-ex exx))] 
  [(unary-expression op exx) (~> r (ro (unary-operator-op op)) (render-ex exx))] 
  [(bracketed-expression exx) (~> r (ro 'lparen) (render-ex exx) (ro 'rparen))]
  [(expression prev last) (~> r (render-ex prev) (ro 'colon) (render-ex last))]
  [(var-name name) (ro r name)]
  [(integer-literal value) (ro r (integer-literal value))]))

(: render-stat (-> Renderer statement Renderer))
(define (render-stat r stat) (match stat
  [(compound-statement items) (~> r (ro 'lbrace) (ro 'newline) (render-list-with render-block-item items) (ro 'rbrace))]
  [(expression-statement ex) (~> r (render-ex ex) (ro 'semicolon))]
  [(if-else-statement pred if-branch else-branch)
     (~> r (ro 'if) (ro 'lparen) (render-ex pred) (ro 'rparen) (render-stat if-branch) (ro 'else) (render-stat else-branch))]
  [(while-statement pred body)
     (~> r (ro 'while) (ro 'lparen) (render-ex pred) (ro 'rparen) (render-stat body))]
  [(do-while-statement body pred)
     (~> r (ro 'do) (render-stat body) (ro 'while) (ro 'lparen) (render-ex pred) (ro 'rparen))]
  [(for-statement init pred update body)
     (~> r (ro 'for) (ro 'lparen) (render-ex init) (ro 'semicolon) (render-ex pred) (ro 'semicolon) (render-ex update) (ro 'rparen) (render-stat body))]))

(: render-block-item (-> Renderer block-item Renderer))
(define (render-block-item r b) (ro (match b
  [(? (make-predicate statement) bb) (render-stat r bb)] 
  [(? (make-predicate declaration) bb) (render-decl r bb)]) 'newline))

(: render-decl (-> Renderer declaration Renderer))
(define (render-decl r decl)
  (let-values
    ([(specifiers declarators) (match decl
       [(var-declaration s d) (values s d)]
       [(type-declaration s d) (values s d)])])
    (~> r
      (render-list-with render-specifier specifiers)
      (render-list-with-sep render-declarator 'colon declarators)
      (ro 'semicolon))))

(: render-specifier (-> Renderer declaration-specifier Renderer))
(define (render-specifier r spec)
  (match spec
    [(? symbol? s) (ro r s)]))

(: ignore-null (All(T) (-> (-> Renderer T Renderer) (-> Renderer (U T Null) Renderer))))
(define (ignore-null f)
  (lambda (r v) (if (null? v) r (f r v))))

(: render-pointer (-> Renderer pointer Renderer))
(define (render-pointer r ptr)
  (let 
    ([render-part (lambda ([r : Renderer] [part : (Listof type-qualifier)]) (~> r (ro '*) (render-list-with ro part)))]
     [parts (pointer-qualifiers ptr)])
    (render-list-with r render-part parts)))

(: render-declarator (-> Renderer (U declarator abstract-declarator) Renderer))
(define (render-declarator r declarator)
   (match declarator
     [(var-name name) (ro r name)]
     [(pointer-declarator p d) (~> r (render-pointer p) (render-declarator d))]
     [(bracketed-declarator d) (~> r (ro 'lparen) (render-declarator d) (ro 'rparen))]
     [(fun-declarator d params ellipsis?)
      (~> r (render-declarator d) (ro 'lparen) (render-list-with-sep render-parameter-decl 'colon params) (ro 'rparen))]
     [(bracketed-abstract-declarator d) (~> r (ro 'lparen) (render-declarator d) (ro 'rparen))]
     [(fun-abstract-declarator d params ellipsis?)
      (~> r ((ignore-null render-declarator) d) (ro 'lparen) (render-list-with-sep render-parameter-decl 'colon params) (ro 'rparen))]))

(: render-parameter-decl (-> Renderer parameter-declaration Renderer))
(define (render-parameter-decl r decl)
  (~> r
      (render-list-with render-specifier (parameter-declaration-specifiers decl))
      (render-declarator (parameter-declaration-target decl))))

(: render (-> Renderer external-declaration Renderer))
(define (render r ed)
  (match ed
    [(function-definition specs decl dl body)
       (~> r
           (render-list-with render-specifier specs)
           (render-declarator decl)
           (render-stat body))]))

(: to-stdout (All (T U) (-> (-> Renderer T Any) T Void)))
(define (to-stdout f v) (f (Renderer (current-output-port) #f) v) (void))
