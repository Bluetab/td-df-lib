defmodule TdDfLib.MixProject do
  use Mix.Project

  def project do
    [
      app: :td_df_lib,
      version: "7.7.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:td_cache]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7.11", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4.5", only: :dev, runtime: false},
      {:ecto, "~> 3.12.5"},
      {:ex_machina, "~> 2.8", only: :test},
      {:nimble_csv, "~> 1.2"},
      {:td_cache, git: "https://github.com/Bluetab/td-cache.git", branch: "feature/td-7401"}
    ]
  end
end
