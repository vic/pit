defmodule Pit do

  defmodule PipedValueMismatch do
    defexception [:message]
  end


  @moduledoc ~S"""

  The `pit` macro lets you pipe value transformations by pattern matching
  on data as it is passed down the pipe.

  The syntax for transforming values is `expression |> pit(value <- pattern)`.


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

  """

  defmacro pit(pipe, expr, options \\ []) do
    fallback = Keyword.get(options, :else, mismatch(expr))
    quote do
      unquote(pipe) |> (unquote(down_the_pit(expr, fallback))).()
    end
  end

  defp down_the_pit({:<-, _, [value, pattern]}, fallback) do
    quote do
      fn
        unquote(pattern) -> unquote(value)
        _ -> unquote(fallback)
      end
    end
  end

  defp down_the_pit({:!, _, [pattern]}, fallback) do
    quote do
      fn
        unquote(pattern) -> unquote(fallback)
        x -> x
      end
    end
  end

  defp down_the_pit(pattern, fallback) do
    quote do
      fn (it) ->
        case it do
          unquote(pattern) -> it
          _ -> unquote(fallback)
        end
      end
    end
  end

  defp mismatch({:<-, _, [_, pattern]}) do
    quote do
      raise PipedValueMismatch, message: "expected piped value to match `#{unquote(Macro.to_string(pattern))}`"
    end
  end

  defp mismatch({:!, _, [pattern]}) do
    quote do
      raise PipedValueMismatch, message: "expected piped value not to match `#{unquote(Macro.to_string(pattern))}`"
    end
  end

  defp mismatch(pattern) do
    quote do
      raise PipedValueMismatch, message: "expected piped value to match `#{unquote(Macro.to_string(pattern))}`"
    end
  end

end
