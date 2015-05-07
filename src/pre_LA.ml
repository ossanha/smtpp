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

(* Pretty printer for the AST *)
open Format
open Lexing
open Ast
open Pp
;;

exception TermError of string;;

let pre_LA_is_assert cmd =
  match cmd.command_desc with
  | CmdAssert t -> true
  | _ -> false
;;

let pre_LA_is_decl_def cmd =
  match cmd.command_desc with
  | CmdAssert _
  | CmdCheckSat
  | CmdExit -> false
  | _ -> true
;;
    
let pre_LA_is_check_exit cmd =
  match cmd.command_desc with
  | CmdCheckSat
  | CmdExit -> true
  | _ -> false
;;   

let rec pre_LA_replace_binds_term vbindings term =
  match vbindings, term.term_desc with
  | [], _ -> term
  | _ , TermLetTerm (vbindings_int, t) -> pre_LA_replace_binds_term vbindings (pre_LA_replace_binds_term vbindings_int t)
  | _ , TermSpecConstant _ -> term

  | (vb::vbs), TermQualIdentifier qid ->
    (match qid.qual_identifier_desc with
     | QualIdentifierIdentifier id -> 
       (match id.id_desc with
       | IdSymbol symbol ->
         let vbind_desc = vb.var_binding_desc in 
         (match vbind_desc with
          | VarBinding (symb, term_b) ->  (match symb.symbol_desc, symbol.symbol_desc with
                                           | SimpleSymbol s1, SimpleSymbol s2
                                           | QuotedSymbol s1, QuotedSymbol s2
                                           | SimpleSymbol s1, QuotedSymbol s2
                                           | QuotedSymbol s1, SimpleSymbol s2 ->
                                             if (s1 = s2) then term_b else pre_LA_replace_binds_term vbs term;)
                                          )
       | IdUnderscore (symbol, indexes) -> 
         let vbind_desc = vb.var_binding_desc in 
         (match vbind_desc with
          | VarBinding (symb, term_b) ->  (match symb.symbol_desc, symbol.symbol_desc with
                                           | SimpleSymbol s1, SimpleSymbol s2
                                           | QuotedSymbol s1, QuotedSymbol s2
                                           | SimpleSymbol s1, QuotedSymbol s2
                                           | QuotedSymbol s1, SimpleSymbol s2 ->
                                             if (s1 = s2) then term_b else pre_LA_replace_binds_term vbs term;)
                                          )
          )
     | QualIdentifierAs (id, sort) -> term)
  
  | _ , TermQualIdentifierTerms (id, terms) -> { term_desc = TermQualIdentifierTerms (id, (List.map (fun t1 -> pre_LA_replace_binds_term vbindings t1) terms)); 
                                                 term_loc = term.term_loc;}
  | vbinds, TermForallTerm (_, _) -> term
  | vbinds, TermExistsTerm (_, _) -> term
  | vbinds, TermAnnotatedTerm (_, _) -> term                                                 
;;

let pre_LA_subs_let_expr_term t =
  match t.term_desc with
  | TermLetTerm (vbindings, term) -> pre_LA_replace_binds_term vbindings term
  | TermSpecConstant _
  | TermQualIdentifier _
  | TermQualIdentifierTerms (_, _)
  | TermForallTerm (_, _)
  | TermExistsTerm (_, _) 
  | TermAnnotatedTerm (_, _) -> t
;;

let pre_LA_subs_let_expr cmd =
  match cmd.command_desc with
  | CmdAssert t -> {command_desc = CmdAssert (pre_LA_subs_let_expr_term t);
                    command_loc = cmd.command_loc ;}
  | _ -> raise (TermError "No Assert command Error")
;;
    

let pre_LA fmt (s: Ast.script) =
  let s_pre = (List.filter pre_LA_is_decl_def s.script_commands) in
  let s_post = (List.filter pre_LA_is_check_exit s.script_commands) in 
               
  let s_assert = (List.filter pre_LA_is_assert s.script_commands) in
  
  
  let s_assert_1 = (List.map pre_LA_subs_let_expr s_assert) in
  
  
  
  
  let s_new = {script_commands = (List.append s_pre (List.append s_assert_1 s_post)) ; 
               script_loc = s.script_loc;} in
          

  pp fmt s_new;


;;

