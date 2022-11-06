%option noyywrap

%x STR_START
%x SLASH_COMMENT_START
%x STAR_COMMENT_START

%{
#include<bits/stdc++.h>
#include "1805082_SymbolTable.h"
using namespace std;

#include "y.tab.h"

extern YYSTYPE yylval;
extern void yyerror(char *);
extern SymbolTable table;
extern ofstream logFile;
extern ofstream errFile;

extern int error_count;
extern int line_count;

int errLineCnt = 0;

string literalStr = "";
string formattedStr = "";

string slashCmmtStr = "";
string starCmmtStr = "";


// ofstream tokenFile ("1805082_token.txt");

char* upperString(char* tokenName){
	for (int i = 0 ; tokenName[i] != '\0'; i++) {
		tokenName[i]=toupper(tokenName[i]);
    }
	return tokenName;
}

int strSize(char* tokenName) {
	int i = 0;
	while(tokenName[i] != '\0') {
		i++;
	}
	// // cout << "len=" << i << endl;
	return i;
}

void foundKeword() {
	string originalKeyword = yytext;
	// tokenFile << "<" << upperString(yytext) << "> ";
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"CONST_INT");
	yylval.sym = s;
	
	// logFile << "\nLine no " << line_count << ": TOKEN <" << upperString(yytext) << "> Lexeme " << originalKeyword << " found\n";
}

void foundOp(string opKeyword) {
	// tokenFile << "<" << opKeyword <<", " << yytext << "> ";
	// logFile << "\nLine no " << line_count << ": TOKEN <" << opKeyword << "> Lexeme " << yytext << " found\n";

	if (opKeyword == "LCURL"){
		// symbolTable.enterScope();
	}
	if (opKeyword == "RCURL"){
		// symbolTable.exitScope();
	}

	
}

void insertTokenConstInt(){
	// tokenFile << "<CONST_INT, " << yytext << "> ";
	// logFile << "\nLine no " << line_count << ": TOKEN <CONST_INT> Lexeme " << yytext << " found\n";
	// if(symbolTable.insert(new SymbolInfo(yytext, "CONST_INT"))){
	// 	symbolTable.printAllScopeTables();
	// }
	
}

void insertTokenConstFloat(){

	// tokenFile << "<CONST_FLOAT, " << yytext << "> ";
	// logFile << "\nLine no " << line_count << ": TOKEN <CONST_FLOAT> Lexeme " << yytext << " found\n";
	// if(symbolTable.insert(new SymbolInfo(yytext, "CONST_FLOAT"))){
	// 	symbolTable.printAllScopeTables();
	// }
	
}

void errPrint(string errMsg, string errLexeme){
	
	// logFile << "\nError at Line no " << line_count << " : <" << errMsg << "> (" << errLexeme << ")\n";
	error_count++;
}

void insertTokenConstChar(){
	string yytextStr(yytext);
	string oriChar = yytextStr.substr(1,1);
		
	// tokenFile << "<CHAR_CONST, " << oriChar << "> ";
	// logFile << "\nLine no " << line_count << ": TOKEN <CONST_CHAR> Lexeme " << yytext << " found --> <CHAR_CONST, " << oriChar << "> \n";

	// if(symbolTable.insert(new SymbolInfo(yytext, "CONST_CHAR"))){
	// 	symbolTable.printAllScopeTables();
	// }
		

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

	
		
	// tokenFile << "<CHAR_CONST, " << oriChar << "> ";
	// logFile << "\nLine no " << line_count << ": TOKEN <CONST_CHAR> Lexeme " << yytext << " found --> <CHAR_CONST, " << oriChar <<">\n";

	// if(symbolTable.insert(new SymbolInfo(yytext, "CONST_CHAR"))){
	// 	symbolTable.printAllScopeTables();
	// }
	
}

void insertTokenIdentifier(){
	// // cout << "ID:" <<  yytext << " found" << endl;
		
	// tokenFile << "<ID, " << yytext << "> ";
	return ID;
	// logFile << "\nLine no " << line_count << ": TOKEN <ID> Lexeme " << yytext << " found\n";

	// if(symbolTable.insert(new SymbolInfo(yytext, "ID"))){
	// 	symbolTable.printAllScopeTables();
	// }
		
	
}

void insertTokenString(){
	string yytextStr(yytext);
	// // cout << yytext << endl;
	// tokenFile << "<STRING, " << yytextStr << "> ";
	// logFile << "\nLine no " << line_count << ": TOKEN <STRING> Lexeme " << yytextStr << " found\n";
}

%}

digit [0-9]
digits {digit}+

whiteSp [ \t\f\r\v]+

obsoleteOp [\*+/-]
obsoleteSp (" "|\t)

alphabet [a-zA-Z_]
alphaneumeric {alphabet}|{digit}

newLine [\r\n]


