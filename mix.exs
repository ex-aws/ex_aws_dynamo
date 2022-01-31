defmodule ExAws.Dynamo.Mixfile do
  use Mix.Project

  @version "4.0.2"
  @service "dynamo"
  @url "https://github.com/ex-aws/ex_aws_#{@service}"
  @name __MODULE__ |> Module.split() |> Enum.take(2) |> Enum.join(".")

  def project do
    [
      app: :ex_aws_dynamo,
      version: @version,
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: @name,
      package: package(),
      docs: docs(),
      aliases: aliases()
    ]
  end

  defp package do
    [
      description: "#{@name} service package",
      files: ["lib", "config", "mix.exs", "README*", "CHANGELOG*"],
      maintainers: ["Darren Klein", "Ben Wilson"],
      licenses: ["MIT"],
      links: %{
        Changelog: "https://hexdocs.pm/ex_aws_dynamo/changelog.html",
        GitHub: @url
      }
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:hackney, ">= 0.0.0", only: [:dev, :test]},
      {:jason, ">= 0.0.0", only: [:dev, :test]},
      {:sweet_xml, ">= 0.0.0", only: [:dev, :test]},
      ex_aws()
    ]
  end

  defp ex_aws() do
    case System.get_env("AWS") do
      "LOCAL" -> {:ex_aws, path: "../ex_aws"}
      _ -> {:ex_aws, ">= 2.1.3"}
    end
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md",
        "README.md",
        "UPGRADE.md"
      ],
      main: "readme",
      source_url: @url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end

  defp aliases do
    [
      code_quality: ["format", "credo --strict", "dialyzer"]
    ]
  end
end
