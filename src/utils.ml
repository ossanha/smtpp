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

module StringMap =
  Map.Make(
      struct
        type t = string
        let compare = String.compare
      end
)
;;

module StringSet = struct
  include Set.Make(
              struct
                type t = string
                let compare = String.compare
              end )
end
;;


let mk_header fmt s =
  let slen = String.length s in
  let sub_hdr = String.make slen '=' in
  Format.fprintf fmt "@[<v 0>%s@ %s@ @]" s sub_hdr
;;

let debug s =
  if Config.get_debug () then
    Format.printf "@[<hov 1>[debug] %s@]@." s
;;

let sfprintf fmt =
  let b = Buffer.create 20 in
  let return fmt = Format.pp_print_flush fmt (); Buffer.contents b in
  Format.kfprintf return (Format.formatter_of_buffer b) fmt
;;

let default_opt v opt =
  match opt with
  | None -> v
  | Some v' -> v'
;;
  
let third (_, _, z) = z ;;
