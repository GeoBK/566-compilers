/*
 * File: CSE_Cpp.cpp
 *
 * Description:
 *   This is where you implement the C++ version of project 4 support.
 */

/* LLVM Header Files */
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Value.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Type.h"
#include "llvm/Analysis/AliasAnalysis.h"
#include "llvm/IR/Dominators.h"
#include "llvm/ADT/GraphTraits.h"
#include "llvm/ADT/SCCIterator.h"
#include "llvm/IR/ValueMap.h"
#include "llvm/Support/GraphWriter.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/Analysis/InstructionSimplify.h"
#include <map>
#include "dominance.h"

using namespace llvm;

// ^^^^
// must be after using namespace llvm; sorry for the ugly code
#include "CSE.h"

int CSEDead=0;
int CSEElim=0;
int CSESimplify=0;
int CSELdElim=0;
int CSELdStElim=0;
int CSERStElim=0;

bool isDead(Instruction &I)
{
  int opcode = I.getOpcode();
  switch(opcode){
  case Instruction::Add:
  case Instruction::FNeg:
  case Instruction::FAdd: 	
  case Instruction::Sub:
  case Instruction::FSub: 	
  case Instruction::Mul:
  case Instruction::FMul: 	
  case Instruction::UDiv:	
  case Instruction::SDiv:	
  case Instruction::FDiv:	
  case Instruction::URem: 	
  case Instruction::SRem: 	
  case Instruction::FRem: 	
  case Instruction::Shl: 	
  case Instruction::LShr: 	
  case Instruction::AShr: 	
  case Instruction::And: 	
  case Instruction::Or: 	
  case Instruction::Xor: 	
  case Instruction::Alloca:
  case Instruction::GetElementPtr: 	
  case Instruction::Trunc: 	
  case Instruction::ZExt: 	
  case Instruction::SExt: 	
  case Instruction::FPToUI: 	
  case Instruction::FPToSI: 	
  case Instruction::UIToFP: 	
  case Instruction::SIToFP: 	
  case Instruction::FPTrunc: 	
  case Instruction::FPExt: 	
  case Instruction::PtrToInt: 	
  case Instruction::IntToPtr: 	
  case Instruction::BitCast: 	
  case Instruction::AddrSpaceCast: 	
  case Instruction::ICmp: 	
  case Instruction::FCmp: 	
  case Instruction::PHI: 
  case Instruction::Select: 
  case Instruction::ExtractElement: 	
  case Instruction::InsertElement: 	
  case Instruction::ShuffleVector: 	
  case Instruction::ExtractValue: 	
  case Instruction::InsertValue: 
    if ( I.use_begin() == I.use_end() )
    {
      return true;
    }    
    break;

  case Instruction::Load:
    {
      LoadInst *li = dyn_cast<LoadInst>(&I);
      if (li->isVolatile())
	      return false;

      if ( I.use_begin() == I.use_end() )
      {
        return true;
      }
      
      break;
    }
  
  default: // any other opcode fails (includes stores and branches)
    // we don't know about this case, so conservatively fail!
    return false;
  }
  
  return false;
}

void dce(Module *M)
{
  for(auto f = M->begin(); f!=M->end(); f++)       // loop over functions
  {
    std::set<Instruction*> worklist;

    for(auto bb= f->begin(); bb!=f->end(); bb++)
    {
      // loop over basic blocks
      for(auto i = bb->begin(); i != bb->end(); i++)
      {
        //loop over instructions
        if (isDead(*i)) 
        {
          //add I to a worklist to replace later
          worklist.insert(&*i);
        }	      
      }
    }

    while(worklist.size()>0) 
    {
      // Get the first item 
      Instruction *i = *(worklist.begin());
      // Erase it from worklist
      worklist.erase(i);
      
      if(isDead(*i))
      {
        for(unsigned op=0; op<i->getNumOperands(); op++)
        {
          // Note, op still has one use (in i) so the isDead routine
          // would return false, so we’d better not check that yet.
          // This forces us to check in the if statement above.
          
          
          
          // The operand could be many different things, in 
          // particular constants. Don’t try to delete them
          // unless they are an instruction:
          if ( isa<Instruction>(i->getOperand(op)) ) 
          {
            Instruction *o = dyn_cast<Instruction>(i->getOperand(op));
            worklist.insert(o);
          }
        }
        i->eraseFromParent();
        CSEDead++;
      }        
    }
  }  
}


