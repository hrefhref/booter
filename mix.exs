defmodule Boater.Mixfile do
  use Mix.Project

  def project do
    [
      app: :boater,
      version: "0.0.1",
      elixir: "~> 0.12.3-dev",
      deps: deps,
    ]
  end

  defp deps do
    [
      { :ex_doc, github: "elixir-lang/ex_doc" },
      { :lager, github: "basho/lager", override: true },
      { :exlager, ">= 0", github: "khia/exlager" },
    ]
  end
end
