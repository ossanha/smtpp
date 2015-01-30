(**************************************************************************)
(*  Copyright (c) 2015 Richard Bonichon <richard.bonichon@gmail.com>      *)
(*                                                                        *)
(*  Permission to use, copy, modify, and distribute this software for any  *)
(*  purpose with or without fee is hereby granted, provided that the above  *)
(*  copyright notice and this permission notice appear in all copies.     *)
(*                                                                        *)
(*  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES  *)
(*  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF      *)
(*  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR  *)
(*  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES  *)
(*  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN  *)
(*  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF  *)
(*  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.        *)
(*                                                                        *)
(**************************************************************************)

{
  open Format
  open Lexing
  open Parser
  ;;

  let reserved = [
      "as"                    , AS;
      "let"                   , LET;
      "forall"                , FORALL;
      "exists"                , EXISTS;
      "set-logic"             , SETLOGIC;
      "set-option"            , SETOPTION;
      "get-option"            , GETOPTION;
      "set-info"              , SETINFO;
      "get-info"              , GETINFO;
      "declare-sort"          , DECLARESORT;
      "declare-fun"           , DECLAREFUN;
      "define-fun"            , DEFINEFUN;
      "define-fun-rec"        , DEFINEFUNREC;
      "declare-const"         , DECLARECONST;
      "push"                  , PUSH;
      "pop"                   , POP;
      "assert"                , ASSERT;
      "check-sat"             , CHECKSAT;
      "get-assertions"        , GETASSERTIONS;
      "get-proof"             , GETPROOF;
      "get-unsat-core"        , GETUNSATCORE;
      "get-value"             , GETVALUE;
      "get-assignment"        , GETASSIGNMENT;
      "get-model"             , GETMODEL;
      "get-unsat-assumptions" , GETUNSATASSUMPTIONS;
      "exit"                  , EXIT;
      "echo"                  , ECHO;
      "reset"                 , RESET;
      "reset-assertions"      , RESETASSERTIONS;
      "lambda"                , LAMBDA;
      "par"                   , PAR;
      "!"                     , BANG;
      "_"                     , UNDERSCORE;
      "true"                  , BOOL(true);
      "false"                 , BOOL(false);
      "meta-info"             , METAINFO;
  ];;

  let reserved_table =
    let len = List.length reserved in
    let h = Hashtbl.create len in
    List.iter
      (fun (s, k) -> Hashtbl.add h s k ) reserved;
    h
  ;;

(* To buffer string literals *)

let string_buffer = Buffer.create 256

let reset_string_buffer () =
  Buffer.reset string_buffer

let store_string_char c = Buffer.add_char string_buffer c

let get_stored_string () =
  let s = Buffer.contents string_buffer in
  reset_string_buffer ();
  s

(* To store the position of the beginning of a string and comment *)
let string_start_loc = ref Locations.none;;

let update_loc lexbuf file line absolute chars =
  let pos = lexbuf.lex_curr_p in
  let new_file = match file with
                 | None -> pos.pos_fname
                 | Some s -> s
  in
  lexbuf.lex_curr_p <- { pos with
    pos_fname = new_file;
    pos_lnum = if absolute then line else pos.pos_lnum + line;
    pos_bol = pos.pos_cnum - chars;
  }
;;

  exception LexError of string ;;

}

(* Some regular expressions *)
let newline = ('\010' | '\013' | "\013\010")
let space = [' ' '\t' '\r']
let digit = ['0'-'9']
let numeral = ('0' | ['1'-'9'] digit*)
let hexadigit = (digit | ['a'-'f'])
let lower = ['a'-'z']
let upper = ['A'-'Z']
let other = ['~' '!' '@' '$' '%' '^' '&' '*' '_' '-' '+' '=' '<' '>' '.' '?' '/']
let startchar= (lower | upper | other)

rule token = parse
  | newline   { Lexing.new_line lexbuf; token lexbuf }
  | space+    { token lexbuf }
  | ';'       { comment lexbuf; (* See the comment rule below  *)
                Lexing.new_line lexbuf;
                token lexbuf }
  | '('       { LPAREN }
  | ')'       { RPAREN }
  | numeral   { NUMERAL(int_of_string (Lexing.lexeme lexbuf)) }
  | "#b" (['0'-'1']+ as s)
              { BINARY(s) }
  | "#x" (hexadigit+ as s) { HEXADECIMAL(s) }
  | numeral '.' digit*
              { DECIMAL(Lexing.lexeme lexbuf) }
  | "\""
      { reset_string_buffer();
        let string_start = lexbuf.lex_start_p in
        string_start_loc := Locations.none;
        string lexbuf;
        lexbuf.lex_start_p <- string_start;
        STRING (get_stored_string()) }
  | ':' (startchar+ as s) { KEYWORD s }
  | startchar (startchar | digit)*
      {
        let s = Lexing.lexeme lexbuf in
        try Hashtbl.find reserved_table s
        with Not_found -> SYMBOL s
      }
  | eof       { EOF }
  | _
      { let msg = sprintf "@[Bad character %c@]" (Lexing.lexeme_char lexbuf 0) in
        raise (LexError msg);
      }

and string = parse
            | "\"\""
      { store_string_char '"';
                string lexbuf;
              }
  | '"'
      { () }
  | '\\' newline ([' ' '\t'] * as space)
      { update_loc lexbuf None 1 false (String.length space);
        string lexbuf
      }
  | eof
      { raise Not_found }
  | _
      { store_string_char (Lexing.lexeme_char lexbuf 0);
        string lexbuf }

and comment = parse
| newline
    { () }
| eof
    { Format.eprintf "Warning: unterminated comment@." }
| _
    { comment lexbuf }
