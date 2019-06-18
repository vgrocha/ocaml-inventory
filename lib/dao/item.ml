open Core
open Async
open Pgx_async

type t =
  { id : int option
  ; name : string
  ; price : float
  ; description : string } [@@deriving sexp]

let price_validation price =
  if price<0.0 then Some ("Price need to be greater than or equal to zero") else None

let name_validation name =
  if name = "" then Some ("Name cannot be an empty string") else None

let description_validation description =
  if description = "" then Some ("Description cannot be an empty string") else None

let validate validations=
  let possible_errors =
    List.fold_left
      ~init:None
      ~f:(fun a b -> Option.merge a b ~f:(fun a b -> a ^ "\n" ^b ))
      validations
  in
  match possible_errors with
  | None -> Ok ()
  | Some errors -> Error errors

let list db =
  let%map items = simple_query db "SELECT id, name, price, description FROM items ORDER BY id" in
  items
  |> List.hd_exn
  |> List.map ~f:(function
      | [ id; name; price; description] ->
        { id = Value.to_int id
        ; name = Value.to_string_exn name
        ; price = Value.to_float_exn price
        ; description = Value.to_string_exn description}
      | _ -> assert false)

let insert db t : (unit, string) Deferred.Result.t=
  validate [ price_validation t.price
           ; name_validation t.name
           ; description_validation t.description]
  |> return
  >>=? fun _ ->
  let query =
    sprintf "INSERT INTO ITEMS (name, price, description) VALUES ('%s', %f, '%s')"
      t.name
      t.price
      t.description in
  let%map _ = simple_query db query in
  Ok ()

let update db id ?name ?price ?description () : (unit, string) Deferred.Result.t =
  validate [ Option.bind name ~f:name_validation
           ; Option.bind price ~f:price_validation
           ; Option.bind description ~f:description_validation]
  |> return
  >>=? fun _ ->
  let query =
    "INSERT INTO ITEMS (id, name, price, description) VALUES ( $1, $2, $3, $4)
     ON CONFLICT (id) DO UPDATE SET
        name=COALESCE(EXCLUDED.name, items.name)\
        , price=COALESCE(EXCLUDED.price, items.price)\
        , description=COALESCE(EXCLUDED.description, items.description)" in
  let price = Option.bind ~f:Pgx.Value.of_float price in
  let%map _ = execute ~params:Pgx.Value.[of_int id; name; price; description] db query in
  Ok ()
