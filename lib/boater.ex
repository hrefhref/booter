defmodule Boater do
  require Lager

  defmacro __before_compile__(_env) do
    quote do
      def boot_steps, do: @boot_step
    end
  end

  defmacro __using__(_opts) do
    quote do
      import Boater
      @before_compile Boater
      Module.register_attribute __MODULE__, :boot_step, accumulate: true, persist: true
    end
  end

  @type step_name :: atom
  @type step_setting :: { atom, term }
  @type t :: { step_name, [ step_setting ] }

  @spec boot! :: :ok | no_return()
  @doc "Run all the sorted boot steps"
  def boot! do
    Lager.debug "Starting boot"
    Enum.each(boot_steps, fn(step) -> run_boot_step(step) end)
    :ok
  end

  @spec unsorted_boot_steps :: [Boater.t]
  @doc "Unsorted list of the boot steps"
  def unsorted_boot_steps, do: all_modules_attributes(:boot_step)

  @spec boot_steps :: [Boater.t]
  @doc "Sorted list of the boot steps"
  def boot_steps do
    unsorted_steps = unsorted_boot_steps
    case build_acyclic_graph(unsorted_steps) do
      { :ok, graph } ->
        sorted_steps = for step_name <- :digraph_utils.topsort(graph) do
          { _step_name, step } = :digraph.vertex(graph, step_name)
          step
        end |> :lists.reverse
        :digraph.delete(graph)
        # TODO Check that all {M,F,A} are exported
        sorted_steps
      { :error, { :vertex, :duplicate, step_name } } ->
        basic_boot_error({:duplicate_boot_step, step_name}, "Duplicate boot step name: ~p", [step_name])
      { :error, { :edge, reason, from, to } } ->
        reason_msg = case reason do
          { :bad_vertex, v } -> "Boot step not registered: #{inspect(v)}"
          { :bad_edge, l } -> "Cyclic dependency: #{inspect(l)}"
        end
        basic_boot_error(
          {:invalid_boot_step_dependency, from, to, },
          "Could not add step dependency of ~p on ~p: ~p", [from,to,reason_msg]
        )
    end
  end

  @spec boot_order :: [atom]
  @doc "Sorted list of boot step names"
  def boot_order do
    Enum.map(boot_steps, fn({ name, _ }) -> name end)
  end

  # ------ Internal

  defp compact(list), do: Enum.filter(list, fn(e) -> e != nil end)

  defp all_modules_attributes(attr_key) do
    modules = for {app, _, _} <- :application.loaded_applications, { :ok, modules } <- [:application.get_key(app, :modules)], do: modules
    Enum.reduce(List.flatten(modules), [], fn(m, acc) ->
      steps = Enum.reduce(m.module_info(:attributes), [], fn({key, val}, acc) -> if key == attr_key, do: ([ val | acc]), else: acc end) |> List.flatten
      if steps == [], do: acc, else: [{m,steps}|acc]
    end) |> List.flatten
  end

  defp run_boot_step({ step, attributes }) do
    case attributes[:mfa] do
      { m, f, a } ->
        try do
          if attributes[:disable] == true do
            Lager.warning "Boot step ~p has been disabled!", [step]
            true
          else
            :erlang.apply(m, f, a)
          end
        catch
          reason -> boot_error(step, reason, :erlang.get_stacktrace)
        end
        :ok
      _ -> :ok
    end
  end

  defp boot_error(step, reason, stack) do
    Lager.emergency "Boot failed!"
    Lager.alert "Boot error: step ~p : ~p", [step, reason]
    Lager.alert stack
    :timer.sleep(1000)
    exit({__MODULE__, :failure_during_boot, reason})
  end

  defp basic_boot_error(reason, format, args) do
    Lager.emergency "Boot failed!"
    Lager.alert "Boot error: ~p", [reason]
    Lager.alert format, args
    :timer.sleep(1000)
    exit({__MODULE__, :failure_during_boot, reason})
  end

  # ------ Acyclic Graph

  defp vertex_fun(steps) do
    for {step, atts} <- steps, do: {step, { step, atts }}
  end

  defp edge_fun(steps) do
    for {step, atts} <- steps, {key, other_step} <- atts do
      case key do
        :requires -> {step, other_step}
        :enables -> {other_step, step}
        _ -> nil
      end
    end |> compact
  end

  defp build_acyclic_graph(graph) do
    g = :digraph.new([:acyclic])
    try do
      for {_module, atts} <- graph, {vertex, label} <- vertex_fun(atts) do
        case :digraph.vertex(g, vertex) do
          false -> :digraph.add_vertex(g, vertex, label)
          _ -> throw({:graph_error, {:vertex, :duplicate, vertex}})
        end
      end
      for {_module, atts} <- graph, {from, to} <- edge_fun(atts) do
        case :digraph.add_edge(g, from, to) do
          { :error, error } -> throw({:graph_error, {:edge, error, from, to } })
          _ -> :ok
        end
      end
      { :ok, g }
    catch
      { :graph_error, reason } ->
        Lager.error "graph error ~p", [reason]
        true = :digraph.delete(g)
        { :error, reason }
    end
  end

end

