defmodule TdDfLib.MixProject do
  use Mix.Project

  def project do
    [
      app: :td_df_lib,
      version: "3.5.0",
      elixir: "~> 1.6",
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

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_ecto, "~> 4.0"},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:td_cache,
       git: "https://github.com/Bluetab/td-cache.git", tag: "3.0.5", only: [:test], runtime: false}
    ]
  end
end
