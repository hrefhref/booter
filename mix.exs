defmodule Booter.Mixfile do
  use Mix.Project

  def project do
    [
      app: :booter,
      version: "0.3.0",
      elixir: "~> 1.7",
      description: "Boot an Elixir application step by step",
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:earmark, "~> 1.3", only: :dev},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      contributors: ["Jordan Bracco", "Jordan Parker"],
      licenses: ["Mozilla Public License 1.1"],
      links: %{
        "GitHub" => "https://github.com/hrefhref/booter",
        "Docs" => "http://hrefhref.github.io/booter"
      }
    ]
  end
end
