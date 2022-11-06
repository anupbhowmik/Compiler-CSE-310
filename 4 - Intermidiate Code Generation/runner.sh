#!/bin/bash

yacc -d -y 1805082.y
echo 'Generated the parser C file as well the header file'
g++ -w -c -o y.o y.tab.c
echo 'Generated the parser object file'
flex 1805082.l
echo 'Generated the scanner C file'
g++ -fpermissive -w -c -o l.o lex.yy.c
# if the above command doesn't work try  g++ -w -c -o l.o lex.yy.c
echo 'Generated the scanner object file'
g++ y.o l.o -lfl -o parser
echo 'All ready, running'
./parser input.c log.txt error.txt code.asm optimized_code.asm


# valgrind -s --leak-check=full ./parser input.c log.txt error.txt