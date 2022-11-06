%{
#include<bits/stdc++.h>
#include "1805082_SymbolTable.h"

using namespace std;

bool DEBUG = false;
// #define YYSTYPE SymbolInfo*
int yyparse(void);
int yylex(void);
extern FILE *yyin;
FILE *inputFile;

ofstream logFile;
ofstream errFile;

SymbolTable table(30);
int line_count = 1;
int error_count = 0;
string currType = "";

bool isError = false;

vector <SymbolInfo*>* tempParamList;
SymbolInfo * currFunc;


void yyerror(char *s)
{
	// // cout << s << endl;
	logFile << "Error at line " << line_count << ": syntax error" << endl << endl;
	errFile << "Error at line " << line_count << ": syntax error" << endl << endl;
	error_count++;
}


%}

%union{
	SymbolInfo * sym;
	vector <SymbolInfo*> *symList;
}

%token <sym>  IF ELSE FOR WHILE LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD PRINTLN RETURN ASSIGNOP LOGICOP RELOP ADDOP MULOP NOT CONST_INT DOUBLE CHAR MAIN CONST_FLOAT INCOP DECOP
%token <sym> INT FLOAT VOID ID SEMICOLON COMMA ERROR 
%token NEWLINE
%type<sym> type_specifier
%type <symList> declaration_list var_declaration program unit func_declaration parameter_list 
%type <symList> func_definition compound_statement statements expression_statement statement variable 
%type <symList> expression logic_expression unary_expression factor term rel_expression simple_expression
%type <symList> arguments argument_list


%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE


%%

start : 
program {
	logFile << "Line " << line_count - 1 << ": start : program" << endl << endl;
}
;

program : 
program unit {
	logFile << "Line " << line_count <<  ": program : program unit" << endl << endl;
	$$ = new vector<SymbolInfo*>();
	for(int i = 0; i < $1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
		
		if($1->at(i)->getSymbolType() == "INT" || $1->at(i)->getSymbolType() == "FLOAT" || $1->at(i)->getSymbolType() == "VOID" || $1->at(i)->getSymbolType() == "RETURN"){
			logFile << " ";
		}

		if($1->at(i)->getSymbolName() == ";" || $1->at(i)->getSymbolName() == "{"){
			logFile << endl;
		}
		if ($1->at(i)->getSymbolName() == "}"){
			logFile << endl << endl;
		}
	}

	for(int i = 0; i < $2->size(); i++){
		logFile << $2->at(i)->getSymbolName();
		$$->push_back($2->at(i));
		
		if($2->at(i)->getSymbolType() == "INT" || $2->at(i)->getSymbolType() == "FLOAT" || $2->at(i)->getSymbolType() == "VOID" || $2->at(i)->getSymbolType() == "RETURN"){
			logFile << " ";
		}

		
		if($2->at(i)->getSymbolName() == ";" || $2->at(i)->getSymbolName() == "{"){
			logFile << endl;
		}
		if ($2->at(i)->getSymbolName() == "}"){
			logFile << endl << endl;
		}
	}
	logFile << endl << endl;
}
| unit {
	logFile << "Line " << line_count <<  ": program : unit" << endl << endl;
	$$ = new vector<SymbolInfo*>();
	for(int i = 0; i < $1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
		
		if($1->at(i)->getSymbolType() == "INT" || $1->at(i)->getSymbolType() == "FLOAT" || $1->at(i)->getSymbolType() == "VOID" || $1->at(i)->getSymbolType() == "RETURN"){
			logFile << " ";
		}

		if($1->at(i)->getSymbolName() == ";" || $1->at(i)->getSymbolName() == "{" || $1->at(i)->getSymbolName() == "}"){
			logFile << endl;
		}
	}
	logFile << endl << endl;
}
;
	
unit : 
var_declaration {
	logFile << "Line " << line_count <<  ": unit : var_declaration" << endl << endl;
	$$ = new vector<SymbolInfo*>();
	for(int i = 0; i < $1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
		
		if($1->at(i)->getSymbolType() == "INT" || $1->at(i)->getSymbolType() == "FLOAT" || $1->at(i)->getSymbolType() == "VOID"){
			logFile << " ";
		}
		
	}
	logFile << endl << endl << endl;

}
| func_declaration {
	logFile << "Line " << line_count <<  ": unit : func_declaration" << endl << endl;
	$$ = new vector<SymbolInfo*>();
	
	for (int i = 0; i<$1->size(); i++){
		
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
		
		if($1->at(i)->getSymbolType() == "INT" || $1->at(i)->getSymbolType() == "FLOAT" || $1->at(i)->getSymbolType() == "VOID"){
			logFile << " ";
		}
	}
	logFile << endl << endl<< endl;
}
| func_definition {
	logFile << "Line " << line_count <<  ": unit : func_definition" << endl << endl;
	$$ = new vector<SymbolInfo*>();
	
	for (int i = 0; i<$1->size(); i++) {
		
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
		
		if($1->at(i)->getSymbolType() == "INT" || $1->at(i)->getSymbolType() == "FLOAT" || $1->at(i)->getSymbolType() == "VOID" || $1->at(i)->getSymbolType() == "RETURN"){
			logFile << " ";
		}
		if($1->at(i)->getSymbolName() == ";" || $1->at(i)->getSymbolName() == "{" || $1->at(i)->getSymbolName() == "}"){
			logFile << endl;
		}

		if ($1->at(i)->getSymbolType() == "RETURN" && $1->at(0)->getSymbolType() == "VOID"){
			logFile << "Error at line " << line_count << ": Returning from a function which has Void return type " << endl << endl;
			errFile << "Error at line " << line_count << ": Returning from a function which has Void return type " << endl << endl;
			error_count++;
		}
	}
	
	logFile << endl << endl << endl;
	
}
;
     
