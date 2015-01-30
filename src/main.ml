(* Default message to the user *)
let umsg = "Usage: smtpoly <file>";;

(* Should we reprint the AST ? *)
let reprint = ref false ;;

(*
 * Specification of the known command-line switches of this program.
 * See OCaml's Arg module.
*)
let rec argspec =
  [
  "--help", Arg.Unit print_usage ,
  " print this option list and exits";
  "-help", Arg.Unit print_usage ,
  " print this option list and exits";
  "-reprint", Arg.Set reprint,
  " reprints the SMT AST read";
  "-debug", Arg.Unit (fun () -> Config.set_debug true),
  " enables debug messages";
  "-multi", Arg.Unit (fun () -> Config.set_pushpop true),
  " generates independent SMTLIB scripts for each (check-sat) command";
  "-disable-success", Arg.Unit (fun () -> Config.set_smtsuccess(false)),
  " do not print success while parsing";
]

and print_usage () =
  Arg.usage (Arg.align argspec) umsg;
  exit 0;
;;

open Lexing;;
open Config ;;

let report_error l  =
  let pos = lexeme_start_p l in
  let o = pos.pos_cnum - pos.pos_bol in
  Format.eprintf "Error in file %s, line %d, column %d@."
                 pos.pos_fname pos.pos_lnum o;
;;

let lex_file () =
  try
    Arg.parse argspec set_file umsg;
    let fname = Config.get_file () in
    let chan =
      match fname with
      | "-" -> stdin
      | file -> open_in file
    in
    let lexbuf = Lexing.from_channel chan in
    lexbuf.Lexing.lex_curr_p <- {
      Lexing.pos_fname = fname;
      Lexing.pos_lnum = 1;
      Lexing.pos_bol = 0;
      Lexing.pos_cnum = 0;
    };
    (lexbuf, fun () -> close_in chan)
  with
    | Not_found -> exit 2;
;;

let main () =
  let (lexbuf, _close) = lex_file () in
  try
     let script = Parser.script Lexer.token lexbuf in
     if Config.get_pushpop () then Pushpop.apply script;
     if !reprint then Pp.pp_tofile "reprinted_ast.smt2" script;
  with
  | Parsing.Parse_error  ->
     Format.eprintf "Parse error:@.";
     report_error lexbuf
;;

main ()
