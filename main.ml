let limit = ref 1000

let rec iter n e = (* 最適化処理をくりかえす (caml2html: main_iter) *)
  Format.eprintf "iteration %d@." n;
  if n = 0 then e else
  let e' = Elim.f (ConstFold.f (Inline.f (Assoc.f (Beta.f e)))) in
  if e = e' then e else
  iter (n - 1) e'

let lexbuf debugchan outchan l lib = (* バッファをコンパイルしてチャンネルへ出力する (caml2html: main_lexbuf) *)
  Id.counter := 0;
  Typing.extenv := M.empty;
  let hoge1 = Parser.exp Lexer.token l in
  let hogelib = Parser.exp Lexer.token lib in
  let hoge11 = CatLib.f hoge1 hogelib in
  let hoge2 = Typing.f hoge11 in
  let hoge3 = KNormal.f hoge2 in
  let hoge4 = Alpha.f hoge3 in
  (* let hoge = CommonSubexpressionElimination.f hoge4 in *)
  let hoge5 = iter !limit hoge4 in
  let hoge6 = Closure.f hoge5 in
  let hoge7 = Virtual.f hoge6 in
  let hoge8 = Simm.f hoge7 in
  let hoge9 = RegAlloc.f hoge8 in
  let hoge10 = Emit.f outchan hoge9 in
  Printf.fprintf debugchan "<****** Parser ******>\n"; OutputSyntax.output_t debugchan hoge1; Printf.fprintf debugchan "\n\n";
  Printf.fprintf debugchan "<****** CatLib ******>\n"; OutputSyntax.output_t debugchan hoge11; Printf.fprintf debugchan "\n\n";
  Printf.fprintf debugchan "<****** Typing ******>\n"; OutputSyntax.output_t debugchan hoge2; Printf.fprintf debugchan "\n\n";
  Printf.fprintf debugchan "<****** KNormal ******>\n"; OutputKNormal.output_t debugchan hoge3; Printf.fprintf debugchan "\n\n";
  Printf.fprintf debugchan "<****** Alpha ******>\n"; OutputKNormal.output_t debugchan hoge4; Printf.fprintf debugchan "\n\n";
  (* Printf.fprintf debugchan "<****** CommonSubexpressionElimination ******>\n"; OutputKNormal.output_t debugchan hoge; Printf.fprintf debugchan "\n\n"; *)
  Printf.fprintf debugchan "<****** iter ******>\n"; OutputKNormal.output_t debugchan hoge5; Printf.fprintf debugchan "\n\n";
  Printf.fprintf debugchan "<****** Closure ******>\n"; OutputClosure.output_prog debugchan hoge6; Printf.fprintf debugchan "\n\n";
  Printf.fprintf debugchan "<****** Virtual ******>\n"; OutputAsm.output_prog debugchan hoge7; Printf.fprintf debugchan "\n\n";
  Printf.fprintf debugchan "<****** Simm ******>\n"; OutputAsm.output_prog debugchan hoge8; Printf.fprintf debugchan "\n\n";
  Printf.fprintf debugchan "<****** RegAlloc ******>\n"; OutputAsm.output_prog debugchan hoge9;
  hoge10

let string s = (* 文字列をコンパイルして標準出力に表示する (caml2html: main_string) *)
  let libchan = open_in "libmincaml.ml" in
  try
    lexbuf stdout stdout (Lexing.from_string s) (Lexing.from_channel libchan);
    close_in libchan
  with e ->
    (Printf.fprintf stdout "%s\n" (Printexc.to_string e);    (* debugchanで良いの? *)
     close_in libchan)

let file f = (* ファイルをコンパイルしてファイルに出力する (caml2html: main_file) *)
  let inchan = open_in (f ^ ".ml") in
  let libchan = open_in "libmincaml.ml" in
  let debugchan = open_out (f ^ ".txt") in    (* 本当に.txtで良いの? *)
  let outchan = open_out (f ^ ".s") in
  try
    lexbuf debugchan outchan (Lexing.from_channel inchan) (Lexing.from_channel libchan);    (* debugchanで良いの? *)
    close_in inchan;
    close_in libchan;
    close_out debugchan;
    close_out outchan
  with e -> 
    (Printf.fprintf debugchan "%s\n" (Printexc.to_string e);
     close_in inchan; 
     close_in libchan; 
     close_out debugchan; 
     close_out outchan)

let () = (* ここからコンパイラの実行が開始される (caml2html: main_entry) *)
  let files = ref [] in
  (* globals.ml（グローバル変数(ExtArrayとか)を宣言）とかlib.ml（外部関数の定義）とかを取り込むか ←別にファイル分けてもわけなくてもよさそうよね
     オプションで選択したいね、Makefileでもいいけど *) (* こうすると、外部からコンパイルできなくて不便 *)
  (* asm.mlにすべて命令を対応させれば、lib.mlだけでlib.sみたいなのは不要になる?????
     そうした方が、外部変数呼出がなくなってスタックの確保等がなくなり、
     インライン化とかされてレジスタ割当も上手く行きそう *)
  Arg.parse
    [("-inline", Arg.Int(fun i -> Inline.threshold := i), "maximum size of functions inlined");
     ("-iter", Arg.Int(fun i -> limit := i), "maximum number of optimizations iterated")]
    (fun s -> files := !files @ [s])
    ("Min-Caml Compiler\n" ^  (* どうやったらこれが出力される? *)
     Printf.sprintf "usage: %s [-inline m] [-iter n] ...filenames without \".ml\"..." Sys.argv.(0));
  List.iter
    (fun f -> ignore (file f))
    !files
