//
// Created by Anup on 5/26/2022.
//
#ifndef SYMBOLTABLE_SYMBOLTABLE_H
#define SYMBOLTABLE_SYMBOLTABLE_H
#include<bits/stdc++.h>
using namespace std;
ofstream output_file ("1805082_output-file.txt");
const bool DEBUG = false;

class SymbolInfo {
private:
    string symbolName;
    string symbolType;
    SymbolInfo *nextSymbol;    //for chaining
    int hashIdx, hashPos;
public:
    SymbolInfo(string name, string type) {
        this->symbolName = name;
        this->symbolType = type;
        nextSymbol = NULL;
    }

    SymbolInfo() {
        nextSymbol = NULL;
    }

    string getSymbolName() {
        return symbolName;
    }

    string getSymbolType() {
        return symbolType;
    }

    SymbolInfo *getNextSymbol() {
        return nextSymbol;
    }

    void setNextSymbol(SymbolInfo *newSymbol) {
        nextSymbol = newSymbol;
    }

    void setHashIdx(int hashIdx) {
        this->hashIdx = hashIdx;
    }


    void setHashPos(int hashPos) {
        this->hashPos = hashPos;
    }

    string getPosition() {
        return to_string(hashIdx) + ", " + to_string(hashPos);
    }

    ~SymbolInfo() {
    //    cout << "destructing " << symbolName << endl;
        // delete nextSymbol;
    }

};

class ScopeTable {
    // the hash table
private:
    string scopeID;
    int childCount;

    long long total_buckets;
    SymbolInfo **chainHashTable;
    ScopeTable *parentScope;

public:
    ScopeTable(int n, ScopeTable *parentScope) {
        childCount = 0;

        this->parentScope = parentScope;

        if (parentScope == NULL) {
//            cout << "creating  root scope with scope id " << scopeID << endl;
            scopeID = "1";

        } else {
            scopeID = parentScope->scopeID + "." + to_string(parentScope->childCount);
        }

        total_buckets = n;
        chainHashTable = new SymbolInfo *[total_buckets];
        for (int i = 0; i < total_buckets; i++)
            chainHashTable[i] = NULL;
    }

    void setParentScope(ScopeTable *parentScope) {
        ScopeTable::parentScope = parentScope;
    }

    void addChild() {
        childCount++;
    }

    int getChildCount() const {
        return childCount;
    }

    ScopeTable *getParentScope() const {
        return parentScope;
    }

    int32_t sdbmhash(string key) {
        const char *str = key.c_str();
        int32_t hash = 0;
        int c;

        while (c = *str++)
            hash = c + (hash << 6) + (hash << 16) - hash;
        return hash % total_buckets;
    }

    const string getScopeId() {
        return scopeID;
    }

    void insert(SymbolInfo *symbol) {
        string key = symbol->getSymbolName();

        int posInChain = 0;

        int idx = sdbmhash(key);
        if (chainHashTable[idx] == NULL) {
            // simply insert
            chainHashTable[idx] = symbol;
            symbol->setHashIdx(idx);
            symbol->setHashPos(posInChain);
        } else {
            // traverse till the end of the linked list for this hash position
            posInChain++;
            SymbolInfo *currSymbol = chainHashTable[idx];
            while (currSymbol->getNextSymbol() != NULL) {
                currSymbol = currSymbol->getNextSymbol();
                posInChain++;
            }
            currSymbol->setNextSymbol(symbol);
            symbol->setHashIdx(idx);
            symbol->setHashPos(posInChain);
        }

        cout << "Inserted in ScopeTable# " << scopeID << " at position " << idx << ", " << posInChain << endl;
        output_file << "Inserted in ScopeTable# " << scopeID << " at position " << idx << ", " << posInChain << endl;

    }

