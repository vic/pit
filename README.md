# Down the pit

The `pit` macro lets you pipe value transformations by pattern matching
on data as it is passed down the pipe.

The syntax for transforming values is `expression |> pit(value <- pattern)`.

```elixir

    iex> # The following will ensure there are no errors on
    iex> # the response and double the count value from data.
    iex> import Pit
    ...> response = {:ok, %{data: %{"count" => 10}, errors: []}}
    ...> response
    ...>    |> pit(data <- {:ok, %{errors: [], data: data}})
    ...>    |> pit(count * 2 <- %{"count" => count})
    20


    iex> # By using the ! operator, you can pipe values
    iex> # only if they dont match some pattern
    iex> # This example only pipes anything that aint an error
    iex> import Pit
    ...> response = {:cool, 22}
    ...> response
    ...>    |> pit(! {:error, _})
    ...>    |> pit(n <- {_, n})
    22


    iex> # if the piped value does not match an error is raised.
    iex> import Pit
    ...> response = {:error, :not_found}
    ...> response
    ...>    |> pit(! {:error, _})
    ...>    |> pit(n <- {:ok, n})
    ** (Pit.PipedValueMismatch) expected piped value not to match `{:error, _}`


    iex> # also, when a guard fails an error is raised
    iex> import Pit
    ...> response = {:ok, 22}
    ...> response
    ...>    |> pit({:ok, n} when n > 30)
    ...>    |> pit(n <- {:ok, n})
    ** (Pit.PipedValueMismatch) expected piped value to match `{:ok, n} when n > 30`


    iex> # You can provide a fallback value for mismatch
    iex> import Pit
    ...> response = {:error, :not_found}
    ...> response
    ...>    |> pit({:ok, _}, else: {:ok, :default})
    ...>    |> pit(n <- {:ok, n})
    :default


```

## Installation

[Available in Hex](https://hex.pm/packages/pit), the package can be installed as:

  1. Add `pit` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:pit, "~> 0.1.1"}]
    end
    ```

