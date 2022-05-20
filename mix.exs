defmodule TdDfLib.MixProject do
  use Mix.Project

  def project do
    [
      app: :td_df_lib,
      version: "4.44.0",
      elixir: "~> 1.11",
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

  defp extra_applications(_), do: []

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ecto, "~> 3.0"},
      {:ex_machina, "~> 2.3", only: :test},
      {:td_cache, git: "https://github.com/Bluetab/td-cache.git", tag: "4.40.3"}
    ]
  end
end
