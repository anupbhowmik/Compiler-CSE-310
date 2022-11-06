%{
#include<bits/stdc++.h>
#include "1805082_SymbolTable.h"

#include <iostream>
#include <fstream>
#include <sstream>
#include <string.h>

using std::cout ;  using std::cerr ; 
using std::endl ;  using std::string ; 
using std::ifstream ;  using std::ostringstream ; 

using namespace std ; 

bool DEBUG = false ; 
// #define YYSTYPE SymbolInfo*
int yyparse(void) ; 
int yylex(void) ; 
extern FILE *yyin ; 
FILE *inputFile ; 

ofstream logFile ; 
ofstream errFile ; 
ofstream asmFile ; 
ofstream optAsmFile ; 
ofstream tempFile ; 

SymbolTable table(30) ; 
int line_count = 1 ; 
int error_count = 0 ; 
int tabCount = 0 ; 
int currOffset = 0 ; 

int currParamOffset = 2 ; 
int currParamLen = 0 ; 
string currFuncName = "" ; 
string currFuncLabel = "" ; 
string whileLabel1 = "" ; 
string whileLabel2 = "" ; 
string forLabel1 = "" ; 
string forLabel2 = "" ; 
string notLabel = "" ; 
string lastExprForCode = "" ; 
int forLoopLineCnt ; 


// string ifLabel1 = "" ; 
// string ifLabel2 = "" ; 
// string elseLabel = "" ; 
stack <string> ifLabel1 ; 
stack <string> ifLabel2 ; 
stack <string> elseLabel ; 
bool inIfAlready = false ; 


string currType = "" ; 

bool isError = false ; 
bool isGlobalSpace = true ; 
bool isArgumentPassing = false ; 
bool noPop = false ; 
bool inForLoop = false ; 

vector <SymbolInfo*>* tempParamList ; 
SymbolInfo * currFunc ; 

int labelCount = 1 ; 
int tempCount = 0 ; 

vector<string> split(const string &s) {
    vector<string> elements ; 
    string item = "" ; 
    for (int i = 0 ;  i < s.length() ;  i++) {
        if (s[i] == ' ' || s[i] == '\t') {
			
            if (item != "") {
                elements.push_back(item) ; 
                item = "" ; 
            }
        }
        else {
			if (s[i] == ' ; ')
				return elements ; 
            item += s[i] ; 
        }
    }

    if (item != "") {
        elements.push_back(item) ; 
    }

    return elements ; 
}

int peepCou = 1;
void optimizeAsmCode(string fileName){
	// cout << fileName << endl ; 
	ifstream file ; 
	file.open(fileName) ; 
	string str ; 
	vector <vector<string> > vecOfLines ; 

	while (getline(file , str)) {
		vector <string> vecOfWords ; 
	
		vecOfWords = split(str) ; 
		if(vecOfWords.size() != 0){
			vecOfLines.push_back(vecOfWords) ; 
		}
	}

//  cout << vecOfLines.size() << endl ; 
	for (int i = 0 ;  i<vecOfLines.size() - 1 ;  i++){
		// cout << "i: " << i << endl ; 
		vector <string> firstLine = vecOfLines[i] ; 
		vector <string> secondLine = vecOfLines[i+1] ; 

		if (firstLine[0] == "PUSH" && secondLine[0] == "POP" && firstLine[1] == secondLine[1]){
			i++ ; 
			optAsmFile << " ; peephole " << peepCou << ": PUSH POP removed\n";
			peepCou++;
			continue ; 

		} else if (firstLine[0] == "PUSH" && secondLine[0] == "POP"){
			// i++ ; 
			optAsmFile << "MOV " << secondLine[1]  << " , " << firstLine[1] << " ; peephole " << peepCou << ": PUSH POP to MOV\n" ; 
			peepCou++;
			continue ; 

		}
		

		// for 2nd or more pass
		if (firstLine[0] == "MOV"){
			// cout << firstLine[1] << endl;
			// cout << firstLine[3] << endl;
		
			
			if (firstLine[1] == firstLine[3]){
				// MOV BX , BX
				// i++ ; 
				optAsmFile << " ; peephole " << peepCou << ": MOV to same loaction removed below\n";
				peepCou++;
		
				continue ; 
			} 
			if (secondLine[0] == "MOV"){
				// two consecutive lines have MOV command
				if (firstLine[1] == secondLine[3] && firstLine[3] == secondLine[1]) {
					// MOV AX , BX
					// MOV BX , AX 
					i++ ; 
					optAsmFile << "MOV " << firstLine[1]  << " , " << firstLine[3] << " ; peephole " << peepCou << ": redundant MOV removed\n" ; 
					continue ; 

				} else if (firstLine[1] == secondLine[1]){
					// MOV AX , BX
					// MOV AX , CX 
					// omit the first line
					i++ ; 
					optAsmFile << "MOV " << secondLine[1]  << " , " << secondLine[3] << " ; peephole " << peepCou << ": omitted first MOV redundant MOV removed \n"; 
					continue ; 
					
				}
				

			}
		}

		// printing to opt file
		
		for (int j = 0 ;  j<vecOfLines[i].size() ;  j++){
			optAsmFile << vecOfLines[i][j] << " " ; 
		}
		
		optAsmFile << endl ; 
		if (i == vecOfLines.size() - 2) {
			// for last line
			for (int j = 0 ;  j<vecOfLines[i+1].size() ;  j++){
				optAsmFile << vecOfLines[i+1][j] << " " ; 
			}
		}
		
		

		// for (int j = 0 ;  j<vecOfLines[i].size() ;  j++){
		// 	// debugging
		// 	cout << vecOfLines[i][j] << " " ; 

		// }
		// cout << endl ; 
		
	}


	



}


char *newLabel() {
	char *lb= new char[4] ; 
	strcpy(lb ,"L") ; 
	char b[3] ; 
	sprintf(b ,"%d" , labelCount) ; 
	labelCount++ ; 
	strcat(lb ,b) ; 
	return lb ; 
}

char *newTemp() {
	char *t= new char[4] ; 
	strcpy(t ,"t") ; 
	char b[3] ; 
	sprintf(b ,"%d" , tempCount) ; 
	tempCount++ ; 
	strcat(t ,b) ; 
	return t ; 
}

int getCurrOffset(){
	currOffset = currOffset - 2 ; 
	return currOffset ; 
}

void resetCurrOffset(){
	currOffset = -8 ; 
}

void setCurrOffset(int offs){
	currOffset = offs ; 
}

int getCurrParamOffset(){
	currParamOffset = currParamOffset + 2 ; 
	return currParamOffset ; 
}

void resetCurrParamOffset(){
	currParamOffset = 2 ; 
}

void setCurrParamOffset(int offs){
	currParamOffset = offs ; 
}

void initCode(){
	string initialCode = ".MODEL SMALL\n.STACK 100H \n\n.DATA\n\tCR EQU 0DH\n\tLF EQU 0AH\n\tNL DB CR , LF\n ;  initialization done\n\n" ; 
	asmFile << initialCode ; 
}

void printEndingCode() {
	string endingCode = "\n\n\tPRINT_NEWLINE PROC\n"
"         ;  PRINTS A NEW LINE WITH CARRIAGE RETURN\n"
"        PUSH AX\n"
"        PUSH DX\n"
"        MOV AH , 2\n"
"        MOV DL , 0Dh\n"
"        INT 21h\n"
"        MOV DL , 0Ah\n"
"        INT 21h\n"
"        POP DX\n"
"        POP AX\n"
"        RET\n"
"    PRINT_NEWLINE ENDP\n"
"    \n"
"    PRINT_CHAR PROC\n"
"         ;  PRINTS A 8 bit CHAR \n"
"         ;  INPUT : GETS A CHAR VIA STACK \n"
"         ;  OUTPUT : NONE    \n"
"        PUSH BP\n"
"        MOV BP , SP\n"
"        \n"
"         ;  STORING THE GPRS\n"
"        PUSH AX\n"
"        PUSH BX\n"
"        PUSH CX\n"
"        PUSH DX\n"
"        PUSHF\n"
"        \n"
"        \n"
"        \n"
"        MOV DX , [BP + 4]\n"
"        MOV AH , 2\n"
"        INT 21H\n"
"        \n"
"        \n"
"        \n"
"        POPF  \n"
"        \n"
"        POP DX\n"
"        POP CX\n"
"        POP BX\n"
"        POP AX\n"
"        \n"
"        POP BP\n"
"        RET 2\n"
"    PRINT_CHAR ENDP \n"
"\n"
"    PRINT_DECIMAL_INTEGER PROC NEAR\n"
"         ;  PRINTS SIGNED INTEGER NUMBER WHICH IS IN HEX FORM IN ONE OF THE REGISTER\n"
"         ;  INPUT : CONTAINS THE NUMBER  (SIGNED 16BIT) IN STACK\n"
"         ;  OUTPUT : \n"
"        \n"
"         ;  STORING THE REGISTERS\n"
"        PUSH BP\n"
"        MOV BP , SP\n"
"        \n"
"        PUSH AX\n"
"        PUSH BX\n"
"        PUSH CX\n"
"        PUSH DX\n"
"        PUSHF\n"
"        \n"
"        MOV AX , [BP+4]\n"
"         ;  CHECK IF THE NUMBER IS NEGATIVE\n"
"        OR AX , AX\n"
"        JNS @POSITIVE_NUMBER\n"
"         ;  PUSHING THE NUMBER INTO STACK BECAUSE A OUTPUT IS WILL BE GIVEN\n"
"        PUSH AX\n"
"\n"
"        MOV AH , 2\n"
"        MOV DL , 2Dh\n"
"        INT 21h\n"
"\n"
"         ;  NOW IT'S TIME TO GO BACK TO OUR MAIN NUMBER\n"
"        POP AX\n"
"\n"
"         ;  AX IS IN 2'S COMPLEMENT FORM\n"
"        NEG AX\n"
"\n"
"        @POSITIVE_NUMBER:\n"
"             ;  NOW PRINTING RELATED WORK GOES HERE\n"
"\n"
"            XOR CX , CX       ;  CX IS OUR COUNTER INITIALIZED TO ZERO\n"
"            MOV BX , 0Ah\n"
"            @WHILE_PRINT:\n"
"                \n"
"                 ;  WEIRD DIV PROPERTY DX:AX / BX = VAGFOL(AX) VAGSESH(DX)\n"
"                XOR DX , DX\n"
"                 ;  AX IS GUARRANTEED TO BE A POSITIVE NUMBER SO DIV AND IDIV IS SAME\n"
"                DIV BX                     \n"
"                 ;  NOW AX CONTAINS NUM/10 \n"
"                 ;  AND DX CONTAINS NUM%10\n"
"                 ;  WE SHOULD PRINT DX IN REVERSE ORDER\n"
"                PUSH DX\n"
"                 ;  INCREMENTING COUNTER \n"
"                INC CX\n"
"\n"
"                 ;  CHECK IF THE NUM IS 0\n"
"                OR AX , AX\n"
"                JZ @BREAK_WHILE_PRINT  ;  HERE CX IS ALWAYS > 0\n"
"\n"
"                 ;  GO AGAIN BACK TO LOOP\n"
"                JMP @WHILE_PRINT\n"
"\n"
"            @BREAK_WHILE_PRINT:\n"
"\n"
"             ; MOV AH , 2\n"
"             ; MOV DL , CL \n"
"             ; OR DL , 30H\n"
"             ; INT 21H\n"
"            @LOOP_PRINT:\n"
"                POP DX\n"
"                OR DX , 30h\n"
"                MOV AH , 2\n"
"                INT 21h\n"
"\n"
"                LOOP @LOOP_PRINT\n"
"\n"
"        CALL PRINT_NEWLINE\n"
"         ;  RESTORE THE REGISTERS\n"
"        POPF\n"
"        POP DX\n"
"        POP CX\n"
"        POP BX\n"
"        POP AX\n"
"        \n"
"        POP BP\n"
"        \n"
"        RET\n"
"\n"
"\n"
"    PRINT_DECIMAL_INTEGER ENDP\n"
"\n"
"END MAIN" ; 
asmFile<<endingCode ; 
}


void yyerror(char *s)
{
	logFile << "Error at line " << line_count << ": syntax error" << endl << endl ; 
	errFile << "Error at line " << line_count << ": syntax error" << endl << endl ; 
	error_count++ ; 
}


%}

%union{
	SymbolInfo * sym ; 
	vector <SymbolInfo*> *symList ; 
}

%token <sym>  IF ELSE FOR WHILE LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD PRINTLN RETURN ASSIGNOP LOGICOP RELOP ADDOP MULOP NOT CONST_INT DOUBLE CHAR MAIN CONST_FLOAT INCOP DECOP
%token <sym> INT FLOAT VOID ID SEMICOLON COMMA ERROR 
%token NEWLINE
%type<sym> type_specifier
%type <symList> declaration_list var_declaration program unit func_declaration parameter_list newIfRule
%type <symList> func_definition compound_statement statements expression_statement statement variable 
%type <symList> expression logic_expression unary_expression factor term rel_expression simple_expression
%type <symList> arguments argument_list


%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE


%%

start : 
program {
	logFile << "Line " << line_count - 1 << ": start : program" << endl << endl ; 
}
 ; 

program : 
program unit {
	logFile << "Line " << line_count <<  ": program : program unit" << endl << endl ; 
	$$ = new vector<SymbolInfo*>() ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
		
		if($1->at(i)->getSymbolType() == "INT" || $1->at(i)->getSymbolType() == "FLOAT" || $1->at(i)->getSymbolType() == "VOID" || $1->at(i)->getSymbolType() == "RETURN"){
			logFile << " " ; 
		}

		if($1->at(i)->getSymbolName() == " ; " || $1->at(i)->getSymbolName() == "{"){
			logFile << endl ; 
		}
		if ($1->at(i)->getSymbolName() == "}"){
			logFile << endl << endl ; 
		}
	}

	for(int i = 0 ;  i < $2->size() ;  i++){
		logFile << $2->at(i)->getSymbolName() ; 
		$$->push_back($2->at(i)) ; 
		
		if($2->at(i)->getSymbolType() == "INT" || $2->at(i)->getSymbolType() == "FLOAT" || $2->at(i)->getSymbolType() == "VOID" || $2->at(i)->getSymbolType() == "RETURN"){
			logFile << " " ; 
		}

		
		if($2->at(i)->getSymbolName() == " ; " || $2->at(i)->getSymbolName() == "{"){
			logFile << endl ; 
		}
		if ($2->at(i)->getSymbolName() == "}"){
			logFile << endl << endl ; 
		}
	}
	logFile << endl << endl ; 
}
| unit {
	logFile << "Line " << line_count <<  ": program : unit" << endl << endl ; 
	$$ = new vector<SymbolInfo*>() ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
		
		if($1->at(i)->getSymbolType() == "INT" || $1->at(i)->getSymbolType() == "FLOAT" || $1->at(i)->getSymbolType() == "VOID" || $1->at(i)->getSymbolType() == "RETURN"){
			logFile << " " ; 
		}

		if($1->at(i)->getSymbolName() == " ; " || $1->at(i)->getSymbolName() == "{" || $1->at(i)->getSymbolName() == "}"){
			logFile << endl ; 
		}
	}
	logFile << endl << endl ; 
}
 ; 
	
