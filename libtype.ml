open Type

let extenv =
  M.add_list 
    [("print_char", Fun([Int], Unit));
     ("print_int", Fun([Int], Unit));
     ("abs_float", Fun([Float], Float)); 
     ("sqrt", Fun([Float], Float)); 
     ("int_of_float", Fun([Float], Int)); 
     ("truncate", Fun([Float], Int)); 
     ("float_of_int", Fun([Int], Float)); 
     ("cos", Fun([Float], Float));
     ("sin", Fun([Float], Float));
     ("tan", Fun([Float], Float));
     ("atan", Fun([Float], Float));
     ("print_newline", Fun([Unit], Unit));
     ("read_int", Fun([Unit], Int));
     ("read_float", Fun([Unit], Float))
     (* ("create_array", Fun([Int; ])) *)
     (* ("not", Fun([Bool], Bool));
     ("xor", Fun([Bool; Bool], Bool));
     ("fequal", Fun([Float; Float], Bool));
     ("fless", Fun([Float; Float], Bool));
     ("fispos", Fun([Float], Bool));
     ("fisneg", Fun([Float], Bool));
     ("fiszero", Fun([Float], Bool));
     ("fhalf", Fun([Float], Float));
     ("fsqr", Fun([Float], Float));
     ("fneg", Fun([Float], Float));
     ("floor", Fun([Float], Float)) *)
     ] 
    M.empty
