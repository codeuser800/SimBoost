(* this file will be renamed later *)
open! Core
open Async
module Server = Cohttp_async.Server

let create_plot () = ()
let draw_UI () = ()

(* url format example: ../aapl/2012-01-01/2013-12-31 *)
let handler ~body:_ _sock req =
  let uri = Cohttp.Request.uri req in
  print_s
    (let uri = Uri.to_string uri in
     [%message "Received a request!" (uri : string)]);
  let header = Cohttp.Header.init_with "Access-Control-Allow-Origin" "*" in
  let request = Uri.path uri |> String.split ~on:'/' in
  print_s [%message (request : string list)];
  match Uri.path uri |> String.split ~on:'/' with
  | [ _; "stock"; stock; start_date; end_date ] ->
    let%bind _response = Scraper.get ~start_date ~end_date ~stock in
    let response =
      Jsonaf.Export.jsonaf_of_string _response |> Jsonaf.to_string
    in
    print_s [%message (response : string)];
    Server.respond_string ~headers:header response
  | _ ->
    Server.respond_string
      ~headers:header
      ~status:`Not_found
      "\" Route not found \""
;;

let start_server port () =
  Stdlib.Printf.eprintf "Listening for HTTP on port %d\n" port;
  Stdlib.Printf.eprintf
    "Try 'curl http://localhost:%d/test?hello=xyz'\n%!"
    port;
  Server.create
    ~on_handler_error:`Raise
    (Async.Tcp.Where_to_listen.of_port port)
    handler
  >>= fun _server -> Deferred.never ()
;;

let command =
  Command.async
    ~summary:"Start server for example [starter_template]"
    (let%map_open.Command port =
       flag
         "port"
         (optional_with_default 8181 int)
         ~doc:"port on which to serve"
     in
     fun () -> start_server port ())
;;
