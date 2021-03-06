defmodule Hologram.Compiler.Pruner do
  alias Hologram.Compiler.Helpers
  alias Hologram.Compiler.IR.{FunctionCall, FunctionDefinition, ModuleDefinition}
  alias Hologram.Typespecs, as: T

  @doc """
  Prunes unused modules and functions.
  """
  @spec prune(T.module_definitions_map()) :: T.module_definitions_map()

  def prune(module_defs_map) do
    find_used_functions(module_defs_map)
    |> prune_unused_functions(module_defs_map)
    |> prune_unused_modules()
  end

  @spec determine_preserved_module_functions(%ModuleDefinition{}, T.function_set()) ::
          list(%FunctionDefinition{})

  defp determine_preserved_module_functions(module_def, used_functions) do
    Enum.reduce(module_def.functions, [], fn function_def, acc ->
      # The function call may use default parameter values,
      # so we include all functions matching the name (regardless of their arity).
      # DEFER: include only functions with matching arity
      if {module_def.module, function_def.name} in used_functions do
        acc ++ [function_def]
      else
        acc
      end
    end)
  end

  @spec find_actions(
    list(%ModuleDefinition{}),
    list(%ModuleDefinition{}),
    T.module_definitions_map()
  ) :: list({module(), %FunctionDefinition{}})

  defp find_actions(pages, components, module_defs_map) do
    (pages ++ components)
    |> Enum.reduce([], &(&2 ++ find_module_actions(&1, module_defs_map)))
  end

  @spec find_components(T.module_definitions_map()) :: list(%ModuleDefinition{})

  defp find_components(module_defs_map) do
    module_defs_map
    |> Enum.filter(fn {_, module_def} ->
      Helpers.is_component?(module_def)
    end)
    |> Enum.map(fn {_, module_def} -> module_def end)
  end

  @spec find_function_defs(
          T.module(),
          T.function_name(),
          T.module_definitions_map()
        ) :: list({%FunctionDefinition{}})

  defp find_function_defs(module, function_name, module_defs_map) do
    if module_defs_map[module] do
      module_defs_map[module].functions
      |> Enum.filter(&(&1.name == function_name))
    else
      []
    end
  end

  @spec find_module_actions(%ModuleDefinition{}, T.module_definitions_map()) ::
          list({module(), %FunctionDefinition{}})

  defp find_module_actions(module_def, module_defs_map) do
    find_function_defs(module_def.module, :action, module_defs_map)
    |> Enum.map(&{module_def.module, &1})
  end

  @spec find_pages(T.module_definitions_map()) :: list(%ModuleDefinition{})

  defp find_pages(module_defs_map) do
    module_defs_map
    |> Enum.filter(fn {_, module_def} ->
      Helpers.is_page?(module_def)
    end)
    |> Enum.map(fn {_, module_def} -> module_def end)
  end

  @spec find_used_functions(T.module_definitions_map()) :: T.function_set()

  defp find_used_functions(module_defs_map) do
    pages = find_pages(module_defs_map)
    components = find_components(module_defs_map)
    actions = find_actions(pages, components, module_defs_map)

    acc =
      Enum.reduce(actions, MapSet.new([]), fn action, acc ->
        include_functions_used_by_action(action, acc, module_defs_map)
      end)

    (pages ++ components)
    |> Enum.reduce(acc, &include_actions_and_templates/2)
  end

  @spec include_actions_and_templates(list(%ModuleDefinition{}), T.function_set()) ::
          T.function_set()

  defp include_actions_and_templates(module_def, acc) do
    MapSet.put(acc, {module_def.module, :action})
    |> MapSet.put({module_def.module, :template})
  end

  @spec include_function_calls(
          T.function_set(),
          %FunctionDefinition{},
          T.module_definitions_map()
        ) :: T.function_set()

  defp include_function_calls(acc, %FunctionDefinition{body: body}, module_defs_map) do
    Enum.reduce(body, acc, &include_function_calls(&2, &1, module_defs_map))
  end

  @spec include_function_calls(T.function_set(), %FunctionCall{}, T.module_definitions_map()) ::
        T.function_set()

  defp include_function_calls(acc, %FunctionCall{} = function_call, module_defs_map) do
    # The function call may use default parameter values,
    # so we include all functions matching the name (regardless of their arity).
    # DEFER: include only functions with matching arity
    elem = {function_call.module, function_call.function}

    unless elem in acc do
      MapSet.put(acc, elem)
      |> include_function_calls(function_call.module, function_call.function, module_defs_map)
    else
      acc
    end
  end

  @spec include_function_calls(T.function_set(), any(), T.module_definitions_map()) ::
          T.function_set()

  defp include_function_calls(acc, _, _), do: acc

  @spec include_function_calls(
          T.function_set(),
          module(),
          T.function_name(),
          T.module_definitions_map()
        ) :: T.function_set()

  defp include_function_calls(acc, module, function_name, module_defs_map) do
    find_function_defs(module, function_name, module_defs_map)
    |> Enum.reduce(acc, &include_function_calls(&2, &1, module_defs_map))
  end

  # TODO: implement include_function_calls which includes function calls nested in blocks

  @spec include_functions_used_by_action(
    {module(), %FunctionDefinition{}},
    T.function_set(),
    T.module_definition_map()
  ) :: T.function_set()

  defp include_functions_used_by_action({_, function_def}, acc, module_defs_map) do
    include_function_calls(acc, function_def, module_defs_map)
  end

  @spec prune_unused_functions(T.function_set(), T.module_definitions_map()) ::
          T.module_definitions_map()

  defp prune_unused_functions(used_functions, module_defs_map) do
    Enum.map(module_defs_map, fn {module, module_def} ->
      preserved_functions = determine_preserved_module_functions(module_def, used_functions)
      {module, %{module_def | functions: preserved_functions}}
    end)
    |> Enum.into(%{})
  end

  @spec prune_unused_modules(T.module_definitions_map()) :: T.module_definitions_map()

  defp prune_unused_modules(module_defs_map) do
    Enum.filter(module_defs_map, fn {_, module_def} ->
      Enum.any?(module_def.functions)
    end)
    |> Enum.into(%{})
  end
end
