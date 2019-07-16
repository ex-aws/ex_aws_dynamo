defmodule ExAws.Dynamo.Mixfile do
  use Mix.Project

  @version "2.1.0"
  @service "ddb"
  @url "https://github.com/circles-learning-labs/ex_aws_#{@service}"
  @name "ExAws.DDB"

  def project do
    [
      app: :ex_aws_ddb,
      version: @version,
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: @name,
      package: package(),
      docs: [main: @name, source_ref: "v#{@version}", source_url: @url]
    ]
  end

  defp package do
    [
      description: "IMPORTANT!!! This package is a fork of https://hex.pm/packages/ex_aws_dynamo - it supports new features of DynamoDB, such as different billing modes - we're publishing this for use in our own https://hex.pm/packages/ecto_adapters_dynamodb. If you need to use ex_aws_dynamo in your project, we highly recommend that you use the original Hex package, as this package may not be maintained and may be unexpectedly deleted in the future.",
      files: ["lib", "config", "mix.exs", "README*"],
      licenses: ["MIT"],
      links: %{github: @url}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:hackney, ">= 0.0.0", only: [:dev, :test]},
      {:sweet_xml, ">= 0.0.0", only: [:dev, :test]},
      {:poison, ">= 0.0.0", only: [:dev, :test]},
      ex_aws()
    ]
  end

  defp ex_aws() do
    case System.get_env("AWS") do
      "LOCAL" -> {:ex_aws, path: "../ex_aws"}
      _ -> {:ex_aws, "~> 2.0"}
    end
  end
end
