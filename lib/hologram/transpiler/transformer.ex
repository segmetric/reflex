defmodule Hologram.Transpiler.Transformer do
  alias Hologram.Transpiler.AST.{AtomType, BooleanType, IntegerType, StringType}
  alias Hologram.Transpiler.AST.{ListType, MapType, StructType}
  alias Hologram.Transpiler.AST.MatchOperator
  alias Hologram.Transpiler.AST.MapAccess
  alias Hologram.Transpiler.AST.{Alias, Call, Function, Module, Variable}

  def transform(ast, module \\ nil, aliases \\ %{})

  # PRIMITIVE TYPES

  # boolean must be before atom
  def transform(ast, _module, _aliases) when is_boolean(ast) do
    %BooleanType{value: ast}
  end

  def transform(ast, _module, _aliases) when is_atom(ast) do
    %AtomType{value: ast}
  end

  def transform(ast, _module, _aliases) when is_integer(ast) do
    %IntegerType{value: ast}
  end

  def transform(ast, _module, _aliases) when is_binary(ast) do
    %StringType{value: ast}
  end

  # DATA STRUCTURES

  def transform(ast, module, aliases) when is_list(ast) do
    data = Enum.map(ast, fn v -> transform(v, module, aliases) end)
    %ListType{data: data}
  end

  def transform({:%{}, _, ast}, module, aliases) do
    data = Enum.map(ast, fn {k, v} ->
      {transform(k, module, aliases), transform(v, module, aliases)}
    end)

    %MapType{data: data}
  end

  def transform({:%, _, [{_, _, module}, ast]}, _module, aliases) do
    data = transform(ast, module, aliases).data

    key = List.last(module)

    module =
      if Map.has_key?(aliases, key) do
        aliases[key]
      else
        module
      end

    %StructType{module: module, data: data}
  end

  # OPERATORS

  def transform({:=, _, [left, right]}, module, aliases) do
    left = transform(left, module, aliases)

    %MatchOperator{
      bindings: aggregate_bindings(left),
      left: left,
      right: transform(right, module, aliases)
    }
  end

  defp aggregate_bindings(_, path \\ [])

  defp aggregate_bindings(%Variable{name: name} = var, path) do
    [[var] ++ path]
  end

  defp aggregate_bindings(%MapType{data: data}, path) do
    Enum.reduce(data, [], fn {k, v}, acc ->
      acc ++ aggregate_bindings(v, path ++ [%MapAccess{key: k}])
    end)
  end

  defp aggregate_bindings(_, path) do
    []
  end

  # OTHER

  def transform({:alias, _, [{:__aliases__, _, module}]}, _parent_module, _aliases) do
    %Alias{module: module}
  end

  def transform({:def, _, [{name, _, params}, [do: body]]}, module, aliases) do
    params = Enum.map(params, fn param -> transform(param, module, aliases) end)

    bindings =
      Enum.map(params, fn param ->
        case aggregate_bindings(param) do
          [] ->
            nil
          path ->
            path
            |> hd()
        end
      end)
      |> Enum.reject(fn item -> item == nil end)

    body =
      case body do
        {:__block__, _, block} ->
          block
        expr ->
          [expr]
      end
      |> Enum.map(fn expr -> transform(expr, module, aliases) end)

    %Function{name: name, params: params, bindings: bindings, body: body}
  end

  def transform({:defmodule, _, [{:__aliases__, _, name}, [do: {:__block__, _, ast}]]}, _module, _aliases) do
    aliases = aggregate_aliases(ast)
    functions = aggregate_functions(ast, name, aliases)

    %Module{name: name, aliases: aliases, functions: functions}
  end

  def transform({:defmodule, _, [{:__aliases__, _, name}, [do: ast]]}, _module, _aliases) do
    aliases = %{list: [], map: %{}}
    functions = aggregate_functions([ast], name, aliases)

    %Module{name: name, aliases: aliases, functions: functions}
  end

  defp aggregate_aliases(ast) do
    list =
      Enum.reduce(ast, [], fn expr, acc ->
        case expr do
          {:alias, _, _} ->
            acc ++ [transform(expr)]
          _ ->
            acc
        end
      end)

    map =
      Enum.reduce(list, %{}, fn elem, acc ->
        Map.put(acc, List.last(elem.module), elem.module)
      end)

    %{list: list, map: map}
  end

  defp aggregate_functions(ast, module, aliases) do
    Enum.reduce(ast, [], fn expr, acc ->
      case expr do
        {:def, _, _} ->
          acc ++ [transform(expr, module, aliases)]
        _ ->
          acc
      end
    end)
  end

  def transform({name, _, nil}, _module, _aliases) when is_atom(name) do
    %Variable{name: name}
  end

  def transform({function, _, params}, module, aliases) when is_atom(function) do
    params = transform_call_params(params, module, aliases)
    module = resolve_module(module, aliases)

    %Call{module: module, function: function, params: params}
  end

  def transform({{:., _, [{:__aliases__, _, module}, function]}, _, params}, parent_module, aliases) do
    params = transform_call_params(params, parent_module, aliases)
    module = resolve_module(module, aliases)

    %Call{module: module, function: function, params: params}
  end

  defp transform_call_params(params, module, aliases) do
    Enum.map(params, fn param -> transform(param, module, aliases) end)
  end

  defp resolve_module(module, aliases) do
    name = hd(module)

    if Enum.count(module) == 1 && Map.has_key?(aliases.map, name) do
      aliases.map[name]
    else
      module
    end
  end
end