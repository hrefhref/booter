defmodule Booter.Step do
  @moduledoc """
  A struct that holds step
  It contains:
  * `name`, the step name or the module who defined it,
  * `description`, an arbitrary description
  * `mfa`, a tuple containing the module, function and arguments to call,
  * `requires`,
  * `enables`,
  * `skip`,
  * `catch`,
  * `source_file`, caller environment location
  """

  @behaviour Access

  @type t :: %Booter.Step{
          name: atom,
          description: String.t(),
          mfa: :erlang.mfa(),
          requires: atom,
          enables: atom,
          skip: boolean | String.t(),
          catch: boolean,
          source_file: Macro.Env.t()
        }

  defstruct name: nil,
            description: nil,
            mfa: nil,
            requires: nil,
            enables: nil,
            skip: false,
            catch: false,
            source_file: false

  defimpl String.Chars, for: __MODULE__ do
    def to_string(step) do
      name = "step #{inspect(step.name)}"

      if step.source_file do
        name <> " (at #{step.source_file[:file]}:#{step.source_file[:line]})"
      else
        name
      end
    end
  end

  # Access callbacks the easy way
  def fetch(term, key) do
    term
    |> Map.from_struct()
    |> Map.fetch(key)
  end

  def get(term, key, default) do
    term
    |> Map.from_struct()
    |> Map.get(key, default)
  end

  def get_and_update(data, key, function) do
    data
    |> Map.from_struct()
    |> Map.get_and_update(key, function)
  end

  def pop(data, key) do
    data
    |> Map.from_struct()
    |> Map.pop(key)
  end
end
