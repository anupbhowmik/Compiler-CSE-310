//
// Created by Anup on 5/26/2022.
//

#include "1805082_symbol-table.h"

int main() {
    int tableSize;
    ifstream input_file ("1805082_input.txt");
    if (!input_file.is_open()) {
        cerr << "Could not open input file";
        return EXIT_FAILURE;
    }
    input_file >> tableSize;
    SymbolTable symbolTable1(tableSize);

    char cmd;
    while(input_file >> cmd) {
        switch (cmd) {
            case 'I':{
                string symbolName, symbolType;
                input_file >> symbolName >> symbolType;
                cout << "I " << symbolName << " " <<symbolType << endl;
                output_file << "I " << symbolName << " " <<symbolType << endl;

                symbolTable1.insert(new SymbolInfo(symbolName, symbolType));
                cout << endl;
                output_file << endl;
                break;
            }
            case 'L':{
                string symbolName;
                input_file >> symbolName;
                cout << "L " << symbolName << endl;
                output_file << "L " << symbolName << endl;
                symbolTable1.lookup(symbolName);
                cout << endl;
                output_file << endl;
                break;
            }
            case 'D':{
                string symbolName;
                input_file >> symbolName;
                cout << "D " << symbolName << endl;
                output_file << "D " << symbolName << endl;
                symbolTable1.remove(symbolName);
                cout << endl;
                output_file << endl;
                break;
            }
            case 'P':{
                string printCmd;
                input_file >> printCmd;
                cout << "P " << printCmd << endl;
                output_file << "P " << printCmd << endl;
                if (printCmd == "A"){
                    symbolTable1.printAllScopeTables();
                } else{
                    symbolTable1.printCurrScopeTable();
                }

                cout << endl;
                output_file << endl;
                break;
            }
            case 'S':{
                cout << "S" << endl ;
                output_file << "S" << endl ;
                symbolTable1.enterScope();
                cout << endl;
                output_file << endl;

                break;
            }
            case 'E':{
                cout << "E" << endl ;
                output_file << "E" << endl ;
                symbolTable1.exitScope();
                cout << endl;
                output_file << endl;

                break;
            }
        }
    }
    input_file.close();
}

