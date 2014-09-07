defmodule Booter.Mixfile do
  use Mix.Project

  def project do
    [app: :booter,
     version: "0.0.1",
     elixir: "~> 1.0.0-rc1",
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.5", only: :dev},
   ]
  end
end
