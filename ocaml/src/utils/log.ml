(*
    This file is part of BinCAT.
    Copyright 2014-2017 - Airbus Group

    BinCAT is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or (at your
    option) any later version.

    BinCAT is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with BinCAT.  If not, see <http://www.gnu.org/licenses/>.
*)

(** log facilities *)

(** fid of the log file *)
let logfid = ref stdout

(** open the given log file *)
let init fname =
  logfid := open_out fname

(** dump a message provided by the analysis step *)
let from_analysis msg = Printf.fprintf (!logfid) "[analysis] %s\n" msg; flush !logfid

(** dump a message produced by the decoding step *)
let from_decoder msg = Printf.fprintf (!logfid) "[decoding] %s\n" msg; flush !logfid
						   
(** dump a message generated by then configuration parsing step *)
let from_config msg = Printf.fprintf !logfid "[config] %s\n" msg; flush !logfid

(** dump the string on the log file *)
let stdout_buf = ref ""
let open_stdout () = stdout_buf := ""
let print msg = stdout_buf := !stdout_buf ^ msg
let dump_stdout () = Printf.fprintf !logfid "%s\n" !stdout_buf; flush !logfid
    
(** dump debug message *)
let debug_lvl msg lvl =
    if !Config.verbose >= lvl then
        Printf.fprintf !logfid "[debug%d] %s\n" lvl msg; flush !logfid

let debug msg = debug_lvl msg 3
								   
(** close the log file *)
let close () = close_out !logfid

let error msg =
  Printexc.print_raw_backtrace !logfid (Printexc.get_callstack 100);
  Printf.fprintf !logfid "fatal error: %s\n" msg;
  flush !logfid;
  flush stdout;
  raise (Exceptions.Error msg)


module Make(Modname: sig val name : string end) = struct
  let modname = Modname.name
  let _loglvl = ref None
  let loglevel = fun () ->
    match !_loglvl with
    | Some lvl -> lvl
    | None -> let lvl = 
		try Hashtbl.find Config.module_loglevel modname
		with Not_found -> !Config.loglevel in
	      _loglvl := Some lvl;
	      lvl
	
  let debug fmsg = 
    if loglevel () >= 4 then
	let msg = fmsg Printf.sprintf in
	Printf.fprintf !logfid  "[DEBUG] %s: %s\n" modname msg;
	flush !logfid
  let info fmsg = 
    if loglevel () >= 3 then
	let msg = fmsg Printf.sprintf in
	Printf.fprintf !logfid  "[INFO]  %s: %s\n" modname msg;
	flush !logfid
  let warn fmsg = 
    if loglevel () >= 2 then
	let msg = fmsg Printf.sprintf in
	Printf.fprintf !logfid  "[WARN]  %s: %s\n" modname msg;
	flush !logfid
  let error fmsg = 
    if loglevel () >= 1 then
	let msg = fmsg Printf.sprintf in
	Printf.fprintf !logfid  "[ERROR] %s: %s\n" modname msg;
	flush !logfid
  let abort fmsg = 
    let msg = fmsg Printf.sprintf in
    Printf.fprintf !logfid  "[ABORT] %s: %s\n" modname msg;
    Printexc.print_raw_backtrace !logfid (Printexc.get_callstack 100);
    flush !logfid;
    flush stdout;
    raise (Exceptions.Error msg)
end
