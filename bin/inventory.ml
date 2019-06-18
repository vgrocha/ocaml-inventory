open Core
open Async
open Pgx_async

let create_tables =
  let summary =
    "Setup the inventory tables" in
  let create_tables_query =
    "DROP TABLE IF EXISTS items;
     CREATE TABLE items \
     (id serial primary key\
     , name character varying(255)\
     , price float \
     , description text \
     , CONSTRAINT price_greater_than_zero check (price>=0))" in
  Command.async_spec ~summary Command.Spec.empty @@ fun () ->
  with_conn ( fun db ->
      simple_query db create_tables_query
      |> Deferred.ignore)
    
let list =
  Command.async_spec
    ~summary:"List all available items in the inventory"
    Command.Spec.empty @@ fun () ->
  with_conn (fun db ->
      let%map items = Dao.Item.list db in
      List.iter items ~f:( fun i ->
          i
          |> Dao.Item.sexp_of_t
          |> Sexp.to_string
          |> print_endline))

let insert =
  Command.async_spec
    ~summary:"Insert item into inventory"
    Command.Spec.( empty
                   +> flag "-n" (required string)  ~doc:"Name of the item"
                   +> flag "-p" (required float) ~doc:"Price of the item"
                   +> flag "-d" (required string)  ~doc:"Description of the item")
  @@ fun name price description () ->
  with_conn ( fun db ->
      let i = Dao.Item.{ id=None; name; price; description} in
      let%bind result = Dao.Item.insert db i in
      match result with
      | Ok _ -> return ()
      | Error errors ->
        print_endline @@ "Unable to process item:\n" ^ errors;
        Async.exit 1)


let update =
  Command.async_spec
    ~summary:"Update item into inventory"
    Command.Spec.( empty
                   +> anon ("id" %: int) 
                   +> flag "-n" (optional string)  ~doc:"Name of the item"
                   +> flag "-p" (optional float) ~doc:"Price of the item"
                   +> flag "-d" (optional string)  ~doc:"Description of the item")
  @@ fun id name price description () ->
  with_conn ( fun db ->
      let%bind result = Dao.Item.update db id ?name ?price ?description () in
      match result with
      | Ok _ -> return ()
      | Error errors ->
        print_endline @@ "Unable to process item:\n" ^ errors;
        Async.exit 1)

let () =
  [ "list", list
  ; "insert", insert
  ; "update", update
  ; "create-tables", create_tables]
  |> Command.group
    ~summary:"Inventory control\n\
              Control your inventory. Use Postgres environment to point to the correct DB"
  |> Command.run ~version:"0.0.1"

