%option noyywrap

%x STR_START
%x SLASH_COMMENT_START
%x STAR_COMMENT_START

%{
#include<bits/stdc++.h>
#include "1805082_symbol-table.h"

SymbolTable symbolTable(10);

int err_count=0;
int line_count=1;
int keywordCnt = 0;
int errLineCnt = 0;

string literalStr = "";
string formattedStr = "";

string slashCmmtStr = "";
string starCmmtStr = "";


ofstream tokenFile ("1805082_token.txt");

char* upperString(char* tokenName){
	for (int i = 0 ; tokenName[i] != '\0'; i++) {
		tokenName[i]=toupper(tokenName[i]);
        
    }
	return tokenName;
}

void foundKeword() {
	string originalKeyword = yytext;
	tokenFile << "<" << upperString(yytext) << "> ";
	logFile << "\nLine no " << line_count << ": TOKEN <" << upperString(yytext) << "> Lexeme " << originalKeyword << " found\n";
}

void foundOp(string opKeyword) {
	tokenFile << "<" << opKeyword <<", " << yytext << "> ";
	logFile << "\nLine no " << line_count << ": TOKEN <" << opKeyword << "> Lexeme " << yytext << " found\n";

	if (opKeyword == "LCURL"){
		symbolTable.enterScope();
	}
	if (opKeyword == "RCURL"){
		symbolTable.exitScope();
	}

	
}

void insertTokenConstInt(){
	tokenFile << "<CONST_INT, " << yytext << "> ";
	logFile << "\nLine no " << line_count << ": TOKEN <CONST_INT> Lexeme " << yytext << " found\n";
	if(symbolTable.insert(new SymbolInfo(yytext, "CONST_INT"))){
		symbolTable.printAllScopeTables();
	}
	
}

void insertTokenConstFloat(){

	tokenFile << "<CONST_FLOAT, " << yytext << "> ";
	logFile << "\nLine no " << line_count << ": TOKEN <CONST_FLOAT> Lexeme " << yytext << " found\n";
	if(symbolTable.insert(new SymbolInfo(yytext, "CONST_FLOAT"))){
		symbolTable.printAllScopeTables();
	}
	
}

void errPrint(string errMsg, string errLexeme){
	
	logFile << "\nError at Line no " << line_count << " : <" << errMsg << "> (" << errLexeme << ")\n";
	err_count++;
}

void insertTokenConstChar(){
	string yytextStr(yytext);
	string oriChar = yytextStr.substr(1,1);
		
	tokenFile << "<CHAR_CONST, " << oriChar << "> ";
	logFile << "\nLine no " << line_count << ": TOKEN <CONST_CHAR> Lexeme " << yytext << " found --> <CHAR_CONST, " << oriChar << "> \n";

	if(symbolTable.insert(new SymbolInfo(yytext, "CONST_CHAR"))){
		symbolTable.printAllScopeTables();
	}
		

}

void insertTokenConstCharSp(){
	string oriChar = "";
	if (strcmp(yytext, "'\\n'") == 0){
		oriChar.push_back('\n');
	}
	if (strcmp(yytext, "'\\t'") == 0){
		oriChar.push_back('\t');
	}
	if (strcmp(yytext, "'\\\\'") == 0){
		oriChar.push_back('\\');
	}
	if (strcmp(yytext, "'\\''") == 0){
		oriChar.push_back('\'');
	}
	if (strcmp(yytext, "'\\a'") == 0){
		oriChar.push_back('\a');
	}
	if (strcmp(yytext, "'\\f'") == 0){
		oriChar.push_back('\f');
	}
	if (strcmp(yytext, "'\\r'") == 0){
		oriChar.push_back('\r');
	}
	if (strcmp(yytext, "'\\b'") == 0){
		oriChar.push_back('\b');
	}
	if (strcmp(yytext, "'\\v'") == 0){
		oriChar.push_back('\v');
	}
	if (strcmp(yytext, "'\\r'") == 0){
		oriChar.push_back('\0');
	}

	
		
	tokenFile << "<CHAR_CONST, " << oriChar << "> ";
	logFile << "\nLine no " << line_count << ": TOKEN <CONST_CHAR> Lexeme " << yytext << " found --> <CHAR_CONST, " << oriChar <<">\n";

	if(symbolTable.insert(new SymbolInfo(yytext, "CONST_CHAR"))){
		symbolTable.printAllScopeTables();
	}
	
}

void insertTokenIdentifier(){
	cout << "ID:" <<  yytext << " found" << endl;
		
	tokenFile << "<ID, " << yytext << "> ";
	logFile << "\nLine no " << line_count << ": TOKEN <ID> Lexeme " << yytext << " found\n";

	if(symbolTable.insert(new SymbolInfo(yytext, "ID"))){
		symbolTable.printAllScopeTables();
	}
		
	
}

void insertTokenString(){
	string yytextStr(yytext);
	// cout << yytext << endl;
	tokenFile << "<STRING, " << yytextStr << "> ";
	logFile << "\nLine no " << line_count << ": TOKEN <STRING> Lexeme " << yytextStr << " found\n";
}

%}