unit : 
var_declaration {
	logFile << "Line " << line_count <<  ": unit : var_declaration" << endl << endl ; 
	$$ = new vector<SymbolInfo*>() ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
		
		if($1->at(i)->getSymbolType() == "INT" || $1->at(i)->getSymbolType() == "FLOAT" || $1->at(i)->getSymbolType() == "VOID"){
			logFile << " " ; 
		}
		
	}
	logFile << endl << endl << endl ; 

}
| func_declaration {
	logFile << "Line " << line_count <<  ": unit : func_declaration" << endl << endl ; 
	$$ = new vector<SymbolInfo*>() ; 
	
	for (int i = 0 ;  i<$1->size() ;  i++){
		
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
		
		if($1->at(i)->getSymbolType() == "INT" || $1->at(i)->getSymbolType() == "FLOAT" || $1->at(i)->getSymbolType() == "VOID"){
			logFile << " " ; 
		}
	}
	logFile << endl << endl<< endl ; 
}
| func_definition {
	logFile << "Line " << line_count <<  ": unit : func_definition" << endl << endl ; 
	$$ = new vector<SymbolInfo*>() ; 
	
	for (int i = 0 ;  i<$1->size() ;  i++) {
		
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
		
		if($1->at(i)->getSymbolType() == "INT" || $1->at(i)->getSymbolType() == "FLOAT" || $1->at(i)->getSymbolType() == "VOID" || $1->at(i)->getSymbolType() == "RETURN"){
			logFile << " " ; 
		}
		if($1->at(i)->getSymbolName() == " ; " || $1->at(i)->getSymbolName() == "{" || $1->at(i)->getSymbolName() == "}"){
			logFile << endl ; 
		}

		if ($1->at(i)->getSymbolType() == "RETURN" && $1->at(0)->getSymbolType() == "VOID"){
			logFile << "Error at line " << line_count << ": Returning from a function which has Void return type " << endl << endl ; 
			errFile << "Error at line " << line_count << ": Returning from a function which has Void return type " << endl << endl ; 
			error_count++ ; 
		}
	}
	
	logFile << endl << endl << endl ; 
	
}
 ; 
     
func_declaration: 
type_specifier ID LPAREN parameter_list RPAREN SEMICOLON {
	logFile << "Line " << line_count <<  ": func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON" << endl << endl ; 
	$$ = new vector<SymbolInfo*>() ; 

	$2->setIsFunction(true) ; 
	//  // cout << "set ret type: " << $1->getSymbolType() << endl ; 
	//  // cout << "get symbol type: " << $2->getSymbolType() << endl ; 
	$2->setReturnType($1->getSymbolType()) ; 
	$2->setParamList($4) ; 
	
	//  // cout << "ret type: " << $2->getReturnType() << endl ; 

	if(!table.insert($2)){
		logFile << "Error at line " << line_count << ": Multiple declaration of " << $2->getSymbolName() << endl << endl ; 
		errFile << "Error at line " << line_count << ": Multiple declaration of " << $2->getSymbolName() << endl << endl ; 
		error_count++ ; 
	}
	
	
	logFile << $1->getSymbolName() << " " << $2->getSymbolName() << $3->getSymbolName() ; 

	
	for(int i = 0 ;  i<$4->size() ;  i++){
		logFile << $4->at(i)->getSymbolName() ; 
		if($4->at(i)->getSymbolType() == "INT" || $4->at(i)->getSymbolType() == "FLOAT" || $4->at(i)->getSymbolType() == "VOID"){
			logFile << " " ; 
			
		}

		if($4->at(i)->getSymbolType() == "COMMA" || $4->at(i)->getSymbolType() == "INT" || $4->at(i)->getSymbolType() == "FLOAT" || $4->at(i)->getSymbolType() == "VOID"){
			// skipping test for type specifiers , only testing IDs
			continue ; 
		}

		vector <string> paramList ; 
		paramList.push_back($4->at(i)->getSymbolName()) ; 
		for(int j = 0 ;  j<paramList.size() - 1 ;  j++){
			if($4->at(i)->getSymbolName() == paramList[j]){
				logFile << "Error at line " << line_count << ": Multiple declaration of " << $4->at(i)->getSymbolName() << " in param list" << endl << endl ; 
				errFile << "Error at line " << line_count << ": Multiple declaration of " << $4->at(i)->getSymbolName() << " in param list" << endl << endl ; 
				error_count++ ; 
			}
		}
		//  // cout << endl ; 
	}

	int j = 0 ; 
	for(int i = 0 ;  i<$4->size() ;  i++) {
		// // cout << $4->at(i)->getSymbolType() << " " ; 
		
		if (i%3==0)
			j++ ; 

		if ($4->at(i)->getSymbolType() == "ERROR") {
			logFile << "Error at line " << line_count << ": " << j << "th parameter's name not given in function declaration of " << $2->getSymbolName() << endl << endl ; 
			errFile << "Error at line " << line_count << ": " << j << "th parameter's name not given in function declaration of " << $2->getSymbolName() << endl << endl ; 
			
			error_count++ ; 
		}

	}
	
	logFile << $5->getSymbolName() << $6->getSymbolName() << endl << endl << endl ; 
			
	$$ = new vector <SymbolInfo*>() ; 
	$$->push_back($1) ; 
	$$->push_back($2) ; 
	$$->push_back($3) ; 
	
	// store param list with respective type
	for(int i = 0 ;  i<$4->size() ;  i++) {
		$$->push_back($4->at(i)) ; 
	}

	$$->push_back($5) ; 
	$$->push_back($6) ; 
}
| type_specifier ID LPAREN RPAREN SEMICOLON {
	logFile << "Line " << line_count <<  ": func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON" << endl << endl ; 
	$$ = new vector<SymbolInfo*>() ; 

	$2->setIsFunction(true) ; 
	//  // cout << "set ret type: " << $1->getSymbolType() << endl ; 
	//  // cout << "get symbol type: " << $2->getSymbolType() << endl ; 
	$2->setReturnType($1->getSymbolType()) ; 
	
	if(!table.insert($2)){
		logFile << "Error at line " << line_count << ": Multiple declaration of " << $2->getSymbolName() << endl << endl ; 
		errFile << "Error at line " << line_count << ": Multiple declaration of " << $2->getSymbolName() << endl << endl ; 
		error_count++ ; 
	}
	
	logFile << $1->getSymbolName() << " " << $2->getSymbolName() << $3->getSymbolName() << $4->getSymbolName() << $5->getSymbolName() << endl << endl << endl ; 
			
	$$ = new vector <SymbolInfo*>() ; 
	$$->push_back($1) ; 
	$$->push_back($2) ; 
	$$->push_back($3) ; 
	$$->push_back($4) ; 
	$$->push_back($5) ; 

}
 ; 
		 
