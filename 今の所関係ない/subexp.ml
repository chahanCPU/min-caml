open Asm

let rec g env =
  | Let((x, t), Add(y, z), e) -> 
      if M.mem (Add(y, z)) env then
        Let((x, t), Mov(find (Add(y, z) env)), g env e)
      else
        let env' = M.add (Add(z, y)) 