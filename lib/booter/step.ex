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

  @derive [Access, Enumerable]

  @type t :: %Booter.Step{name: atom, description: String.t, mfa: :erlang.mfa,
              requires: atom, enables: atom, skip: boolean | String.t, catch: boolean, source_file: Macro.Env.t}

  defstruct name: nil, description: nil, mfa: nil, requires: nil, enables: nil, skip: false, catch: false, source_file: false

  defimpl String.Chars, for: __MODULE__ do
    def to_string(step) do
      name = "step #{inspect step.name}"
      if step.source_file do
        name <> " (at #{step.source_file[:file]}:#{step.source_file[:line]})"
      else
        name
      end
    end
  end

end
