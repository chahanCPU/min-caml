let rec sum n =
  let rec inner_sum m ans =
    if m = n then ans 
    else inner_sum (m+1) (ans+m+1)
  in inner_sum 0 0
in sum 100
