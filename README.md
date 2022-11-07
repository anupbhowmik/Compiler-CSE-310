# Compiler-CSE-310

# Contents
- [Symbol Table](https://github.com/Anupznk/Compiler-CSE-310/new/master?readme=1#symbol-table)
- [Lexical Analyzer](https://github.com/Anupznk/Compiler-CSE-310/edit/master/README.md#lexical-analyzer)
- [Syntax Analyzer](https://github.com/Anupznk/Compiler-CSE-310/edit/master/README.md#syntax-analyzer)
- [Semantic Analyzer](https://github.com/Anupznk/Compiler-CSE-310/edit/master/README.md#syntax-analyzer)
- [Intermidiate Code Generator]()

## Symbol Table
- Used hash of hash table to store all the data
- The Scope table keeps track of the current and parent scopes

## Lexical Analyzer
- Takes stream of `lexemes` and produces a stream of `tokens`
- Reports lexical errors with corresponding line number and error message
  - Unfinished multi line comment `/*this is a comment` then `EOF` is found
  - Too many decimal points `2.32.3`
  - Ill formed number `1E10.7`
  - Empty character `''`
  - Multi character constant `'abd'`
  - Unfinished character `'a`
  - Unfinished String `"Unfinished String`
  - Invalid prefix on ID or invalid suffix on Number `12ABc`
  - Any Unrecognized character
  
- The IO folder contains some sample input output
- [Problem Specifications](https://github.com/Anupznk/Compiler-CSE-310/blob/master/2%20-%20Lexical%20Analyzer/Assignment%202%20Specification.pdf)
### Run locally
  - Need to install `flex` on your `linux` machine or `WSL`
``` bash
flex -o sample.c 1805082.l
g++ sample.c -lfl -o sample.o
./sample.o
```
## Syntax Analyzer
### Our chosen subset of the C language has the following characteristics:

- There can be multiple functions. No two functions will have the same name. A function needs
  to be defined or declared before it is called. Also, a function and a global variable cannot have the same symbol.
- There will be no pre-processing directives like `#include` or `#define`.
- Variables can be declared at suitable places inside a function. Variables can also be declared in
  the global scope.
- Precedence and associativity rules are as per standard. Although we will ignore consecutive logical operators or consecutive
  relational operators like, `a && b && c`, `a < b < c`.
- No `break` statement and `switch-case` statement will be used.
- `println(n)` is used instead of `printf(“%d\n”, n)` to simplify the analysis, where `n` is a declared variable.

### Error recovery:
Some common syntax errors are handled and recovered so that the parser does not stop parsing immediately after recongnizing an error.

## Semantic Analyser

### Following semantics are checked in the compiler:

<div>
<details>
<summary>
        Type Checking 
</summary>
<ol>
<li>
        Generates error message if operands of an assignment operator are not consistent with each other. The second operand of the assignment operator will be an expression that may contain numbers, variables, function calls, etc.
</li>
<li> 
        Generates an error message if the index of an array is not an integer.
</li>
<li> 
        Both the operands of the modulus operator should be integers.
</li>
        During a function call all the arguments should be consistent with the function definition.
<li>
        A void function cannot be called as a part of an expression.
</li>
</ol>
</details>
<details>
<summary>
        Type Conversion 
</summary>
        Conversion from float to integer in any expression generates an error. Also, the result of RELOP and LOGICOP operations are integers.
</details>
<details>
<summary>
        Uniqueness Checking
</summary>
        Checks whether a variable used in an expression is declared or not. Also, checks whether there are multiple declarations of variables with the same ID in the same scope.
</details>
<details>
<summary>
        Array Index
</summary>
        Checks whether there is an index used with array and vice versa.
</details>
<details>
<summary>
        Function Parameters
</summary>
        Check whether a function is called with appropriate number of parameters with appropriate types. Function definitions should also be consistent with declaration if there is any. Besides that, a function call cannot be made with non-function type identifier.
</details>
  
## Intermidiate Code Generator

  
