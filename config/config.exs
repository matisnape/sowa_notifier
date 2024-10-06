import Config
# config :tesla, adapter: Tesla.Adapter.Hackney

config :sowa_notifier, SowaScheduler,
  jobs: [
    {"*/2 * * * *", {SowaScheduler, :run, []}}
    # monday through saturday between 8 and 19 every 10 minutes
    # {"*/10 8-19 * * 1-6", {SowaScheduler, :run, []}}
  ]