void simplify(Module* M)
{
  for(auto f = M->begin(); f!=M->end(); f++)       // loop over functions
  {
    for(auto bb= f->begin(); bb!=f->end(); bb++)
    {
      // loop over basic blocks
      for(auto i = bb->begin(); i != bb->end(); i++)
      {
        Value* simplified_inst = SimplifyInstruction(&*i, M->getDataLayout());
        //loop over instructions
        if (simplified_inst!=NULL) 
        {          
          CSESimplify++;
          (*i).replaceAllUsesWith(simplified_inst);
        }	      
      }
    }
  }
}


bool cse_candidate(Instruction &I)
{
  int opcode = I.getOpcode();
  switch(opcode){
  case Instruction::Add:
  case Instruction::FNeg:
  case Instruction::FAdd: 	
  case Instruction::Sub:
  case Instruction::FSub: 	
  case Instruction::Mul:
  case Instruction::FMul: 	
  case Instruction::UDiv:	
  case Instruction::SDiv:	
  case Instruction::FDiv:	
  case Instruction::URem: 	
  case Instruction::SRem: 	
  case Instruction::FRem: 	
  case Instruction::Shl: 	
  case Instruction::LShr: 	
  case Instruction::AShr: 	
  case Instruction::And: 	
  case Instruction::Or: 	
  case Instruction::Xor: 	
  // // case Instruction::Alloca:
  case Instruction::GetElementPtr: 	
  case Instruction::Trunc: 	
  case Instruction::ZExt: 	
  case Instruction::SExt: 	
  case Instruction::FPToUI: 	
  case Instruction::FPToSI: 	
  case Instruction::UIToFP: 	
  case Instruction::SIToFP: 	
  case Instruction::FPTrunc: 	
  case Instruction::FPExt: 	

  case Instruction::PtrToInt: 	
  case Instruction::IntToPtr: 	
  case Instruction::BitCast: 	
  case Instruction::AddrSpaceCast: 	
  case Instruction::ICmp: 	
  // // case Instruction::FCmp: 	
  case Instruction::PHI: 
  case Instruction::Select: 
  case Instruction::ExtractElement: 	
  case Instruction::InsertElement: 

  case Instruction::ShuffleVector: 	
  // case Instruction::ExtractValue: 	
  // case Instruction::InsertValue:     
    return true;        
    break;  
  
  default: // any other opcode fails (includes stores and branches)
    // we don't know about this case, so conservatively fail!
    return false;
  }
}
void cse(Module* M)
{
   // visit all instructions j that are dominated by i
    // if i and j are common subexpression
    //   replace all uses of j with i
    //   erase j
    //   CSE_Basic++
  for(auto f = M->begin(); f!=M->end(); f++)       // loop over functions
  {
    std::set<Instruction*> worklist;
    for(auto bb= f->begin(); bb!=f->end(); bb++)
    {
      // loop over basic blocks
      for(auto i = bb->begin(); i != bb->end(); i++)
      {
        if(cse_candidate(*i))
        {
          auto curr_block_inst = std::next(i);        
          while(curr_block_inst!=bb->end())
          {
            if((*i).getOpcode()==(*curr_block_inst).getOpcode()
                && (*i).getType()==(*curr_block_inst).getType()
                && (*i).getNumOperands()==(*curr_block_inst).getNumOperands())
            {
              bool equal = true;
              for(unsigned op=0; op<i->getNumOperands(); op++)
              {
                if ((*i).getOperand(op) !=  (*curr_block_inst).getOperand(op)) 
                {
                  equal = false;
                  break;
                }
              }
              if(equal)
              {
                (*curr_block_inst).replaceAllUsesWith((Value*)&*i);
                CSEElim++;
              }            
            }
            curr_block_inst++;
          }
          auto dom_child = (BasicBlock*)LLVMFirstDomChild((LLVMBasicBlockRef)&*bb);
          // while(dom_child!=NULL)
          // {
          //   for(auto dom_child_inst=dom_child->begin();dom_child_inst!=dom_child->end();dom_child_inst++)
          //   {              
          //     if((*i).getOpcode()==(*dom_child_inst).getOpcode()
          //       && (*i).getType()==(*dom_child_inst).getType()
          //       && (*i).getNumOperands()==(*dom_child_inst).getNumOperands())
          //     {
          //       bool equal = true;
          //       for(unsigned op=0; op< dom_child_inst->getNumOperands(); op++)
          //       {
          //         if ((*i).getOperand(op) !=  (*dom_child_inst).getOperand(op)) 
          //         {
          //           equal = false;
          //           break;
          //         }
          //       }
          //       if(equal)
          //       {
          //         (*dom_child_inst).replaceAllUsesWith((Value*)&*i);
          //         CSEElim++;
          //       }            
          //     }              
          //   }
          //   dom_child = (BasicBlock*)LLVMNextDomChild((LLVMBasicBlockRef)&*bb,(LLVMBasicBlockRef)dom_child);
          // }
        }  
      }
    }
  }
}