    bool deleteSymbolFromCurrScope(string key) {
        int idx = sdbmhash(key);

        SymbolInfo *currSymbol = chainHashTable[idx];

        if (lookup(key) == NULL) {
            cout << key << " not found, cannot delete" << endl;
            output_file << key << " not found, cannot delete" << endl;
            return false;
        }

        // currSymbol has no further chain
        if (currSymbol->getSymbolName() == key && currSymbol->getNextSymbol() == NULL) {
            delete currSymbol;
            chainHashTable[idx] = NULL;
            return true;
        }

        // has chain
        SymbolInfo *parent = chainHashTable[idx];
        int c = 0;
        while (currSymbol->getSymbolName() != key && currSymbol->getNextSymbol() != NULL) {
            parent = currSymbol;
            currSymbol = currSymbol->getNextSymbol();
            c++;
        }

        // when found match and the symbol is in the middle of the current table
        if (currSymbol->getSymbolName() == key && currSymbol->getNextSymbol() != NULL) {
            // if the deleted item is at the first place of the chain, need to make the next symbol the head of the chain
            if (c == 0) {
                chainHashTable[idx] = currSymbol->getNextSymbol();
            }
            parent->setNextSymbol(currSymbol->getNextSymbol());
            currSymbol->setNextSymbol(NULL);

            delete currSymbol;
            return true;
        } else {
            // the symbol is at the end of the curr table
            parent->setNextSymbol(NULL);
            currSymbol->setNextSymbol(NULL);
            delete currSymbol;
            return true;
        }
        return false;
    }

    void printCurr() {
        cout << "ScopeTable# " << scopeID << endl;
        output_file << "ScopeTable# " << scopeID << endl;
        for (int i = 0; i < total_buckets; i++) {
            cout << i << " --> ";
            output_file << i << " --> ";

            SymbolInfo *currSymbol = chainHashTable[i];
            while (currSymbol != NULL) {
                cout << "< " << currSymbol->getSymbolName() << " : " << currSymbol->getSymbolType() << " > ";
                output_file << "< " << currSymbol->getSymbolName() << " : " << currSymbol->getSymbolType() << " > ";
                currSymbol = currSymbol->getNextSymbol();
            }
            cout << endl;
            output_file << endl;
        }
    }

    SymbolInfo *lookup(string key) {
        int idx = sdbmhash(key);
        SymbolInfo *currSymbol = chainHashTable[idx];
        if (currSymbol == NULL) {
            return NULL;
        }

        int c = 0;
        while (currSymbol != NULL) {
            if (currSymbol->getSymbolName() == key) {
                currSymbol->setHashPos(c);
                return currSymbol;
            }
            c++;
            currSymbol = currSymbol->getNextSymbol();
        }
        return NULL;
    }


    ~ScopeTable() {
    //    cout << "Destroying the current ScopeTable" << endl;
        for (int i = 0; i < total_buckets; i++) {

            SymbolInfo *tempSymbol = chainHashTable[i];
            while(tempSymbol){
                // cleaning the chains
                SymbolInfo * currNext = tempSymbol->getNextSymbol();
                delete tempSymbol;
                tempSymbol = currNext;
            }
            // delete chainHashTable[i];
        }
        delete[] chainHashTable;

    }
};


class SymbolTable {
private:
    ScopeTable *currScopeTable;
    int tableSize;

public:
    SymbolTable(int tableSize) {
        this->tableSize = tableSize;
        // constructing the root scopeTable here
        currScopeTable = new ScopeTable(tableSize, NULL);
    }

    void enterScope() {
        currScopeTable->addChild();
//        Create a new ScopeTable and make it current one. Also
//        make the previous current table as its parentScopeTable.
        currScopeTable = new ScopeTable(tableSize, currScopeTable);
        cout << "New ScopeTable with id " << currScopeTable->getScopeId() << " created" << endl;
        output_file << "New ScopeTable with id " << currScopeTable->getScopeId() << " created" << endl;
    }