func_definition : 
type_specifier ID LPAREN parameter_list RPAREN {
	// will understand if declared if already found on symbol table
	currFuncLabel = newLabel() ; 
	resetCurrOffset() ; 

	if(isGlobalSpace)
		asmFile << ".CODE" << endl ; 
	asmFile << "\n\t" << $2->getSymbolName() << " PROC\n" ; 
	isGlobalSpace = false ; 

	if($2->getSymbolName() == "main"){
		asmFile << "\t\tmov AX , @DATA\n\t\tmov DS , AX\n\t\t ;  data segment loaded\n\n" ; 
		// asmFile << "\t\tPUSH BP\t ;  saving BP in stack\n\t\tMOV BP , SP\t ;  loading the current SP to BP\n" ; 
	} else {
		
		string code = "\t\tPUSH BP\n"
					"\t\tMOV BP , SP\n"
					"\n"
					"\t\t ;  STORING THE GPRS\n"
					"\t\t ;  DX for returning results\n"
					"\t\tPUSH AX\n"
					"\t\tPUSH BX\n"
					"\t\tPUSH CX\n"
					"\t\tPUSHF\n\n" ; 
		asmFile << code ; 
	}


	SymbolInfo * currSymbol = table.getSymbolInfo($2->getSymbolName()) ; 
	
	string funcName = $2->getSymbolName() ; 
	currFuncName = $2->getSymbolName() ; 
	
	if (table.lookupEntire($2->getSymbolName())) {
		// cout << "get symbol type: " << currSymbol->getSymbolType() << endl ; 
		// the ID is available in the symbol table
		// already declared as ID or function declaration
		
		// already checked for multiple IDs of same variable name in func_declaration part , no need to raise error again
		if (!currSymbol->isFunction()) {
			// logFile << "Error at line " << line_count << ": Identifier '" << $2->getSymbolName() << "' is not a function." << endl << endl ; 
			// errFile << "Error at line " << line_count << ": Identifier '" << $2->getSymbolName() << "' is not a function." << endl << endl ; 
			errFile << "Error at line " << line_count << ": Multiple declaration of " << $2->getSymbolName() << endl << endl ; 
			logFile << "Error at line " << line_count << ": Multiple declaration of " << $2->getSymbolName() << endl << endl ; 
			error_count++ ; 
		} else {
			if (currSymbol->isDefined()){
				logFile << "Error at line " << line_count << ": Re-definition of function '" << $2->getSymbolName() << "'" << endl << endl ; 
				errFile << "Error at line " << line_count << ": Re-definition of function '" << $2->getSymbolName() << "'" << endl << endl ; 
				
				error_count++ ; 
			} else {
				// check the param list and return type for inconsistency with the declaration
				if (currSymbol->getReturnType() != $1->getSymbolType()){
					logFile << "Error at line " << line_count << ": Return type mismatch with function declaration in function " << funcName << endl << endl ; 
					errFile << "Error at line " << line_count << ": Return type mismatch with function declaration in function " << funcName << endl << endl ; 
					
					error_count++ ; 
				}

				if (currSymbol->getParamList()->size() != $4->size()){
					logFile << "Error at line " << line_count << ": Total number of arguments mismatch with declaration in function "  << funcName << endl << endl ; 
					errFile << "Error at line " << line_count << ": Total number of arguments mismatch with declaration in function "  << funcName << endl << endl ; 
					
					error_count++ ; 
				} else if( $4->size() != 0) {
					
					for(int i = 0 ;  i<$4->size() ;  i++) {
						if ($4->at(i)->getSymbolType() == "ID" ||$4->at(i)->getSymbolType() == "COMMA"){
							// no need to check if the IDs are of the same name , only the types must match
							continue ; 
						}
						if (currSymbol->getParamList()->at(i)->getSymbolName() != $4->at(i)->getSymbolName()){
							logFile << "Error at line " << line_count << ": Type mismatch of function parameter '" << currSymbol->getParamList()->at(i)->getSymbolName() << "'" << endl << endl ; 
							errFile << "Error at line " << line_count << ": Type mismatch of function parameter '" << currSymbol->getParamList()->at(i)->getSymbolName() << "'" << endl << endl ; 
							
							error_count++ ; 
						}
					}

					
				}

				string funcName = currSymbol->getSymbolName() ; 
				string symType = currSymbol->getSymbolType() ; 
				SymbolInfo * newSymbol = new SymbolInfo(funcName , symType) ; 
				vector <SymbolInfo*>* paramList = currSymbol->getParamList() ; 
				currSymbol->setParamList(paramList) ; 
				currSymbol->setIsDefined(true) ; 
				currSymbol->setIsFunction(true) ; 
				
				// table.remove(currSymbol->getSymbolName()) ; 	// removing old declared function and inserting a new symbol info in the table with defined status
				// HERE WE DELETED $2 , MUST NOT TRY TO ACCESS IN ANY LATER PART
				//  // cout << "get defined ret type: " << currSymbol->getReturnType() << endl ; 
				currFunc = table.getSymbolInfo(funcName) ; 
				
			}
		}
	} else {
		// the func is not declared yet , direct definition found
		// check if multiple declaration of param name on the same list
		for(int i = 0 ;  i<$4->size() ;  i++){

			if($4->at(i)->getSymbolType() == "COMMA" || $4->at(i)->getSymbolType() == "INT" || $4->at(i)->getSymbolType() == "FLOAT" || $4->at(i)->getSymbolType() == "VOID"){
				// skipping test for type specifiers , only testing IDs
				continue ; 
			}
			currParamLen++ ; 
			vector <string> paramList ; 
			paramList.push_back($4->at(i)->getSymbolName()) ; 
			for(int j = 0 ;  j<paramList.size() - 1 ;  j++){
				if($4->at(i)->getSymbolName() == paramList[j]){
					logFile << "Error at line " << line_count << ": Multiple declaration of " << $4->at(i)->getSymbolName() << " in param list" << endl << endl ; 
					errFile << "Error at line " << line_count << ": Multiple declaration of " << $4->at(i)->getSymbolName() << " in param list" << endl << endl ; 
					error_count++ ; 
				}
			}
		
		}

		SymbolInfo * newSymbol = new SymbolInfo(funcName , "ID") ; 
		vector <SymbolInfo*>* paramList = $4 ; 
		newSymbol->setParamList(paramList) ; 
		newSymbol->setIsDefined(true) ; 
		newSymbol->setIsFunction(true) ; 

		//  // cout << "set ret type: " << $1->getSymbolType() << endl ; 
		newSymbol->setReturnType($1->getSymbolType()) ; 

		table.insert(newSymbol) ; 

		// tempParamList = new vector<SymbolInfo*> ; 
		// for (int i = 0 ;  i<$4->size() ;  i++) {
		// 	tempParamList->push_back($4->at(i)) ; 
		// }
	
		currFunc = table.getSymbolInfo(funcName) ; 
		//  // cout << "herer" << endl ; 
	}

	int j = 0 ; 
	for(int i = 0 ;  i<$4->size() ;  i++) {
		// // cout << $4->at(i)->getSymbolType() << " " ; 
		
		if (i%3==0)
			j++ ; 

		if ($4->at(i)->getSymbolType() == "ERROR") {
			logFile << "Error at line " << line_count << ": " << j << "th parameter's name not given in function definition of " << $2->getSymbolName() << endl << endl ; 
			errFile << "Error at line " << line_count << ": " << j << "th parameter's name not given in function definition of " << $2->getSymbolName() << endl << endl ; 
			
			error_count++ ; 
		}

	}

	// adding the parameters to symbol table in either case
	tempParamList = new vector<SymbolInfo*> ; 
	for (int i = 0 ;  i<$4->size() ;  i++) {
		tempParamList->push_back($4->at(i)) ; 
	}
	resetCurrParamOffset() ; 

	for (int i = $4->size() - 1 ;  i>=0 ;  i--) {
		if (tempParamList->at(i)->getSymbolType() != "ID" || tempParamList->at(i)->getSymbolType() == "ERROR") {
			continue ; 
		}
		// set param offset here in reverse direction
		// cout << $4->at(i)->getSymbolName() << endl ; 
		$4->at(i)->setOffset(getCurrParamOffset()) ; 

	}

} compound_statement {
	table.printAllScopeTables() ; 
	table.exitScope() ; 
	
} {
	logFile << "Line " << line_count <<  ": func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement" << endl << endl ; 
	$$ = new vector<SymbolInfo*>() ; 

	logFile << $1->getSymbolName() << " " << $2->getSymbolName() << $3->getSymbolName() ; 
	
	$$->push_back($1) ; 
	$$->push_back($2) ; 
	$$->push_back($3) ; 
	for (int i = 0 ;  i < $4->size() ;  i++){
		logFile << $4->at(i)->getSymbolName() ; 
		$$->push_back($4->at(i)) ; 
		if($4->at(i)->getSymbolType() == "INT" || $4->at(i)->getSymbolType() == "FLOAT" || $4->at(i)->getSymbolType() == "VOID" || $4->at(i)->getSymbolType() == "RETURN")
			logFile << " " ; 
	}
	logFile << $5->getSymbolName() ; 
	$$->push_back($5) ; 
	for (int i = 0 ;  i < $7->size() ;  i++){
		logFile << $7->at(i)->getSymbolName() ; 
		$$->push_back($7->at(i)) ; 
		if($7->at(i)->getSymbolType() == "INT" || $7->at(i)->getSymbolType() == "FLOAT" || $7->at(i)->getSymbolType() == "VOID" || $7->at(i)->getSymbolType() == "RETURN")
			logFile << " " ; 
		if($7->at(i)->getSymbolName() == " ; " || $7->at(i)->getSymbolName() == "{" || $7->at(i)->getSymbolName() == "}")
			logFile << endl ; 
	}
	logFile << endl << endl ; 

	if(currFunc->getSymbolName() == "main"){
		asmFile <<  "\n\t\t ;  return point main\n" ; 
		asmFile << 	"\t\t" << newLabel()  ; 
		asmFile <<  ": \n" ; 
		asmFile <<	"\t\tmov AH , 4Ch\n" ; 
		asmFile <<	"\t\tint 21h\n" ; 
		asmFile <<	"\t\t ;  returned control to OS\n\n" ; 
		asmFile << "\tmain ENDP\n\n" ; 
	} else {
		asmFile << "\t\t ;  return point of proc " << currFuncName << endl ;  
		asmFile << "\t\t" << currFuncLabel << ":\n" ; 
		string code = "\t\tMOV SP , BP\n"
		"\t\tSUB SP , 8\n"	// hardcoded
		"\t\tPOPF  \n"
		"\n"
		"\t\tPOP CX\n"
		"\t\tPOP BX\n"
		"\t\tPOP AX\n"
		"\n"
		"\t\tPOP BP\n\n" ; 
		asmFile << code ; 
		asmFile << "\t\tRET " << currParamLen*2 << endl<< endl ; 
		asmFile << "\t" << currFuncName << " ENDP\n\n" ; 
		currParamLen = 0 ; 

	}

	tempParamList->clear() ; 

	resetCurrParamOffset() ; 
	
	
}
| type_specifier ID LPAREN RPAREN {

	currFuncLabel = newLabel() ; 
	resetCurrOffset() ; 
	currFuncName = $2->getSymbolName() ; 
	
	if(isGlobalSpace)
		asmFile << ".CODE" << endl ; 
	asmFile << "\n\t" << $2->getSymbolName() << " PROC\n" ; 
	isGlobalSpace = false ; 

	if($2->getSymbolName() == "main"){
		asmFile << "\t\tmov AX , @DATA\n\t\tmov DS , AX\n\t\t ;  data segment loaded" << endl ; 
	} else {
		string code = "\t\tPUSH BP\n"
					"\t\tMOV BP , SP\n"
					"\n"
					"\t\t ;  STORING THE GPRS\n"
					"\t\t ;  DX for returning results\n"
					"\t\tPUSH AX\n"
					"\t\tPUSH BX\n"
					"\t\tPUSH CX\n"
					"\t\tPUSHF\n\n" ; 
		asmFile << code ; 
	}

	// asmFile << "\t\tPUSH BP\t ;  saving BP in stack\n\t\tMOV BP , SP\t ;  loading the current SP to BP\n" ; 
	

	SymbolInfo * currSymbol = table.getSymbolInfo($2->getSymbolName()) ; 
	string funcName = $2->getSymbolName() ; 

	if (table.lookupEntire($2->getSymbolName())) {
		// the ID is available in the symbol table
		// already declared as ID or function declaration
		
		if (!currSymbol->isFunction()) {
			logFile << "Error at line " << line_count << ": Identifier '" << $2->getSymbolName() << "' is not a function." << endl << endl ; 
			errFile << "Error at line " << line_count << ": Identifier '" << $2->getSymbolName() << "' is not a function." << endl << endl ; 
			error_count++ ; 
		} else {
			if (currSymbol->isDefined()){
				logFile << "Error at line " << line_count << ": Re-definition of function '" << $2->getSymbolName() << "'" << endl << endl ; 
				errFile << "Error at line " << line_count << ": Re-definition of function '" << $2->getSymbolName() << "'" << endl << endl ; 
				
				error_count++ ; 
			} else {
				if (currSymbol->getReturnType() != $1->getSymbolType()){
					logFile << "Error at line " << line_count << ": Function return type doesn't match with declaration" << endl << endl ; 
					errFile << "Error at line " << line_count << ": Function return type doesn't match with declaration" << endl << endl ; 
					
					error_count++ ; 
				}
			}
		}
		
		currSymbol->setIsDefined(true) ; 
		currSymbol->setIsFunction(true) ; 
		//  // cout << "get defined ret type: " << currSymbol->getReturnType() << endl ; 

		currFunc = table.getSymbolInfo(funcName) ; 
		

	} else {
		// the func is not declared yet , direct definition found
		// // cout << "funct name " << funcName << endl ; 
		SymbolInfo * newSymbol = new SymbolInfo(funcName , "ID") ; 
		newSymbol->setIsDefined(true) ; 
		newSymbol->setIsFunction(true) ; 
		//  // cout << "set ret type: " << $1->getSymbolType() << endl ; 
		newSymbol->setReturnType($1->getSymbolType()) ; 
		
		table.insert(newSymbol) ; 
		currFunc = table.getSymbolInfo(funcName) ; 

	
		
	}
}
 compound_statement {
	table.printAllScopeTables() ; 
	table.exitScope() ; 
} {
	
	logFile << "Line " << line_count <<  ": func_definition : type_specifier ID LPAREN RPAREN compound_statement" << endl << endl ; 
	$$ = new vector<SymbolInfo*>() ; 

	logFile << $1->getSymbolName() << " " << $2->getSymbolName() << $3->getSymbolName() << $4->getSymbolName() ; 
	$$->push_back($1) ; 
	$$->push_back($2) ; 
	$$->push_back($3) ; 
	$$->push_back($4) ; 
	
	for (int i = 0 ;  i < $6->size() ;  i++){
		logFile << $6->at(i)->getSymbolName() ; 
		$$->push_back($6->at(i)) ; 
		if($6->at(i)->getSymbolType() == "INT" || $6->at(i)->getSymbolType() == "FLOAT" || $6->at(i)->getSymbolType() == "VOID" || $6->at(i)->getSymbolType() == "RETURN" || $6->at(i)->getSymbolType() == "IF")
			logFile << " " ; 
		if($6->at(i)->getSymbolName() == " ; " || $6->at(i)->getSymbolName() == "{" || $6->at(i)->getSymbolName() == "}" || $6->at(i)->getSymbolName() == "ELSE")
			logFile << endl ; 
	}
	logFile << endl << endl ; 

	if(currFunc->getSymbolName() == "main"){
		asmFile <<  "\n\t\t ;  return point main\n" ; 
		asmFile << 	"\t\t" << currFuncLabel  ; 
		asmFile <<  ": \n" ; 
		asmFile <<	"\t\tmov AH , 4Ch\n" ; 
		asmFile <<	"\t\tint 21h\n" ; 
		asmFile <<	"\t\t ;  returned control to OS\n\n" ; 
		asmFile << "\tmain ENDP\n\n" ; 
		
	} else {
		asmFile << "\t\t ;  return point of proc " << currFuncName << endl ;  
		asmFile << "\t\t" << currFuncLabel << ":\n" ; 
		string code = "\t\tMOV SP , BP\n"
		"\t\tSUB SP , 8\n"	// hardcoded
		"\t\tPOPF  \n"
		"\n"
		"\t\tPOP CX\n"
		"\t\tPOP BX\n"
		"\t\tPOP AX\n"
		"\n"
		"\t\tPOP BP\n\n" ; 
		asmFile << code ; 
		asmFile << "\t\tRET 0" << endl<< endl ;  // RET 0 cz no parameeter
		asmFile << "\t" << currFuncName << " ENDP\n\n" ; 
	}

	resetCurrParamOffset() ; 
 }
 ; 

parameter_list : 
parameter_list COMMA type_specifier ID {

	int  currOff = getCurrParamOffset() ; 
	$4->setOffset(currOff) ; 

	logFile << "Line " << line_count <<  ": parameter_list : parameter_list COMMA type_specifier ID" << endl << endl ; 
	$$ = new vector<SymbolInfo*>() ; 
	
	for (int i = 0 ;  i<$1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
		
		if($1->at(i)->getSymbolType() == "INT" || $1->at(i)->getSymbolType() == "FLOAT" || $1->at(i)->getSymbolType() == "VOID"){
			logFile << " " ; 
		}

	}
	logFile << $2->getSymbolName() << $3->getSymbolName() << " " << $4->getSymbolName() << endl << endl ; 
	$$->push_back($2) ; 
	$$->push_back($3) ; 
	$$->push_back($4) ; 
	
}
| parameter_list COMMA type_specifier {
	// eta apatoto lagbe na
	logFile << "Line " << line_count <<  ": parameter_list : parameter_list COMMA type_specifier" << endl << endl ; 
	$$ = new vector <SymbolInfo*>() ; 
	
	for (int i = 0 ;  i<$1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
		
		if($1->at(i)->getSymbolType() == "INT" || $1->at(i)->getSymbolType() == "FLOAT" || $1->at(i)->getSymbolType() == "VOID"){
			logFile << " " ; 
		}

	}
	logFile << $2->getSymbolName() << $3->getSymbolName() << endl << endl ; 
	$$->push_back($2) ; 
	$$->push_back($3) ; 
	
}

| parameter_list COMMA type_specifier error {
	logFile << "Line " << line_count <<  ": parameter_list : parameter_list COMMA type_specifier" << endl << endl ; 
	$$ = new vector <SymbolInfo*>() ; 
	
	for (int i = 0 ;  i<$1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
		
		if($1->at(i)->getSymbolType() == "INT" || $1->at(i)->getSymbolType() == "FLOAT" || $1->at(i)->getSymbolType() == "VOID"){
			logFile << " " ; 
		}

	}
	logFile << $2->getSymbolName() << $3->getSymbolName() << endl << endl ; 
	$$->push_back($2) ; 
	$$->push_back($3) ; 

	SymbolInfo* errSymbol = new SymbolInfo("" , "ERROR") ; 
	$$->push_back(errSymbol) ; 
	
	yyclearin ; 

}

| type_specifier ID {
	

	int  currOff = getCurrParamOffset() ; 
	$2->setOffset(currOff) ; 

	logFile << "Line " << line_count <<  ": parameter_list : type_specifier ID" << endl << endl ; 
	$$ = new vector <SymbolInfo*>() ; 
	
	logFile << $1->getSymbolName() << " " << $2->getSymbolName() << endl << endl ; 
	$$->push_back($1) ; 
	$$->push_back($2) ; 

}
| type_specifier {
	// eta apatoto ignore
	logFile << "Line " << line_count <<  ": parameter_list : type_specifier" << endl << endl ; 
	$$ = new vector <SymbolInfo*>() ; 
	
	logFile << $1->getSymbolName() << endl << endl ; 
	$$->push_back($1) ; 
	
}

| type_specifier error {
	logFile << "Line " << line_count <<  ": parameter_list : type_specifier" << endl << endl ; 
	$$ = new vector <SymbolInfo*>() ; 
	
	logFile << $1->getSymbolName() << endl << endl ; 
	$$->push_back($1) ; 

	SymbolInfo* errSymbol = new SymbolInfo("" , "ERROR") ; 
	$$->push_back(errSymbol) ; 
	
	yyclearin ; 
}
 ; 

compound_statement : 
LCURL {

	isGlobalSpace = false ; 

	table.enterScope() ; 
	// insert the parameters in the current scope table
	for (int i = 0 ;  i<tempParamList->size() ;  i++){
		
		if (tempParamList->at(i)->getSymbolType() != "ID" || tempParamList->at(i)->getSymbolType() == "ERROR") {
			continue ; 
		}
		if (!table.insert(tempParamList->at(i))){
			logFile << "Error at line " << line_count -1 << ": Multiple declaration of " << tempParamList->at(i)->getSymbolName() << " in parameter" << endl << endl ; 
			errFile << "Error at line " << line_count -1 << ": Multiple declaration of " << tempParamList->at(i)->getSymbolName() << " in parameter" << endl << endl ; 
			
			error_count++ ; 
		}
	}
	// tempParamList = NULL ; 

} statements RCURL {

	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": compound_statement : LCURL statements RCURL" << endl << endl ; 

	logFile << $1->getSymbolName() << endl ; 
	$$->push_back($1) ; 

	
	for(int i = 0 ;  i < $3->size() ;  i++){
		$$->push_back($3->at(i)) ; 
		logFile << $3->at(i)->getSymbolName() ; 
		if($3->at(i)->getSymbolType() == "INT" || $3->at(i)->getSymbolType() == "FLOAT" || $3->at(i)->getSymbolType() == "VOID" || $3->at(i)->getSymbolType() == "RETURN" || $3->at(i)->getSymbolType() == "IF" )
			logFile << " " ; 
		if($3->at(i)->getSymbolName() == " ; " || $3->at(i)->getSymbolName() == "{" || $3->at(i)->getSymbolName() == "}" || $3->at(i)->getSymbolName() == "ELSE")
			logFile << endl ; 
	}

	logFile << $4->getSymbolName() << endl << endl ; 
	$$->push_back($4) ; 
	

}
| LCURL {
	isGlobalSpace = false ; 
	table.enterScope() ; 

} RCURL {
	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": compound_statement : LCURL RCURL" << endl << endl ; 
	logFile << $1->getSymbolName() << $3->getSymbolName() << endl << endl ; 
	$$->push_back($1) ; 
	$$->push_back($3) ; 

	table.printAllScopeTables() ; 
	// table.exitScope() ; 
}
 ; 
 		    
