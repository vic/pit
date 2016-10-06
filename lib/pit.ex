defmodule Pit do
  @moduledoc ~S"""
  The `pit` macro lets you pipe value transformations by pattern matching
  on data as it is passed down the pipe.

  The syntax is `expression |> pit(value <- pattern)`.

  ```elixir

    iex> # The following will ensure there are no errors on
    iex> # the response and double the count value from data.
    ...> import Pit
    ...> response = {:ok, %{data: %{"count" => 10}, errors: []}}
    ...> response
    ...>    |> pit(data <- {:ok, %{errors: [], data: data}})
    ...>    |> pit(count * 2 <- %{"count" => count})
    20

  ```
  """
  defmacro pit(pipe, {:<-, _, [value, pattern]}) do
    quote do
      unquote(pipe) |> (fn unquote(pattern) -> unquote(value) end).()
    end
  end
end
