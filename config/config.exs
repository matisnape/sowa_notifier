import Config
# config :tesla, adapter: Tesla.Adapter.Hackney

config :sowa_notifier, SowaScheduler,
  jobs: [
    {"*/2 * * * *", {SowaScheduler, :run, []}}
  ]
