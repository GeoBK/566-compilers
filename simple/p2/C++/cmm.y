%{
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Value.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/IRBuilder.h"

#include "llvm/Bitcode/BitcodeWriter.h"
#include "llvm/ADT/StringSet.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/SystemUtils.h"
#include "llvm/Support/ToolOutputFile.h"

#include <memory>
#include <algorithm>
#include <list>
#include <vector>
#include <utility>
#include <stack>
#include <string>

#include "list.h"
#include "symbol.h"
#include <map>
  
using namespace llvm;
using namespace std;

using parameter = pair<Type*,const char*>;
using parameter_list = std::list<parameter>;


// typedef struct {
//   BasicBlock* expr;
//   BasicBlock* body;
//   BasicBlock* reinit;
//   BasicBlock* exit;
// } loop_info_t;

stack<loop_info_t> loop_stack;
 map<string,Function*> func_map;
int num_errors;

extern int yylex();   /* lexical analyzer generated from lex.l */

int yyerror(const char *error);
int parser_error(const char*);

void cmm_abort();
char *get_filename();
int get_lineno();

int loops_found=0;

extern Module *M;
extern LLVMContext TheContext;

map<Value* ,BasicBlock*> switch_map;
 
Function *Fun;
IRBuilder<> *Builder=NULL;
bool is_first_case;
BasicBlock *post_return;

Value* BuildFunction(Type* RetType, const char *name, 
			   parameter_list *params);

%}

/* Data structure for tree nodes*/

%union {
  int inum;
  char * id;
  Type*  type;
  Value* value;
  parameter_list *plist;
  vector<Value*> *arglist;
  BasicBlock* bb;
}

/* these tokens are simply their corresponding int values, more terminals*/

%token SEMICOLON COMMA MYEOF
%token LBRACE RBRACE LPAREN RPAREN LBRACKET RBRACKET

%token ASSIGN PLUS MINUS STAR DIV MOD 
%token LT GT LTE GTE EQ NEQ
%token BITWISE_OR BITWISE_XOR LSHIFT RSHIFT BITWISE_INVERT
%token DOT AMPERSAND 

%token FOR WHILE IF ELSE DO RETURN SWITCH
%token BREAK CONTINUE CASE COLON DEFAULT
%token INT VOID BOOL
%token I2P P2I SEXT ZEXT

/* NUMBER and ID have values associated with them returned from lex*/

%token <inum> CONSTANT_INTEGER /*data type of NUMBER is num union*/
%token <id>  ID

%left EQ NEQ LT GT LTE GTE
%left BITWISE_OR
%left BITWISE_XOR
%left AMPERSAND
%left LSHIFT RSHIFT
%left PLUS MINUS
%left MOD DIV STAR 
%nonassoc ELSE

%type <type> type_specifier

%type <value> opt_initializer
%type <value> expression bool_expression
%type <value> lvalue_location primary_expression unary_expression
%type <value> constant constant_expression unary_constant_expression
%type <arglist> argument_list argument_list_opt
%type <plist> param_list param_list_opt
%%

translation_unit:	  external_declaration
			| translation_unit external_declaration
                        | translation_unit MYEOF
{
  YYACCEPT;
}
;

external_declaration:	  function_definition
                        | global_declaration 
;

function_definition:	  type_specifier ID LPAREN param_list_opt RPAREN
// NO MODIFICATION NEEDED
{
  symbol_push_scope();
  BuildFunction($1,$2,$4);
}
compound_stmt 
{
  Builder->CreateBr(post_return);
  symbol_pop_scope();
}

// NO MODIFICATION NEEDED
| type_specifier STAR ID LPAREN param_list_opt RPAREN
{
  printf("----------------------Identified function definition!!------------\n");
  symbol_push_scope();
  BuildFunction(PointerType::get($1,0),$3,$5);
}
compound_stmt
{
  Builder->CreateBr(post_return);
  symbol_pop_scope();
}
;