any_char_except_backslash ([ -~]{-}['\\])

const_float {digit}*(\.)?{digit}+(E[+-]?{digit}+)?

slashComment \/\/

%%

[\n] {line_count++;}

{newLine} {
	return NEWLINE;
}

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
	// logFile << "\nLine no " << line_count << ":  TOKEN <COMMENT> Lexeme " << slashCmmtStr <<" found\n";
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
	// logFile << "\nLine no " << line_count << ":  TOKEN <COMMENT> Lexeme " << starCmmtStr <<" found\n";
	
	BEGIN INITIAL;
}

<STAR_COMMENT_START><<EOF>> {
	// starCmmtStr.append(yytext);
	// logFile << "\nLine no " << line_count << ":  TOKEN <COMMENT> Lexeme " << starCmmtStr <<" found\n";
	// errPrint("Unfinished multi line comment", starCmmtStr);
	// logFile << "\nError at Line no " << errLineCnt << " : <" << "Unfinished multi line comment" << "> (" << starCmmtStr << ")\n";
	BEGIN INITIAL;
	// symbolTable.printAllScopeTables();
	// printf("Total lines: %d \nTotal errors: %d\n",line_count,error_count); 
	// logFile << "Total lines: " << line_count << endl << "Total errors: " << error_count << endl;
	logFile << "Error at line no  " << errLineCnt << ": " << "Unfinished multi line comment " <<  starCmmtStr << endl;
	errFile << "Error at line no  " << errLineCnt << ": " << "Unfinished multi line comment " <<  starCmmtStr << endl;

	error_count++;	
	return 0;

}

<STAR_COMMENT_START>. {
	starCmmtStr.append(yytext);
}



{digit}+ {
	// insertTokenConstInt();
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"CONST_INT");
	yylval.sym = s;
	return CONST_INT;
}

{const_float} {	
	// insertTokenConstFloat();
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"CONST_FLOAT");
	yylval.sym = s;
	return CONST_FLOAT;
		
}

({digit}+\.{digit}+\.{digit}+)+ {
	logFile << "Error at line no  " << line_count << ": " << "Too Many Decimal Points " <<  yytext << endl << endl;
	errFile << "Error at line no  " << line_count << ": " << "Too Many Decimal Points " <<  yytext << endl;
	
	error_count++;	
}

({digit}*([Ee][+-]?{digits})+(\.{digits})+)|({digits}\.)+	{
	logFile << "Error at line no "  << line_count << ": " << "Ill Formed Number " <<  yytext << endl << endl;
	errFile << "Error at line no "  << line_count << ": " << "Ill Formed Number " <<  yytext << endl;
	
	error_count++;
}

'\\''	|
'\\t'	|
'\\a'	|
'\\f'	|
'\\r'	|
'\\b'	|
'\\v'	|
'\\0'	|
'\\\\'	|
'\\n'	{
			// insertTokenConstCharSp();
			// todo: not expecting const_char
		}


''	{
	// not expecting const_char
	errPrint("Empty character", yytext);
	}	
'{any_char_except_backslash}{2,}'		{
											// not expecting const_char
											errPrint("Multi character constant", yytext);
											}
'{any_char_except_backslash}*|('(\\[\\nfratbv0\"\'])*)	{
	// not expecting const_char
	errPrint("Unfinished character", yytext);
	}

'{any_char_except_backslash}' 		{
	// not expecting const_char
	// insertTokenConstChar();
	}

\"	{
	BEGIN STR_START;
	literalStr.append(yytext);
	formattedStr.append(yytext);
	errLineCnt = line_count;	// stored the current line no.

}

<STR_START>{newLine} {
	// errPrint("Unfinished String",literalStr);
	// logFile << "\nError at Line no " << errLineCnt << " : <" << "Unfinished String" << "> (" << literalStr << ")\n";
	error_count++;
	line_count++;
	formattedStr = "";
	literalStr = "";
	BEGIN INITIAL;
	
}

<STR_START><<EOF>> {
	// errPrint("Unfinished String", literalStr);
	// logFile << "\nError at Line no " << errLineCnt << " : <" << "Unfinished String" << "> (" << literalStr << ")\n";
	error_count++;
	line_count++;
	formattedStr = "";
	literalStr = "";
	BEGIN INITIAL;
	// symbolTable.printAllScopeTables();
	printf("Total lines: %d \nTotal errors: %d\n",line_count,error_count); 
	// logFile << "Total lines: " << line_count << endl << "Total errors: " << error_count << endl;
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
	// tokenFile << "<STRING, "<< formattedStr << "> ";
	// logFile << "\nLine no " << line_count << ":  TOKEN <STRING> Lexeme " << literalStr <<" found --> " <<   "<STRING, "<< formattedStr << "> \n";

	formattedStr = "";
	literalStr = "";
	BEGIN INITIAL;	

}

<STR_START>. {
	literalStr.append(yytext);
	formattedStr.append(yytext);
}


