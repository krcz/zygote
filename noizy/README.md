# Noizy

Noizy is a subproject of [Zygote](../README.md), exploring the possibility of idiomatic translation of programming language, i.e. creating a programming language that could be translated into various others, possibly different paradigm languages, generating idiomatic code in the process - that programmer skilled in such language would write. Noizy focuses on C as a target and is aimed towards creating functional abstractions and translating them into imperative constructs.

Racket was used for implementation, as it facilitates creation of new programming languages - by allowing to parse s-expressions and attaching any meaning to it.

## Layers

Generation of the target C code (or any target language code) is sequential, going from more abstract representations into more concrete ones. Each of these has its representation called layer.

Layers, from the most concrete to the most abstract one:
* **Syntactic layer** - representation of C grammar; it can be translated into a string that follows C grammar (as defined in the specification); each correct C program has representation in that layer.
* **Semantic layer** - representation of C program concepts and behaviour - all identifiers are resolved and typed; it can be translated into a correct C program; each correct C program can be translated into a representation behaving the same way.
* **Abstract layer** - code representation that can use concepts that don't exist in C (eg. tuples, macros, etc.); it can be translated into lower layers, but not the other way.

### Syntactic layer

C grammar as specified in the ISO C11 standard accepts programs that are not correct, sometimes obviously not correct. It is also ambiguous in some points as Jacques-Henri Jourdan and François Pottier describe in their 2017 [paper](http://gallium.inria.fr/~fpottier/publis/jourdan-fpottier-2016.pdf). They provide a grammar with some modifications, removing the ambiguities. The syntactic layer in Noizy is based on a bespoke mix of these grammars.

The set of the programs representable in this layer is going to be a subset of programs representable by ISO C11 grammar, but a superset of correct ones. 

### Semantic layer

The syntactic layer is expressive enough to represent every possible C program, but it is hard to reason about - it allows representing of incorrect programs, so the person generating anything needs to track the scope, to assure that used functions are declared, variables have meaning, types used are valid.

It is where the semantic layer comes in. It tracks the whole context required for any analysis, making it available to higher layers. It detects attempts to use a variable that has been shadowed.

The semantic layer represents the meaning, not the exact structure. When translating a C program forth and back we can end up with a different program, but one that is going to give the same results when ran or interacted with as a library.

### Abstract layer

Just as lower layers are instrumental to the translation, the abstract layer is the end goal. It's meant to be used to create programs using different constructions and concepts. Lower layers are language-specific, while the abstract layer can be universal, allowing translation into many targets.

While it is specified as a singular entity here, the abstract layer can consist of numerous smaller, semi-distinct, composable parts.

## Current state

A considerable part of the syntactic layer has been implemented, in `c-syntax-defs.rkt` - which contains definitions of grammar elements - and `c-syntax-render.rkt` - which allows rendering them into C code.

Implemented things:
* decimal integer literals,
* expressions (prefix/binary operators, ternary operator, casts, field access, assignments, function calls, array access),
* most statements (blocks, if/else, while, do/while,  for),
* declarations (variables, types, functions, pointers)

To be implemented:
* other literals (string, floating point, non-decimal)
* labelled statements + goto,
* `sizeof`, `alignof`
* structs and unions,
* structure initializers,
* switch statement,
* static asserts,
* enums,
* `_Atomic`
* `_Generic`

## Roadmap

The project will be developed vertically not horizontally (i.e. 

Soon:
* basic version of semantic layer,
* tooling to generate, compile and run programs represented in any layer,
* structs/unions support,
* example programs.

Later:
* basic C++ support (enough to program microcontrollers) - probably by forking C syntactic/semantic layer,
* create abstractions for commonly used programming patterns.

One day:
* full coverage of ISO C11 language,
* functional language in the abstract layer,
* moving away from Racket.