global_declaration:    type_specifier STAR ID opt_initializer SEMICOLON
{
  auto gv = new GlobalVariable(*M,$1,false,GlobalValue::CommonLinkage,0,$3);
  // Check to make sure global isn't already allocated    
  if($4 != nullptr)
  {    
    gv->setInitializer(dyn_cast<llvm::ConstantInt>($4));
  }  
}
| type_specifier ID opt_initializer SEMICOLON
{  
  // Check to make sure global isn't already allocated
  auto gv = new GlobalVariable(*M,$1,false,GlobalValue::CommonLinkage,0,$2);
    if($3 != nullptr)
    {    
      //printf("IN here!\n") ;
      //Builder->CreateStore($3, gv); 
      gv->setInitializer(dyn_cast<llvm::ConstantInt>($3));    
    }  
}
;

// YOU MUST FIXME: hacked to prevent segfault on initial testing
opt_initializer:   ASSIGN constant_expression 
{ 
  // printf("optional initializer identified\n");
  $$ = $2; 
} 
| 
{ 
  // printf("optional initializer identified as null\n");
  $$ = nullptr; 
};

// NO MODIFICATION NEEDED
type_specifier:		  INT
{
  // printf("Type specifier identified\n");
  $$ = Type::getInt64Ty(TheContext);
}
                     |    VOID
{
  $$ = Type::getVoidTy(TheContext);
}
;


param_list_opt:           
{
  $$ = nullptr;
}
| param_list
{
  $$ = $1;
}
;

// USED FOR FUNCTION DEFINITION; NO MODIFICATION NEEDED
param_list:	
param_list COMMA type_specifier ID
{
  $$ = $1;
  $$->push_back( parameter($3,$4) );
}
| param_list COMMA type_specifier STAR ID
{
  $$ = $1;
  $$->push_back( parameter(PointerType::get($3,0),$5) );
}
| type_specifier ID
{
  $$ = new parameter_list;
  $$->push_back( parameter($1,$2) );
}
| type_specifier STAR ID
{
  $$ = new parameter_list;
  $$->push_back( parameter(PointerType::get($1,0),$3) );
}
;


statement:		  expr_stmt            
			        | compound_stmt        
			        | selection_stmt       
			        | iteration_stmt       
			        | return_stmt            
              | break_stmt
              | continue_stmt
              
;



expr_stmt:	           SEMICOLON            
			|  assign_expression SEMICOLON       
;

local_declaration:    type_specifier STAR ID opt_initializer SEMICOLON
{
  Value * ai = Builder->CreateAlloca(PointerType::get($1,0),0,$3);
  if (nullptr != $4)
    Builder->CreateStore($4,ai);
  symbol_insert($3,ai);
}
| type_specifier ID opt_initializer SEMICOLON
{
  Value * ai = Builder->CreateAlloca($1,0,$2);
  if (nullptr != $3)
    Builder->CreateStore($3,ai);
  symbol_insert($2,ai);  
}
;

local_declaration_list:	   local_declaration
                         | local_declaration_list local_declaration  
;

local_declaration_list_opt:	
			| local_declaration_list
;

compound_stmt:		  LBRACE {
  // PUSH SCOPE TO RECORD VARIABLES WITHIN COMPOUND STATEMENT
  symbol_push_scope();
}
local_declaration_list_opt
statement_list_opt 
{
  // POP SCOPE TO REMOVE VARIABLES NO LONGER ACCESSIBLE
  symbol_pop_scope();
}
RBRACE
;


statement_list_opt:	
			| statement_list
;

statement_list:		statement
		      | statement_list statement
;

