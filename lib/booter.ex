defmodule Booter do
  @moduledoc """
  Booter allows modules to define a list of **boot steps** using module attributes. Each step define what to call, what
  it requires and enables. A directed acyclic graph is then created from theses steps and progressively executed.

  Why? Complicated applications can be composed of multiple subsystems or groups or processes, independants or dependants of
  each others. And starting theses subsystems is not easy as `:application.start/2` or a supervisor child spec.

  Inspired/adapted to Elixir by RabbitMQ's boot process implemented in [rabbit.erl][1] and [rabbit_misc.erl][2]. For an
  in-depth explaination, read Alvaro Videla's [article][3] and [slides][2].

  ## Usage

  ### Defining boot steps

  Using `boot_step/3` macro (recommended):

  ```elixir
  defmodule MyModule do
    use Booter

    # without name (__MODULE__ is assumed)
    boot_step mfa: {mod, fun, args}, requires: :required_step, enables: :another_step

    # with name
    boot_step :awesome_name, mfa: {mod, fun, args}, requires: :required_step, enables: :another_step

    # With name and description
    boot_step :awesome_name, "Unicorn generator", mfa: {mod,fun,args}, requires: :rainbow_server, enables: :magic
  end
  ```

  Or without:

  ```elixir
  defmodule MyModule do
    Module.register_attribute __MODULE__, :boot_step, accumulate: true, persist: true

    @boot_step %Booter.Step{name: :awesome_step, description: "Awesome things",
                            mfa: { :application, :start, [:awesome] },
                            requires: awesome_step}
  end
  ```

  ### Start boot

  Just call `Booter.boot!`. Can raise exceptions.

  Usually called in `start/2` of Application behaviour.

  ```elixir
    defmodule MyApp do
      use Application

      def start(_) do
        # Start your main supervisor
        { :ok, pid } = Supervisor.start_link()
        # Boot the rest
        Booter.boot!
        { :ok, pid }
      end
    end
  ```

  [1]: https://github.com/videlalvaro/rabbit-internals/blob/master/rabbit_boot_process.md
  [2]: http://fr.slideshare.net/old_sound/rabbitmq-boot-system
  [2]: https://github.com/rabbitmq/rabbitmq-server/blob/master/src/rabbit.erl
  [3]: https://github.com/rabbitmq/rabbitmq-server/blob/master/src/rabbit_misc.erl
  """

  require Logger
  alias Booter.Step
  alias Booter.Graph
  alias Booter.Error

  defmacro __using__(_opts) do
    quote do
      require Booter
      import Booter, only: :macros
      Module.register_attribute __MODULE__, :boot_step, accumulate: true, persist: true
    end
  end

  @doc "Macro to define a boot_step"
  @spec boot_step(atom | nil, String.t | nil, Keyword.t) :: no_return
  defmacro boot_step(name \\ nil, description \\ nil, options) do
    options = Dict.put_new(options, :source_file, Macro.Env.location(__CALLER__))
    quote do
      step = unquote(options)
        |> Dict.put_new(:name, unquote(name) || __MODULE__)
        |> Dict.put_new(:description, unquote(description))
        |> (&(struct(Booter.Step, &1))).()
      @boot_step step
    end
  end

  @doc "Boot the steps"
  @spec boot!([module, ...] | nil) :: [{ :ok | :skip | :no_mfa | :error, Step.t, any }, ...]
  def boot!(modules \\ nil) do
    ordered_modules_steps(modules)
      |> log_boot_start
      |> Enum.map(&run_boot_step/1)
      |> log_boot_end
  end

  @doc "List steps of the given list of modules"
  @spec modules_steps([module, ...] | nil) :: [Step.t, ...]
  def modules_steps(modules \\ nil) do
    modules || all_loaded_modules
      |> Enum.reduce([], fn(module, acc) ->
            steps = module_steps(module)
          if steps == [], do: acc, else: [steps | acc]
        end)
      |> List.flatten
  end

  @doc "List steps of the given `module`"
  @spec module_steps(module) :: [Step.t, ...]
  # FIXME: Steps may conflict. Raise an exception, return an error ?
  def module_steps(module) do
    module.module_info(:attributes)
      |> Keyword.get_values(:boot_step)
      |> List.flatten
  end

  @doc "List steps of the given `modules` and order them using `ordered_steps/1`"
  @spec ordered_modules_steps([module, ...] | nil) :: [Step.t, ...]
  def ordered_modules_steps(modules \\ nil) do
    ordered_steps(modules_steps(modules))
  end

  @doc "Orders a list of boot steps"
  @spec ordered_steps([Step.t, ...]) :: [Step.t, ...]
  def ordered_steps(unordered_steps) do
    case Graph.build_acyclic_graph(unordered_steps) do
      { :ok, graph } ->
        ordered_steps = for step_name <- :digraph_utils.topsort(graph) do
          { _step_name, step } = :digraph.vertex(graph, step_name)
          step
        end |> :lists.reverse
        :digraph.delete(graph)
        ordered_steps
      { :error, { :vertex, :duplicate, step, vertex } } ->
        raise Error.DuplicateStep, duplicate: step, vertex: vertex
      { :error, { :edge, reason, step, from, to } } ->
        case reason do
          { :bad_vertex, vertex } -> raise Error.UnknownDependency, step: step, from: from, to: to, vertex: vertex
          { :bad_edge, edge } -> raise Error.CyclicDependency, step: step, from: from, to: to, edge: edge
        end
    end
  end

  @doc false
  @spec run_boot_step(Step.t) :: { :ok | :skip | :no_mfa | :error, Step.t, any }
  def run_boot_step(step) do
    case step.mfa do
      mfa={_m, _f, _a} -> safe_apply(step, mfa)
      _ -> {:no_mfa, step, nil}
    end
  end

  defp all_loaded_modules do
    modules = for {app, _, _} <- :application.loaded_applications, { :ok, modules } <- [:application.get_key(app, :modules)], do: modules
    List.flatten(modules)
  end

  defp safe_apply(step, {m, f, a}) do
    try do
      if step.skip do
        Logger.warn "Booter: skipping #{step}: #{inspect step.skip}"
        {:skip, step, step.skip}
      else
        {:ok, step, apply(m, f, a)}
      end
    rescue
      error ->
        handle_error(step, error)
    catch
      error ->
        handle_error(step, error)
    end
  end

  defp handle_error(step, error) do
    if step[:catch] do
      Logger.error "Booter: catched error in #{step}: #{inspect error}"
      {:error, step, error}
    else
      raise Error.StepError, step: step, error: error, stacktrace: System.stacktrace
    end
  end

  defp log_boot_start(steps) do
    Enum.each(steps, fn(step) ->
      Logger.debug "Booter: loaded #{step} - requires #{inspect step.requires}, enables #{inspect step.enables}"
    end)
    Logger.info "Booter: booting #{Enum.count(steps)} steps."
    steps
  end

  defp log_boot_end(return) do
    ok = Enum.filter(return, fn({status, _, _}) -> status == :ok end)
    skip = Enum.filter(return, fn({status, _, _}) -> status == :skip end)
    no_mfa = Enum.filter(return, fn({status, _, _}) -> status == :no_mfa end)
    error = Enum.filter(return, fn({status, _, _}) -> status == :error end)
    Logger.info "Booter: completed ok:#{Enum.count(ok)} error:#{Enum.count(error)} skip:#{Enum.count(skip)} no_mfa:#{Enum.count(no_mfa)}"
    return
  end

  defp log_boot_failure(step) do
    Logger.error "Booter: aborted at step #{step}"
  end

end
