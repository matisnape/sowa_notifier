defmodule SowaNotifier.MixProject do
  use Mix.Project

  def project do
    [
      app: :sowa_notifier,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {SowaNotifier.Application, []}
    ]
  end

  defp deps do
    [
      {:tesla, "~> 1.4"},
      {:floki, "~> 0.34.0"},
      {:jason, "~> 1.4"},
      {:quantum, "~> 3.0"},
      {:tzdata, "~> 1.1"},
      {:dotenv, "~> 3.0.0"},
      {:mock, "~> 0.3.0", only: :test}
    ]
  end
end