break_stmt:               BREAK SEMICOLON
{
  loop_info_t info = get_loop();
  if(info.exit==NULL)
  {
    num_errors++;
    parser_error("Invalid break statement - might not be in a loop!\n");
  }
  Builder->CreateBr(info.exit);
  BasicBlock* post_break = BasicBlock::Create(TheContext, "post_break", Fun);
  Builder->SetInsertPoint(post_break);
  
}
default_stmt: DEFAULT COLON
{  
  BasicBlock* default_node = BasicBlock::Create(TheContext, "default_node", Fun);
  if(!is_first_case)
  {
    Builder->CreateBr(default_node);
  }
  is_first_case = false;  
  
  Builder->SetInsertPoint(default_node);
  $<bb>$ = default_node;
} statement_list_opt
{$<bb>$=$<bb>3;}

case_stmt_list: case_stmt
| case_stmt_list case_stmt


default_stmt_opt: 
{$<bb>$ = get_loop().exit;}
|default_stmt
{$<bb>$ = $<bb>1;}


case_default_list: case_stmt_list default_stmt_opt
{$<bb>$ = $<bb>2;}

case_stmt:                CASE constant_expression COLON
{  
  BasicBlock* case_node = BasicBlock::Create(TheContext, "case_node", Fun);
  if(!is_first_case)
  {
    Builder->CreateBr(case_node);
  }
  is_first_case = false;
  
  switch_map.insert({$2,case_node});
  Builder->SetInsertPoint(case_node);
  
} statement_list_opt


;

continue_stmt:            CONTINUE SEMICOLON
{
  loop_info_t info = get_loop();
  if(info.body==NULL)
  {
    num_errors++;
    parser_error("Invalid continue statement - might not be in a loop!\n");
  }
  //For loop needs to continue with the update - Eg i++;
  
  //Do-while needs to continue with the body of the loop
  if(info.expr==NULL && info.reinit==NULL)
  {
    Builder->CreateBr(info.body);
  }
  //While loop needs to continue with condition check
  else if(info.reinit==NULL)
  {
    Builder->CreateBr(info.expr);
  }
  else
  {
    Builder->CreateBr(info.reinit);
  }
  
  BasicBlock* post_break = BasicBlock::Create(TheContext, "post_break", Fun);
  Builder->SetInsertPoint(post_break);
}

selection_stmt:		  
  IF LPAREN bool_expression RPAREN 
  {
    BasicBlock *then = BasicBlock::Create(TheContext, "if.th", Fun);
    BasicBlock* els  = BasicBlock::Create(TheContext, "if.els", Fun);  
    Value * pred = $3;
    if($3->getType()!=Type::getInt1Ty(TheContext))
    {
      pred = Builder->CreateTrunc($3,Builder->getInt1Ty());
    }  
    Value* branch = Builder->CreateCondBr(pred, then, els);
    Builder->SetInsertPoint(then); 
    $<bb>$ = els;
  }
  statement 
  {
    BasicBlock* join = BasicBlock::Create(TheContext, "if.jn", Fun);
    Builder->CreateBr(join);
    BasicBlock *els =$<bb>5;
    Builder->SetInsertPoint(els);
    $<bb>$ = join;
  }
  ELSE statement
  {
    BasicBlock* join = $<bb>7;
    Builder->CreateBr(join);
    Builder->SetInsertPoint(join);
  }
| SWITCH LPAREN expression RPAREN
{
  is_first_case = true;
  BasicBlock* join = BasicBlock::Create(TheContext,"case_join",Fun);
  push_loop(NULL, NULL, NULL, join);
  BasicBlock* switch_eval = BasicBlock::Create(TheContext,"switch_eval",Fun);
  Builder->CreateBr(switch_eval);
  $<bb>$ = switch_eval;
} LBRACE case_default_list RBRACE
{
  printf("Inside post switch midrule expression\n");
  loop_info_t l_item = get_loop();
  Builder->CreateBr(l_item.exit);
  pop_loop();
  Builder->SetInsertPoint($<bb>5);  
  is_first_case = false;
  BasicBlock* jump_to_block;
  for(auto it = switch_map.begin();it!=switch_map.end();it++)
  {
    BasicBlock* next_bb = BasicBlock::Create(TheContext,"redirect_nodes",Fun);
    Value* pred = Builder->CreateICmpEQ($3,(*it).first);
    Builder->CreateCondBr(pred,(*it).second,next_bb);
    Builder->SetInsertPoint(next_bb);    
  }
  Builder->CreateBr($<bb>7);
  Builder->SetInsertPoint(l_item.exit);
}
;


