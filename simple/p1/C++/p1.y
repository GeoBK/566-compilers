%{
  

#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <list>
#include <map>
  
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Value.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Type.h"

#include "llvm/Bitcode/BitcodeReader.h"
#include "llvm/Bitcode/BitcodeWriter.h"
#include "llvm/Support/SystemUtils.h"
#include "llvm/Support/ToolOutputFile.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/Support/FileSystem.h"

using namespace llvm;
struct expr_wrapper{
  Value *exp;
  Value *ptr;
  };

using namespace std;


extern FILE *yyin;
int yylex(void);
int yyerror(const char *);

// From main.cpp
extern char *fileNameOut;
extern Module *M;
extern LLVMContext TheContext;
extern Function *Func;
extern IRBuilder<> Builder;

// Used to lookup Value associated with ID
map<string,Value*> idLookup;

%}

%union {
  int num;
  char *id;
  expr_wrapper val;
  std::list<expr_wrapper> *vals;
}

%token IDENT NUM MINUS PLUS MULTIPLY DIVIDE LPAREN RPAREN SETQ SETF AREF MIN MAX ERROR MAKEARRAY

%type <num> NUM 
%type <id> IDENT
%type <val> expr token exprlist program token_or_expr
%type <vals> token_or_expr_list

%start program

%%


/*
   IMPLMENT ALL THE RULES BELOW HERE!
 */

program : exprlist 
{ 
  /* 
    IMPLEMENT: return value
    Hint: the following code is not sufficient
  */
  Builder.CreateRet($1.exp);
  return 0;
}
;

exprlist:  exprlist expr    {$$=$2;}
| expr {$$=$1;}// MAYBE ADD ACTION HERE?
;         

expr: LPAREN MINUS token_or_expr RPAREN
{ 
  // IMPLEMENT
  $$.exp = Builder.CreateNeg($3.exp);
  $$.ptr= NULL;
}
| LPAREN PLUS token_or_expr_list RPAREN
{
  // IMPLEMENT
  printf("Inside plus\n");
  Value* sum = Builder.getInt32(0);
  for(auto it=$3->begin();it!=$3->end();it++)
  {
    sum = Builder.CreateAdd((*it).exp,sum);
  }
  $$.exp = sum;
  $$.ptr= NULL;
}
| LPAREN MULTIPLY token_or_expr_list RPAREN
{
  // IMPLEMENT
  Value* prod = Builder.getInt32(1);
  for(auto it=$3->begin();it!=$3->end();it++)
  {
    prod = Builder.CreateMul((*it).exp,prod);
  }
  $$.exp = prod;
  $$.ptr= NULL;
}
| LPAREN DIVIDE token_or_expr_list RPAREN
{
  // IMPLEMENT
  Value* div = Builder.getInt32(1);
  if($3->size()>1)
  {
    auto it = $3->begin();
    div = (*it).exp;
    it++;
    for(;it!=$3->end();it++)
    {
      div = Builder.CreateUDiv(div,(*it).exp);
    }
    $$.exp = div;
    $$.ptr= NULL;
  }
  else
  {
    $$ = *($3->begin());
  }
  
  
}
| LPAREN SETQ IDENT token_or_expr RPAREN
{
  // IMPLEMENT
  printf("reached setq\n");
  Value* var = NULL;
  if(idLookup.find($3)==idLookup.end())
  {
    var = Builder.CreateAlloca(Builder.getInt32Ty(),nullptr,$3);
    idLookup[$3] = var;
  }
  else
  {
    var = idLookup[$3];
  }
  Builder.CreateStore($4.exp,var);  
  $$ = $4;
  $$.ptr = NULL;
  
}
| LPAREN MIN token_or_expr_list RPAREN
{
  // HINT: select instruction
  if($3->size()==1)
  {
    $$ = *($3->begin());
  }
  else
  {
    auto it = $3->begin();
    Value* min = (*it).exp;
    it++;
    for(;it!=$3->end();it++)
    {
      Value* cmp = Builder.CreateICmpULT((*it).exp,min);
      min = Builder.CreateSelect(cmp,(*it).exp,min);
    }
    $$.exp = min;
    $$.ptr= NULL;
  }
}
| LPAREN MAX token_or_expr_list RPAREN
{
  // HINT: select instruction
  if($3->size()==1)
  {
    $$ = *($3->begin());
  }
  else
  {
    auto it = $3->begin();
    Value* max = (*it).exp;
    it++;
    for(;it!=$3->end();it++)
    {
      Value* cmp = Builder.CreateICmpUGT((*it).exp,max);
      max = Builder.CreateSelect(cmp,(*it).exp,max);
    }
    $$.exp = max;
    $$.ptr= NULL;
  }
  
}
| LPAREN SETF token_or_expr token_or_expr RPAREN
{
  // ECE 566 only
  // IMPLEMENT  
  if($3.ptr==NULL)
  {
    printf("Syntax error, inside setf function\n");
    return 1;
  }
  Builder.CreateStore($4.exp,$3.ptr);
  $$ = $4;
}
| LPAREN AREF IDENT token_or_expr RPAREN
{
  if (idLookup.find($3) == idLookup.end())
  {
    printf("Syntax error. Use of undeclared variable\n");
    return 1;
  }
  Value* ptr = Builder.CreateGEP(idLookup[$3],$4.exp);
  $$.ptr = ptr;
  $$.exp = Builder.CreateLoad(ptr);  

}
| LPAREN MAKEARRAY IDENT NUM token_or_expr RPAREN
{
  // ECE 566 only
  // IMPLEMENT  
  Value *val = Builder.CreateAlloca(Builder.getInt32Ty(),Builder.getInt32($4),$3);
  for(int i=0; i< $4; i++)
  {
    Builder.CreateStore($5.exp, Builder.CreateGEP(val,Builder.getInt32(i)));
  }
  idLookup[$3]=val;
  $$ = $5;

}
;

token_or_expr_list:   token_or_expr_list token_or_expr
{
  // IMPLEMENT
  $1->push_back($2);
}
| token_or_expr
{
  // IMPLEMENT
  // HINT: $$.exp = new std::list<Value*>;  
  list<expr_wrapper> *temp = new list<expr_wrapper>();  
  temp->push_back($1);
  $$ = temp;
  // $$->push_back($1);
}
;

token_or_expr :  token
{
  // IMPLEMENT
  $$ = $1;  
}
| expr
{
  // IMPLEMENT
  $$ = $1;
}
; 

token:   IDENT
{  
  if (idLookup.find($1) != idLookup.end())
  {
    $$.exp = Builder.CreateLoad(idLookup[$1]);
    $$.ptr = NULL;
  }
  else
  {
    printf("Syntax error. Use of undeclared variable\n");
    return 1;
  }
}
| NUM
{
  // IMPLEMENT  
  $$.exp = Builder.getInt32($1);
  $$.ptr = NULL;
}
;

%%

void initialize()
{
  // printf("Inside initialize\n");
  string s = "arg_array";
  
  idLookup[s] = (Value*)(Func->arg_begin()+1);
  
  string s2 = "arg_size";
  Argument *a = Func->arg_begin();
  
  
  Value * v = Builder.CreateAlloca(a->getType());
  
  Builder.CreateStore(a,v);
  idLookup[s2] = (Value*)v;
  // printf("Initialization complete\n");
  /* IMPLEMENT: add something else here if needed */
}

extern int line;

int yyerror(const char *msg)
{
  printf("%s at line %d.\n",msg,line);
  return 0;
}