var_declaration : 
type_specifier declaration_list SEMICOLON {


	// setting global type
	currType = $1->getSymbolType() ; 

	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": var_declaration : type_specifier declaration_list SEMICOLON" << endl << endl ; 
	
	if($1->getSymbolType() == "VOID"){
		logFile << "Error at line " << line_count << ": Variable type cannot be void" << endl << endl ;  ; 
		errFile << "Error at line " << line_count << ": Variable type cannot be void" << endl << endl ;  ;  
		error_count++ ; 
	}

	logFile << $1->getSymbolName() << " " ; 
	$$->push_back($1) ; 
	for(int i = 0 ;  i < $2->size() ;  i++){
		$$->push_back($2->at(i)) ; 
		logFile << $2->at(i)->getSymbolName() ; 
		if ($2->at(i)->getSymbolType() == "ERROR") {
			// logFile << "Error at line " << line_count << ": syntax error" << endl << endl ; 
			// errFile << "Error at line " << line_count << ": syntax error" << endl << endl ; 
			error_count++ ; 
		}
	}
	
	logFile << $3->getSymbolName() << endl << endl ; 
	$$->push_back($3) ; 

}
 ; 
 		 
type_specifier	: 
INT	{
	logFile << "Line " << line_count << ": type_specifier : INT" << endl << endl ; 
	logFile << $1->getSymbolName() << endl<< endl ; 
	$$ = $1 ; 
	currType = "INT" ; 
}
| FLOAT {
	logFile << "Line " << line_count << ": type_specifier : FLOAT" << endl << endl ; 
	logFile << $1->getSymbolName() << endl<< endl ; 
	$$ = $1 ; 
	currType = "FLOAT" ; 
}
| VOID {
	logFile << "Line " << line_count << ": type_specifier : VOID" << endl << endl ; 
	logFile << $1->getSymbolName() << endl<< endl ; 
	$$ = $1 ; 
	currType = "VOID" ; 
}
 ; 
 		
declaration_list : 
declaration_list COMMA ID {
	if (DEBUG){
		logFile << "test" << endl ; 
 		table.printAllScopeTables() ; 
	}

	if (currType == "INT"){
		if (isGlobalSpace){
			for (int i = 0 ;  i< tabCount ;  i++){
				asmFile <<  "\t" ; 
			}
			asmFile << "\t" << $3->getSymbolName() << " DW 0\t ;  line no " << line_count << " " << $3->getSymbolName() << " declared\n\n" ; 
		} 
	} else {
		cout << "Float not supported" << endl ; 
		error_count ++ ; 
	}

	$3->setVariableType(currType) ; 
	if(isGlobalSpace){
		// setting global variable
		$3->setOffset(0) ; 
	} else {
		// setting appropriate offset for local vars
		int  currOff = getCurrOffset() ; 
		$3->setOffset(currOff) ; 
		// cout << currOff << endl ; 
		asmFile << "\t\t"<< "PUSH BX\t ;  line no " << line_count << " " << $3->getSymbolName() << " declared\n\n" ; 
		// pushing garbage value to stack and updating the SP	
	}

	if(!table.insert($3)){
		logFile << "Error at line " << line_count << ": Multiple declaration of " << $3->getSymbolName() <<endl<<endl ; 
		errFile << "Error at line " << line_count << ": Multiple declaration of " << $3->getSymbolName() <<endl<<endl ; 
		error_count++ ; 
	}

	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": declaration_list : declaration_list COMMA ID" << endl << endl ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		// taking the old list from $1 and adding to $$
		$$->push_back($1->at(i)) ; 
		logFile << $1->at(i)->getSymbolName() ; 
	}
	logFile << $2->getSymbolName() << $3->getSymbolName() << endl << endl ; 
	$$->push_back($2) ; 	// adding COMMA as well
	$$->push_back($3) ; 

	

}

| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {

	if (currType == "INT"){
		if (isGlobalSpace){
			for (int i = 0 ;  i< tabCount ;  i++){
				asmFile <<  "\t" ; 
			}
			asmFile << "\t" << $3->getSymbolName() << " DW " << $5->getSymbolName() << " DUP (0)\t ;  line no " << line_count << " " << $3->getSymbolName() << " array declared\n"  ; 
		}
	} else {
		cout << "Float not supported" << endl ; 
		error_count ++ ; 
	}

	$3->setVariableType(currType) ; 
	if(isGlobalSpace){
		// setting global variable
		$3->setOffset(0) ; 
	} else {
		// setting appropriate offset for local vars
		$3->setOffset(getCurrOffset()) ; 		// offset to the first element of the array

		// pushing garbage value to stack and updating the SP	
		asmFile << "\t\tMOV CX , " << $5->getSymbolName() << "\t ;  line no "<< line_count << ": new array of size " << $5->getSymbolName() << endl ; 
		string currLabel1 = newLabel() ; 
		asmFile <<"\t\t" << currLabel1 << ":" << endl ; 
		string currLabel2 = newLabel() ; 
		asmFile << "\t\tJCXZ " << currLabel2 << endl ; 
		asmFile << "\t\tPUSH BX" << endl ; 
		asmFile << "\t\tDEC CX" << endl ; 
		asmFile << "\t\tJMP " <<  currLabel1 << endl ; 
		asmFile <<"\t\t" <<  currLabel2 << ": \n" ;  
		
		int arrSize = stoi($5->getSymbolName()) ; 
		// cout << arrSize << endl ; 
		setCurrOffset(currOffset - arrSize*2) ; 
	}

	$3->setIsArray(true) ; 
	$3->setVariableType(currType) ; 
	if(!table.insert($3)){
		logFile << "Error at line " << line_count << ": Multiple declaration of " << $3->getSymbolName() <<endl<<endl ; 
		errFile << "Error at line " << line_count << ": Multiple declaration of " << $3->getSymbolName() <<endl<<endl ; 
		error_count++ ; 
	}

	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD" << endl << endl ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		// taking the old list from $1 and adding to $$
	
		$$->push_back($1->at(i)) ; 
		logFile << $1->at(i)->getSymbolName() ; 
	}
	logFile << $2->getSymbolName() << $3->getSymbolName() << $4->getSymbolName() << $5->getSymbolName() << $6->getSymbolName() << endl << endl ; 
	$$->push_back($2) ; 	// adding COMMA as well
	$$->push_back($3) ; 
	$$->push_back($4) ; 
	$$->push_back($5) ; 
	$$->push_back($6) ; 

	

}
| ID {

	if(isGlobalSpace){
		// setting global variables
		$1->setOffset(0) ; 
	} else {
		// setting appropriate offset for local vars
		int  currOff = getCurrOffset() ; 
		$1->setOffset(currOff) ; 
		// cout << currOff << endl ; 
		
		asmFile << "\t\t"<< "PUSH BX\t ;  line no " << line_count << " " << $1->getSymbolName() << " declared\n\n" ; 
		// pushing garbage value to stack and updating the SP
	}

	if(!table.insert($1)){
		logFile << "Error at line " << line_count << ": Multiple declaration of " << $1->getSymbolName() <<endl<<endl ; 
		errFile << "Error at line " << line_count << ": Multiple declaration of " << $1->getSymbolName() <<endl<<endl ; 
		error_count++ ; 
	}
	

	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": declaration_list : ID" << endl<< endl ; 
	logFile << $1->getSymbolName() << endl<< endl ; 
	$$->push_back($1) ; 

	if (currType == "INT"){
		if (isGlobalSpace){
			for (int i = 0 ;  i< tabCount ;  i++){
				asmFile <<  "\t" ; 
			}
			asmFile << "\t" << $1->getSymbolName() << " DW 0\t ;  line no " << line_count << " " << $1->getSymbolName() << " declared\n\n"  ; 
		} else {
			// push to stack
		}
	} else {
		cout << "Float not supported" << endl ; 
		error_count ++ ; 
	}


}
| ID LTHIRD CONST_INT RTHIRD {

	if (currType == "INT"){
		if (isGlobalSpace){
			for (int i = 0 ;  i< tabCount ;  i++){
				asmFile <<  "\t" ; 
			}
			asmFile << "\t" << $1->getSymbolName() << " DW " << $3->getSymbolName() << " DUP (0)\t ;  line no " << line_count << " " << $1->getSymbolName() << " array declared\n"  ; 
		}
	} else {
		cout << "Float not supported" << endl ; 
		error_count ++ ; 
	}

	$1->setVariableType(currType) ; 
	if(isGlobalSpace){
		// setting global variable
		$1->setOffset(0) ; 
	} else {
		// setting appropriate offset for local vars
		$1->setOffset(getCurrOffset()) ; 

		// pushing garbage value to stack and updating the SP	
		asmFile << "\t\tMOV CX , " << $3->getSymbolName() << "\t ;  line no "<< line_count << ": new array of size " << $3->getSymbolName() << endl ; 
		string currLabel1 = newLabel() ; 
		asmFile <<"\t\t" << currLabel1 << ":" << endl ; 
		string currLabel2 = newLabel() ; 
		asmFile << "\t\tJCXZ " << currLabel2 << endl ; 
		asmFile << "\t\tPUSH BX" << endl ; 
		asmFile << "\t\tDEC CX" << endl ; 
		asmFile << "\t\tJMP " <<  currLabel1 << endl ; 
		asmFile <<"\t\t" <<  currLabel2 << ": \n" ;  

		int arrSize = stoi($3->getSymbolName()) ; 
		// cout << arrSize << endl ; 
		setCurrOffset(currOffset - arrSize*2) ; 
	}

	$1->setIsArray(true) ; 
	if(!table.insert($1)){
		logFile << "Error at line " << line_count << ": Multiple declaration of " << $1->getSymbolName() <<endl<<endl ; 
		errFile << "Error at line " << line_count << ": Multiple declaration of " << $1->getSymbolName() <<endl<<endl ; 
		error_count++ ; 
	}

	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": declaration_list : ID LTHIRD CONST_INT RTHIRD" << endl<< endl ; 
	logFile << $1->getSymbolName() << $2->getSymbolName() << $3->getSymbolName() << $4->getSymbolName() << endl<< endl ; 
	$$->push_back($1) ; 
	$$->push_back($2) ; 
	$$->push_back($3) ; 
	$$->push_back($4) ; 

	
}

| declaration_list ADDOP ID LTHIRD CONST_INT RTHIRD {
	// these are for error detection from now on for this production rule
	$$ = new vector<SymbolInfo*>() ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		$$->push_back($1->at(i)) ; 
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
}

| declaration_list MULOP ID LTHIRD CONST_INT RTHIRD {
	$$ = new vector<SymbolInfo*>() ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		$$->push_back($1->at(i)) ; 
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
}

| declaration_list INCOP ID LTHIRD CONST_INT RTHIRD {
	$$ = new vector<SymbolInfo*>() ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		$$->push_back($1->at(i)) ; 
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
}

| declaration_list DECOP ID LTHIRD CONST_INT RTHIRD {
	$$ = new vector<SymbolInfo*>() ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		$$->push_back($1->at(i)) ; 
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
}

| declaration_list RELOP ID LTHIRD CONST_INT RTHIRD {
	$$ = new vector<SymbolInfo*>() ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		$$->push_back($1->at(i)) ; 
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
}

| declaration_list ASSIGNOP ID LTHIRD CONST_INT RTHIRD {
	$$ = new vector<SymbolInfo*>() ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		$$->push_back($1->at(i)) ; 
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
}

| declaration_list LOGICOP ID LTHIRD CONST_INT RTHIRD {
	$$ = new vector<SymbolInfo*>() ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		$$->push_back($1->at(i)) ; 
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
}

| declaration_list ADDOP ID {
	$$ = new vector<SymbolInfo*>() ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		$$->push_back($1->at(i)) ; 
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
}

| declaration_list MULOP ID {
	$$ = new vector<SymbolInfo*>() ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		$$->push_back($1->at(i)) ; 
	}
	logFile << "Error at line " << line_count <<  ":OK syntax error" << endl<< endl ; 
	errFile << "Error at line " << line_count <<  ":OK syntax error" << endl<< endl ; 
}

| declaration_list INCOP ID {
	$$ = new vector<SymbolInfo*>() ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		$$->push_back($1->at(i)) ; 
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
}

| declaration_list DECOP ID {
	$$ = new vector<SymbolInfo*>() ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		$$->push_back($1->at(i)) ; 
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
}

| declaration_list RELOP ID {
	$$ = new vector<SymbolInfo*>() ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		$$->push_back($1->at(i)) ; 
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
}

| declaration_list ASSIGNOP ID {
	$$ = new vector<SymbolInfo*>() ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		$$->push_back($1->at(i)) ; 
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
}

| declaration_list LOGICOP ID {
	$$ = new vector<SymbolInfo*>() ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		$$->push_back($1->at(i)) ; 
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl ; 
}

 ; 
 		  