void load_cse(Module* M)
{
  std::set<Instruction*> worklist;
  // for each load, L:
  //   for each instruction, R, that follows L in its basic block:
  //     if R is load && R is not volatile and R’s load address is the same as L && TypeOf(R)==TypeOf(L):
  //       Replace all uses of R with L
  //       Erase R
  //       CSE_RLoad++
  //     if R is a store:
  //       break (stop considering load L, move on)
  for(auto f = M->begin(); f!=M->end(); f++)       // loop over functions
  {
    for(auto bb= f->begin(); bb!=f->end(); bb++)
    {
      // loop over basic blocks
      for(auto i = bb->begin(); i != bb->end(); i++)
      {           
        if(i->getOpcode() == Instruction::Load)
        {
          auto subsequent_inst = std::next(i);
          while(subsequent_inst!=bb->end())
          {
            
            if((*subsequent_inst).getOpcode() == Instruction::Load
              && ! (dyn_cast<LoadInst>(&*subsequent_inst))->isVolatile()
              && i->getOperand(0) == subsequent_inst->getOperand(0)
              && i->getType() == subsequent_inst->getType() )
            {
              (*subsequent_inst).replaceAllUsesWith((Value*)&*i);
              worklist.insert(&*subsequent_inst);
              //(*subsequent_inst).eraseFromParent();
              CSELdElim++;

            }
            else if((*subsequent_inst).getOpcode() == Instruction::Store)
            {
              break;
            } 
            subsequent_inst++;     
          }
        }            
      }
      while(worklist.size()>0) 
      {
        // Get the first item 
        Instruction *i = *(worklist.begin());
        // Erase it from worklist
        worklist.erase(i);        
        i->eraseFromParent();               
      }
    }
  }
}

bool has_sideeffect(Instruction &I)
{
  int opcode = I.getOpcode();
  switch(opcode){
  case Instruction::Add:
  case Instruction::FNeg:
  case Instruction::FAdd: 	
  case Instruction::Sub:
  case Instruction::FSub: 	
  case Instruction::Mul:
  case Instruction::FMul: 	
  case Instruction::UDiv:	
  case Instruction::SDiv:	
  case Instruction::FDiv:	
  case Instruction::URem: 	
  case Instruction::SRem: 	
  case Instruction::FRem: 	
  case Instruction::Shl: 	
  case Instruction::LShr: 	
  case Instruction::AShr: 	
  case Instruction::And: 	
  case Instruction::Or: 	
  case Instruction::Xor: 	
  // case Instruction::Alloca:
  case Instruction::GetElementPtr: 	
  case Instruction::Trunc: 	
  case Instruction::ZExt: 	
  case Instruction::SExt: 	
  case Instruction::FPToUI: 	
  case Instruction::FPToSI: 	
  case Instruction::UIToFP: 	
  case Instruction::SIToFP: 	
  case Instruction::FPTrunc: 	
  case Instruction::FPExt: 	
  case Instruction::PtrToInt: 	
  case Instruction::IntToPtr: 	
  case Instruction::BitCast: 	
  case Instruction::AddrSpaceCast: 	
  case Instruction::ICmp: 	
  // case Instruction::FCmp: 	
  case Instruction::PHI: 
  case Instruction::Select: 
  case Instruction::ExtractElement: 	
  case Instruction::InsertElement: 	
  case Instruction::ShuffleVector: 	
  case Instruction::ExtractValue: 	
  case Instruction::InsertValue:     
    return false;        
    break;  
  
  default: // any other opcode fails (includes stores and branches)
    // we don't know about this case, so conservatively fail!
    return true;
  }
}

