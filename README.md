# Inventory CLI in OCaml

This is a little OCaml CLI to manipulate inventory items in a Postgres database.

The Items table contain the following fields:

| Field       | Type   |
|-------------|--------|
| id          | int    |
| name        | string |
| price       | float  |
| description | text   |
|-------------|--------|

Using the CLI you can insert, update and list items in the DB.

##  Examples

Create some items:

```
$ ./_build/default/bin/inventory.exe insert -n "Flux Capacitor" -d "Allows you to travel in time" -p 10.99
$ ./_build/default/bin/inventory.exe insert -n "Magical Doohikee" -d "Does magic things" -p 7.5
```

List the items:

```
$ ./_build/default/bin/inventory.exe list
((id(1))(name"Flux Capacitor")(price 10.99)(description"Allows you to travel in time"))
((id(2))(name"Magical Doohikee")(price 7.5)(description"Does magic things"))
```

Update the price of the "Flux Capacitor", since travelling in time is in high
demand:

```
./_build/default/bin/inventory.exe update 1 -p 100000
```

Invalid values will yield errors
```
$ ./_build/default/bin/inventory.exe update 1 -p -1 -n ""
Unable to process item:
Name cannot be an empty string
Price need to be greater than or equal to zero
```

## Setup

### Dependencies

In order to build this project you need to have installed:
- [Opam](https://opam.ocaml.org/) - OCaml's package manager
- [Dune](https://github.com/ocaml/dune) - Build system for OCaml

Install Inventory's Opam dependencies:

```
opam install -y  --deps-only .
```

### Build

Build with `dune build`.

### Setup DB

Export Postgres environment variables to target a running cluster that you have
access to. If you have a local instance, set at least `PGDATABASE`. Also, create
the tables necessary for the app:

```
export PGDATABASE=vgrocha
./_build/default/bin/inventory.exe create-tables
```

You are all setup and ready to go.

## Known issues

- You can create items with `update` command
- No tests