%{ 
/* P1. Implements scanner.  Some changes are needed! */
#include <stdio.h>

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

#include <list>

using namespace llvm;
struct expr_wrapper{
  Value *exp;
  Value *ptr;
  };
  
int line=1;

#include "p1.y.hpp" 
%}

%option noyywrap noinput nounput
 
%% 

\n           line++;
[\t ]        ;

setq                    { return SETQ;          }
min                     { return MIN;           }
max                     { return MAX;           }
aref                    { return AREF;          }
setf                    { return SETF;          }
make-array              { return MAKEARRAY;     }
[a-zA-Z_][_a-zA-Z0-9]*  { yylval.id = strdup(yytext); return IDENT; } 
[0-9]+                  { yylval.num = atoi(yytext); return NUM;    }
"-"	                    { return MINUS;         } 
"+"	                    { return PLUS;          }  
"*"	                    { return MULTIPLY;      } 
"/"	                    { return DIVIDE;        } 
"("                     {  return LPAREN;        }
")"                     { return RPAREN;        }

.           { return ERROR;       }

%%
