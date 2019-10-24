defmodule ExAws.Dynamo.Mixfile do
  use Mix.Project

  @version "2.3.3"
  @service "dynamo"
  @url "https://github.com/ex-aws/ex_aws_#{@service}"
  @name __MODULE__ |> Module.split() |> Enum.take(2) |> Enum.join(".")

  def project do
    [
      app: :ex_aws_dynamo,
      version: @version,
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: @name,
      package: package(),
      docs: [main: @name, source_ref: "v#{@version}", source_url: @url],
      aliases: aliases()
    ]
  end

  defp package do
    [
      description: "#{@name} service package",
      files: ["lib", "config", "mix.exs", "README*"],
      maintainers: ["Darren Klein", "Franko Franicevich", "Gilad Barkan", "Ben Wilson"],
      licenses: ["MIT"],
      links: %{github: @url}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:test_options), do: ["lib", "test/support"]
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
      {:hackney, ">= 0.0.0", only: [:dev, :test, :test_options]},
      {:sweet_xml, ">= 0.0.0", only: [:dev, :test, :test_options]},
      {:poison, ">= 0.0.0", only: [:dev, :test, :test_options]},
      ex_aws()
    ]
  end

  defp ex_aws() do
    case System.get_env("AWS") do
      "LOCAL" -> {:ex_aws, path: "../ex_aws"}
      _ -> {:ex_aws, "~> 2.0"}
    end
  end

  defp aliases do
    [
      {:"test.all", [&run_tests/1, "test.options"]},
      {:"test.options", [&run_options_tests/1]}
    ]
  end

  defp run_tests(_) do
    Mix.shell().cmd(
      "mix test --color",
      env: [{"MIX_ENV", "test"}]
    )
  end

  defp run_options_tests(_) do
    IO.puts("\nRunning tests with options enabled...")

    Mix.shell().cmd(
      "mix test --color",
      env: [{"MIX_ENV", "test_options"}]
    )
  end
end