digit [0-9]

whiteSp [ \t\f\r\v]+

alphabet [a-zA-Z_]
alphaneumeric {alphabet}|{digit}

newLine [\r\n]
any_char_except_newLine [^\r\n]

any_char_except_backslash ([ -~]{-}['\\])

const_float {digit}*(\.)?{digit}+(E[+-]?{digit}+)?

slashComment \/\/

%%

[\n] {line_count++;}

{whiteSp}  {}

{slashComment} {
	slashCmmtStr.append(yytext);
	BEGIN SLASH_COMMENT_START;

}

<SLASH_COMMENT_START>((\\)){newLine} {
	line_count ++;
	slashCmmtStr.append(yytext);

}

<SLASH_COMMENT_START>{newLine} {
	line_count ++;
	logFile << "\nLine no " << line_count << ":  TOKEN <COMMENT> Lexeme " << slashCmmtStr <<" found\n";
	BEGIN INITIAL;

}

<SLASH_COMMENT_START>. {
	slashCmmtStr.append(yytext);
}



\/\* {
	BEGIN STAR_COMMENT_START;
	starCmmtStr.append(yytext);
	errLineCnt = line_count;
}

<STAR_COMMENT_START>{newLine} {
	line_count++;
	starCmmtStr.append(yytext);
}

<STAR_COMMENT_START>\*\/ {
	starCmmtStr.append(yytext);
	logFile << "\nLine no " << line_count << ":  TOKEN <COMMENT> Lexeme " << starCmmtStr <<" found\n";
	
	BEGIN INITIAL;
}

<STAR_COMMENT_START><<EOF>> {
	// starCmmtStr.append(yytext);
	// logFile << "\nLine no " << line_count << ":  TOKEN <COMMENT> Lexeme " << starCmmtStr <<" found\n";
	// errPrint("Unfinished multi line comment", starCmmtStr);
	logFile << "\nError at Line no " << errLineCnt << " : <" << "Unfinished multi line comment" << "> (" << starCmmtStr << ")\n";
	err_count++;
	BEGIN INITIAL;
	symbolTable.printAllScopeTables();
	printf("Total lines: %d \nTotal errors: %d\n",line_count,err_count); 
	logFile << "Total lines: " << line_count << endl << "Total errors: " << err_count << endl;
	
	return 0;

}

<STAR_COMMENT_START>. {
	starCmmtStr.append(yytext);
}



{digit}+ {insertTokenConstInt();}

{const_float} {insertTokenConstFloat();}

({digit}+\.{digit}+\.{digit}+)+ 						{errPrint("Too many decimal points", yytext);}
({digit}+|{const_float})[E]*[+-]*{const_float}*[+-]*	{errPrint("Ill formatted number", yytext);}

'\\''	|
'\\t'	|
'\\a'	|
'\\f'	|
'\\r'	|
'\\b'	|
'\\v'	|
'\\0'	|
'\\\\'	|
'\\n'	{insertTokenConstCharSp();}


''										{errPrint("Empty character", yytext);}	
'{any_char_except_backslash}{2,}'		{errPrint("Multi character constant", yytext);}
'{any_char_except_backslash}*|('(\\[\\nfratbv0\"\'])*)	{errPrint("Unfinished character", yytext);}

'{any_char_except_backslash}' 		{insertTokenConstChar();}

\"	{
	BEGIN STR_START;
	literalStr.append(yytext);
	formattedStr.append(yytext);
	errLineCnt = line_count;	// stored the current line no.

}

<STR_START>{newLine} {
	// errPrint("Unfinished String",literalStr);
	logFile << "\nError at Line no " << errLineCnt << " : <" << "Unfinished String" << "> (" << literalStr << ")\n";
	err_count++;
	line_count++;
	formattedStr = "";
	literalStr = "";
	BEGIN INITIAL;
	
}

<STR_START><<EOF>> {
	// errPrint("Unfinished String", literalStr);
	logFile << "\nError at Line no " << errLineCnt << " : <" << "Unfinished String" << "> (" << literalStr << ")\n";
	err_count++;
	line_count++;
	formattedStr = "";
	literalStr = "";
	BEGIN INITIAL;
	symbolTable.printAllScopeTables();
	printf("Total lines: %d \nTotal errors: %d\n",line_count,err_count); 
	logFile << "Total lines: " << line_count << endl << "Total errors: " << err_count << endl;
	return 0;

}

<STR_START>((\\)){newLine} {
	line_count ++;
	literalStr.append(yytext);

}

<STR_START>(\\[\\nfratbv0\"\']) {
		literalStr.append(yytext);

		switch(yytext[1]){
			case 'n' : formattedStr.push_back('\n'); break;
			case 't' : formattedStr.push_back('\t'); break;
			case 'a' : formattedStr.push_back('\a'); break;
			case 'b' : formattedStr.push_back('\b'); break;
			case 'r' : formattedStr.push_back('\r'); break;
			case 'f' : formattedStr.push_back('\f'); break;
			case 'v' : formattedStr.push_back('\v'); break;
			case '0' : formattedStr.push_back('\0'); break;
			case '\\' : formattedStr.push_back('\\'); break;
			case '\'' : formattedStr.push_back('\''); break;
			case '\"' : formattedStr.push_back('\"'); break;
			

		}
		
}

<STR_START>\" {
	literalStr.append(yytext);
	formattedStr.append(yytext);
	tokenFile << "<STRING, "<< formattedStr << "> ";
	logFile << "\nLine no " << line_count << ":  TOKEN <STRING> Lexeme " << literalStr <<" found --> " <<   "<STRING, "<< formattedStr << "> \n";

	formattedStr = "";
	literalStr = "";
	BEGIN INITIAL;	

}

<STR_START>. {
	literalStr.append(yytext);
	formattedStr.append(yytext);
}


if		|
for		|
do 		|
int		|
float 	|
void 	|
switch 	|
default	|
else 	|
while 	|
break 	|
char 	|
double 	|
return	|
case 	|
continue 	{foundKeword();}

{alphabet}{alphaneumeric}* 	{insertTokenIdentifier();}

{digit}+({alphaneumeric})*	{errPrint("Invalid prefix on ID or invalid suffix on Number ", yytext);}

("+"|"-")						{foundOp("ADDOP");}
("*"|"/"|"%")					{foundOp("MULOP");}
("++"|"--")						{foundOp("INCOP");}
("<="|">="|"=="|"!="|"<"|">") 	{foundOp("RELOP");}
("=")							{foundOp("ASSIGNOP");}
("&&"|"||")						{foundOp("LOGICOP");}
"!"								{foundOp("NOT");}
"("								{foundOp("LPAREN");}
")"								{foundOp("RPAREN");}
"{"								{foundOp("LCURL");}
"}"								{foundOp("RCURL");}
"["								{foundOp("LTHIRD");}
"]"								{foundOp("RTHIRD");}
","								{foundOp("COMMA");}
";"								{foundOp("SEMICOLON");}

. {errPrint("Unrecognized character", yytext);}

<<EOF>> {
	symbolTable.printAllScopeTables();
	printf("Total lines: %d \nTotal errors: %d\n",line_count,err_count); 
	logFile << "Total lines: " << line_count << endl << "Total errors: " << err_count << endl;
	return 0;
}

%%

int main(int argc,char *argv[]){

	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	yyin= fin;

	yylex();	
	fclose(yyin);
	logFile.close();
	tokenFile.close();

	yy_delete_buffer( YY_CURRENT_BUFFER );
	return 0;
}
