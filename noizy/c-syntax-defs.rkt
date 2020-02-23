#lang typed/racket

(require "utils.rkt")
(provide (all-defined-out))

(struct integer-literal
  ([value : Integer])
  #:transparent)

(define-type identifier (U var-name type-name))

(struct var-name
  ([name : String]) #:transparent)

(struct type-name
  ([name : String])
  #:transparent)

; ISO section 2.1 Expressions

; ISO primary-expression
(define-type primary-expression (U bracketed-expression var-name integer-literal))

(struct bracketed-expression
  ([ex : expression+])
  #:transparent)

; ISO postfix-expression
(define-type postfix-expression+ (U primary-expression indexing-expression call-expression access-expression postfix-expression))

(struct indexing-expression
  ([ex : postfix-expression+]
   [index : expression])
  #:transparent)

(struct access-expression
  ([ex : postfix-expression+]
   [field : var-name])
  #:transparent)

(struct call-expression
  ([ex : postfix-expression+]
   [arguments : (Listof assignment-expression+)])
  #:transparent)

(define-type postfix-operator (U '++ '--))
(struct postfix-expression
  ([ex : postfix-expression+]
   [op : postfix-operator])
  #:transparent)

; ISO unary-expression
(define-type unary-operator (U '+ '- '++ '--))

(define-type unary-expression+ (U unary-expression postfix-expression+))
(struct unary-expression
  ([op : unary-operator]
   [ex : unary-expression+])
  #:transparent)

(define-type cast-expression+ (U cast-expression unary-expression+))
(struct cast-expression
  ([type : type-name]
   [ex : cast-expression+])
  #:transparent)


(define-type binary-operator (U '* '/ '% '+ '- '<< '>> '< '> '<= '>= '== '!= 'bin-and 'bin-xor 'bin-or 'logical-and 'logical-or))
(: binary-operators (Listof (Listof binary-operator)))
(define binary-operators (list
  (list '* '/ '%)
  (list '+ '-)
  (list  '<< '>>)
  (list  '< '> '<= '>=)
  (list  '== '!=)
  (list  'bin-and)
  (list  'bin-xor)
  (list  'bin-or)
  (list  'logical-and)
  (list  'logical-or)))
(: stronger-operator? (-> binary-operator binary-operator Boolean))
(define stronger-operator? (lower-in-tower binary-operators))

(define-type binary-expression+ (U binary-expression cast-expression+))
(struct binary-expression
  ([op : binary-operator]
   [left : binary-expression+]
   [right : binary-expression+])
   #:transparent) ;TODO: verify precedence of sub-binaries?

(define-type conditional-expression+ (U conditional-expression binary-expression+))
(struct conditional-expression
  ([condition : binary-expression]
   [left : expression]
   [right : conditional-expression+]))

(define-type assignment-operator (U '= '+= '-= '*= '/= '%= '<<= '>>= 'and-= 'xor-= 'or-=))

(define-type assignment-expression+ (U assignment-expression conditional-expression+))
(struct assignment-expression
  ([op : assignment-operator]
   [left : unary-expression+]
   [right : assignment-expression+])
  #:transparent)

(define-type expression+ (U expression assignment-expression+))
(struct expression
  ([prev : expression+]
   [last : assignment-expression+])
  #:transparent)

(define-type constant-expression conditional-expression+)

; ISO A.2.2 Declarations

; ISO declaration
(define-type declaration (U var-declaration type-declaration))

(struct var-declaration
  ([specifiers : (Listof declaration-specifier)] ; todo: non-unique / unique check
   [declarator-list : (Listof declarator)])
  #:transparent)

(struct type-declaration
  ([specifiers : (Listof declaration-specifier)] ; todo: typedef + non-unique / unique check
   [declarator-list : (Listof declarator)])
  #:transparent)

; ISO declaration-specifiers
(define-type declaration-specifier (U storage-class-specifier type-specifier type-qualifier function-specifier)) ; TODO: alignment-specifier

; ISO init-declarator
(struct init-declarator
  ([declarator : declarator]
   [initializer : (U initializer Null)])
   #:transparent)

; ISO storage-class-specifier
(define-type storage-class-specifier (U 'extern 'static 'thread-local 'auto 'register 'typedef))

; ISO type-specifier
(define-type type-specifier (U type-specifier-unique type-specifier-nonunique))
(define-type type-specifier-nonunique (U 'char 'short 'int 'long 'float 'double 'signed 'unsigned 'complex))
(define-type type-specifier-unique (U 'void 'bool)) ;TODO: typedef-name-spec structs uninons enums atomic

; ISO type-qualifier
(define-type type-qualifier (U 'const 'restrict 'volatile 'atomic))

; ISO function-specifier
(define-type function-specifier (U 'inline 'noreturn))

; ISO declarator

(define-type declarator (U pointer-declarator direct-declarator))
(struct pointer-declarator
  ([ptr : pointer]
   [decl : direct-declarator])
  #:transparent)

; ISO direct-declarator
(define-type direct-declarator (U identifier bracketed-declarator fun-declarator))

(struct bracketed-declarator
  ([decl : declarator])
  #:transparent)

(struct fun-declarator
  ([decl : direct-declarator]
   [parameters : (Listof parameter-declaration)] ; ISO parameter-list
   [ellipsis? : Boolean]) ; ISO parameter-type-list
  #:transparent)

; ISO pointer

(struct pointer
  ([qualifiers : (Listof (Listof type-qualifier))])
   #:transparent)

; ISO parameter-declaration
(struct parameter-declaration
  ([specifiers : (Listof declaration-specifier)]
   [target : (U declarator abstract-declarator)])
   #:transparent)

; ISO abstract-declarator

(define-type abstract-declarator (U direct-abstract-declarator pointer-abstract-declarator))
(struct pointer-abstract-declarator
  ([ptr : pointer]
   [decl : direct-abstract-declarator])
  #:transparent)

; ISO abstract-direct-declarator
(define-type direct-abstract-declarator (U bracketed-abstract-declarator fun-abstract-declarator))

(struct bracketed-abstract-declarator
  ([delc : abstract-declarator])
  #:transparent)

(struct fun-abstract-declarator
  ([decl : (U abstract-declarator Null)]
   [parameters : (Listof parameter-declaration)]
   [ellipsis : Boolean])
  #:transparent)

; ISO initalizer
(define-type initializer assignment-expression+)

; ISO Section A.2.3 Statements

; ISO statement
(define-type statement (U expression-statement compound-statement selection-statement iteration-statement))

; ISO compound-statement
(struct compound-statement
  ([els : (Listof block-item)]) ; ISO block-item-list
  #:transparent)

; ISO block-item
(define-type block-item (U statement declaration))

; ISO expression-statement
(struct expression-statement
  ([ex : expression+])
  #:transparent)

; ISO selection-statement
(define-type selection-statement if-else-statement)

(struct if-else-statement
  ([pred : expression+]
   [if-branch : statement]
   [else-branch : statement])
  #:transparent)

; ISO iteration-statement
(define-type iteration-statement (U while-statement do-while-statement for-statement))

(struct while-statement
  ([pred : expression+]
   [body : statement])
  #:transparent)

(struct do-while-statement
  ([body : statement]
   [predicate : expression+])
  #:transparent)

(struct for-statement
  ([init : expression+]
   [pred : expression+]
   [update : expression+]
   [body : statement])
  #:transparent)

; ISO section A.2.4 External definitions

; ISO external-declaration
(define-type external-declaration (U declaration function-definition))

; ISO function-definition
(struct function-definition
  ([specifiers : (Listof declaration-specifier)]
   [decl : declarator]
   [declaration-list : (Listof declaration)]
   [body : compound-statement])
  #:transparent)

;(define-syntax-rule (nc-module-begin args . other)
                    ;(#%module-begin (display (render (list args . other)))))
                    ;(+ (#%module-begin '(display args . other))))
