let rec f _ = f () in
(Array.make 1 f).(0) <- f
