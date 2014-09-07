defmodule Booter.Error do
  @moduledoc false

  defmodule DuplicateStep do
    defexception [:duplicate, :vertex]

    def message(error) do
      "Duplicate step: #{error.duplicate} is already defined by #{error.vertex}"
    end
  end

  defmodule UnknownDependency do
    defexception [:step, :from, :to, :vertex]

    def message(error) do
      "Unknown dependency: #{inspect error.vertex} from #{error.step} (#{inspect error.from} -> #{inspect error.to})"
    end
  end

  defmodule CyclicDependency do
    defexception [:step, :from, :to, :edge]

    def message(error) do
      # Cyclic dependency on step :flying_unicorn (at /Users/j/dev/booter/test/booter_test.exs:108), from :flying_unicorn to magic, edge: [:magic, :flying_unicorn]
      # step, from, to, edge
      "Cyclic dependency on #{error.step} and step #{inspect error.to}"
    end
  end

  defmodule StepError do
    defexception [:step, :error, :stacktrace]

    def message(error) do
      "Exception in #{error.step}: #{inspect error.error}"
    end
  end
end