iteration_stmt:
  WHILE LPAREN 
  {

    BasicBlock * cond = BasicBlock::Create(TheContext, "cond", Fun);
    Builder->CreateBr(cond);
    // Position Builder at end of new block 
    Builder->SetInsertPoint(cond);
    $<bb>$ = cond;
  }
  bool_expression 
  {
    BasicBlock* cond = $<bb>3;
    BasicBlock *body = BasicBlock::Create(TheContext, "body", Fun);
    BasicBlock *join = BasicBlock::Create(TheContext, "join", Fun);
    Value* branch = Builder->CreateCondBr($4, body, join);    
    Builder->SetInsertPoint(body);
    push_loop(cond,body,NULL,join);
    $<bb>$ = join;
  }
  RPAREN statement
  {
    pop_loop();
    BasicBlock* join = $<bb>5;
    BasicBlock* cond = $<bb>3;
    Builder->CreateBr(cond);
    Builder->SetInsertPoint(join);
  }
| FOR LPAREN expr_opt SEMICOLON 
  {
    BasicBlock * cond = BasicBlock::Create(TheContext, "cond", Fun);
    Builder->CreateBr(cond);
    // Position Builder at end of new block 
    Builder->SetInsertPoint(cond);
    $<bb>$ = cond;
  }
bool_expression SEMICOLON 
  {
    BasicBlock * body = BasicBlock::Create(TheContext, "body", Fun);
    $<bb>$ = body;
  }
  {
    BasicBlock *join = BasicBlock::Create(TheContext, "join", Fun);
    $<bb>$ = join;
  }
  {       
    BasicBlock * update = BasicBlock::Create(TheContext, "update", Fun);
    // Position Builder at end of new block 
    BasicBlock* body = $<bb>8;
    BasicBlock* join = $<bb>9;
    Value* branch = Builder->CreateCondBr($6, body, join);    
    
    Builder->SetInsertPoint(update);
    $<bb>$ = update;
  }
expr_opt RPAREN
  {
    BasicBlock * cond = $<bb>5;
    Builder->CreateBr(cond);
    BasicBlock * body = $<bb>8;
    Builder->SetInsertPoint(body);
    BasicBlock * join = $<bb>9;
    BasicBlock * update = $<bb>10;
    push_loop(cond,body,update,join);
  }
 statement 
  {
    pop_loop();
    BasicBlock * update = $<bb>10;
    Builder->CreateBr(update);
    BasicBlock * join = $<bb>9;
    Builder->SetInsertPoint(join);
  }
| DO 
  {
    $<bb>$ = BasicBlock::Create(TheContext, "join", Fun);
  }
  {
    BasicBlock* join = $<bb>2;
    BasicBlock * body = BasicBlock::Create(TheContext, "body", Fun);
    Builder->CreateBr(body);
    // Position Builder at end of new block 
    Builder->SetInsertPoint(body);
    push_loop(NULL,body,NULL,join);
    $<bb>$ = body;
  }
statement 
  {
    pop_loop();
    BasicBlock * cond = BasicBlock::Create(TheContext, "cond", Fun);
    Builder->CreateBr(cond);
    // Position Builder at end of new block 
    Builder->SetInsertPoint(cond);
    $<bb>$ = cond;
  }
WHILE LPAREN bool_expression RPAREN SEMICOLON
  {
    BasicBlock *join = BasicBlock::Create(TheContext, "join", Fun);
    BasicBlock *body = $<bb>2;
    Builder->CreateCondBr($8, body, join);    
    Builder->SetInsertPoint(join);
  }