func_declaration: 
type_specifier ID LPAREN parameter_list RPAREN SEMICOLON {
	logFile << "Line " << line_count <<  ": func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON" << endl << endl;
	$$ = new vector<SymbolInfo*>();

	$2->setIsFunction(true);
	//  // cout << "set ret type: " << $1->getSymbolType() << endl;
	//  // cout << "get symbol type: " << $2->getSymbolType() << endl;
	$2->setReturnType($1->getSymbolType());
	$2->setParamList($4);
	
	//  // cout << "ret type: " << $2->getReturnType() << endl;

	if(!table.insert($2)){
		logFile << "Error at line " << line_count << ": Multiple declaration of " << $2->getSymbolName() << endl << endl;
		errFile << "Error at line " << line_count << ": Multiple declaration of " << $2->getSymbolName() << endl << endl;
		error_count++;
	}
	
	
	logFile << $1->getSymbolName() << " " << $2->getSymbolName() << $3->getSymbolName();
	
	// check if multiple declaration of param name on the same list

	// SymbolTable paramTable(20);
	// for(int i = 0; i<$4->size(); i++){
	// 	logFile << $4->at(i)->getSymbolName();
	// 	if($4->at(i)->getSymbolType() == "INT" || $4->at(i)->getSymbolType() == "FLOAT" || $4->at(i)->getSymbolType() == "VOID"){
	// 		logFile << " ";
	// 	}
	// 	if(i%2 == 1){
	// 		// skipping test for type specifiers, only testing IDs
	// 		continue;
	// 	}
	// 	if(!paramTable.insert($4->at(i))){
	// 		logFile << "Error at line " << line_count << ": Multiple declaration of " << $4->at(i)->getSymbolName() << " in param list" << endl << endl;
	// 		errFile << "Error at line " << line_count << ": Multiple declaration of " << $4->at(i)->getSymbolName() << " in param list" << endl << endl;
	// 		error_count++;
	// 	}
	// }

	
	for(int i = 0; i<$4->size(); i++){
		logFile << $4->at(i)->getSymbolName();
		if($4->at(i)->getSymbolType() == "INT" || $4->at(i)->getSymbolType() == "FLOAT" || $4->at(i)->getSymbolType() == "VOID"){
			logFile << " ";
			
		}

		if($4->at(i)->getSymbolType() == "COMMA" || $4->at(i)->getSymbolType() == "INT" || $4->at(i)->getSymbolType() == "FLOAT" || $4->at(i)->getSymbolType() == "VOID"){
			// skipping test for type specifiers, only testing IDs
			continue;
		}

		vector <string> paramList;
		paramList.push_back($4->at(i)->getSymbolName());
		for(int j = 0; j<paramList.size() - 1; j++){
			if($4->at(i)->getSymbolName() == paramList[j]){
				logFile << "Error at line " << line_count << ": Multiple declaration of " << $4->at(i)->getSymbolName() << " in param list" << endl << endl;
				errFile << "Error at line " << line_count << ": Multiple declaration of " << $4->at(i)->getSymbolName() << " in param list" << endl << endl;
				error_count++;
			}
		}
		//  // cout << endl;
	}

	int j = 0;
	for(int i = 0; i<$4->size(); i++) {
		// // cout << $4->at(i)->getSymbolType() << " ";
		
		if (i%3==0)
			j++;

		if ($4->at(i)->getSymbolType() == "ERROR") {
			logFile << "Error at line " << line_count << ": " << j << "th parameter's name not given in function declaration of " << $2->getSymbolName() << endl << endl;
			errFile << "Error at line " << line_count << ": " << j << "th parameter's name not given in function declaration of " << $2->getSymbolName() << endl << endl;
			
			error_count++;
		}

	}
	
	logFile << $5->getSymbolName() << $6->getSymbolName() << endl << endl << endl;
			
	$$ = new vector <SymbolInfo*>();
	$$->push_back($1);
	$$->push_back($2);
	$$->push_back($3);
	
	// store param list with respective type
	for(int i = 0; i<$4->size(); i++) {
		$$->push_back($4->at(i));
	}

	$$->push_back($5);
	$$->push_back($6);
}
| type_specifier ID LPAREN RPAREN SEMICOLON {
	logFile << "Line " << line_count <<  ": func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON" << endl << endl;
	$$ = new vector<SymbolInfo*>();

	$2->setIsFunction(true);
	//  // cout << "set ret type: " << $1->getSymbolType() << endl;
	//  // cout << "get symbol type: " << $2->getSymbolType() << endl;
	$2->setReturnType($1->getSymbolType());
	
	if(!table.insert($2)){
		logFile << "Error at line " << line_count << ": Multiple declaration of " << $2->getSymbolName() << endl << endl;
		errFile << "Error at line " << line_count << ": Multiple declaration of " << $2->getSymbolName() << endl << endl;
		error_count++;
	}
	
	logFile << $1->getSymbolName() << " " << $2->getSymbolName() << $3->getSymbolName() << $4->getSymbolName() << $5->getSymbolName() << endl << endl << endl;
			
	$$ = new vector <SymbolInfo*>();
	$$->push_back($1);
	$$->push_back($2);
	$$->push_back($3);
	$$->push_back($4);
	$$->push_back($5);

}
;
		 
