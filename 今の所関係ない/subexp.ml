open Asm

let rec g env =
  | Let((x, t), exp, e) ->
      let exp' = g' env exp in
      if then

      else
        Let((x, t), exp', g (M.add .... env) e)
  | Let((x, t), Add(y, z), e) -> 
      if M.mem (Add(y, z)) env then
        Let((x, t), Mov(find (Add(y, z) env)), g env e)
      else
        let env' = M.add (Add(z, y)) 