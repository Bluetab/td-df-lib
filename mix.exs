defmodule TdDfLib.MixProject do
  use Mix.Project

  def project do
    [
      app: :td_df_lib,
      version: "3.23.2",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: extra_applications(Mix.env())
    ]
  end

  defp extra_applications(:test) do
    [:logger, :td_cache]
  end

  defp extra_applications(_), do: [:logger]

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_ecto, "~> 4.0"},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:ex_machina, "~> 2.3", only: [:test]},
      {:td_cache,
       git: "https://github.com/Bluetab/td-cache.git",
       tag: "3.16.1",
       only: [:test],
       runtime: false}
    ]
  end
end
