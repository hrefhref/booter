defmodule Boater.Mixfile do
  use Mix.Project

  def project do
    [
      app: :boater,
      version: "0.0.1",
      elixir: "~> 0.15.1",
      deps: deps,
    ]
  end

  defp deps do
    [
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.5", only: :dev},
   ]
  end
end
