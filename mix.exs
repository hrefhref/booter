defmodule Booter.Mixfile do
  use Mix.Project

  def project do
    [app: :booter,
     version: "0.2.0",
     elixir: "~> 1.4",
     description: "Boot an Elixir application step by step",
     package: package(),
     deps: deps()]
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

  defp package do
    [files: ["lib", "mix.exs", "README.md", "LICENSE"],
      contributors: ["Jordan Bracco", "Jordan Parker"],
      licenses: ["Mozilla Public License 1.1"],
      links: %{"GitHub" => "https://github.com/eraserewind/booter",
                "Docs" => "http://eraserewind.github.io/booter"}]
  end
end