    void exitScope() {
//        Remove the current ScopeTable
        if(!isSymbolTableEmpty()){

            if (currScopeTable->getParentScope() == NULL) {
                // reached the root scope
                cout << "ScopeTable# " << currScopeTable->getScopeId() << " removed" << endl;
                output_file << "ScopeTable# " << currScopeTable->getScopeId() << " removed" << endl;
                cout << "Destroying the First Scope" << endl;
                output_file << "Destroying the First Scope" << endl;

                // currScopeTable = NULL;
                delete currScopeTable;
                currScopeTable = NULL;
            }
            if (currScopeTable != NULL) {
                ScopeTable *parentScope = currScopeTable->getParentScope();
                cout << "ScopeTable# " << currScopeTable->getScopeId() << " removed" << endl;
                output_file << "ScopeTable# " << currScopeTable->getScopeId() << " removed" << endl;
                delete currScopeTable;
                currScopeTable = parentScope;
            }
        }
    }

    bool insert(SymbolInfo *newSymbol) {
//        Insert a symbol in current ScopeTable. Return true for
//        successful insertion and false otherwise.
        if(currScopeTable == NULL){
            currScopeTable = new ScopeTable(tableSize, NULL);
        }
        if (currScopeTable->lookup(newSymbol->getSymbolName())){

            cout << "< " << newSymbol->getSymbolName() << " : " << newSymbol->getSymbolType() << " > " << " already exists in current scope" <<endl;
            output_file << "< " << newSymbol->getSymbolName() << " : " << newSymbol->getSymbolType() << " > " << " already exists in current scope" <<endl;
            delete newSymbol;
            return false;
        }
        currScopeTable->insert(newSymbol);

        return true;
    }

    bool remove(string symbol) {

        SymbolInfo *currSymbol = currScopeTable->lookup(symbol);
        if (currScopeTable->deleteSymbolFromCurrScope(symbol)) {
            cout << "Found in ScopeTable# " << currScopeTable->getScopeId() << " at position " << currSymbol->getPosition() << endl;
            cout << "Deleted Entry " << currSymbol->getPosition() << " from current ScopeTable" << endl;

            output_file << "Found in ScopeTable# " << currScopeTable->getScopeId() << " at position " << currSymbol->getPosition() << endl;
            output_file << "Deleted Entry " << currSymbol->getPosition() << " from current ScopeTable" << endl;

            return true;
        }

        cout << symbol << " Not found" << endl;
        return false;
    }

    bool lookup(string symbol) {
        ScopeTable *scope = currScopeTable;
        while (scope) {
            SymbolInfo *currSymbol = scope->lookup(symbol);
            if (currSymbol != NULL) {
                cout << "Found in ScopeTable# " << scope->getScopeId() << " at position " << currSymbol->getPosition() << endl;
                output_file << "Found in ScopeTable# " << scope->getScopeId() << " at position " << currSymbol->getPosition() << endl;
                return true;
            } else scope = scope->getParentScope();
        }
        cout << symbol << " Not found" << endl;
        output_file << symbol << " Not found" << endl;
        return false;
    }

    void printCurrScopeTable() {
        if(!isSymbolTableEmpty())
            currScopeTable->printCurr();
    }

    void printAllScopeTables() {
        ScopeTable *tempScope = currScopeTable;

        while (tempScope) {
            tempScope->printCurr();
            tempScope = tempScope->getParentScope();

        }
    }

    bool isSymbolTableEmpty(){
        if(!currScopeTable){
            cout << "NO CURRENT SCOPE" << endl;
            output_file << "NO CURRENT SCOPE" << endl;
            return true;
        }
        else return false;
    }

    ~SymbolTable() {
        if(currScopeTable->getParentScope() != NULL){
            delete currScopeTable->getParentScope();
        }
        delete currScopeTable;

    //    cout << "Destroying the current SymbolTable" << endl;
    }
};


#endif //SYMBOLTABLE_SYMBOLTABLE_H
