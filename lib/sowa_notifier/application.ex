defmodule SowaNotifier.Application do
  use Application

  def start(_type, _args) do
    unless Mix.env() == :prod do
      Dotenv.load()
      Mix.Task.run("loadconfig")
    end

    children = [
      SowaScheduler
    ]

    opts = [strategy: :one_for_one, name: SowaNotifier.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