;

expr_opt:  	
	| assign_expression
;

return_stmt:		  RETURN SEMICOLON
{
  Builder->CreateRetVoid();
  post_return = BasicBlock::Create(TheContext, "post_return", Fun);
  Builder->SetInsertPoint(post_return);
}
| RETURN expression SEMICOLON
{
  Builder->CreateRet($2);
  post_return = BasicBlock::Create(TheContext, "post_return", Fun);
  Builder->SetInsertPoint(post_return);
}      
;

bool_expression: expression 
;

assign_expression:
  lvalue_location ASSIGN expression
  {
    // printf("Assign expression identified\n");
    Builder->CreateStore($3,$1);
  }
| expression
;

expression:
  unary_expression
| expression BITWISE_OR expression
{
  $$ = Builder->CreateOr($1,$3, "bitwise OR");
}
| expression BITWISE_XOR expression
{
  $$ = Builder->CreateXor($1,$3, "bitwise XOR");
}

| expression AMPERSAND expression
{
  $$ = Builder->CreateAnd($1,$3, "bitwise AND");
}
| expression EQ expression
{
  $$ = Builder->CreateICmpEQ($1,$3, "equality check");
}
| expression NEQ expression
{
  $$ = Builder->CreateICmpNE($1,$3, "not equals");
}
| expression LT expression
{
  $$ = Builder->CreateICmpSLT($1,$3, "less than check");
}
| expression GT expression
{
  $$ = Builder->CreateICmpSGT($1,$3, "greater than check");
}
| expression LTE expression
{
  $$ = Builder->CreateICmpSLE($1,$3, "less than equals check");
}
| expression GTE expression
{
  $$ = Builder->CreateICmpSGE($1,$3, "greater than equals check");
}
| expression LSHIFT expression
{
  $$ = Builder->CreateShl($1,$3, "left shift");
}
| expression RSHIFT expression
{
  $$ = Builder->CreateLShr($1,$3, "Right shift");
}
| expression PLUS expression
{
  // Value* v1 = Builder->CreateLoad($1);
  // Value* v2 = Builder->CreateLoad($3);
  $$ = Builder->CreateAdd($1,$3);
}
| expression MINUS expression
{
  $$ = Builder->CreateSub($1,$3, "Subtraction");
}
| expression STAR expression
{
  $$ = Builder->CreateMul($1,$3, "Multiply");
}
| expression DIV expression
{
  $$ = Builder->CreateSDiv($1,$3, "Division");
}
| expression MOD expression
{
  $$ = Builder->CreateSRem($1,$3, "MODULO");
}
| BOOL LPAREN expression RPAREN
{
  Value* pred = Builder->CreateICmpEQ($3,Builder->getInt64(0));
  $$ = Builder->CreateSelect(pred,Builder->getInt1(0),Builder->getInt1(1));
}
| I2P LPAREN expression RPAREN
{  
  $$ = Builder->CreateIntToPtr($3,PointerType::get(Builder->getInt64Ty(),0));
}
| P2I LPAREN expression RPAREN
{
  $$ = Builder->CreatePtrToInt($3,Builder->getInt64Ty());
}
| ZEXT LPAREN expression RPAREN
{
  $$ = Builder->CreateZExt($3,Builder->getInt64Ty());
}
| SEXT LPAREN expression RPAREN
{
  $$ = Builder->CreateSExt($3,Builder->getInt64Ty());
}
| ID LPAREN argument_list_opt RPAREN
{
  //function call i think  
  // printf("1\n");
  // Function* func = (Function*)symbol_find($1);
  Function* func = NULL;
  string func_name($1);
  if(func_map.find(func_name)!=func_map.end())
  {
    func = func_map[func_name];
  }
  if(func==NULL)
  {
    parser_error("Function not defined yet!!! \n");
  }
  llvm::SmallVector<Value*, 10> smallVector;
  // printf("2\n");
  for(auto it = $3->begin(); it!=$3->end(); it++)
  {
    // printf("3\n");
    smallVector.push_back(*it);
  }
  // printf("4\n");
  // printf("%u\n",func);
  $$ = Builder->CreateCall(func,smallVector); 
  
}
| LPAREN expression RPAREN
{
  $$ = $2;
}
;


