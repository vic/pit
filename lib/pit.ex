defmodule Pit do

  defmodule PipedValueMismatch do
    defexception [:message, :pattern, :value]
  end

  @doc ~S"""

  The `pit` macro lets you pipe value transformations by pattern matching
  on data as it is passed down the pipe.

  The syntax for transforming values is `expression |> pit(value <- pattern)`.

  By default if a value does not match the pattern, `pit` simply passes down
  the value it was given. You can however enforce the pattern
  to match by using `pit!` which will raise an error on mismatch. Or you
  can provide an `else:` option to `pit` to handle the mismatch yourself.

  See the following examples:

  ## Examples

      iex> # this example transforms an ok tuple
      iex> import Pit
      ...> value = {:ok, 11}
      ...> value
      ...>   |> pit(n * 2 <- {:ok, n})
      22


      iex> # If the value does not match, no transformation is made.
      iex> import Pit
      ...> value = {:ok, :hi}
      ...> value
      ...>   |> pit(n * 2 <- {:ok, n} when is_number(n))
      {:ok, :hi}


      iex> # You can force the pattern to match by using `pit!`
      iex> import Pit
      ...> value = {:ok, :hi}
      ...> value
      ...>   |> pit!(n * 2 <- {:ok, n} when is_number(n))
      ** (Pit.PipedValueMismatch) expected piped value to match `{:ok, n} when is_number(n)` but got `{:ok, :hi}`


      iex> # The following will ensure there are no errors on
      iex> # the response and double the count value from data.
      iex> import Pit
      ...> response = {:ok, %{data: %{"count" => 10}, errors: []}}
      ...> response
      ...>    |> pit!(data <- {:ok, %{errors: [], data: data}})
      ...>    |> pit(count * 2 <- %{"count" => count})
      20


      iex> # The pattern can be negated with `not` or `!`.
      iex> # in this case raise if an error tuple is found.
      iex> import Pit
      ...> response = {:cool, 22}
      ...> response
      ...>    |> pit!(not {:error, _})
      ...>    |> pit(n <- {_, n})
      22


      iex> # should raise when using `pit!`
      iex> import Pit
      ...> response = {:error, :not_found}
      ...> response
      ...>    |> pit!(not {:error, _})
      ...>    |> pit(n <- {_, n})
      ** (Pit.PipedValueMismatch) did not expect piped value to match `{:error, _}` but got `{:error, :not_found}`


      iex> # also, when a guard fails an error is raised
      iex> import Pit
      ...> response = {:ok, 22}
      ...> response
      ...>    |> pit!({:ok, n} when n > 30)
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


      iex> # The do form can take a block using bound variables.
      iex> import Pit
      ...> {:error, :none} |> pit({:ok, _})
      {:error, :none}


  """
  defmacro pit(pipe, expr, options \\ []) do
    options = else_fallback_option(options)
    pit_pipe(pipe, expr, options)
  end

  defmacro pit!(pipe, expr, options \\ []) do
    pit_pipe(pipe, expr, options)
  end

  defp else_fallback_option(options) do
    if Keyword.has_key?(options, :else) || Keyword.has_key?(options, :else_value) do
      options
    else
      Keyword.put(options, :else, :it)
    end
  end

  defp pit_pipe(piped, expr, options) do
    options = [
      do: do_pipe(Keyword.take(options, [:do, :do_value])),
      else: else_pipe(expr, Keyword.take(options, [:else, :else_value]))
    ]
    quote do
      unquote(piped) |> unquote(pit_fn(expr, options)).()
    end
  end

  defp pit_fn(expr, options) do
    it = Macro.var(:it, __MODULE__)
    quote do
      fn unquote(it) ->
        case unquote(it) do
          unquote(pit_branches(it, expr, options))
        end
      end
    end
  end

  defp pit_branches(_it, {:<-, _, [expr, pattern = {v, _, s}]}, [do: do_pipe, else: _else_pipe]) when is_atom(v) and is_atom(s) do
    quote do
      unquote(pattern) -> unquote(expr) |> unquote(do_pipe)
    end
  end

  defp pit_branches(it, {:<-, _, [expr, pattern]}, [do: do_pipe, else: else_pipe]) do
    quote do
      unquote(pattern) -> unquote(expr) |> unquote(do_pipe)
      _ -> unquote(it) |> unquote(else_pipe)
    end
  end

  defp pit_branches(it, {nop, _, [pattern]}, [do: do_pipe, else: else_pipe]) when nop == :! or nop == :not do
    quote do
      unquote(pattern) -> unquote(it) |> unquote(else_pipe)
      _ -> unquote(it) |> unquote(do_pipe)
    end
  end

  defp pit_branches(it, pattern = {v, _, s}, [do: do_pipe, else: _else_pipe]) when is_atom(v) and is_atom(s) do
    quote do
      unquote(pattern) -> unquote(it) |> unquote(do_pipe)
    end
  end

  defp pit_branches(it, pattern, [do: do_pipe, else: else_pipe]) do
    quote do
      unquote(pattern) -> unquote(it) |> unquote(do_pipe)
      _ -> unquote(it) |> unquote(else_pipe)
    end
  end

  defp do_pipe(do: :it), do: do_pipe([])
  defp do_pipe(do: body = {:__block__, _, _}) do
    quote do
      (fn _ -> unquote(body) end).()
    end
  end
  defp do_pipe(do: pipe), do: pipe
  defp do_pipe(do_value: expr) do
    quote do
      (fn _ -> unquote(expr) end).()
    end
  end
  defp do_pipe([]) do
    quote do
      (fn it -> it end).()
    end
  end

  defp else_pipe(_expr, else: :it) do
    quote do
      (fn it -> it end).()
    end
  end
  defp else_pipe(_expr, body = {:__block__, _, _}) do
    quote do
      (fn _ -> unquote(body) end).()
    end
  end
  defp else_pipe(_expr, else: pipe), do: pipe
  defp else_pipe(_expr, else_value: expr) do
    quote do
      (fn _ -> unquote(expr) end).()
    end
  end
  defp else_pipe({:<-, _, [_, pattern]}, []) do
    mismatch({"expected piped value to match", pattern})
  end
  defp else_pipe({nop, _, [pattern]}, []) when nop == :! or nop == :not do
    mismatch({"did not expect piped value to match", pattern})
  end
  defp else_pipe(pattern, []) do
    mismatch({"expected piped value to match", pattern})
  end

  defp mismatch({message, pattern}) do
    quote do
      (fn it ->
        raise PipedValueMismatch,
        message: "#{unquote(message)} `#{unquote(Macro.to_string(pattern))}` but got `#{inspect(it)}`",
        pattern: unquote(Macro.escape(pattern)),
        value: it
      end).()
    end
  end
end
