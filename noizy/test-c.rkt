#lang s-exp "c-syntax.rkt"

(to-stdout render
  (function-definition
    (list 'int)
    (fun-declarator
      (var-name "main")
      (list
        (parameter-declaration (list 'int) (var-name "argc"))
        (parameter-declaration (list 'char) (pointer-declarator (pointer (list (list) (list))) (var-name "argv"))))
      #f)
    (list)
    (compound-statement (list
      (var-declaration (list 'int) (list (var-name "i") (var-name "n")))
      (expression-statement
        (assignment-expression (assignment-operator "=") (var-name "n") (integer-literal 10)))
      (for-statement
        (assignment-expression (assignment-operator "=") (var-name "i") (integer-literal 1))
        (binary-expression (binary-operator "<=") (var-name "i") (var-name "n"))
        (unary-expression (unary-operator "++") (var-name "i"))
        (compound-statement (list
          (expression-statement (call-expression (var-name "f") (list (var-name "i") (var-name "n")))))))))))
