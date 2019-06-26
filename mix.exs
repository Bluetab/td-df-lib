defmodule TdDfLib.MixProject do
  use Mix.Project

  def project do
    [
      app: :td_df_lib,
      version: "2.21.4",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :td_cache]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_ecto, "~> 4.0"},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:td_cache,
       git: "https://github.com/Bluetab/td-cache.git",
       ref: "d471249e484bf1b469a0987f39108f30ad734cdf"}
    ]
  end
end