argument_list_opt: 
{
  $$ = new vector<Value*>();
}
| argument_list
{
  $$ = $1;
}
;

argument_list:
  expression
  {
    vector<Value*>* args = new vector<Value*>();
    args->push_back($1);
    $$ = args;
  }
| argument_list COMMA expression
{
  $1->push_back($3);
  $$ = $1;
}
;


unary_expression:         primary_expression
| AMPERSAND lvalue_location
{
  $$ = $2;
}
| STAR primary_expression
{  
  $$ = Builder->CreateLoad($2,"Load for ptr");
}
| MINUS unary_expression
{
  $$ = Builder->CreateNeg($2,"Unary MINUS");
}
| PLUS unary_expression
{
  $$ = $2 ;
}
| BITWISE_INVERT unary_expression
{
  $$ = Builder->CreateNot($2,"Unary NOT expression");
}
;

primary_expression:
  lvalue_location
  {
    $$ = Builder->CreateLoad($1);
  }
| constant
;

lvalue_location:
  ID
  {
    $$ = symbol_find($1);
  }
| lvalue_location LBRACKET expression RBRACKET
{
  Value* base = Builder->CreateLoad($1);
  $$ = Builder->CreateGEP(base,$3);
}
| STAR LPAREN expression RPAREN
{
  //Might have to convert the below into pointer
  $$ = $3;
}
;

constant_expression:
  unary_constant_expression
| constant_expression BITWISE_OR constant_expression
{
  $$ = Builder->CreateOr($1,$3, "Const bitwise OR");
}
| constant_expression BITWISE_XOR constant_expression
{
  $$ = Builder->CreateXor($1,$3, "Const bitwise XOR");
}
| constant_expression AMPERSAND constant_expression
{
  $$ = Builder->CreateAnd($1,$3, "Const bitwise AND");
}
| constant_expression LSHIFT constant_expression
{
  $$ = Builder->CreateShl($1,$3, "Const left shift");
}
| constant_expression RSHIFT constant_expression
{
  $$ = Builder->CreateLShr($1,$3, "Const Right shift");
}
| constant_expression PLUS constant_expression
{
  $$ = Builder->CreateAdd($1,$3, "Const Addition");
}
| constant_expression MINUS constant_expression
{
  $$ = Builder->CreateSub($1,$3, "Const Subtraction");
}
| constant_expression STAR constant_expression
{
  $$ = Builder->CreateMul($1,$3, "Const Multiply");
}
| constant_expression DIV constant_expression
{
  $$ = Builder->CreateSDiv($1,$3, "Const Division");
}
| constant_expression MOD constant_expression
{
  $$ = Builder->CreateSRem($1,$3, "Const MODULO");
}
| I2P LPAREN constant_expression RPAREN
{
  $$ = Builder->CreateIntToPtr($3,PointerType::get(Builder->getInt64Ty(),0));
}
| LPAREN constant_expression RPAREN
{
  $$ = $2;
}
;

unary_constant_expression:
  constant
| MINUS unary_constant_expression
{
  $$ = Builder->CreateNeg($2,"Unary MINUS");
}
| PLUS unary_constant_expression
{
  $$ = $2 ;
}
| BITWISE_INVERT unary_constant_expression
{
  $$ = Builder->CreateNot($2,"Unary NOT expression");
}
;


