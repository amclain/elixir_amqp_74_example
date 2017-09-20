defmodule ElixirAmqp74Example.Mixfile do
  use Mix.Project

  def project do
    [
      app: :elixir_amqp_74_example,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      preferred_cli_env: [espec: :test],
      aliases: [test: "espec"],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [
        :logger,
        :amqp,
        :exactor,
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:exactor, "2.2.3", warn_missing: false},
      # Current release fails the dialyzer; tests pass showing code is valid.
      {:amqp, "0.3.0"},
      # Fork with the updated typespec passes the dialyzer and tests.
      # {:amqp, git: "https://github.com/amclain/amqp.git", ref: "33bf97f"},
      {:dialyxir, "0.5.1", only: :dev},
      {:espec, "1.4.6", only: :test},
    ]
  end
end
