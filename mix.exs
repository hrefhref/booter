defmodule Boater.Mixfile do
  use Mix.Project

  def project do
    [
      app: :boater,
      version: "0.0.1",
      elixir: "~> 0.14.3",
      deps: deps,
    ]
  end

  defp deps do
    [
      { :ex_doc, github: "elixir-lang/ex_doc" },
      { :lager, github: "basho/lager", override: true },
      { :exlager, github: "eraserewind/exlager", branch: "elixir-10.3.3" },
    ]
  end
end
