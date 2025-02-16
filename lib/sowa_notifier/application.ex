defmodule SowaNotifier.Application do
  use Application

  def start(_type, _args) do
    unless Mix.env() == :prod do
      Dotenv.load()
      Mix.Task.run("loadconfig")
    end

    SowaNotifier.Helpers.init_file()

    children = [
      SowaScheduler,
      {Plug.Cowboy, scheme: :http, plug: SowaNotifier.Router, options: [port: 8080]},
      ExGram,
      {SowaNotifier.Telegram.Bot, [method: :polling, token: telegram_token()]},
      SowaNotifier.Telegram.Subscription
    ]

    opts = [strategy: :one_for_one, name: SowaNotifier.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp telegram_token do
    Application.fetch_env!(:ex_gram, :token)
  end
end