func_definition : 
type_specifier ID LPAREN parameter_list RPAREN {
	// will understand if declared if already found on symbol table
	
	SymbolInfo * currSymbol = table.getSymbolInfo($2->getSymbolName());
	
	string funcName = $2->getSymbolName();
	
	
	if (table.lookupEntire($2->getSymbolName())) {
		//  // cout << "get symbol type: " << currSymbol->getSymbolType() << endl;
		// the ID is available in the symbol table
		// already declared as ID or function declaration
		
		// already checked for multiple IDs of same variable name in func_declaration part, no need to raise error again
		if (!currSymbol->isFunction()) {
			// logFile << "Error at line " << line_count << ": Identifier '" << $2->getSymbolName() << "' is not a function." << endl << endl;
			// errFile << "Error at line " << line_count << ": Identifier '" << $2->getSymbolName() << "' is not a function." << endl << endl;
			errFile << "Error at line " << line_count << ": Multiple declaration of " << $2->getSymbolName() << endl << endl;
			logFile << "Error at line " << line_count << ": Multiple declaration of " << $2->getSymbolName() << endl << endl;
			error_count++;
		} else {
			if (currSymbol->isDefined()){
				logFile << "Error at line " << line_count << ": Re-definition of function '" << $2->getSymbolName() << "'" << endl << endl;
				errFile << "Error at line " << line_count << ": Re-definition of function '" << $2->getSymbolName() << "'" << endl << endl;
				
				error_count++;
			} else {
				// check the param list and return type for inconsistency with the declaration
				if (currSymbol->getReturnType() != $1->getSymbolType()){
					logFile << "Error at line " << line_count << ": Return type mismatch with function declaration in function " << funcName << endl << endl;
					errFile << "Error at line " << line_count << ": Return type mismatch with function declaration in function " << funcName << endl << endl;
					
					error_count++;
				}

				if (currSymbol->getParamList()->size() != $4->size()){
					logFile << "Error at line " << line_count << ": Total number of arguments mismatch with declaration in function "  << funcName << endl << endl;
					errFile << "Error at line " << line_count << ": Total number of arguments mismatch with declaration in function "  << funcName << endl << endl;
					
					error_count++;
				} else if( $4->size() != 0) {
					
					for(int i = 0; i<$4->size(); i++) {
						if ($4->at(i)->getSymbolType() == "ID" ||$4->at(i)->getSymbolType() == "COMMA"){
							// no need to check if the IDs are of the same name, only the types must match
							continue;
						}
						if (currSymbol->getParamList()->at(i)->getSymbolName() != $4->at(i)->getSymbolName()){
							logFile << "Error at line " << line_count << ": Type mismatch of function parameter '" << currSymbol->getParamList()->at(i)->getSymbolName() << "'" << endl << endl;
							errFile << "Error at line " << line_count << ": Type mismatch of function parameter '" << currSymbol->getParamList()->at(i)->getSymbolName() << "'" << endl << endl;
							
							error_count++;
						}
					}

					
				}

				string funcName = currSymbol->getSymbolName();
				string symType = currSymbol->getSymbolType();
				SymbolInfo * newSymbol = new SymbolInfo(funcName, symType);
				vector <SymbolInfo*>* paramList = currSymbol->getParamList();
				currSymbol->setParamList(paramList);
				currSymbol->setIsDefined(true);
				currSymbol->setIsFunction(true);
				
				// table.remove(currSymbol->getSymbolName());	// removing old declared function and inserting a new symbol info in the table with defined status
				// HERE WE DELETED $2, MUST NOT TRY TO ACCESS IN ANY LATER PART
				//  // cout << "get defined ret type: " << currSymbol->getReturnType() << endl;
				currFunc = table.getSymbolInfo(funcName);
				
			}
		}
	} else {
		// the func is not declared yet, direct definition found
		// check if multiple declaration of param name on the same list
		for(int i = 0; i<$4->size(); i++){

			if($4->at(i)->getSymbolType() == "COMMA" || $4->at(i)->getSymbolType() == "INT" || $4->at(i)->getSymbolType() == "FLOAT" || $4->at(i)->getSymbolType() == "VOID"){
				// skipping test for type specifiers, only testing IDs
				continue;
			}

			vector <string> paramList;
			paramList.push_back($4->at(i)->getSymbolName());
			for(int j = 0; j<paramList.size() - 1; j++){
				if($4->at(i)->getSymbolName() == paramList[j]){
					logFile << "Error at line " << line_count << ": Multiple declaration of " << $4->at(i)->getSymbolName() << " in param list" << endl << endl;
					errFile << "Error at line " << line_count << ": Multiple declaration of " << $4->at(i)->getSymbolName() << " in param list" << endl << endl;
					error_count++;
				}
			}
		
		}

		SymbolInfo * newSymbol = new SymbolInfo(funcName, "ID");
		vector <SymbolInfo*>* paramList = $4;
		newSymbol->setParamList(paramList);
		newSymbol->setIsDefined(true);
		newSymbol->setIsFunction(true);

		//  // cout << "set ret type: " << $1->getSymbolType() << endl;
		newSymbol->setReturnType($1->getSymbolType());

		table.insert(newSymbol);

		// tempParamList = new vector<SymbolInfo*>;
		// for (int i = 0; i<$4->size(); i++) {
		// 	tempParamList->push_back($4->at(i));
		// }
	
		currFunc = table.getSymbolInfo(funcName);
		//  // cout << "herer" << endl;
	}

	int j = 0;
	for(int i = 0; i<$4->size(); i++) {
		// // cout << $4->at(i)->getSymbolType() << " ";
		
		if (i%3==0)
			j++;

		if ($4->at(i)->getSymbolType() == "ERROR") {
			logFile << "Error at line " << line_count << ": " << j << "th parameter's name not given in function definition of " << $2->getSymbolName() << endl << endl;
			errFile << "Error at line " << line_count << ": " << j << "th parameter's name not given in function definition of " << $2->getSymbolName() << endl << endl;
			
			error_count++;
		}

	}

	// adding the parameters to symbol table in either case
	tempParamList = new vector<SymbolInfo*>;
	for (int i = 0; i<$4->size(); i++) {
		tempParamList->push_back($4->at(i));
	}

} compound_statement {
	table.printAllScopeTables();
	table.exitScope();
	
} {
	logFile << "Line " << line_count <<  ": func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement" << endl << endl;
	$$ = new vector<SymbolInfo*>();

	logFile << $1->getSymbolName() << " " << $2->getSymbolName() << $3->getSymbolName();
	
	$$->push_back($1);
	$$->push_back($2);
	$$->push_back($3);
	for (int i = 0; i < $4->size(); i++){
		logFile << $4->at(i)->getSymbolName();
		$$->push_back($4->at(i));
		if($4->at(i)->getSymbolType() == "INT" || $4->at(i)->getSymbolType() == "FLOAT" || $4->at(i)->getSymbolType() == "VOID" || $4->at(i)->getSymbolType() == "RETURN")
			logFile << " ";
	}
	logFile << $5->getSymbolName();
	$$->push_back($5);
	for (int i = 0; i < $7->size(); i++){
		logFile << $7->at(i)->getSymbolName();
		$$->push_back($7->at(i));
		if($7->at(i)->getSymbolType() == "INT" || $7->at(i)->getSymbolType() == "FLOAT" || $7->at(i)->getSymbolType() == "VOID" || $7->at(i)->getSymbolType() == "RETURN")
			logFile << " ";
		if($7->at(i)->getSymbolName() == ";" || $7->at(i)->getSymbolName() == "{" || $7->at(i)->getSymbolName() == "}")
			logFile << endl;
	}
	logFile << endl << endl;

	tempParamList->clear();
	
	
}
| type_specifier ID LPAREN RPAREN {
	SymbolInfo * currSymbol = table.getSymbolInfo($2->getSymbolName());
	string funcName = $2->getSymbolName();

	if (table.lookupEntire($2->getSymbolName())) {
		// the ID is available in the symbol table
		// already declared as ID or function declaration
		
		if (!currSymbol->isFunction()) {
			logFile << "Error at line " << line_count << ": Identifier '" << $2->getSymbolName() << "' is not a function." << endl << endl;
			errFile << "Error at line " << line_count << ": Identifier '" << $2->getSymbolName() << "' is not a function." << endl << endl;
			error_count++;
		} else {
			if (currSymbol->isDefined()){
				logFile << "Error at line " << line_count << ": Re-definition of function '" << $2->getSymbolName() << "'" << endl << endl;
				errFile << "Error at line " << line_count << ": Re-definition of function '" << $2->getSymbolName() << "'" << endl << endl;
				
				error_count++;
			} else {
				if (currSymbol->getReturnType() != $1->getSymbolType()){
					logFile << "Error at line " << line_count << ": Function return type doesn't match with declaration" << endl << endl;
					errFile << "Error at line " << line_count << ": Function return type doesn't match with declaration" << endl << endl;
					
					error_count++;
				}
			}
		}
		
		currSymbol->setIsDefined(true);
		currSymbol->setIsFunction(true);
		//  // cout << "get defined ret type: " << currSymbol->getReturnType() << endl;

		currFunc = table.getSymbolInfo(funcName);
		

	} else {
		// the func is not declared yet, direct definition found
		// // cout << "funct name " << funcName << endl;
		SymbolInfo * newSymbol = new SymbolInfo(funcName, "ID");
		newSymbol->setIsDefined(true);
		newSymbol->setIsFunction(true);
		//  // cout << "set ret type: " << $1->getSymbolType() << endl;
		newSymbol->setReturnType($1->getSymbolType());
		
		table.insert(newSymbol);
		currFunc = table.getSymbolInfo(funcName);

		// table.enterScope();
		
	}
}
 compound_statement {
	table.printAllScopeTables();
	table.exitScope();
} {
	
	logFile << "Line " << line_count <<  ": func_definition : type_specifier ID LPAREN RPAREN compound_statement" << endl << endl;
	$$ = new vector<SymbolInfo*>();

	logFile << $1->getSymbolName() << " " << $2->getSymbolName() << $3->getSymbolName() << $4->getSymbolName();
	$$->push_back($1);
	$$->push_back($2);
	$$->push_back($3);
	$$->push_back($4);
	
	for (int i = 0; i < $6->size(); i++){
		logFile << $6->at(i)->getSymbolName();
		$$->push_back($6->at(i));
		if($6->at(i)->getSymbolType() == "INT" || $6->at(i)->getSymbolType() == "FLOAT" || $6->at(i)->getSymbolType() == "VOID" || $6->at(i)->getSymbolType() == "RETURN" || $6->at(i)->getSymbolType() == "IF")
			logFile << " ";
		if($6->at(i)->getSymbolName() == ";" || $6->at(i)->getSymbolName() == "{" || $6->at(i)->getSymbolName() == "}" || $6->at(i)->getSymbolName() == "ELSE")
			logFile << endl;
	}
	logFile << endl << endl;
 }
;

parameter_list  : 
parameter_list COMMA type_specifier ID {
	logFile << "Line " << line_count <<  ": parameter_list : parameter_list COMMA type_specifier ID" << endl << endl;
	$$ = new vector<SymbolInfo*>();
	
	for (int i = 0; i<$1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
		
		if($1->at(i)->getSymbolType() == "INT" || $1->at(i)->getSymbolType() == "FLOAT" || $1->at(i)->getSymbolType() == "VOID"){
			logFile << " ";
		}

	}
	logFile << $2->getSymbolName() << $3->getSymbolName() << " " << $4->getSymbolName() << endl << endl;
	$$->push_back($2);
	$$->push_back($3);
	$$->push_back($4);
	
}
| parameter_list COMMA type_specifier {
	logFile << "Line " << line_count <<  ": parameter_list : parameter_list COMMA type_specifier" << endl << endl;
	$$ = new vector <SymbolInfo*>();
	
	for (int i = 0; i<$1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
		
		if($1->at(i)->getSymbolType() == "INT" || $1->at(i)->getSymbolType() == "FLOAT" || $1->at(i)->getSymbolType() == "VOID"){
			logFile << " ";
		}

	}
	logFile << $2->getSymbolName() << $3->getSymbolName() << endl << endl;
	$$->push_back($2);
	$$->push_back($3);
	
}

| parameter_list COMMA type_specifier error {
	logFile << "Line " << line_count <<  ": parameter_list : parameter_list COMMA type_specifier" << endl << endl;
	$$ = new vector <SymbolInfo*>();
	
	for (int i = 0; i<$1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
		
		if($1->at(i)->getSymbolType() == "INT" || $1->at(i)->getSymbolType() == "FLOAT" || $1->at(i)->getSymbolType() == "VOID"){
			logFile << " ";
		}

	}
	logFile << $2->getSymbolName() << $3->getSymbolName() << endl << endl;
	$$->push_back($2);
	$$->push_back($3);

	SymbolInfo* errSymbol = new SymbolInfo("", "ERROR");
	$$->push_back(errSymbol);
	
	yyclearin;

}

| type_specifier ID {
	logFile << "Line " << line_count <<  ": parameter_list : type_specifier ID" << endl << endl;
	$$ = new vector <SymbolInfo*>();
	
	logFile << $1->getSymbolName() << " " << $2->getSymbolName() << endl << endl;
	$$->push_back($1);
	$$->push_back($2);

}
| type_specifier {
	logFile << "Line " << line_count <<  ": parameter_list : type_specifier" << endl << endl;
	$$ = new vector <SymbolInfo*>();
	
	logFile << $1->getSymbolName() << endl << endl;
	$$->push_back($1);
	
}

