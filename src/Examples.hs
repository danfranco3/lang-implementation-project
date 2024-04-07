{--------------------------------------
  Fun: a minimal functional language
  -------------------------------------
 
  This module contains some example programs.
  Pedro Vasconcelos, 2008--2009.
-}
module Examples where
import Fun
import SECD1

-- simple computations
ex1 = (Snd (Pair (Const 42) (Const 5)) :+ Const 23) :* Const 5

ex1'= Const 5 :* (Const 42 :+ Const 23) 

-- the identity function
ex2 = Lambda "x" (Var "x")

-- the sucessor function
ex3 = Lambda "x" (Var "x" :+ Const 1)

-- one function between two integers
ex4 = Lambda "x" 
      (Lambda "y"
       (IfZero (Var "x" :- Var "y") 
        (Var "y") (Var "x")))
                       
-- an example that builds a closure with free vars
ex5 = Let "x" (Const 42) (Lambda "y" (Var "x" :+ Var "y"))

ex5b = Let "x" (Const 23) (Lambda "y" (Var "x" :+ Var "y"))

-- a recursive function (factorial)
ex6 = Fix 
      (Lambda "f" 
       (Lambda "n"
        (IfZero (Var "n")
         (Const 1)
         ((App (Var "f") (Var "n" :- Const 1)) :* Var "n")
        )))


-- compute the factorial of 10
ex7 = App ex6 (Const 10)

-- factorial of a negative number (diverges)
ex8 = App ex6  (Const (-1))

-- recursive sum 0^2 + 1^2 + 2^2 + ... + n^2
ex9 = Fix 
      (Lambda "f"
       (Lambda "n"
         (IfZero (Var "n")
          (Const 0)
           ((Var "n" :* Var "n") :+ 
            App (Var "f") (Var "n" :- Const 1)))))

ex10 = Head(List (Const 4) (List (Const 3) Nil))

ex11 = Tail(Tail(List (Const 4) (List (Const 3) Nil)))
 
ex12 = IfZero (Null (List (Const 1) Nil)) (Const 1) (Const 2) -- Should output 2

ex13 = IfZero (Null Nil) (Const 1) (Const 2) -- Should output 1

-- buggy expressions (type errors)

bug1 = Const 42 :+ Lambda "x" (Var "x")

bug2 = App (Const 42) (Const 1)


