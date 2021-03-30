defmodule BrewingStand.Util.Macros do
  defmacro __using__(_) do
    quote do
      require BrewingStand.Util.Macros
      import BrewingStand.Util.Macros
    end
  end

  defmacro defenum([_ | _] = names) do
    for {name, idx} <- Enum.with_index(names) do
      quote do
        defmacro unquote({name, [], nil}), do: unquote(idx)
      end
    end
  end

  # https://github.com/turbomates/defconst/blob/master/lib/defconst.ex
  # defmacro defconst(name, value) do
  #   {evaluated, _} = Code.eval_quoted(value)
  #   escaped_value = Macro.escape(evaluated) |> Macro.escape()

  #   if is_atom(name) do
  #     quote do
  #       defmacro unquote({name, [], nil}), do: unquote(escaped_value)
  #     end
  #   else
  #     quote do
  #       defmacro unquote(name), do: unquote(escaped_value)
  #     end
  #   end
  # end
end