if		{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"IF");
	yylval.sym = s;
	return IF;}
for		{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"FOR");
	yylval.sym = s;
	return FOR;}
int		{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"INT");
	yylval.sym = s;
	return INT;
}
float 	{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"FLOAT");
	yylval.sym = s;
	return FLOAT;}
void 	{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"VOID");
	yylval.sym = s;
	return VOID;}
else 	{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"ELSE");
	yylval.sym = s;
	return ELSE;}
while 	{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"WHILE");
	yylval.sym = s;
	return WHILE;}
char 	{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"CHAR");
	yylval.sym = s;
	return CHAR;}
double 	{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"DOUBLE");
	yylval.sym = s;
	return DOUBLE;}
return	{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"RETURN");
	yylval.sym = s;
	return RETURN;}
println	{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"PRINTLN");
	yylval.sym = s;
	return PRINTLN;}

{alphabet}{alphaneumeric}* 	{
	// insertTokenIdentifier();
	SymbolInfo *s = new SymbolInfo(yytext, (char *)"ID");
	yylval.sym = s;

	if (strSize(yytext) > 31){
		logFile << "Error at line no  " << line_count << ": " << "Length of ID exeeded 31 characters " <<  yytext << endl << endl;
		errFile << "Error at line no  " << line_count << ": " << "Length of ID exeeded 31 characters " <<  yytext << endl << endl;
		error_count++;
	}

	return ID;
}

{digit}+({alphaneumeric})*	{
	logFile << "Error at line no  " << line_count << ": " << "Invalid prefix on ID or invalid suffix on Number " <<  yytext << endl << endl;
	errFile << "Error at line no  " << line_count << ": " << "Invalid prefix on ID or invalid suffix on Number " <<  yytext << endl;
	
	error_count++;
}



("+"|"-")						{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"ADDOP");
	yylval.sym = s;
	return ADDOP;}
("*"|"/"|"%")					{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"MULOP");
	yylval.sym = s;
	return MULOP;}
"++"							{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"INCOP");
	yylval.sym = s;
	return INCOP;}
"--"							{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"DECOP");
	yylval.sym = s;
	return DECOP;}
("<="|">="|"=="|"!="|"<"|">") 	{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"RELOP");
	yylval.sym = s;
	return RELOP;}
("=")							{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"ASSIGNOP");
	yylval.sym = s;
	return ASSIGNOP;}
("&&"|"||")						{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"LOGICOP");
	yylval.sym = s;
	return LOGICOP;}
"!"								{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"NOT");
	yylval.sym = s;
	return NOT;}
"("								{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"LPAREN");
	yylval.sym = s;
	return LPAREN;}
")"								{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"RPAREN");
	yylval.sym = s;
	return RPAREN;}
"{"								{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"LCURL");
	yylval.sym = s;
	return LCURL;}
"}"								{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"RCURL");
	yylval.sym = s;
	return RCURL;}
"["								{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"LTHIRD");
	yylval.sym = s;
	return LTHIRD;}
"]"								{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"RTHIRD");
	yylval.sym = s;
	return RTHIRD;}
","								{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"COMMA");
	yylval.sym = s;
	return COMMA;}
";"								{
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"SEMICOLON");
	yylval.sym = s;
	return SEMICOLON;}



({obsoleteOp}{obsoleteSp}*=)({obsoleteOp}*{obsoleteSp}*[=]*)* {
	logFile << "Error at line " << line_count << ": " << "syntax error" << endl << endl;
	errFile << "Error at line " << line_count << ": " << "syntax error" << endl << endl;
	error_count++;
	
	// cout << "here " <<  line_count << yytext << endl;
	SymbolInfo *s= new  SymbolInfo("", (char *)"ERROR");
	yylval.sym = s;
	return ERROR;
}



. {
	logFile << "Error at line " << line_count << ": " << "Unrecognized character " <<  yytext << endl;
	errFile << "Error at line " << line_count << ": " << "Unrecognized character " <<  yytext << endl;
	error_count++;
}

<<EOF>> {
	// symbolTable.printAllScopeTables();
	// printf("Total lines: %d \nTotal errors: %d\n",line_count,error_count); 
	// logFile << "Total lines: " << line_count << endl << "Total errors: " << error_count << endl;
	return 0;
}

%%

// int main(int argc,char *argv[]){

// 	if(argc!=2){
// 		printf("Please provide input file name and try again\n");
// 		return 0;
// 	}
	
// 	FILE *fin=fopen(argv[1],"r");
// 	if(fin==NULL){
// 		printf("Cannot open specified file\n");
// 		return 0;
// 	}
	
// 	yyin= fin;

// 	yylex();	
// 	fclose(yyin);
// 	// logFile.close();
// 	// tokenFile.close();

// 	yy_delete_buffer( YY_CURRENT_BUFFER );
// 	return 0;
// }