constant:	          CONSTANT_INTEGER
{
  if(Builder==NULL)
  {
    Builder = new IRBuilder<>(M->getContext());    
  }
  $$ = Builder->getInt64($1);
}
;


%%
// Value* GlobalVariable(Type* type, const char *name,Value* val)
// {
  
//   BasicBlock* BB = BasicBlock::Create(M->getContext(),"global",NULL);
//   if(Builder==NULL)
//   {
//     Builder = new IRBuilder<>(M->getContext());    
//   }
//   else
//   {
//     Builder->CreateBr(BB);
//   }
//   Builder->SetInsertPoint(BB);
//   if(is_global_scope())
//   {
//     symbol_push_scope();
//   }
//   Value * ai = Builder->CreateAlloca(type,0,name);
//   if (nullptr != val)
//     Builder->CreateStore(val,ai);
//   symbol_insert(name,ai);
// }

Value* BuildFunction(Type* RetType, const char *name, 
			   parameter_list *params)
{
  // if(is_global_scope())
  // {
  //   printf("Inserting scope \n");
  //   symbol_push_scope();
  // }
  
  std::vector<Type*> v;
  std::vector<const char*> vname;

  if (params)
    for(auto ii : *params)
      {
	vname.push_back( ii.second );
	v.push_back( ii.first );      
      }
  
  
  ArrayRef<Type*> Params(v);

  FunctionType* FunType = FunctionType::get(RetType,Params,false);

  Fun = Function::Create(FunType,GlobalValue::ExternalLinkage,
			 name,M);
  //printf("Inserting function definition into hash, %s\n",name);
  printf("%s\n",name);
  string str(name);
  func_map.insert(std::make_pair(str,Fun));
  //auto gv = new GlobalVariable(*M,FunType,true,GlobalValue::CommonLinkage,Fun,name);
  // symbol_insert(name,Fun);
  Twine T("entry");
  BasicBlock* BB = BasicBlock::Create(M->getContext(),T,Fun);

  /* Create an Instruction Builder */
  if(Builder==NULL)
  {
    Builder = new IRBuilder<>(M->getContext());
  }
  Builder->SetInsertPoint(BB);

  Function::arg_iterator I = Fun->arg_begin();
  for(int i=0; I!=Fun->arg_end();i++, I++)
    {
      // map args and create allocas!
      AllocaInst *AI = Builder->CreateAlloca(v[i]);
      Builder->CreateStore(&(*I),(Value*)AI);
      symbol_insert(vname[i],(Value*)AI);
    }


  return Fun;
}

extern int verbose;
extern int line_num;
extern char *infile[];
static int   infile_cnt=0;
extern FILE * yyin;
extern int use_stdin;

int parser_error(const char *msg)
{
  if (use_stdin)
    printf("stdin:%d: Error -- %s\n",line_num,msg);
  else
    printf("%s:%d: Error -- %s\n",infile[infile_cnt-1],line_num,msg);
  return 1;
}

int internal_error(const char *msg)
{
  printf("%s:%d Internal Error -- %s\n",infile[infile_cnt-1],line_num,msg);
  return 1;
}

int yywrap() {

  if (use_stdin)
    {
      yyin = stdin;
      return 0;
    }
  
  static FILE * currentFile = NULL;

  if ( (currentFile != 0) ) {
    fclose(yyin);
  }
  
  if(infile[infile_cnt]==NULL)
    return 1;

  currentFile = fopen(infile[infile_cnt],"r");
  if(currentFile!=NULL)
    yyin = currentFile;
  else
    printf("Could not open file: %s",infile[infile_cnt]);

  infile_cnt++;
  
  return (currentFile)?0:1;
}

int yyerror(const char* error)
{
  parser_error("Un-resolved syntax error.");
  return 1;
}

char * get_filename()
{
  return infile[infile_cnt-1];
}

int get_lineno()
{
  return line_num;
}


void cmm_abort()
{
  parser_error("Too many errors to continue.");
  exit(1);
}
