defmodule Hologram.Transpiler.Transformers.CallTransformer do
  alias Hologram.Transpiler.AST.Call
  alias Hologram.Transpiler.Helpers
  alias Hologram.Transpiler.Transformer

  def transform(called_module, function, params, current_module, imports, aliases) do
    params = transform_call_params(params, current_module, imports, aliases)

    resolved_module =
      resolve_module(called_module, function, params, current_module, imports, aliases)

    %Call{module: resolved_module, function: function, params: params}
  end

  defp resolve_aliased_module(as, aliases) do
    resolved = Enum.find(aliases, &(&1.as == as))
    if resolved, do: resolved.module, else: nil
  end

  defp resolve_imported_module(function, arity, imports) do
    resolved =
      Enum.find(imports, fn i ->
        module = Helpers.fully_qualified_module(i.module)
        {function, arity} in module.module_info()[:exports]
      end)

    if resolved, do: resolved.module, else: nil
  end

  defp resolve_module(called_module, function, params, current_module, imports, aliases) do
    arity = Enum.count(params)

    if Enum.count(called_module) == 0 do
      imported_module = resolve_imported_module(function, arity, imports)
      if imported_module, do: imported_module, else: current_module
    else
      aliased_module = resolve_aliased_module(called_module, aliases)
      if aliased_module, do: aliased_module, else: called_module
    end
  end

  defp transform_call_params(params, module, imports, aliases) do
    Enum.map(params, &(Transformer.transform(&1, module, imports, aliases)))
  end
end