statements : 
statement {
	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": statements : statement" << endl << endl ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		// cout << "line no: "<< line_count <<  ": statement" << endl ; 
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
		if($1->at(i)->getSymbolType() == "INT" || $1->at(i)->getSymbolType() == "FLOAT" || $1->at(i)->getSymbolType() == "VOID" || $1->at(i)->getSymbolType() == "RETURN" || $1->at(i)->getSymbolType() == "IF")
			logFile << " " ; 
		if($1->at(i)->getSymbolName() == " ; " || $1->at(i)->getSymbolName() == "{" || $1->at(i)->getSymbolName() == "}" || $1->at(i)->getSymbolType() == "ELSE")
			logFile << endl ; 
	}
	logFile << endl << endl ; 

}
| statements statement {
	// cout << "statements statement" << endl ; 

	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": statements : statements statement" << endl << endl ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
		if($1->at(i)->getSymbolType() == "INT" || $1->at(i)->getSymbolType() == "FLOAT" || $1->at(i)->getSymbolType() == "VOID" || $1->at(i)->getSymbolType() == "RETURN" || $1->at(i)->getSymbolType() == "IF" || $1->at(i)->getSymbolType() == "WHILE")
			logFile << " " ; 
		if($1->at(i)->getSymbolName() == " ; " || $1->at(i)->getSymbolName() == "{" || $1->at(i)->getSymbolName() == "}" || $1->at(i)->getSymbolType() == "ELSE")
			logFile << endl ; 
	}

	for(int i = 0 ;  i < $2->size() ;  i++){
		logFile << $2->at(i)->getSymbolName() ; 
		$$->push_back($2->at(i)) ; 
		if($2->at(i)->getSymbolType() == "INT" || $2->at(i)->getSymbolType() == "FLOAT" || $2->at(i)->getSymbolType() == "VOID" || $2->at(i)->getSymbolType() == "RETURN"  || $2->at(i)->getSymbolType() == "IF" || $2->at(i)->getSymbolType() == "WHILE")
			logFile << " " ; 
		if($2->at(i)->getSymbolName() == " ; " || $2->at(i)->getSymbolName() == "{" || $2->at(i)->getSymbolName() == "}" || $2->at(i)->getSymbolType() == "ELSE")
			logFile << endl ; 
	}
	
	logFile << endl << endl ; 
}
 ; 

newIfRule : IF LPAREN expression RPAREN {
	
	
	ifLabel1.push(newLabel()) ; 
	// cout << "label: " << ifLabel1.top() << endl ; 
	
	string code = "\t\tPOP BX\n"
				"\t\tCMP BX , 0\n"	// meaning the IF conditon is false
				"\t\tJE " + ifLabel1.top() + "\t ;  go to else\n\n" ; 
	asmFile << code ; 

	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": statement : IF LPAREN expression RPAREN statement" << endl << endl ; 
	
	logFile << $1->getSymbolName() << " " << $2->getSymbolName() ; 
	$$->push_back($1) ; 
	$$->push_back($2) ; 

	for(int i = 0 ;  i < $3->size() ;  i++){
		logFile << $3->at(i)->getSymbolName() ; 
		$$->push_back($3->at(i)) ; 
	}

	logFile << $4->getSymbolName()  ; 
	$$->push_back($4) ; 


}
	   
statement : 
var_declaration {
	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": statement : var_declaration" << endl << endl ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
		if($1->at(i)->getSymbolType() == "INT" || $1->at(i)->getSymbolType() == "FLOAT" || $1->at(i)->getSymbolType() == "VOID" || $1->at(i)->getSymbolType() == "RETURN"  || $1->at(i)->getSymbolType() == "IF")
			logFile << " " ; 

	}
	logFile << endl << endl << endl ; 
}
| func_definition {
	logFile << "Error at line " << line_count << ": Invalid scoping of the function " <<  $1->at(1)->getSymbolName() << endl << endl ; 
	errFile << "Error at line " << line_count << ": Invalid scoping of the function " <<  $1->at(1)->getSymbolName() << endl << endl ; 
	
	error_count++ ; 
		
}
| func_declaration {
	logFile << "Error at line " << line_count << ": Invalid scoping of the function declaration " <<  $1->at(1)->getSymbolName() << endl << endl ; 
	errFile << "Error at line " << line_count << ": Invalid scoping of the function declaration " <<  $1->at(1)->getSymbolName() << endl << endl ; 
	
	error_count++ ; 
	
}
| expression_statement {
	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": statement : expression_statement" << endl << endl ; 
	// cout << "in expression statement" << endl ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 

		
		// cout << $1->at(i)->getSymbolName() ; 
		
	}
	// cout << " expression_statement found" << endl ; 
	logFile << endl << endl << endl ; 

}
| { isGlobalSpace = false ;  table.enterScope() ;  } compound_statement {
	table.printAllScopeTables() ; 
	table.exitScope() ; 
} {
	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": statement : compound_statement" << endl << endl ; 
	for(int i = 0 ;  i < $2->size() ;  i++){
		logFile << $2->at(i)->getSymbolName() ; 
		$$->push_back($2->at(i)) ; 
		if($2->at(i)->getSymbolType() == "INT" || $2->at(i)->getSymbolType() == "FLOAT" || $2->at(i)->getSymbolType() == "VOID" || $2->at(i)->getSymbolType() == "RETURN"  || $2->at(i)->getSymbolType() == "IF")
			logFile << " " ; 
		if($2->at(i)->getSymbolName() == " ; " || $2->at(i)->getSymbolName() == "{" || $2->at(i)->getSymbolName() == "}")
			logFile << endl ; 
	}
	logFile << endl << endl ; 

}

| FOR LPAREN expression_statement {
	noPop = true ; 	// to halt pop after semicolon expression_statement
	forLabel1 = newLabel() ; 

	asmFile << "\t\t" << forLabel1 << ":\t ;  for loop start label\n\n" ; 

} expression_statement {
	inForLoop = true ; 
	forLoopLineCnt = line_count ; 
	forLabel2 = newLabel() ; 
	asmFile << "\t\tPOP BX\n" ; 
	asmFile << "\t\tCMP BX , 0\n" ; 
	asmFile << "\t\tJE " << forLabel2 << ":\t ;  condition false\n\n" ; 

} expression RPAREN {
	noPop = false ; 
	inForLoop = false ; 

} statement {
	// write the 'expression' code here in the asm file(ekhane ashar agei 'statement' er code asmfile e lekha hoye jabe)

	string tempCode ; 
	tempFile.close() ; 
	ifstream t("temp.txt") ; 
	stringstream buffer ; 
	buffer << t.rdbuf() ; 

	tempCode = buffer.str() ; 

	// cout << tempCode << endl ; 
	
	asmFile << tempCode ; 
	tempFile.open("temp.txt") ; 

	asmFile << "\t\tJMP " << forLabel1 << "\t ;   go to check point\n" ; 
	asmFile << forLabel2 << ":\t ;   exit loop \n\n" ; 

	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement" << endl << endl ; 
	
	logFile << $1->getSymbolName() << $2->getSymbolName() ; 
	$$->push_back($1) ; 
	$$->push_back($2) ; 

	for(int i = 0 ;  i < $3->size() ;  i++){
		logFile << $3->at(i)->getSymbolName() ; 
		$$->push_back($3->at(i)) ; 
	}

	for(int i = 0 ;  i < $5->size() ;  i++){
		logFile << $5->at(i)->getSymbolName() ; 
		$$->push_back($5->at(i)) ; 
	}

	for(int i = 0 ;  i < $7->size() ;  i++){
		logFile << $7->at(i)->getSymbolName() ; 
		$$->push_back($7->at(i)) ; 
	}
	
	logFile << $8->getSymbolName() ; 
	$$->push_back($8) ; 

	for(int i = 0 ;  i < $10->size() ;  i++){
		logFile << $10->at(i)->getSymbolName() ; 
		$$->push_back($10->at(i)) ; 
		if($10->at(i)->getSymbolType() == "INT" || $10->at(i)->getSymbolType() == "FLOAT" || $10->at(i)->getSymbolType() == "VOID" || $10->at(i)->getSymbolType() == "RETURN")
			logFile << " " ; 
		if($10->at(i)->getSymbolName() == " ; " || $10->at(i)->getSymbolName() == "{" || $10->at(i)->getSymbolName() == "}")
			logFile << endl ; 
	}
	logFile << endl << endl ; 

}

| newIfRule statement %prec LOWER_THAN_ELSE {
	asmFile << "\t\t" << ifLabel1.top() << ":  ;  exit label (only one if)\n\n" ; 
	ifLabel1.pop() ; 
	
	$$ = new vector<SymbolInfo*>() ; 

	for(int i = 0 ;  i < $1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
	}

	for(int i = 0 ;  i < $2->size() ;  i++){
		logFile << $2->at(i)->getSymbolName() ; 
		$$->push_back($2->at(i)) ; 
		if($2->at(i)->getSymbolType() == "INT" || $2->at(i)->getSymbolType() == "FLOAT" || $2->at(i)->getSymbolType() == "VOID" || $2->at(i)->getSymbolType() == "RETURN" || $2->at(i)->getSymbolType() == "IF")
			logFile << " " ; 
		if($2->at(i)->getSymbolName() == " ; " || $2->at(i)->getSymbolName() == "{" || $2->at(i)->getSymbolName() == "}")
			logFile << endl ; 
	}

	logFile << endl << endl ; 

}
| newIfRule statement ELSE {
	ifLabel2.push(newLabel()) ; 
	asmFile << "\t\tJMP " << ifLabel2.top() << "  ;  exit\n" ; 
	
	asmFile << "\t\t" << ifLabel1.top() << ":  ;  exit label\n\n" ; 
	// cout << "label: " << ifLabel1.top() << endl ; 
	ifLabel1.pop() ; 

} statement {

	asmFile << "\t\t" << ifLabel2.top() << ":  ;  if else exit\n\n"  ; 
	ifLabel2.pop() ; 

	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": statement : IF LPAREN expression RPAREN statement ELSE statement" << endl << endl ; 
	
	for(int i = 0 ;  i < $1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
	}
	
	for(int i = 0 ;  i < $2->size() ;  i++){
		logFile << $2->at(i)->getSymbolName() ; 
		$$->push_back($2->at(i)) ; 
		if($2->at(i)->getSymbolType() == "INT" || $2->at(i)->getSymbolType() == "FLOAT" || $2->at(i)->getSymbolType() == "VOID" || $2->at(i)->getSymbolType() == "RETURN" || $2->at(i)->getSymbolType() == "IF")
			logFile << " " ; 
		if($2->at(i)->getSymbolName() == " ; " || $2->at(i)->getSymbolName() == "{" || $2->at(i)->getSymbolName() == "}")
			logFile << endl ; 
	}

	logFile << $3->getSymbolName()  ; 
	$$->push_back($3) ; 

	for(int i = 0 ;  i < $5->size() ;  i++){
		logFile << $5->at(i)->getSymbolName() ; 
		$$->push_back($5->at(i)) ; 
		if($5->at(i)->getSymbolType() == "INT" || $5->at(i)->getSymbolType() == "FLOAT" || $5->at(i)->getSymbolType() == "VOID" || $5->at(i)->getSymbolType() == "RETURN" || $5->at(i)->getSymbolType() == "IF")
			logFile << " " ; 
		if($5->at(i)->getSymbolName() == " ; " || $5->at(i)->getSymbolName() == "{" || $5->at(i)->getSymbolName() == "}")
			logFile << endl ; 
	}

	
	logFile << endl << endl ; 
}
| WHILE LPAREN {
	whileLabel1 = newLabel() ; 
	asmFile << "\t\t ;  line no " << line_count << ": starting while loop\n" ; 
	asmFile << "\t\t" << whileLabel1 << ":\n\n" ; 
	
} expression RPAREN {
	whileLabel2 = newLabel() ; 
	asmFile << "\t\tPOP BX\n" ; 
	asmFile << "\t\tCMP BX , 0\n" ; 
	asmFile << "\t\tJE " << whileLabel2 << "\t ;  condition false. so jump to exit\n\n" ; 
		
} statement {
	asmFile << "\t\tJMP " << whileLabel1 << "\t ;  again go to begining\n" ; 
	asmFile << "\t\t" << whileLabel2 << ":\t ;   ;  line no 8 : while loop end\n\n" ; 
	
		
	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": statement : WHILE LPAREN expression RPAREN statement" << endl << endl ; 
	
	logFile << $1->getSymbolName() << " " << $2->getSymbolName() ; 
	$$->push_back($1) ; 
	$$->push_back($2) ; 

	for(int i = 0 ;  i < $4->size() ;  i++){
		logFile << $4->at(i)->getSymbolName() ; 
		$$->push_back($4->at(i)) ; 
	}

	logFile << $5->getSymbolName()  ; 
	$$->push_back($5) ; 

	for(int i = 0 ;  i < $7->size() ;  i++){
		logFile << $7->at(i)->getSymbolName() ; 
		$$->push_back($7->at(i)) ; 
		if($7->at(i)->getSymbolType() == "INT" || $7->at(i)->getSymbolType() == "FLOAT" || $7->at(i)->getSymbolType() == "VOID" || $7->at(i)->getSymbolType() == "RETURN")
			logFile << " " ; 
		if($7->at(i)->getSymbolName() == " ; " || $7->at(i)->getSymbolName() == "{" || $7->at(i)->getSymbolName() == "}")
			logFile << endl ; 
	}

	logFile << endl << endl ; 
}
| PRINTLN LPAREN ID RPAREN SEMICOLON {

	SymbolInfo* currSymbol = table.getSymbolInfo($3->getSymbolName()) ; 
	if (currSymbol->isArray()){
		cout << "Error at line " << line_count << ": Type mismatch , b is an array\tterminating program\n" ; 
		error_count++ ; 
	}

	if(currSymbol->getOffset() == 0){
		// it's a global variable
		asmFile << "\t\tMOV BX , [" << currSymbol->getSymbolName() << " + " << currSymbol->getOffset() << "]\n" ; 
	} else {
		asmFile << "\t\tMOV BX , [BP + " << currSymbol->getOffset() << "]\n" ; 

	}
	
	asmFile << "\t\tPUSH BX\t ;  line no " << line_count << ": " << currSymbol->getSymbolName() << " loaded\n" ; 
	asmFile << "\t\tCALL PRINT_DECIMAL_INTEGER\n\n" ; 

	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": statement : PRINTLN LPAREN ID RPAREN SEMICOLON" << endl << endl ; 

	if (!table.lookupEntire($3->getSymbolName())) {
		logFile << "Error at line " << line_count << ": Undeclared variable " << $3->getSymbolName() << endl << endl ; 
		errFile << "Error at line " << line_count << ": Undeclared variable " << $3->getSymbolName() << endl << endl ; 
		error_count++ ; 
	}

	logFile << $1->getSymbolName() << $2->getSymbolName() << $3->getSymbolName() << $4->getSymbolName() << $5->getSymbolName() << endl << endl << endl ; 
	$$->push_back($1) ; 
	$$->push_back($2) ; 
	$$->push_back($3) ; 
	$$->push_back($4) ; 
	$$->push_back($5) ; 
	
}
| RETURN expression SEMICOLON {
	asmFile << "\t\tPOP BX\t ;  line no " << line_count << " :  return value saved in DX\n" ; 
	asmFile <<	"\t\tMOV DX , BX\n" ; 
	asmFile <<	"\t\tJMP " << currFuncLabel << "  ;  line no " << line_count << ": exit from the function\n\n" ; 
		

	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": statement : RETURN expression SEMICOLON" << endl << endl ; 
	
	logFile << $1->getSymbolName() << " " ; 
	$$->push_back($1) ; 
	

	for(int i = 0 ;  i < $2->size() ;  i++){
		logFile << $2->at(i)->getSymbolName() ; 
		$$->push_back($2->at(i)) ; 
	}

	logFile << $3->getSymbolName()  ; 
	$$->push_back($3) ; 

	logFile << endl << endl << endl ; 
}
 ; 
	  