| type_specifier error {
	logFile << "Line " << line_count <<  ": parameter_list : type_specifier" << endl << endl;
	$$ = new vector <SymbolInfo*>();
	
	logFile << $1->getSymbolName() << endl << endl;
	$$->push_back($1);

	SymbolInfo* errSymbol = new SymbolInfo("", "ERROR");
	$$->push_back(errSymbol);
	
	yyclearin;
}
;

compound_statement : 
LCURL {
	table.enterScope();
	// insert the parameters in the current scope table
	for (int i = 0; i<tempParamList->size(); i++){
		
		if (tempParamList->at(i)->getSymbolType() != "ID" || tempParamList->at(i)->getSymbolType() == "ERROR") {
			continue;
		}
		if (!table.insert(tempParamList->at(i))){
			logFile << "Error at line " << line_count -1 << ": Multiple declaration of " << tempParamList->at(i)->getSymbolName() << " in parameter" << endl << endl;
			errFile << "Error at line " << line_count -1 << ": Multiple declaration of " << tempParamList->at(i)->getSymbolName() << " in parameter" << endl << endl;
			
			error_count++;
		}
	}
	// tempParamList = NULL;

} statements RCURL {

	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": compound_statement : LCURL statements RCURL" << endl << endl;

	logFile << $1->getSymbolName() << endl;
	$$->push_back($1);

	
	for(int i = 0; i < $3->size(); i++){
		$$->push_back($3->at(i));
		logFile << $3->at(i)->getSymbolName();
		if($3->at(i)->getSymbolType() == "INT" || $3->at(i)->getSymbolType() == "FLOAT" || $3->at(i)->getSymbolType() == "VOID" || $3->at(i)->getSymbolType() == "RETURN" || $3->at(i)->getSymbolType() == "IF" )
			logFile << " ";
		if($3->at(i)->getSymbolName() == ";" || $3->at(i)->getSymbolName() == "{" || $3->at(i)->getSymbolName() == "}" || $3->at(i)->getSymbolName() == "ELSE")
			logFile << endl;
	}

	logFile << $4->getSymbolName() << endl << endl;
	$$->push_back($4);
	

}
| LCURL {
	table.enterScope();

} RCURL {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": compound_statement : LCURL RCURL" << endl << endl;
	logFile << $1->getSymbolName() << $3->getSymbolName() << endl << endl;
	$$->push_back($1);
	$$->push_back($3);

	table.printAllScopeTables();
	// table.exitScope();
}
;
 		    
var_declaration : 
type_specifier declaration_list SEMICOLON {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": var_declaration : type_specifier declaration_list SEMICOLON" << endl << endl;
	
	if($1->getSymbolType() == "VOID"){
		logFile << "Error at line " << line_count << ": Variable type cannot be void" << endl << endl;;
		errFile << "Error at line " << line_count << ": Variable type cannot be void" << endl << endl;; 
		error_count++;
	}

	logFile << $1->getSymbolName() << " ";
	$$->push_back($1);
	for(int i = 0; i < $2->size(); i++){
		$$->push_back($2->at(i));
		logFile << $2->at(i)->getSymbolName();
		if ($2->at(i)->getSymbolType() == "ERROR") {
			// logFile << "Error at line " << line_count << ": syntax error" << endl << endl;
			// errFile << "Error at line " << line_count << ": syntax error" << endl << endl;
			error_count++;
		}
	}
	
	logFile << $3->getSymbolName() << endl << endl;
	$$->push_back($3);

}
;
 		 
type_specifier	: 
INT	{
	logFile << "Line " << line_count << ": type_specifier : INT" << endl << endl;
	logFile << $1->getSymbolName() << endl<< endl;
	$$ = $1;
	currType = "INT";
}
| FLOAT {
	logFile << "Line " << line_count << ": type_specifier : FLOAT" << endl << endl;
	logFile << $1->getSymbolName() << endl<< endl;
	$$ = $1;
	currType = "FLOAT";
}
| VOID {
	logFile << "Line " << line_count << ": type_specifier : VOID" << endl << endl;
	logFile << $1->getSymbolName() << endl<< endl;
	$$ = $1;
	currType = "VOID";
}
;
 		
declaration_list : 
declaration_list COMMA ID {
	if (DEBUG){
		logFile << "test" << endl;
 		table.printAllScopeTables();
	}
	// if(currType != "VOID"){
		// not skipping void insertion
		$3->setVariableType(currType);
		if(!table.insert($3)){
			logFile << "Error at line " << line_count << ": Multiple declaration of " << $3->getSymbolName() <<endl<<endl;
			errFile << "Error at line " << line_count << ": Multiple declaration of " << $3->getSymbolName() <<endl<<endl;
			error_count++;
		}
	// }

	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": declaration_list : declaration_list COMMA ID" << endl << endl;
	for(int i = 0; i < $1->size(); i++){
		// taking the old list from $1 and adding to $$
		
		$$->push_back($1->at(i));
		logFile << $1->at(i)->getSymbolName();
	}
	logFile << $2->getSymbolName() << $3->getSymbolName() << endl << endl;
	$$->push_back($2);	// adding COMMA as well
	$$->push_back($3);
}

| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
	// if(currType != "VOID"){
		// not skipping void insertion
		$3->setIsArray(true);
		$3->setVariableType(currType);
		if(!table.insert($3)){
			logFile << "Error at line " << line_count << ": Multiple declaration of " << $3->getSymbolName() <<endl<<endl;
			errFile << "Error at line " << line_count << ": Multiple declaration of " << $3->getSymbolName() <<endl<<endl;
			error_count++;
		}
	// }

	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD" << endl << endl;
	for(int i = 0; i < $1->size(); i++){
		// taking the old list from $1 and adding to $$
	
		$$->push_back($1->at(i));
		logFile << $1->at(i)->getSymbolName();
	}
	logFile << $2->getSymbolName() << $3->getSymbolName() << $4->getSymbolName() << $5->getSymbolName() << $6->getSymbolName() << endl << endl;
	$$->push_back($2);	// adding COMMA as well
	$$->push_back($3);
	$$->push_back($4);
	$$->push_back($5);
	$$->push_back($6);

}
| ID {
	// if(currType != "VOID"){
		// not skipping void insertion
		if(!table.insert($1)){
			logFile << "Error at line " << line_count << ": Multiple declaration of " << $1->getSymbolName() <<endl<<endl;
			errFile << "Error at line " << line_count << ": Multiple declaration of " << $1->getSymbolName() <<endl<<endl;
			error_count++;
		}
	// }

	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": declaration_list : ID" << endl<< endl;
	logFile << $1->getSymbolName() << endl<< endl;
	$$->push_back($1);

}
| ID LTHIRD CONST_INT RTHIRD {
	// if(currType != "VOID"){
		// mot skipping void insertion
		$1->setIsArray(true);
		if(!table.insert($1)){
			logFile << "Error at line " << line_count << ": Multiple declaration of " << $1->getSymbolName() <<endl<<endl;
			errFile << "Error at line " << line_count << ": Multiple declaration of " << $1->getSymbolName() <<endl<<endl;
			error_count++;
		}
	// }

	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": declaration_list : ID LTHIRD CONST_INT RTHIRD" << endl<< endl;
	logFile << $1->getSymbolName() << $2->getSymbolName() << $3->getSymbolName() << $4->getSymbolName() << endl<< endl;
	$$->push_back($1);
	$$->push_back($2);
	$$->push_back($3);
	$$->push_back($4);
}

