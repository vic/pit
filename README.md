# Down the pit

The `pit` macro lets you pipe value transformations by pattern matching
on data as it is passed down the pipe.

The syntax for transforming values is `value |> pit(expression <- pattern)`.


## Examples

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
** (Pit.PipedValueMismatch) did not expect piped value to match `{:error, _}` but got `{:error, :not_found}`


iex> # also, when a guard fails an error is raised
iex> import Pit
...> response = {:ok, 22}
...> response
...>    |> pit({:ok, n} when n > 30)
...>    |> pit(n <- {:ok, n})
** (Pit.PipedValueMismatch) expected piped value to match `{:ok, n} when n > 30` but got `{:ok, 22}`


iex> # You can provide a default value in case of mismatch
iex> import Pit
...> response = {:error, :not_found}
...> response
...>    |> pit({:ok, _}, else_value: {:ok, :default})
...>    |> pit(n <- {:ok, n})
:default


iex> # Or you can pipe the mismatch value to other pipe using `else:` option
iex> # and get the value down a more interesting transformation flow.
iex> import Pit
...> response = {:ok, "hello"}
...> response
...>   |> pit({:ok, n} when is_integer(n),
...>        do_value: {:ok, :was_integer, n},
...>        else: pit(s <- {:ok, s} when is_binary(s)) |> String.length |> pit({:ok, :was_string, len} <- len))
...>   |> pit(x * 2 <- {:ok, _, x})
10


iex> # Both `do` and `else` if given the `:it` atom just pass the value down
iex> import Pit
...> {:error, 22} |> pit({:ok, _}, else: :it)
{:error, 22}

iex> import Pit
...> {:ok, 22} |> pit({:ok, _}, do: :it)
{:ok, 22}


iex> # The do form can take a block using bound variables.
iex> import Pit
...> {:ok, 22} |> (pit {:ok, n} do
...>  x = n / 11
...>  x * 2
...> end)
4.0


```

## Installation

[Available in Hex](https://hex.pm/packages/pit), the package can be installed as:

  1. Add `pit` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:pit, "~> 0.1.4"}]
    end
    ```

