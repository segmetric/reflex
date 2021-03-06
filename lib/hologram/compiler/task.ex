# DEFER: test

defmodule Mix.Tasks.Compile.Hologram do
  use Mix.Task.Compiler

  alias Hologram.Compiler.Builder
  alias Hologram.Runtime.Reflection

  @app_path Reflection.app_path()

  def run(_) do
    "#{@app_path}/priv/static/hologram"
    |> File.mkdir_p!()

    remove_old_files()

    # DEFER: parallelize
    Reflection.list_pages()
    |> Enum.map(&build_page/1)
    |> build_manifest()

    reload_routes()

    :ok
  end

  defp build_manifest(digests) do
    json =
      Enum.into(digests, %{})
      |> Jason.encode!()

    "#{@app_path}/priv/static/hologram/manifest.json"
    |> File.write!(json)
  end

  defp build_page(page) do
    js = Builder.build(page)

    digest =
      :crypto.hash(:md5, js)
      |> Base.encode16()
      |> String.downcase()

    "#{@app_path}/priv/static/hologram/page-#{digest}.js"
    |> File.write!(js)

    {page, digest}
  end

  # Routes are defined in page modules and the router aggregates the routes dynamically by reflection.
  # So everytime a route is updated in a page module, we need to explicitely recompile the router module, so that
  # it rebuilds the list of routes.
  defp reload_routes do
    router_path = "#{@app_path}/lib/demo_web/router.ex"

    opts = Code.compiler_options()
    Code.compiler_options(ignore_module_conflict: true)
    Code.compile_file(router_path)
    Code.compiler_options(ignore_module_conflict: opts.ignore_module_conflict)
  end

  defp remove_old_files do
    "#{@app_path}/priv/static/hologram/*"
    |> Path.wildcard()
    |> Enum.each(&File.rm!/1)
  end
end
