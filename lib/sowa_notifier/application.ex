defmodule SowaNotifier.Application do
  use Application

  def start(_type, _args) do
    unless Mix.env() == :prod do
      Dotenv.load()
      Mix.Task.run("loadconfig")
    end

    children = [
      SowaScheduler,
      {Plug.Cowboy, scheme: :http, plug: SowaNotifier.Router, options: [port: 8080]}
    ]

    opts = [strategy: :one_for_one, name: SowaNotifier.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