void store_cse(Module* M)
{
  std::set<Instruction*> worklist;
  // for each Store, S:
  //   for each instruction, R, that follows S in its basic block:
  //     if R is a load && R is not volatile and R’s load address is the same as S and TypeOf(R)==TypeOf(S’s value operand):
  //       Replace all uses of R with S’s data operand
  //       Erase R
  //       CSE_Store2Load++
  //       continue to next instruction
  //     if R is a store && R is storing to the same address && S is not volatile && R and S value operands are the same type:
  //       Erase S
  //       CSE_RStore++
  //       break (and move to next Store)
  //     if R is a load or a store (or any instruction with a side-effect):
  //       break (and move to next Store)

  for(auto f = M->begin(); f!=M->end(); f++)       // loop over functions
  {
    for(auto bb= f->begin(); bb!=f->end(); bb++)
    {
      // loop over basic blocks
      for(auto i = bb->begin(); i != bb->end(); i++)
      {
        // (*i).print(errs(),true);
        // printf("\n"); 
        if (i->getOpcode() == Instruction::Store) 
        {          
          auto subsequent_inst = std::next(i);
          while(subsequent_inst!=bb->end())
          {
            // printf("\t");
            // subsequent_inst->print(errs(),true);
            // printf("\n");
            if((*subsequent_inst).getOpcode() == Instruction::Load
              && ! (dyn_cast<LoadInst>(&*subsequent_inst))->isVolatile()
              && i->getOperand(1) == subsequent_inst->getOperand(0)
              && i->getOperand(0)->getType() == subsequent_inst->getType() )
            {
              (*subsequent_inst).replaceAllUsesWith(i->getOperand(0));
              worklist.insert(&*subsequent_inst);
              CSELdStElim++;
              subsequent_inst++;    
              continue;
            }
             if((*subsequent_inst).getOpcode() == Instruction::Store              
              && i->getOperand(1) == subsequent_inst->getOperand(1)
              && ! (dyn_cast<StoreInst>(&*subsequent_inst))->isVolatile()
              && i->getType() == subsequent_inst->getType() )
            {              
              worklist.insert(&*i);
              CSERStElim++;
              break;
            }
            if(has_sideeffect(*subsequent_inst))
            {
              break;
            }
            subsequent_inst++;    
          }          
        }	      
      }
      while(worklist.size()>0) 
      {
        // Get the first item 
        Instruction *i = *(worklist.begin());
        // Erase it from worklist
        worklist.erase(i);        
        i->eraseFromParent();               
      }
    }
  }
}

void LLVMCommonSubexpressionElimination_Cpp(Module *M)
{
  // for each function, f:
  //   FunctionCSE(f);  
  dce(M);
  simplify(M);
  cse(M);
  load_cse(M);
  store_cse(M);
  
 
  // print out summary of results
  fprintf(stderr,"CSE_Dead......%d\n", CSEDead);
  fprintf(stderr,"CSE_Basic.....%d\n", CSEElim);
  fprintf(stderr,"CSE_Simplify..%d\n", CSESimplify);
  fprintf(stderr,"CSE_RLd.......%d\n", CSELdElim);
  fprintf(stderr,"CSE_RSt.......%d\n", CSERStElim);
  fprintf(stderr,"CSE_LdSt......%d\n", CSELdStElim);  
}