expression_statement : 
SEMICOLON {
	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": expression_statement : SEMICOLON" << endl << endl ; 
	if(!isError){
		logFile << $1->getSymbolName()  ; 
		$$->push_back($1) ; 
		logFile << endl << endl ; 
	}

}	
| expression SEMICOLON {
	if(!noPop)
		asmFile << "\t\tPOP BX\t ;  line no " << line_count << ": previously pushed value on stack is removed\n\n" ; 

	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": expression_statement : expression SEMICOLON" << endl << endl ; 

	
	if(!isError){
		for(int i = 0 ;  i < $1->size() ;  i++){
			logFile << $1->at(i)->getSymbolName() ; 
			$$->push_back($1->at(i)) ; 
		}
		logFile << $2->getSymbolName() ; 
		$$->push_back($2) ; 
		logFile << endl << endl ; 
	}

}

| expression error {
	// cout << "expression error" << endl ; 
	for (int i = 0 ;  i<$1->size() ;  i++){
		// cout << $1->at(i)->getSymbolName() << " " ; 
	}
	// cout << endl ; 
	$$ = new vector<SymbolInfo*>() ; 
	for(int i = 0 ;  i < $1->size() ;  i++){
		// logFile << $1->at(i)->getSymbolName() ; 
		// $$->push_back($1->at(i)) ; 
	}

	logFile << endl << endl ; 
	// SymbolInfo * errSymbol = new SymbolInfo("" , "ERROR") ; 
	// $$->push_back(errSymbol) ; 
	yyclearin ; 
}

 ; 
	  
variable : 
ID {
	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": variable : ID" << endl << endl ; 

	if(DEBUG) {
		logFile << "test" << endl ; 
		table.printAllScopeTables() ; 
	}

	SymbolInfo* currSymbol = table.getSymbolInfo($1->getSymbolName()) ; 

	if (!isArgumentPassing) {
		if (inForLoop){
			if(currSymbol->getOffset() == 0){
				// it's a global variable
				tempFile << "\t\tMOV BX , [" << currSymbol->getSymbolName() << " + " << currSymbol->getOffset() << "]\n" ; 
			} else {
				tempFile << "\t\tMOV BX , [BP + " << currSymbol->getOffset() << "]\n" ; 

			}
			tempFile << "\t\tPUSH BX\t ;  line no " << line_count << ": " << currSymbol->getSymbolName() << " loaded\n\n" ; 
		} else{
			if(currSymbol->getOffset() == 0){
				// it's a global variable
				asmFile << "\t\tMOV BX , [" << currSymbol->getSymbolName() << " + " << currSymbol->getOffset() << "]\n" ; 
			} else {
				asmFile << "\t\tMOV BX , [BP + " << currSymbol->getOffset() << "]\n" ; 

			}
			asmFile << "\t\tPUSH BX\t ;  line no " << line_count << ": " << currSymbol->getSymbolName() << " loaded\n\n" ; 
		}
	}

	if(currSymbol == NULL) {
		logFile << "Error at line " << line_count << ": Undeclared variable " << $1->getSymbolName() << endl << endl ; 
		errFile << "Error at line " << line_count << ": Undeclared variable " << $1->getSymbolName() << endl << endl ; 
		error_count++ ; 
	} else {
		if (currSymbol->isFunction()){
			logFile << "Error at line " << line_count << ": Type mismatch , " << $1->getSymbolName() << " is an function" << endl << endl ; 
			errFile << "Error at line " << line_count << ": Type mismatch , " << $1->getSymbolName() << " is an function" << endl << endl ; 
			error_count++ ; 

		}

		if (currSymbol->isArray()){
			logFile << "Error at line " << line_count << ": Type mismatch , " << $1->getSymbolName() << " is an array" << endl << endl ; 
			errFile << "Error at line " << line_count << ": Type mismatch , " << $1->getSymbolName() << " is an array" << endl << endl ; 
			error_count++ ; 

		}
	}

	logFile << $1->getSymbolName() << endl << endl ; 
	$$->push_back(currSymbol) ; 
	

}
| ID LTHIRD expression RTHIRD {
	SymbolInfo* currSymbol = table.getSymbolInfo($1->getSymbolName()) ; 

	// [hopefully] expression er desired code part already niche thekei constructed hoye asche and dorkari jinish stack e ache
	// so , just pop from stack
	if (currSymbol->getOffset() == 0){
		asmFile << "\t\tPOP BX\t ;  line no " << line_count << ": Array index is in BX (global array)\n" ; 
		asmFile << "\t\tSHL BX , 1\t ;  line no " << line_count << ": multiply the offset by 2 (word = 2 bytes)\n" ; 
		asmFile << "\t\tPUSH " << currSymbol->getSymbolName() << "[BX]\n" ; 
		// asmFile << "\t\tPUSH BX\t ;  line no " << line_count << ":here goes the index\n" ; 
		
	} else {
		asmFile << "\t\tPOP BX\t ;  line no " << line_count << ": Array index is in BX\n" ; 
		asmFile << "\t\tSHL BX , 1\t ;  line no " << line_count << ": multiply the offset by 2 (word = 2 bytes)\n" ; 
		asmFile << "\t\tNEG BX\n" ; 
		asmFile << "\t\tADD BX , " << currSymbol->getOffset() << "\t ;  line no " << line_count << ": getting the actual offset from the base offset of the array\n" ; 
		asmFile << "\t\tADD BX , BP\n" ; 	// adding to base pointer for handling inside function
		asmFile << "\t\tPUSH [BX]" << "\t ;  line no " << line_count << ": value of the array pushed\n" ; 
	}
	
	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": variable : ID LTHIRD expression RTHIRD" << endl << endl ; 

	
	if(currSymbol == NULL) {
		logFile << "Error at line " << line_count << ": Undeclared variable " << $1->getSymbolName() << endl << endl ; 
		errFile << "Error at line " << line_count << ": Undeclared variable " << $1->getSymbolName() << endl << endl ; 
		error_count++ ; 
	} else {
		if (currSymbol->isFunction()){
			logFile << "Error at line " << line_count << ": Type mismatch , " << $1->getSymbolName() << " is an function" << endl << endl ; 
			errFile << "Error at line " << line_count << ": Type mismatch , " << $1->getSymbolName() << " is an function" << endl << endl ; 
			error_count++ ; 

		}

		if (!currSymbol->isArray()){
			logFile << "Error at line " << line_count << ": " << $1->getSymbolName() << " not an array" << endl << endl ; 
			errFile << "Error at line " << line_count << ": " << $1->getSymbolName() << " not an array" << endl << endl ; 
			error_count++ ; 

		}
	}

	if($3->at(0)->getSymbolType() != "CONST_INT"){
		logFile << "Error at line " << line_count << ": Expression inside third brackets not an integer" << endl << endl ; 
		errFile << "Error at line " << line_count << ": Expression inside third brackets not an integer" << endl << endl ; 
		error_count++ ; 
	}
	
	logFile << $1->getSymbolName() << $2->getSymbolName() << $3->at(0)->getSymbolName() << $4->getSymbolName() << endl << endl ; 
	$$->push_back(currSymbol) ; 
	$$->push_back($2) ; 
	$$->push_back($3->at(0)) ; 
	$$->push_back($4) ; 


}
 ; 
	 
expression : 
logic_expression {
	$$ = new vector<SymbolInfo*>() ; 
	if (!isError)
		logFile << "Line " << line_count <<  ": expression : logic_expression" << endl << endl ; 

	for(int i = 0 ;  i < $1->size() ;  i++){
		if (!isError){
			logFile << $1->at(i)->getSymbolName() ; 
			$$->push_back($1->at(i)) ; 
		}
	}
	if (!isError)
		logFile << endl << endl ; 

}
| variable ASSIGNOP {
	SymbolInfo* currSymbol = table.getSymbolInfo($1->at(0)->getSymbolName()) ; 
	if(currSymbol->isArray()) {
		if(inForLoop) {
			asmFile << "\t\tPUSH BX\t ;  line no " << forLoopLineCnt << ": address pushed to stack\n\n" ; 
			
		} else
			asmFile << "\t\tPUSH BX\t ;  line no " << line_count << ": address pushed to stack\n\n" ; 
	}

} logic_expression {
	// logic_expression can be const_int , const_float , function , variable... 
	SymbolInfo* currSymbol = table.getSymbolInfo($1->at(0)->getSymbolName()) ; 

	if(inForLoop) {
		tempFile << "\t\tPOP AX\n" ; 
	} else {
		asmFile << "\t\tPOP AX\n" ; 
	}

	if(currSymbol->isArray()) {
		if (inForLoop){
			tempFile << "\t\tPOP BX\n" ; 
			tempFile << "\t\tPOP DX\n" ; 
			tempFile << "\t\tMOV [BX] , AX\n" ; 
			tempFile << "\t\tMOV BX , AX\n" ; 
			tempFile << "\t\tPUSH BX\n" ; 

		} else {
			asmFile << "\t\tPOP BX\t ;  line no " << line_count << ": array elememt position retrieved\n" ; 
			asmFile << "\t\tPOP DX\t ;  line no " << line_count << ": array value popped and stored in DX\n" ; 
			
			if (currSymbol->getOffset() == 0){
				// global array handle
				asmFile << "\t\tMOV " << currSymbol->getSymbolName() << "[BX] , AX\t ;  line no " << line_count << ": " << currSymbol->getSymbolName() << " global array assigned\n" ; 
			
			} else {
				asmFile << "\t\tMOV [BX] , AX\t ;  line no " << line_count << ": " << currSymbol->getSymbolName() << " array assigned\n" ; 
			}
			asmFile << "\t\tMOV BX , AX\n" ; 
			asmFile << "\t\tPUSH BX\n" ; 
		}
		

	} else {
		if(inForLoop) {
			if(currSymbol->getOffset() == 0){
				// it's a global variable
				tempFile << "\t\tMOV [" << currSymbol->getSymbolName() <<  " + " << $1->at(0)->getOffset() << "] , AX\t ;  line no " << line_count << ": " << $1->at(0)->getSymbolName() << " assigned\n" ; 
			
			} else {
				tempFile << "\t\tMOV [BP + " << $1->at(0)->getOffset() << "] , AX\t ;  line no " << line_count << ": " << $1->at(0)->getSymbolName() << " assigned\n" ; 
			}
			tempFile << "\t\tMOV BX , AX\n" ; 
			tempFile << "\t\tPUSH BX\n\n" ; 

		}else {
			if(currSymbol->getOffset() == 0){
				// it's a global variable
				asmFile << "\t\tMOV [" << currSymbol->getSymbolName() <<  " + " << $1->at(0)->getOffset() << "] , AX\t ;  line no " << line_count << ": " << $1->at(0)->getSymbolName() << " assigned\n" ; 
			
			} else {
				asmFile << "\t\tMOV [BP + " << $1->at(0)->getOffset() << "] , AX\t ;  line no " << line_count << ": " << $1->at(0)->getSymbolName() << " assigned\n" ; 
			}
			asmFile << "\t\tMOV BX , AX\n" ; 
			asmFile << "\t\tPUSH BX\n\n" ; 
		}
		
		
	}
	// asmFile << "\t\tPUSH BX\n"	// for concatenation of expression maybe?

	$$ = new vector<SymbolInfo*>() ; 
	if (!isError)
		logFile << "Line " << line_count <<  ": expression : variable ASSIGNOP logic_expression" << endl << endl ; 
	
	// functions with void return type cannot be used in a logic_expression
	for(int i = 0 ;  i < $4->size() ;  i++) {   
		if(table.lookupEntire($4->at(i)->getSymbolName()) && $4->at(i)->getSymbolType() == "ID"){
			SymbolInfo* currSymbol = table.getSymbolInfo($4->at(i)->getSymbolName()) ; 
			//  // cout << "line " << line_count << ": func name: " << currSymbol->getSymbolName() << " ret type: " <<  currSymbol->getReturnType() << endl ; 
			if(currSymbol->isFunction() && currSymbol->getReturnType() == "VOID"){
				
				logFile << "Error at line " << line_count << ": Void function used in expression" << endl << endl ; 
				errFile << "Error at line " << line_count << ": Void function used in expression" << endl << endl ; 
				error_count++ ; 
			}
		}
	}

	// currently not expecting chaining
	// float assignment in int variable
	if(table.lookupEntire($1->at(0)->getSymbolName())) {
		// // cout << $1->at(0)->getSymbolName() << endl ; 
		
		SymbolInfo *currSymbol = table.getSymbolInfo($1->at(0)->getSymbolName()) ; 

		if(currSymbol->getVariableType() == "INT"){
			
			for(int i = 0 ;  i < $4->size() ;  i++){
				// // cout << $3->at(i)->getSymbolName() << ": " << $3->at(i)->getSymbolType() << endl ; 
				if($4->at(i)->getSymbolType() == "CONST_FLOAT" || $4->at(i)->getVariableType() == "FLOAT"){
					logFile << "Error at line " << line_count << ": Type Mismatch" << endl << endl ; 
					errFile << "Error at line " << line_count << ": Type Mismatch" << endl << endl ; 
					error_count++ ; 
					// break ; 
				}
			}
			// // cout << endl ; 
		}
	}

	for(int i = 0 ;  i < $1->size() ;  i++){
		if (!isError){
			logFile << $1->at(i)->getSymbolName() ; 
			$$->push_back($1->at(i)) ; 
		}
	}
	
	if (!isError){
		logFile << $2->getSymbolName() ; 
		$$->push_back($2) ; 
	}

	for(int i = 0 ;  i < $4->size() ;  i++){
		if (!isError){
			logFile << $4->at(i)->getSymbolName() ; 
			$$->push_back($4->at(i)) ; 
		}
	}
	if (!isError)
		logFile << endl << endl ; 
}
 ; 
			
