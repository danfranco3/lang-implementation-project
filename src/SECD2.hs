{-# LANGUAGE DeriveFunctor #-}
{- -----------------------------------
   Fun: a minimal functional language
   -----------------------------------
   A byte-code compiler for a SECD-like virtual machine.
   
   Pedro Vasconcelos, 2008--2020.
 -}
module SECD2 where
import           Fun
import           Data.List (elemIndex)
import           Data.Map (Map)
import qualified Data.Map as Map
import           Control.Monad.State

-----------------------------------------------------------------
-- SECD machine definitions
-----------------------------------------------------------------

-- pseudo instructions parameterized by label type
data Instr l = HALT            -- finished
             | LDC Int         -- load constant
             | LD Int          -- load variable
             | ADD             -- addition
             | SUB             -- subtraction
             | MUL             -- multiplication
             | SEL l l         -- select zero/non-zero
             | LDF l           -- load a closure
             | LDRF l          -- load a recursive closure
             | AP              -- apply
             | RTN             -- return 
             | JOIN            -- close branch
             deriving (Show, Functor)

-- symbolic labels are just strings
type Label = String

-- a block of (symbolic code) 
type Block = [Instr Label]

-- a State monad for generating fresh labels and storing code blocks
type CodeGen = State (Map Label Block)

-- add a new code block segment
-- returns the new generated label
newBlock :: Block -> CodeGen Label
newBlock code = do
  table <- get
  let label = "l" ++ show (Map.size table) 
  put (Map.insert label code table)
  return label



-- compile a Fun term into SECD code
compile :: Term -> [Ident] -> CodeGen Block
compile (Var x) sym 
    = case elemIndex x sym of
        Nothing -> error ("free variable: " ++ show x)
        Just k ->  return [LD k]
-- "elemIndex x xs" 
-- gives the index of first occurence of x in xs or Nothing 

compile (Lambda x e) sym 
  = do code <- compile e (x:sym) 
       label <- newBlock (code++[RTN])
       return [LDF label]

-- compile a recursive function
compile (Fix (Lambda f (Lambda x e1))) sym
  = do code <- compile e1 (x:f:sym) 
       label <- newBlock (code++[RTN])
       return [LDRF label]

compile (App e1 e2) sym 
  = do code1 <- compile e1 sym 
       code2 <- compile e2 sym 
       return (code1 ++ code2 ++ [AP])
       
compile (Const n) sym
  = return [LDC n]

compile (e1 :+ e2) sym 
  = do code1 <- compile e1 sym 
       code2 <- compile e2 sym 
       return (code1++code2 ++ [ADD])

compile (e1 :- e2) sym 
  = do code1 <- compile e1 sym
       code2 <- compile e2 sym 
       return (code1 ++ code2 ++ [SUB])

compile (e1 :* e2) sym 
  = do code1 <- compile e1 sym 
       code2 <- compile e2 sym 
       return (code1 ++ code2 ++ [MUL])

compile (IfZero e1 e2 e3) sym
  = do code1 <- compile e1 sym  
       code2 <- compile e2 sym
       code3 <- compile e3 sym
       ltrue <- newBlock (code2 ++ [JOIN])
       lfalse<- newBlock (code3 ++ [JOIN])
       return (code1 ++ [SEL ltrue lfalse])

compile (Let x e1 e2) sym
    = compile (App (Lambda x e2) e1) sym
 

-- compile a top-level expression
compileExpr :: Term -> CodeGen Block
compileExpr e = do
  code <- compile e [] 
  return (code ++ [HALT])

-- run a code generator
-- entry point begins at label "_main"
-- note: it should be the first label in sorting order
runCodeGen :: CodeGen Block -> Map Label Block
runCodeGen cgen =  Map.insert "_main" code0 labels  
  where (code0, labels) = runState cgen Map.empty


-----------------------------------------------------------------------------
-- resolving labels
-----------------------------------------------------------------------------
-- code addresses are simple integers
type Addr = Int

-- assign each label to a bytecode address
resolveLabels :: Map Label Block -> Map Label Addr
resolveLabels table
  = Map.fromList (zip labels addrs)
  where
    labels = Map.keys table
    sizes = map (\code -> sum (map sizeof code)) (Map.elems table)
    addrs = scanl (+) 0 sizes

-- flatten labeled blocks into a list of instructions
flattenCode :: Map Label Block -> [Instr Addr]
flattenCode table
  = map patch $ concat (Map.elems table)
  where addrs = resolveLabels table
        patch = fmap (\l -> Map.findWithDefault undefined l addrs)


----------------------------------------------------------------------------
-- assemblying into bytecodes
----------------------------------------------------------------------------
-- bytecodes are just fixed size integers
type Bytecode = Int

-- "assemble" a single instruction to bytecode
asmInstr :: Instr Addr -> [Bytecode]
asmInstr HALT        = [0]
asmInstr (LDC n)     = [1, n]
asmInstr (LD n)      = [2, n]
asmInstr ADD         = [3]
asmInstr SUB         = [4]
asmInstr MUL         = [5]
asmInstr (SEL l1 l2) = [6, l1, l2]
asmInstr (LDF l)     = [7, l]
asmInstr (LDRF l)    = [8, l]
asmInstr AP          = [9]
asmInstr RTN         = [10]
asmInstr JOIN        = [11]

-- assemble a code block  
asmCode :: [Instr Addr] ->  [Bytecode]
asmCode = concatMap asmInstr

-- number of bytecodes for each instruction
sizeof :: Instr l -> Int
sizeof instr = case instr of
  SEL _ _ -> 3
  LD _ -> 2
  LDC _ -> 2
  LDF _ -> 2
  LDRF _ -> 2
  _ -> 1


-------------------------------------------------------------------
-- putting it all together
-------------------------------------------------------------------

-- generate bytecode for a closed term
compileBytecode :: Term -> [Bytecode]
compileBytecode
  = asmCode . flattenCode . runCodeGen  . compileExpr

-- write bytecode one item per line
showBytecode :: [Bytecode] -> String
showBytecode code = unlines $ map show code

-- compile a closed term to a bytecode file
compileToFile :: FilePath -> Term -> IO ()
compileToFile path expr
  = writeFile path $ showBytecode $ compileBytecode expr
  
