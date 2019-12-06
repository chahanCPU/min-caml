let rec f x = 
  (print_int (int_of_float ((sin x) *. 100.0));
   print_newline ();
   print_int (int_of_float ((cos x) *. 100.0));
   print_newline ())  
in
f 3.14; 
f 10.0; 
f 21.0; 
f 34.0