logic_expression : 
rel_expression {
	isError = false ; 

	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": logic_expression : rel_expression" << endl << endl ; 

	for(int i = 0 ;  i < $1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
	}
	logFile << endl << endl ; 


}
| rel_expression LOGICOP rel_expression {
	string andLabel1 = newLabel() ; 
	string andLabel2 = newLabel() ; 
	if ($2->getSymbolName() == "&&") {
		if (inForLoop){
			tempFile << "\t\tPOP BX\n" ; 
			tempFile << "\t\tCMP BX , 0\n" ; 
			tempFile << "\t\tJE " << andLabel1 << "\t ;  line no " << line_count << ": not true\n" ; 
			tempFile << "\t\tPOP BX\n" ; 
			tempFile << "\t\tCMP BX , 0\n" ; 
			tempFile << "\t\tJE " << andLabel1 << "\t ;  line no " << line_count << ": not true\n" ; 
			tempFile << "\t\tPUSH 1 ; \t line no " << line_count << ": conditioin is true\n" ; 
			tempFile << "\t\tJMP " << andLabel2 <<"\n" ; 
			tempFile << "\t\t" << andLabel1 << ":\n" ; 
			tempFile << "\t\tPUSH 0\n" ; 
			tempFile << "\t\t" << andLabel2 << ":\t ;  line no " << line_count << ": exiting and operation\n\n" ; 
		} else {
			asmFile << "\t\tPOP BX\n" ; 
			asmFile << "\t\tCMP BX , 0\n" ; 
			asmFile << "\t\tJE " << andLabel1 << "\t ;  line no " << line_count << ": not true\n" ; 
			asmFile << "\t\tPOP BX\n" ; 
			asmFile << "\t\tCMP BX , 0\n" ; 
			asmFile << "\t\tJE " << andLabel1 << "\t ;  line no " << line_count << ": not true\n" ; 
			asmFile << "\t\tPUSH 1 ; \t line no " << line_count << ": conditioin is true\n" ; 
			asmFile << "\t\tJMP " << andLabel2 <<"\n" ; 
			asmFile << "\t\t" << andLabel1 << ":\n" ; 
			asmFile << "\t\tPUSH 0\n" ; 
			asmFile << "\t\t" << andLabel2 << ":\t ;  line no " << line_count << ": exiting and operation\n\n" ; 
		}

	}

	if ($2->getSymbolName() == "||") {
		string code = "\t\t ;  OR OPERATION\n"
					"\t\tPOP BX\n"
					"\t\tPOP AX\n"
					"\t\tOR BX , AX\n"
					"\t\tPUSH BX\n\n" ; 

		if(inForLoop)
			tempFile << code ; 
		else
			asmFile << code ; 
		
	}

	isError = false ; 

	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": logic_expression : rel_expression LOGICOP rel_expression" << endl << endl ; 

	for(int i = 0 ;  i < $1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
	}

	logFile << $2->getSymbolName() ; 
	$$->push_back($2) ; 

	for(int i = 0 ;  i < $3->size() ;  i++){
		logFile << $3->at(i)->getSymbolName() ; 
		$$->push_back($3->at(i)) ; 
	}
	logFile << endl << endl ; 
}

| rel_expression ERROR rel_expression {
	isError = true ; 
	$$ = new vector<SymbolInfo*>() ; 
	for (int i=0 ;  i<$1->size() ;  i++ ){
		$$->push_back($1->at(i)) ; 
	}
	$$->push_back($2) ; 
	for (int i=0 ;  i<$3->size() ;  i++ ){
		$$->push_back($3->at(i)) ; 
	}
}
 ; 
			
rel_expression : 
simple_expression {
	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": rel_expression : simple_expression" << endl << endl ; 

	for(int i = 0 ;  i < $1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
	}
	logFile << endl << endl ; 

}
| simple_expression RELOP simple_expression	{
	string controlStr ; 
	if($2->getSymbolName() == "<="){
		controlStr = "JLE" ; 
	} else if($2->getSymbolName() == ">="){
		controlStr = "JGE" ; 
	} else if($2->getSymbolName() == "=="){
		controlStr = "JE" ; 
	} else if($2->getSymbolName() == "!="){
		controlStr = "JNE" ; 
	} else if($2->getSymbolName() == "<"){
		controlStr = "JL" ; 
	} else if($2->getSymbolName() == ">"){
		controlStr = "JG" ; 
	}

	string currLabel = newLabel() ; 
	
	if (inForLoop){
		tempFile << "\t\tPOP BX\n" ; 
		tempFile << "\t\tPOP AX\n" ; 
		tempFile << "\t\tCMP AX , BX\t ;  line no "<< line_count << ": relop operation\n" ; 
		tempFile << "\t\tMOV BX , 1\t ;  line no "<< line_count << ":  First let it assume positive\n\t\t" << controlStr << " " << currLabel << "\n" ; 
		tempFile << "\t\tMOV BX , 0\t ;  line no "<< line_count << ": the condition is false\n\t\t" << currLabel << ": \n" ; 
		tempFile << "\t\tPUSH BX\n\n" ; 
	} else {
		asmFile << "\t\tPOP BX\n" ; 
		asmFile << "\t\tPOP AX\n" ; 
		asmFile << "\t\tCMP AX , BX\t ;  line no "<< line_count << ": relop operation\n" ; 
		asmFile << "\t\tMOV BX , 1\t ;  line no "<< line_count << ":  First let it assume positive\n\t\t" << controlStr << " " << currLabel << "\n" ; 
		asmFile << "\t\tMOV BX , 0\t ;  line no "<< line_count << ": the condition is false\n\t\t" << currLabel << ": \n" ; 
		asmFile << "\t\tPUSH BX\n\n" ; 
	}


	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": rel_expression : simple_expression RELOP simple_expression" << endl << endl ; 

	for(int i = 0 ;  i < $1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
	}

	logFile << $2->getSymbolName() ; 
	$$->push_back($2) ; 

	for(int i = 0 ;  i < $3->size() ;  i++){
		logFile << $3->at(i)->getSymbolName() ; 
		$$->push_back($3->at(i)) ; 
	}
	logFile << endl << endl ; 
}
 ; 
				
simple_expression : 
term {
	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": simple_expression : term" << endl << endl ; 
	
	for(int i = 0 ;  i < $1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
	}
	logFile << endl << endl ; 
}
| simple_expression ADDOP term {
	bool isAdd = false ; 
	if ($2->getSymbolName() == "+")	isAdd = true ; 
	else isAdd = false ; 

	// term jetai ashuk seta niche theke parsed hoye loaded hoye stack e pushed hoye asbe [hopefully]
	if(inForLoop){
		tempFile << "\t\tPOP BX\n" ; 
		tempFile << "\t\tPOP AX\n" ; 	// 2nd operand from the stack
		if(isAdd){
			tempFile << "\t\tADD BX , AX\n" ; 
			
		} else {
			tempFile << "\t\tSUB AX , BX\n" ; 
			tempFile << "\t\tMOV BX , AX\n" ; 
			
		}

		tempFile << "\t\tPUSH BX\n\n" ;  
	} else {
		asmFile << "\t\tPOP BX\n" ; 
		asmFile << "\t\tPOP AX\n" ; 	// 2nd operand from the stack
		if(isAdd){
			asmFile << "\t\tADD BX , AX\n" ; 
			
		} else {
			asmFile << "\t\tSUB AX , BX\n" ; 
			asmFile << "\t\tMOV BX , AX\n" ; 
			
		}

		asmFile << "\t\tPUSH BX\n\n" ;  
	}

	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": simple_expression : simple_expression ADDOP term" << endl << endl ; 

	for(int i = 0 ;  i < $1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
	}
	logFile << $2->getSymbolName() ; 
	$$->push_back($2) ; 
	for(int i = 0 ;  i < $3->size() ;  i++){
		logFile << $3->at(i)->getSymbolName() ; 
		$$->push_back($3->at(i)) ; 
	}
	logFile << endl << endl ; 
}
 ; 
					
term :	
unary_expression {
	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": term : unary_expression" << endl << endl ; 
	
	for(int i = 0 ;  i < $1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
	}
	logFile << endl << endl ; 
}
|  term MULOP unary_expression {

	if (inForLoop){
		if($2->getSymbolName() == "*"){
			tempFile << "\t\tPOP BX\t ;  line no "<< line_count << ": multiplication start of integer\n" ; 
			tempFile << "\t\tMOV CX , BX\n" ; 
			tempFile << "\t\tPOP AX\n" ; 
			tempFile << "\t\tIMUL CX\n" ; 
			tempFile << "\t\tMOV BX , AX\t ;  line no "<< line_count << ": only last 16 bit is taken in mul\n" ; 
			tempFile << "\t\tPUSH BX\n\n" ; 
		
		} else if($2->getSymbolName() == "%"){
			tempFile << "\t\tPOP BX\n" ; 
			tempFile << "\t\tMOV CX , BX\t ;  line no "<< line_count << ": / or % operation\n" ; 
			tempFile << "\t\tXOR DX , DX\n" ; 
			tempFile << "\t\tPOP AX\n" ; 
			tempFile << "\t\tIDIV CX\n" ; 
			tempFile << "\t\tMOV BX , DX\n" ; 
			tempFile << "\t\tPUSH BX\n\n" ; 
			
		} else if($2->getSymbolName() == "/"){
			tempFile << "\t\tPOP BX\n" ; 
			tempFile << "\t\tMOV CX , BX\t ;  line no "<< line_count << ": / or % operation\n" ; 
			tempFile << "\t\tXOR DX , DX\n" ; 
			tempFile << "\t\tPOP AX\n" ; 
			tempFile << "\t\tIDIV CX\n" ; 
			tempFile << "\t\tMOV BX , AX\n" ; 
			tempFile << "\t\tPUSH BX\n\n" ; 
		
		}
	} else {

		if($2->getSymbolName() == "*"){
			asmFile << "\t\tPOP BX\t ;  line no "<< line_count << ": multiplication start of integer\n" ; 
			asmFile << "\t\tMOV CX , BX\n" ; 
			asmFile << "\t\tPOP AX\n" ; 
			asmFile << "\t\tIMUL CX\n" ; 
			asmFile << "\t\tMOV BX , AX\t ;  line no "<< line_count << ": only last 16 bit is taken in mul\n" ; 
			asmFile << "\t\tPUSH BX\n\n" ; 
			
		} else if($2->getSymbolName() == "%"){
			asmFile << "\t\tPOP BX\n" ; 
			asmFile << "\t\tMOV CX , BX\t ;  line no "<< line_count << ": / or % operation\n" ; 
			asmFile << "\t\tXOR DX , DX\n" ; 
			asmFile << "\t\tPOP AX\n" ; 
			asmFile << "\t\tIDIV CX\n" ; 
			asmFile << "\t\tMOV BX , DX\n" ; 
			asmFile << "\t\tPUSH BX\n\n" ; 
			
		} else if($2->getSymbolName() == "/"){
			asmFile << "\t\tPOP BX\n" ; 
			asmFile << "\t\tMOV CX , BX\t ;  line no "<< line_count << ": / or % operation\n" ; 
			asmFile << "\t\tXOR DX , DX\n" ; 
			asmFile << "\t\tPOP AX\n" ; 
			asmFile << "\t\tIDIV CX\n" ; 
			asmFile << "\t\tMOV BX , AX\n" ; 
			asmFile << "\t\tPUSH BX\n\n" ; 
		
		}
	}

	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": term : term MULOP unary_expression" << endl << endl ; 

	// mod must be operated on an integer

	if($2->getSymbolName() == "%") {
		if($1->size() == 1 && $3->size() == 1){
			// if($1->at(0)->getSymbolType() != "CONST_INT" || $3->at(0)->getSymbolType() != "CONST_INT"){
			// 	cout << "here err" << endl ; 
			// 	logFile << "Error at line " << line_count << ": Non-Integer operand on modulus operator" << endl << endl ; 
			// 	errFile << "Error at line " << line_count << ": Non-Integer operand on modulus operator" << endl << endl ; 
			// 	error_count++ ; 
			// }
			if($3->at(0)->getSymbolName() == "0"){
				logFile << "Error at line " << line_count << ": Modulus by Zero" << endl << endl ; 
				errFile << "Error at line " << line_count << ": Modulus by Zero" << endl << endl ; 
				error_count++ ; 
			}
		}

		// making them integer for modulus operator
		$3->at(0)->setSymbolType("CONST_INT") ; 
	}

	for(int i = 0 ;  i < $1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
	}
	logFile << $2->getSymbolName() ; 
	$$->push_back($2) ; 
	for(int i = 0 ;  i < $3->size() ;  i++){
		logFile << $3->at(i)->getSymbolName() ; 
		$$->push_back($3->at(i)) ; 
	}
	logFile << endl << endl ; 
}
 ; 

unary_expression : 
ADDOP unary_expression {
	
	if($1->getSymbolName() == "-"){
		if(inForLoop){
			tempFile << "\t\tPOP BX\n" ; 
			tempFile << "\t\tNEG BX\n" ; 
			tempFile << "\t\tPUSH BX\n" ; 

		} else {
			asmFile << "\t\tPOP BX\n" ; 
			asmFile << "\t\tNEG BX\n" ; 
			asmFile << "\t\tPUSH BX\n" ; 
		}
	}
	
	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": unary_expression : ADDOP unary_expression" << endl << endl ; 

	logFile << $1->getSymbolName() ; 
	$$->push_back($1) ; 
	for(int i = 0 ;  i < $2->size() ;  i++){
		logFile << $2->at(i)->getSymbolName() ; 
		$$->push_back($2->at(i)) ; 
	}
	logFile << endl << endl ; 
}
| NOT unary_expression {
	notLabel = newLabel() ; 

	asmFile << "\t\tPOP BX ; \tline no " << line_count << ": NOT operation\n" ; 
	asmFile << "\t\tCMP BX , 0\n" ; 
	asmFile << "\t\tMOV BX , 0\n" ; 
	asmFile << "\t\tJNE " << notLabel << endl ; 
	asmFile << "\t\tINC BX\n\n" ; 
	asmFile << "\t\t" << notLabel << ":\n" ; 
	asmFile << "\t\tPUSH BX\n\n" ; 



	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": unary_expression : NOT unary_expression" << endl << endl ; 

	logFile << $1->getSymbolName() ; 
	$$->push_back($1) ; 
	for(int i = 0 ;  i < $2->size() ;  i++){
		logFile << $2->at(i)->getSymbolName() ; 
		$$->push_back($2->at(i)) ; 
	}
	logFile << endl << endl ; 
}
| factor {
	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": unary_expression : factor" << endl << endl ; 

	
	for(int i = 0 ;  i < $1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
	}
	logFile << endl << endl ; 
}
 ; 
	