| declaration_list ADDOP ID LTHIRD CONST_INT RTHIRD {
	$$ = new vector<SymbolInfo*>();
	for(int i = 0; i < $1->size(); i++){
		$$->push_back($1->at(i));
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
}

| declaration_list MULOP ID LTHIRD CONST_INT RTHIRD {
	$$ = new vector<SymbolInfo*>();
	for(int i = 0; i < $1->size(); i++){
		$$->push_back($1->at(i));
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
}

| declaration_list INCOP ID LTHIRD CONST_INT RTHIRD {
	$$ = new vector<SymbolInfo*>();
	for(int i = 0; i < $1->size(); i++){
		$$->push_back($1->at(i));
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
}

| declaration_list DECOP ID LTHIRD CONST_INT RTHIRD {
	$$ = new vector<SymbolInfo*>();
	for(int i = 0; i < $1->size(); i++){
		$$->push_back($1->at(i));
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
}

| declaration_list RELOP ID LTHIRD CONST_INT RTHIRD {
	$$ = new vector<SymbolInfo*>();
	for(int i = 0; i < $1->size(); i++){
		$$->push_back($1->at(i));
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
}

| declaration_list ASSIGNOP ID LTHIRD CONST_INT RTHIRD {
	$$ = new vector<SymbolInfo*>();
	for(int i = 0; i < $1->size(); i++){
		$$->push_back($1->at(i));
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
}

| declaration_list LOGICOP ID LTHIRD CONST_INT RTHIRD {
	$$ = new vector<SymbolInfo*>();
	for(int i = 0; i < $1->size(); i++){
		$$->push_back($1->at(i));
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
}

| declaration_list ADDOP ID {
	$$ = new vector<SymbolInfo*>();
	for(int i = 0; i < $1->size(); i++){
		$$->push_back($1->at(i));
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
}

| declaration_list MULOP ID {
	$$ = new vector<SymbolInfo*>();
	for(int i = 0; i < $1->size(); i++){
		$$->push_back($1->at(i));
	}
	logFile << "Error at line " << line_count <<  ":OK syntax error" << endl<< endl;
	errFile << "Error at line " << line_count <<  ":OK syntax error" << endl<< endl;
}

| declaration_list INCOP ID {
	$$ = new vector<SymbolInfo*>();
	for(int i = 0; i < $1->size(); i++){
		$$->push_back($1->at(i));
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
}

| declaration_list DECOP ID {
	$$ = new vector<SymbolInfo*>();
	for(int i = 0; i < $1->size(); i++){
		$$->push_back($1->at(i));
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
}

| declaration_list RELOP ID {
	$$ = new vector<SymbolInfo*>();
	for(int i = 0; i < $1->size(); i++){
		$$->push_back($1->at(i));
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
}

| declaration_list ASSIGNOP ID {
	$$ = new vector<SymbolInfo*>();
	for(int i = 0; i < $1->size(); i++){
		$$->push_back($1->at(i));
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
}

| declaration_list LOGICOP ID {
	$$ = new vector<SymbolInfo*>();
	for(int i = 0; i < $1->size(); i++){
		$$->push_back($1->at(i));
	}
	logFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
	errFile << "Error at line " << line_count <<  ": syntax error" << endl<< endl;
}

;
 		  
statements : 
statement {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": statements : statement" << endl << endl;
	for(int i = 0; i < $1->size(); i++){
		// cout << "line no: "<< line_count <<  ": statement" << endl;
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
		if($1->at(i)->getSymbolType() == "INT" || $1->at(i)->getSymbolType() == "FLOAT" || $1->at(i)->getSymbolType() == "VOID" || $1->at(i)->getSymbolType() == "RETURN" || $1->at(i)->getSymbolType() == "IF")
			logFile << " ";
		if($1->at(i)->getSymbolName() == ";" || $1->at(i)->getSymbolName() == "{" || $1->at(i)->getSymbolName() == "}" || $1->at(i)->getSymbolType() == "ELSE")
			logFile << endl;
	}
	logFile << endl << endl;

}
| statements statement {
	// cout << "statements statement" << endl;

	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": statements : statements statement" << endl << endl;
	for(int i = 0; i < $1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
		if($1->at(i)->getSymbolType() == "INT" || $1->at(i)->getSymbolType() == "FLOAT" || $1->at(i)->getSymbolType() == "VOID" || $1->at(i)->getSymbolType() == "RETURN" || $1->at(i)->getSymbolType() == "IF" || $1->at(i)->getSymbolType() == "WHILE")
			logFile << " ";
		if($1->at(i)->getSymbolName() == ";" || $1->at(i)->getSymbolName() == "{" || $1->at(i)->getSymbolName() == "}" || $1->at(i)->getSymbolType() == "ELSE")
			logFile << endl;
	}

	for(int i = 0; i < $2->size(); i++){
		logFile << $2->at(i)->getSymbolName();
		$$->push_back($2->at(i));
		if($2->at(i)->getSymbolType() == "INT" || $2->at(i)->getSymbolType() == "FLOAT" || $2->at(i)->getSymbolType() == "VOID" || $2->at(i)->getSymbolType() == "RETURN"  || $2->at(i)->getSymbolType() == "IF" || $2->at(i)->getSymbolType() == "WHILE")
			logFile << " ";
		if($2->at(i)->getSymbolName() == ";" || $2->at(i)->getSymbolName() == "{" || $2->at(i)->getSymbolName() == "}" || $2->at(i)->getSymbolType() == "ELSE")
			logFile << endl;
	}
	
	logFile << endl << endl;
}
;
	   
statement : 
var_declaration {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": statement : var_declaration" << endl << endl;
	for(int i = 0; i < $1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
		if($1->at(i)->getSymbolType() == "INT" || $1->at(i)->getSymbolType() == "FLOAT" || $1->at(i)->getSymbolType() == "VOID" || $1->at(i)->getSymbolType() == "RETURN"  || $1->at(i)->getSymbolType() == "IF")
			logFile << " ";

	}
	logFile << endl << endl << endl;
}
| func_definition {
	logFile << "Error at line " << line_count << ": Invalid scoping of the function " <<  $1->at(1)->getSymbolName() << endl << endl;
	errFile << "Error at line " << line_count << ": Invalid scoping of the function " <<  $1->at(1)->getSymbolName() << endl << endl;
	
	error_count++;
		
}
| func_declaration {
	logFile << "Error at line " << line_count << ": Invalid scoping of the function declaration " <<  $1->at(1)->getSymbolName() << endl << endl;
	errFile << "Error at line " << line_count << ": Invalid scoping of the function declaration " <<  $1->at(1)->getSymbolName() << endl << endl;
	
	error_count++;
	
}
| expression_statement {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": statement : expression_statement" << endl << endl;
	// cout << "in expression statement" << endl;
	for(int i = 0; i < $1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));

		
		// cout << $1->at(i)->getSymbolName();
		
	}
	// cout << " expression_statement found" << endl;
	logFile << endl << endl << endl;

}
| { table.enterScope(); } compound_statement {
	table.printAllScopeTables();
	table.exitScope();
} {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": statement : compound_statement" << endl << endl;
	for(int i = 0; i < $2->size(); i++){
		logFile << $2->at(i)->getSymbolName();
		$$->push_back($2->at(i));
		if($2->at(i)->getSymbolType() == "INT" || $2->at(i)->getSymbolType() == "FLOAT" || $2->at(i)->getSymbolType() == "VOID" || $2->at(i)->getSymbolType() == "RETURN"  || $2->at(i)->getSymbolType() == "IF")
			logFile << " ";
		if($2->at(i)->getSymbolName() == ";" || $2->at(i)->getSymbolName() == "{" || $2->at(i)->getSymbolName() == "}")
			logFile << endl;
	}
	logFile << endl << endl;

}

| FOR LPAREN expression_statement expression_statement expression RPAREN statement {

	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement" << endl << endl;
	
	logFile << $1->getSymbolName() << $2->getSymbolName();
	$$->push_back($1);
	$$->push_back($2);

	for(int i = 0; i < $3->size(); i++){
		logFile << $3->at(i)->getSymbolName();
		$$->push_back($3->at(i));
	}

	for(int i = 0; i < $4->size(); i++){
		logFile << $4->at(i)->getSymbolName();
		$$->push_back($4->at(i));
	}

	for(int i = 0; i < $5->size(); i++){
		logFile << $5->at(i)->getSymbolName();
		$$->push_back($5->at(i));
	}
	
	logFile << $6->getSymbolName() ;
	$$->push_back($6);

	for(int i = 0; i < $7->size(); i++){
		logFile << $7->at(i)->getSymbolName();
		$$->push_back($7->at(i));
		if($7->at(i)->getSymbolType() == "INT" || $7->at(i)->getSymbolType() == "FLOAT" || $7->at(i)->getSymbolType() == "VOID" || $7->at(i)->getSymbolType() == "RETURN")
			logFile << " ";
		if($7->at(i)->getSymbolName() == ";" || $7->at(i)->getSymbolName() == "{" || $7->at(i)->getSymbolName() == "}")
			logFile << endl;
	}
	logFile << endl << endl;

}
| IF LPAREN expression RPAREN statement	%prec LOWER_THAN_ELSE {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": statement : IF LPAREN expression RPAREN statement" << endl << endl;
	
	logFile << $1->getSymbolName() << " " << $2->getSymbolName();
	$$->push_back($1);
	$$->push_back($2);

	for(int i = 0; i < $3->size(); i++){
		logFile << $3->at(i)->getSymbolName();
		$$->push_back($3->at(i));
	}

	logFile << $4->getSymbolName() ;
	$$->push_back($4);

	for(int i = 0; i < $5->size(); i++){
		logFile << $5->at(i)->getSymbolName();
		$$->push_back($5->at(i));
		if($5->at(i)->getSymbolType() == "INT" || $5->at(i)->getSymbolType() == "FLOAT" || $5->at(i)->getSymbolType() == "VOID" || $5->at(i)->getSymbolType() == "RETURN" || $5->at(i)->getSymbolType() == "IF")
			logFile << " ";
		if($5->at(i)->getSymbolName() == ";" || $5->at(i)->getSymbolName() == "{" || $5->at(i)->getSymbolName() == "}")
			logFile << endl;
	}

	logFile << endl << endl;

}
| IF LPAREN expression RPAREN statement ELSE statement {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": statement : IF LPAREN expression RPAREN statement ELSE statement" << endl << endl;
	
	logFile << $1->getSymbolName() << " " << $2->getSymbolName();
	$$->push_back($1);
	$$->push_back($2);

	for(int i = 0; i < $3->size(); i++){
		logFile << $3->at(i)->getSymbolName();
		$$->push_back($3->at(i));
	}

	logFile << $4->getSymbolName() ;
	$$->push_back($4);

	for(int i = 0; i < $5->size(); i++){
		logFile << $5->at(i)->getSymbolName();
		$$->push_back($5->at(i));
		if($5->at(i)->getSymbolType() == "INT" || $5->at(i)->getSymbolType() == "FLOAT" || $5->at(i)->getSymbolType() == "VOID" || $5->at(i)->getSymbolType() == "RETURN" || $5->at(i)->getSymbolType() == "IF")
			logFile << " ";
		if($5->at(i)->getSymbolName() == ";" || $5->at(i)->getSymbolName() == "{" || $5->at(i)->getSymbolName() == "}")
			logFile << endl;
	}

	logFile << $6->getSymbolName() << endl ;
	$$->push_back($6);

	for(int i = 0; i < $7->size(); i++){
		logFile << $7->at(i)->getSymbolName();
		$$->push_back($7->at(i));
		if($7->at(i)->getSymbolType() == "INT" || $7->at(i)->getSymbolType() == "FLOAT" || $7->at(i)->getSymbolType() == "VOID" || $7->at(i)->getSymbolType() == "RETURN" || $7->at(i)->getSymbolType() == "IF")
			logFile << " ";
		if($7->at(i)->getSymbolName() == ";" || $7->at(i)->getSymbolName() == "{" || $7->at(i)->getSymbolName() == "}" || $7->at(i)->getSymbolType() == "ELSE" )
			logFile << endl;
	}
	logFile << endl << endl;
}
| WHILE LPAREN expression RPAREN statement {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": statement : WHILE LPAREN expression RPAREN statement" << endl << endl;
	
	logFile << $1->getSymbolName() << " " << $2->getSymbolName();
	$$->push_back($1);
	$$->push_back($2);

	for(int i = 0; i < $3->size(); i++){
		logFile << $3->at(i)->getSymbolName();
		$$->push_back($3->at(i));
	}

	logFile << $4->getSymbolName() ;
	$$->push_back($4);

	for(int i = 0; i < $5->size(); i++){
		logFile << $5->at(i)->getSymbolName();
		$$->push_back($5->at(i));
		if($5->at(i)->getSymbolType() == "INT" || $5->at(i)->getSymbolType() == "FLOAT" || $5->at(i)->getSymbolType() == "VOID" || $5->at(i)->getSymbolType() == "RETURN")
			logFile << " ";
		if($5->at(i)->getSymbolName() == ";" || $5->at(i)->getSymbolName() == "{" || $5->at(i)->getSymbolName() == "}")
			logFile << endl;
	}

	logFile << endl << endl;
}
| PRINTLN LPAREN ID RPAREN SEMICOLON {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": statement : PRINTLN LPAREN ID RPAREN SEMICOLON" << endl << endl;

	if (!table.lookupEntire($3->getSymbolName())) {
		logFile << "Error at line " << line_count << ": Undeclared variable " << $3->getSymbolName() << endl << endl;
		errFile << "Error at line " << line_count << ": Undeclared variable " << $3->getSymbolName() << endl << endl;
		error_count++;
	}

	logFile << $1->getSymbolName() << $2->getSymbolName() << $3->getSymbolName() << $4->getSymbolName() << $5->getSymbolName() << endl << endl << endl;
	$$->push_back($1);
	$$->push_back($2);
	$$->push_back($3);
	$$->push_back($4);
	$$->push_back($5);

	
	
}
| RETURN expression SEMICOLON {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": statement : RETURN expression SEMICOLON" << endl << endl;
	
	logFile << $1->getSymbolName() << " ";
	$$->push_back($1);
	

	for(int i = 0; i < $2->size(); i++){
		logFile << $2->at(i)->getSymbolName();
		$$->push_back($2->at(i));
	}

	logFile << $3->getSymbolName() ;
	$$->push_back($3);

	logFile << endl << endl << endl;
}
;
	  
expression_statement : 
SEMICOLON {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": expression_statement : SEMICOLON" << endl << endl;
	if(!isError){
		logFile << $1->getSymbolName() ;
		$$->push_back($1);
		logFile << endl << endl;
	}

}	
| expression SEMICOLON {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": expression_statement : expression SEMICOLON" << endl << endl;

	
	if(!isError){
		for(int i = 0; i < $1->size(); i++){
			logFile << $1->at(i)->getSymbolName();
			$$->push_back($1->at(i));
		}
		logFile << $2->getSymbolName();
		$$->push_back($2);
		logFile << endl << endl;
	}

}

| expression error {
	// cout << "expression error" << endl;
	for (int i = 0; i<$1->size(); i++){
		// cout << $1->at(i)->getSymbolName() << " ";
	}
	// cout << endl;
	$$ = new vector<SymbolInfo*>();
	for(int i = 0; i < $1->size(); i++){
		// logFile << $1->at(i)->getSymbolName();
		// $$->push_back($1->at(i));
	}

	logFile << endl << endl;
	// SymbolInfo * errSymbol = new SymbolInfo("", "ERROR");
	// $$->push_back(errSymbol);
	yyclearin;
}

;
	  
variable : 
ID {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": variable : ID" << endl << endl;

	if(DEBUG) {
		logFile << "test" << endl;
		table.printAllScopeTables();
	}


	SymbolInfo* currSymbol = table.getSymbolInfo($1->getSymbolName());
	if(currSymbol == NULL) {
		logFile << "Error at line " << line_count << ": Undeclared variable " << $1->getSymbolName() << endl << endl;
		errFile << "Error at line " << line_count << ": Undeclared variable " << $1->getSymbolName() << endl << endl;
		error_count++;
	} else {
		if (currSymbol->isFunction()){
			logFile << "Error at line " << line_count << ": Type mismatch, " << $1->getSymbolName() << " is an function" << endl << endl;
			errFile << "Error at line " << line_count << ": Type mismatch, " << $1->getSymbolName() << " is an function" << endl << endl;
			error_count++;

		}

		if (currSymbol->isArray()){
			logFile << "Error at line " << line_count << ": Type mismatch, " << $1->getSymbolName() << " is an array" << endl << endl;
			errFile << "Error at line " << line_count << ": Type mismatch, " << $1->getSymbolName() << " is an array" << endl << endl;
			error_count++;

		}
	}

	logFile << $1->getSymbolName() << endl << endl;
	$$->push_back($1);
	

}
| ID LTHIRD expression RTHIRD {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": variable : ID LTHIRD expression RTHIRD" << endl << endl;

	SymbolInfo* currSymbol = table.getSymbolInfo($1->getSymbolName());
	if(currSymbol == NULL) {
		logFile << "Error at line " << line_count << ": Undeclared variable " << $1->getSymbolName() << endl << endl;
		errFile << "Error at line " << line_count << ": Undeclared variable " << $1->getSymbolName() << endl << endl;
		error_count++;
	} else {
		if (currSymbol->isFunction()){
			logFile << "Error at line " << line_count << ": Type mismatch, " << $1->getSymbolName() << " is an function" << endl << endl;
			errFile << "Error at line " << line_count << ": Type mismatch, " << $1->getSymbolName() << " is an function" << endl << endl;
			error_count++;

		}

		if (!currSymbol->isArray()){
			logFile << "Error at line " << line_count << ": " << $1->getSymbolName() << " not an array" << endl << endl;
			errFile << "Error at line " << line_count << ": " << $1->getSymbolName() << " not an array" << endl << endl;
			error_count++;

		}
	}

	if($3->at(0)->getSymbolType() != "CONST_INT"){
		logFile << "Error at line " << line_count << ": Expression inside third brackets not an integer" << endl << endl;
		errFile << "Error at line " << line_count << ": Expression inside third brackets not an integer" << endl << endl;
		error_count++;
	}
	
	logFile << $1->getSymbolName() << $2->getSymbolName() << $3->at(0)->getSymbolName() << $4->getSymbolName() << endl << endl;
	$$->push_back($1);
	$$->push_back($2);
	$$->push_back($3->at(0));
	$$->push_back($4);


}
;
	 
expression : 
logic_expression {
	$$ = new vector<SymbolInfo*>();
	if (!isError)
		logFile << "Line " << line_count <<  ": expression : logic_expression" << endl << endl;

	for(int i = 0; i < $1->size(); i++){
		if (!isError){
			logFile << $1->at(i)->getSymbolName();
			$$->push_back($1->at(i));
		}
	}
	if (!isError)
		logFile << endl << endl;

}
| variable ASSIGNOP logic_expression {
	// logic_expression can be const_int, const_float, function, variable...
	$$ = new vector<SymbolInfo*>();
	if (!isError)
		logFile << "Line " << line_count <<  ": expression : variable ASSIGNOP logic_expression" << endl << endl;
	
	// functions with void return type cannot be used in a logic_expression
	for(int i = 0; i < $3->size(); i++) {   
		if(table.lookupEntire($3->at(i)->getSymbolName()) && $3->at(i)->getSymbolType() == "ID"){
			SymbolInfo* currSymbol = table.getSymbolInfo($3->at(i)->getSymbolName());
			//  // cout << "line " << line_count << ": func name: " << currSymbol->getSymbolName() << " ret type: " <<  currSymbol->getReturnType() << endl;
			if(currSymbol->isFunction() && currSymbol->getReturnType() == "VOID"){
				
				logFile << "Error at line " << line_count << ": Void function used in expression" << endl << endl;
				errFile << "Error at line " << line_count << ": Void function used in expression" << endl << endl;
				error_count++;
			}
		}
	}

	// todo: currently not expecting chaining
	// float assignment in int variable
	if(table.lookupEntire($1->at(0)->getSymbolName())) {
		// // cout << $1->at(0)->getSymbolName() << endl;
		
		SymbolInfo *currSymbol = table.getSymbolInfo($1->at(0)->getSymbolName());

		if(currSymbol->getVariableType() == "INT"){
			
			for(int i = 0; i < $3->size(); i++){
				// // cout << $3->at(i)->getSymbolName() << ": " << $3->at(i)->getSymbolType() << endl;
				if($3->at(i)->getSymbolType() == "CONST_FLOAT" || $3->at(i)->getVariableType() == "FLOAT"){
					logFile << "Error at line " << line_count << ": Type Mismatch" << endl << endl;
					errFile << "Error at line " << line_count << ": Type Mismatch" << endl << endl;
					error_count++;
					// break;
				}
			}
			// // cout << endl;
		}
	}
	
	

	for(int i = 0; i < $1->size(); i++){
		if (!isError){
			logFile << $1->at(i)->getSymbolName();
			$$->push_back($1->at(i));
		}
	}
	
	if (!isError){
		logFile << $2->getSymbolName();
		$$->push_back($2);
	}

	for(int i = 0; i < $3->size(); i++){
		if (!isError){
			logFile << $3->at(i)->getSymbolName();
			$$->push_back($3->at(i));
		}
	}
	if (!isError)
		logFile << endl << endl;
}
;
			
logic_expression : 
rel_expression {
	isError = false;

	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": logic_expression : rel_expression" << endl << endl;

	for(int i = 0; i < $1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
	}
	logFile << endl << endl;


}
| rel_expression LOGICOP rel_expression {
	isError = false;

	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": logic_expression : rel_expression LOGICOP rel_expression" << endl << endl;

	for(int i = 0; i < $1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
	}

	logFile << $2->getSymbolName();
	$$->push_back($2);

	for(int i = 0; i < $3->size(); i++){
		logFile << $3->at(i)->getSymbolName();
		$$->push_back($3->at(i));
	}
	logFile << endl << endl;
}

| rel_expression ERROR rel_expression {
	isError = true;
	$$ = new vector<SymbolInfo*>();
	for (int i=0; i<$1->size(); i++ ){
		$$->push_back($1->at(i));
	}
	$$->push_back($2);
	for (int i=0; i<$3->size(); i++ ){
		$$->push_back($3->at(i));
	}
}
;
			
rel_expression : 
simple_expression {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": rel_expression : simple_expression" << endl << endl;

	for(int i = 0; i < $1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
	}
	logFile << endl << endl;

}
| simple_expression RELOP simple_expression	{
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": rel_expression : simple_expression RELOP simple_expression" << endl << endl;

	for(int i = 0; i < $1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
	}

	logFile << $2->getSymbolName();
	$$->push_back($2);

	for(int i = 0; i < $3->size(); i++){
		logFile << $3->at(i)->getSymbolName();
		$$->push_back($3->at(i));
	}
	logFile << endl << endl;
}
;
				
simple_expression : 
term {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": simple_expression : term" << endl << endl;
	
	for(int i = 0; i < $1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
	}
	logFile << endl << endl;
}
| simple_expression ADDOP term {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": simple_expression : simple_expression ADDOP term" << endl << endl;

	for(int i = 0; i < $1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
	}
	logFile << $2->getSymbolName();
	$$->push_back($2);
	for(int i = 0; i < $3->size(); i++){
		logFile << $3->at(i)->getSymbolName();
		$$->push_back($3->at(i));
	}
	logFile << endl << endl;
}
;
					
term :	
unary_expression {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": term : unary_expression" << endl << endl;
	
	for(int i = 0; i < $1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
	}
	logFile << endl << endl;
}
|  term MULOP unary_expression {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": term : term MULOP unary_expression" << endl << endl;

	

	// mod must be operated on an integer
	// todo: not expecting chaining of unary_expression
	if($2->getSymbolName() == "%") {
		if($1->size() == 1 && $3->size() == 1){
			if($1->at(0)->getSymbolType() != "CONST_INT" || $3->at(0)->getSymbolType() != "CONST_INT"){
				logFile << "Error at line " << line_count << ": Non-Integer operand on modulus operator" << endl << endl;
				errFile << "Error at line " << line_count << ": Non-Integer operand on modulus operator" << endl << endl;
				error_count++;
			}
			else if($3->at(0)->getSymbolName() == "0"){
				logFile << "Error at line " << line_count << ": Modulus by Zero" << endl << endl;
				errFile << "Error at line " << line_count << ": Modulus by Zero" << endl << endl;
				error_count++;
			}
		}

		// making them integer for modulus operator
		$3->at(0)->setSymbolType("CONST_INT");
	}

	for(int i = 0; i < $1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
	}
	logFile << $2->getSymbolName();
	$$->push_back($2);
	for(int i = 0; i < $3->size(); i++){
		logFile << $3->at(i)->getSymbolName();
		$$->push_back($3->at(i));
	}
	logFile << endl << endl;
}
;

unary_expression : 
ADDOP unary_expression {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": unary_expression : ADDOP unary_expression" << endl << endl;

	logFile << $1->getSymbolName();
	$$->push_back($1);
	for(int i = 0; i < $2->size(); i++){
		logFile << $2->at(i)->getSymbolName();
		$$->push_back($2->at(i));
	}
	logFile << endl << endl;
}
| NOT unary_expression {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": unary_expression : NOT unary_expression" << endl << endl;

	logFile << $1->getSymbolName();
	$$->push_back($1);
	for(int i = 0; i < $2->size(); i++){
		logFile << $2->at(i)->getSymbolName();
		$$->push_back($2->at(i));
	}
	logFile << endl << endl;
}
| factor {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": unary_expression : factor" << endl << endl;

	
	for(int i = 0; i < $1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
	}
	logFile << endl << endl;
}
;
	
factor : 
variable {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": factor : variable" << endl << endl;

	for(int i = 0; i < $1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
	}
	logFile << endl << endl;
}
| ID LPAREN argument_list RPAREN {
	// function call
	// need to match parameter type, no. of parameters
	
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": factor : ID LPAREN argument_list RPAREN" << endl << endl;

	if (DEBUG){
		logFile << "test" << endl;
		table.printAllScopeTables();
	}

	if(!table.lookupEntire($1->getSymbolName())) {
		
		logFile << "Error at line " << line_count << ": Undeclared function " << $1->getSymbolName() << endl << endl;
		errFile << "Error at line " << line_count << ": Undeclared function " << $1->getSymbolName() << endl << endl;
		error_count++;
	} else {
		SymbolInfo* currSymbol = table.getSymbolInfo($1->getSymbolName());
		if (!currSymbol->isFunction()) {
			logFile << "Error at line " << line_count << ": " << $1->getSymbolName() << " not a function" << endl << endl;
			errFile << "Error at line " << line_count << ": " << $1->getSymbolName() << " not a function" << endl << endl;
			error_count++;
		}

		vector <SymbolInfo*>* paramList = currSymbol->getParamList();
		vector <string> definedFuncParamsType;
		// // cout << "defined parameter list" << endl;
		for (int i = 0; i<paramList->size(); i++){
			if (paramList->at(i)->getSymbolType() != "ID" && paramList->at(i)->getSymbolType() != "COMMA") {
				// // cout << paramList->at(i)->getSymbolType() << " " ;
				definedFuncParamsType.push_back(paramList->at(i)->getSymbolType());
			}
		}

		// // cout << endl<< "arg list" << endl;
		vector <string> argsType;
		for (int i = 0; i<$3->size(); i++){
			// ekhanei manually alada kore type bujhe bujhe (before comma) parse
			
			bool isFloat = false;
			while($3->at(i)->getSymbolName() != ","){
				// // cout << $3->at(i)->getSymbolName() << " ";
				if ($3->at(i)->getSymbolType() == "ID") {
					// variable
					if ($3->at(i)->getVariableType() == "FLOAT")
						isFloat = true;
					
				}
				else {
					// constant
					if ($3->at(i)->getSymbolType() == "CONST_FLOAT")
						isFloat = true;
				}
				i++;
				if (i >= $3->size())
					break;
			}

			// assuming only array, float and int data types
			// todo: handle array ( if the function parameter is like this int foo(int a[], int b) )
				// I don't think there is rule for functions to have array parameters
			if (isFloat)
				argsType.push_back("FLOAT");
			
			else 
				argsType.push_back("INT");

		}

		// // cout <<  endl << "argsType list" << endl;
		// for (int i = 0; i<argsType.size(); i++){
		// 	// cout << argsType[i] << " ";
		// }
		// // cout << endl << endl;

		//  // cout << "args size: " << argsType.size() << "param size: " << definedFuncParamsType.size() << endl;

		if (argsType.size() != definedFuncParamsType.size()) {
			logFile << "Error at line " << line_count << ": Total number of arguments mismatch in function " << $1->getSymbolName() << endl << endl;
			errFile << "Error at line " << line_count << ": Total number of arguments mismatch in function " << $1->getSymbolName() << endl << endl;
			error_count++;
		} else {
			// not allowing passing int type in place of float type
			
			for (int i = 0; i<argsType.size(); i++){
				if (argsType[i] != definedFuncParamsType[i]) {
					logFile << "Error at line " << line_count << ": " << i+1 << "th argument mismatch in function " << $1->getSymbolName() << endl << endl;
					errFile << "Error at line " << line_count << ": " << i+1 << "th argument mismatch in function " << $1->getSymbolName() << endl << endl;
					error_count++;
				}
			}
		}

	}

	logFile << $1->getSymbolName();
	$$->push_back($1);
	logFile << $2->getSymbolName();
	$$->push_back($2);
	for(int i = 0; i < $3->size(); i++){
		logFile << $3->at(i)->getSymbolName();
		$$->push_back($3->at(i));
	}

	logFile << $4->getSymbolName();
	$$->push_back($4);
	logFile << endl << endl;

}
| LPAREN expression RPAREN {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": factor : LPAREN expression RPAREN" << endl << endl;

	logFile << $1->getSymbolName();
	$$->push_back($1);
	for(int i = 0; i < $2->size(); i++){
		logFile << $2->at(i)->getSymbolName();
		$$->push_back($2->at(i));
	}
	logFile << $3->getSymbolName();
	$$->push_back($3);
	logFile << endl << endl;

}
| CONST_INT {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": factor : CONST_INT" << endl << endl;

	logFile << $1->getSymbolName();
	$$->push_back($1);
	logFile << endl << endl;
}
| CONST_FLOAT {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": factor : CONST_FLOAT" << endl << endl;

	logFile << $1->getSymbolName();
	// // cout << $1->getSymbolName() << ": " << $1->getSymbolType() << endl;;
	$$->push_back($1);
	logFile << endl << endl;
}
| variable INCOP {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": factor : variable INCOP" << endl << endl;

	
	for(int i = 0; i < $1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
	}
	logFile << $2->getSymbolName();
	$$->push_back($2);
	logFile << endl << endl;
}
| variable DECOP {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": factor : variable DECOP" << endl << endl;

	
	for(int i = 0; i < $1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
	}
	logFile << $2->getSymbolName();
	$$->push_back($2);
	logFile << endl << endl;
}
;
		
argument_list : 
arguments {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": argument_list : arguments" << endl << endl;

	for(int i = 0; i < $1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
	}
	logFile << endl << endl;
}
;
	
arguments : 
arguments COMMA logic_expression {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": arguments : arguments COMMA logic_expression" << endl << endl;

	for(int i = 0; i < $1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
	}
	logFile << $2->getSymbolName();
	$$->push_back($2);
	
	for(int i = 0; i < $3->size(); i++){
		logFile << $3->at(i)->getSymbolName();
		$$->push_back($3->at(i));
	}
	logFile << endl << endl;
}
| logic_expression {
	$$ = new vector<SymbolInfo*>();
	logFile << "Line " << line_count <<  ": arguments : logic_expression" << endl << endl;

	for(int i = 0; i < $1->size(); i++){
		logFile << $1->at(i)->getSymbolName();
		$$->push_back($1->at(i));
	}
	logFile << endl << endl;
}
;
 

%%
int main(int argc,char *argv[]) {
	if(argc!=4) {
		// cout << "Please provide all the file names and try again" << endl;
		return 0;
	}

	if((inputFile=fopen(argv[1],"r"))==NULL) {
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	logFile.open(argv[2]);

	errFile.open(argv[3]);

	yyin=inputFile;
	tempParamList = new vector <SymbolInfo*>;
	yyparse();

	table.printAllScopeTables();
	logFile << "Total lines: " << line_count - 1 << endl;
	logFile << "Total errors: " << error_count << endl << endl;
    

	logFile.close();
	errFile.close();
	fclose(yyin);
	
	return 0;
}

