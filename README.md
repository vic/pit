# Pit

The `pit` macro lets you pipe value transformations by pattern matching
on data as it is passed down the pipe.

The syntax is `expression |> pit(value <- pattern)`.

```elixir

  iex> # The following will ensure there are no errors on
  iex> # the response and double the count value from data.
  ...> import PipeIt
  ...> response = {:ok, %{data: %{"count" => 10}, errors: []}}
  ...> response
  ...>    |> pit(data <- {:ok, %{errors: [], data: data}})
  ...>    |> pit(count * 2 <- %{"count" => count})
  20

```


## Installation

[Available in Hex](https://hex.pm/packages/pit), the package can be installed as:

  1. Add `pit` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:pit, "~> 0.1.0"}]
    end
    ```