factor : 
variable {
	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": factor : variable" << endl << endl ; 

	for(int i = 0 ;  i < $1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
	}
	logFile << endl << endl ; 
}
| ID LPAREN RPAREN {
	// function call without argument

	if (inForLoop){
		tempFile << "\n\t\tCALL " << $1->getSymbolName() << "\t ;  line no " << line_count << ": function " << $1->getSymbolName() << " called\n" ; 
		tempFile << "\t\tMOV BX , DX\t ;  line no " << line_count << ": return result in DX\n" ; 
		tempFile << "\t\tPUSH BX\n\n" ;   

	} else {
		asmFile << "\n\t\tCALL " << $1->getSymbolName() << "\t ;  line no " << line_count << ": function " << $1->getSymbolName() << " called\n" ; 
		asmFile << "\t\tMOV BX , DX\t ;  line no " << line_count << ": return result in DX\n" ; 
		asmFile << "\t\tPUSH BX\n\n" ; 
	}

	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": factor : ID LPAREN RPAREN" << endl << endl ; 

	logFile << $1->getSymbolName() ; 
	$$->push_back($1) ; 
	logFile << $2->getSymbolName() ; 
	$$->push_back($2) ; 
	logFile << $3->getSymbolName() ; 
	$$->push_back($3) ; 

	logFile << endl << endl ; 

}
| ID LPAREN argument_list RPAREN {
	// function call with argument
	// need to match parameter type , no. of parameters

	// ekhane reverse direction e push (if CONST_INT) or set offset
	// here
	// isArgumentPassing = true ; 
	// for(int i = $3->size()-1 ;  i>=0 ;  i--){
	// 	if($3->at(i)->getSymbolType() == "ID"){
	// 		SymbolInfo* currSymbol = table.getSymbolInfo($3->at(i)->getSymbolName()) ; 
	// 		asmFile << "\t\tMOV BX , [BP + " << currSymbol->getOffset() << "]\n" ; 
	// 		asmFile << "\t\tPUSH BX\t ;  line no " << line_count << ": " << currSymbol->getSymbolName() << " loaded\n\n" ;  
	// 	} else {
	// 		// const int
	// 		asmFile << "\t\tPUSH " << $1->getSymbolName() << endl << endl ; 
	// 	}
	// }
	// isArgumentPassing = false ; 

	if (inForLoop){ 
		tempFile << "\n\t\tCALL " << $1->getSymbolName() << "\t ;  line no " << line_count << ": function " << $1->getSymbolName() << " called\n" ; 
		tempFile << "\t\tMOV BX , DX\t ;  line no " << line_count << ": return result in DX\n" ; 
		tempFile << "\t\tPUSH BX\n\n" ; 
	} else {
		asmFile << "\n\t\tCALL " << $1->getSymbolName() << "\t ;  line no " << line_count << ": function " << $1->getSymbolName() << " called\n" ; 
		asmFile << "\t\tMOV BX , DX\t ;  line no " << line_count << ": return result in DX\n" ; 
		asmFile << "\t\tPUSH BX\n\n" ;   
	}

	
	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": factor : ID LPAREN argument_list RPAREN" << endl << endl ; 

	if (DEBUG){
		logFile << "test" << endl ; 
		table.printAllScopeTables() ; 
	}

	if(!table.lookupEntire($1->getSymbolName())) {
		
		logFile << "Error at line " << line_count << ": Undeclared function " << $1->getSymbolName() << endl << endl ; 
		errFile << "Error at line " << line_count << ": Undeclared function " << $1->getSymbolName() << endl << endl ; 
		error_count++ ; 
	} else {
		SymbolInfo* currSymbol = table.getSymbolInfo($1->getSymbolName()) ; 
		if (!currSymbol->isFunction()) {
			logFile << "Error at line " << line_count << ": " << $1->getSymbolName() << " not a function" << endl << endl ; 
			errFile << "Error at line " << line_count << ": " << $1->getSymbolName() << " not a function" << endl << endl ; 
			error_count++ ; 
		}

		vector <SymbolInfo*>* paramList = currSymbol->getParamList() ; 
		vector <string> definedFuncParamsType ; 
		// // cout << "defined parameter list" << endl ; 
		for (int i = 0 ;  i<paramList->size() ;  i++){
			if (paramList->at(i)->getSymbolType() != "ID" && paramList->at(i)->getSymbolType() != "COMMA") {
				// // cout << paramList->at(i)->getSymbolType() << " "  ; 
				definedFuncParamsType.push_back(paramList->at(i)->getSymbolType()) ; 
			}
		}

		// // cout << endl<< "arg list" << endl ; 
		vector <string> argsType ; 
		for (int i = 0 ;  i<$3->size() ;  i++){
			// ekhanei manually alada kore type bujhe bujhe (before comma) parse
			
			bool isFloat = false ; 
			while($3->at(i)->getSymbolName() != " ,"){
				// // cout << $3->at(i)->getSymbolName() << " " ; 
				if ($3->at(i)->getSymbolType() == "ID") {
					// variable
					if ($3->at(i)->getVariableType() == "FLOAT")
						isFloat = true ; 
					
				}
				else {
					// constant
					if ($3->at(i)->getSymbolType() == "CONST_FLOAT")
						isFloat = true ; 
				}
				i++ ; 
				if (i >= $3->size())
					break ; 
			}

			// assuming only array , float and int data types
			
				// I don't think there is rule for functions to have array parameters
			if (isFloat)
				argsType.push_back("FLOAT") ; 
			
			else 
				argsType.push_back("INT") ; 

		}

		// // cout <<  endl << "argsType list" << endl ; 
		// for (int i = 0 ;  i<argsType.size() ;  i++){
		// 	// cout << argsType[i] << " " ; 
		// }
		// // cout << endl << endl ; 

		//  // cout << "args size: " << argsType.size() << "param size: " << definedFuncParamsType.size() << endl ; 

		if (argsType.size() != definedFuncParamsType.size()) {
			logFile << "Error at line " << line_count << ": Total number of arguments mismatch in function " << $1->getSymbolName() << endl << endl ; 
			errFile << "Error at line " << line_count << ": Total number of arguments mismatch in function " << $1->getSymbolName() << endl << endl ; 
			error_count++ ; 
		} else {
			// not allowing passing int type in place of float type
			
			for (int i = 0 ;  i<argsType.size() ;  i++){
				if (argsType[i] != definedFuncParamsType[i]) {
					logFile << "Error at line " << line_count << ": " << i+1 << "th argument mismatch in function " << $1->getSymbolName() << endl << endl ; 
					errFile << "Error at line " << line_count << ": " << i+1 << "th argument mismatch in function " << $1->getSymbolName() << endl << endl ; 
					error_count++ ; 
				}
			}
		}

	}

	logFile << $1->getSymbolName() ; 
	$$->push_back($1) ; 
	logFile << $2->getSymbolName() ; 
	$$->push_back($2) ; 
	for(int i = 0 ;  i < $3->size() ;  i++){
		logFile << $3->at(i)->getSymbolName() ; 
		$$->push_back($3->at(i)) ; 
	}

	logFile << $4->getSymbolName() ; 
	$$->push_back($4) ; 
	logFile << endl << endl ; 

}
| LPAREN expression RPAREN {
	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": factor : LPAREN expression RPAREN" << endl << endl ; 

	logFile << $1->getSymbolName() ; 
	$$->push_back($1) ; 
	for(int i = 0 ;  i < $2->size() ;  i++){
		logFile << $2->at(i)->getSymbolName() ; 
		$$->push_back($2->at(i)) ; 
	}
	logFile << $3->getSymbolName() ; 
	$$->push_back($3) ; 
	logFile << endl << endl ; 

}
| CONST_INT {
	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": factor : CONST_INT" << endl << endl ; 

	logFile << $1->getSymbolName() ; 
	$$->push_back($1) ; 
	logFile << endl << endl ; 
	
	
	if (!isArgumentPassing){
		if (inForLoop){
			tempFile << "\t\tPUSH " << $1->getSymbolName() << endl << endl ; 
		} else
			asmFile << "\t\tPUSH " << $1->getSymbolName() << endl << endl ; 
	}
	
}
| CONST_FLOAT {
	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": factor : CONST_FLOAT" << endl << endl ; 

	logFile << $1->getSymbolName() ; 
	// // cout << $1->getSymbolName() << ": " << $1->getSymbolType() << endl ;  ; 
	$$->push_back($1) ; 
	logFile << endl << endl ; 
}
| variable INCOP {

	if (inForLoop){
		if ($1->at(0)->isArray()){
			tempFile << "\t\tPOP AX\t ;  line no: " << line_count << " taking the variable's value in AX\n" ; 
			tempFile << "\t\tPUSH AX\n\n" ; 
			tempFile << "\t\tINC AX\n" ; 
			tempFile << "\t\tMOV [BX] , AX\t ;  line no: " << line_count << " assigning the incremented value to the array variable\n\n" ; 

		} else {
			tempFile << "\t\tPOP AX\t ;  line no: " << line_count << " taking the variable's value in AX\n" ; 
			tempFile << "\t\tPUSH AX\n\n" ; 
			tempFile << "\t\tINC AX\n" ; 
			tempFile << "\t\tMOV [BP + " << $1->at(0)->getOffset() << " ] , AX\t ;  line no: " << line_count << " assigning the incremented value to the variable\n\n" ; 
		}
	} else {
		if ($1->at(0)->isArray()){
			asmFile << "\t\tPOP AX\t ;  line no: " << line_count << " taking the variable's value in AX\n" ; 
			asmFile << "\t\tPUSH AX\n\n" ; 
			asmFile << "\t\tINC AX\n" ; 
			asmFile << "\t\tMOV [BX] , AX\t ;  line no: " << line_count << " assigning the incremented value to the array variable\n\n" ; 

		} else {
			asmFile << "\t\tPOP AX\t ;  line no: " << line_count << " taking the variable's value in AX\n" ; 
			asmFile << "\t\tPUSH AX\n\n" ; 
			asmFile << "\t\tINC AX\n" ; 
			asmFile << "\t\tMOV [BP + " << $1->at(0)->getOffset() << " ] , AX\t ;  line no: " << line_count << " assigning the incremented value to the variable\n\n" ; 
		}
	}
	
	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": factor : variable INCOP" << endl << endl ; 

	
	for(int i = 0 ;  i < $1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
	}
	logFile << $2->getSymbolName() ; 
	$$->push_back($2) ; 
	logFile << endl << endl ; 
}
| variable DECOP {

	if (inForLoop){
		if ($1->at(0)->isArray()){
			tempFile << "\t\tPOP AX\t ;  line no: " << line_count << " taking the variable's value in AX\n" ; 
			tempFile << "\t\tPUSH AX\n\n" ; 
			tempFile << "\t\tDEC AX\n" ; 
			tempFile << "\t\tMOV [BX] , AX\t ;  line no: " << line_count << " assigning the decremented value to the array variable\n\n" ; 

		} else {
			tempFile << "\t\tPOP AX\t ;  line no: " << line_count << " taking the variable's value in AX\n" ; 
			tempFile << "\t\tPUSH AX\n\n" ; 
			tempFile << "\t\tDEC AX\n" ; 
			tempFile << "\t\tMOV [BP + " << $1->at(0)->getOffset() << " ] , AX\t ;  line no: " << line_count << " assigning the decremented value to the variable\n\n" ; 


		}
	} else {

		if ($1->at(0)->isArray()){
			asmFile << "\t\tPOP AX\t ;  line no: " << line_count << " taking the variable's value in AX\n" ; 
			asmFile << "\t\tPUSH AX\n\n" ; 
			asmFile << "\t\tDEC AX\n" ; 
			asmFile << "\t\tMOV [BX] , AX\t ;  line no: " << line_count << " assigning the decremented value to the array variable\n\n" ; 

		} else {
			asmFile << "\t\tPOP AX\t ;  line no: " << line_count << " taking the variable's value in AX\n" ; 
			asmFile << "\t\tPUSH AX\n\n" ; 
			asmFile << "\t\tDEC AX\n" ; 
			asmFile << "\t\tMOV [BP + " << $1->at(0)->getOffset() << " ] , AX\t ;  line no: " << line_count << " assigning the decremented value to the variable\n\n" ; 


		}
	}

	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": factor : variable DECOP" << endl << endl ; 

	
	for(int i = 0 ;  i < $1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
	}
	logFile << $2->getSymbolName() ; 
	$$->push_back($2) ; 
	logFile << endl << endl ; 
}
 ; 
		
argument_list : 
arguments {
	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": argument_list : arguments" << endl << endl ; 

	for(int i = 0 ;  i < $1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
	}
	logFile << endl << endl ; 
}
 ; 
	
arguments : 
arguments COMMA logic_expression {
	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": arguments : arguments COMMA logic_expression" << endl << endl ; 

	for(int i = 0 ;  i < $1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
	}
	logFile << $2->getSymbolName() ; 
	$$->push_back($2) ; 
	
	for(int i = 0 ;  i < $3->size() ;  i++){
		logFile << $3->at(i)->getSymbolName() ; 
		$$->push_back($3->at(i)) ; 
	}
	logFile << endl << endl ; 
}
| logic_expression {
	$$ = new vector<SymbolInfo*>() ; 
	logFile << "Line " << line_count <<  ": arguments : logic_expression" << endl << endl ; 

	for(int i = 0 ;  i < $1->size() ;  i++){
		logFile << $1->at(i)->getSymbolName() ; 
		$$->push_back($1->at(i)) ; 
	}
	logFile << endl << endl ; 
}
 ; 
 

%%
int main(int argc ,char *argv[]) {
	if(argc!=6) {
		cout << "Please provide all the file names and try again" << endl ; 
		return 0 ; 
	}

	if((inputFile=fopen(argv[1] ,"r"))==NULL) {
		printf("Cannot Open Input File.\n") ; 
		exit(1) ; 
	}

	logFile.open(argv[2]) ; 

	errFile.open(argv[3]) ; 
	asmFile.open(argv[4]) ; 
	optAsmFile.open(argv[5]) ; 
	tempFile.open("temp.txt") ; 

	yyin=inputFile ; 
	tempParamList = new vector <SymbolInfo*> ; 
	initCode() ; 

	yyparse() ; 

	printEndingCode() ; 

	if(error_count > 0) {

		cout<< "ERROR IN CODE.. CLEARING ASM FILES..."<< endl ; 
		FILE *fp = fopen(argv[4] , "w") ; 
		fclose(fp) ; 
		FILE *fp2 = fopen(argv[5] , "w") ; 
		fclose(fp2) ; 
		return 0 ; 
	}



	asmFile.close() ; 
	optimizeAsmCode(argv[4]) ; 
	// 2nd pass
	// optimizeAsmCode(argv[5]) ;

	// optimizeAsmCode("test.txt") ; 




	logFile.close() ; 
	errFile.close() ; 
	asmFile.close() ; 
	optAsmFile.close() ; 
	tempFile.close() ; 
	fclose(yyin) ; 
	
	return 0 ; 
}

