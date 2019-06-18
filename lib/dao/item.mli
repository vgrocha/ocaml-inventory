open Async

type t = 
  { id : int option
  ; name : string
  ; price : float
  ; description : string } [@@deriving sexp]

val list: Pgx_async.t -> t list Deferred.t

val insert: Pgx_async.t -> t -> (unit, string) Deferred.Result.t

val update:
  Pgx_async.t
  -> int
  -> ?name:string
  -> ?price:float
  -> ?description:string
  -> unit
  -> (unit, string) Deferred.Result.t
