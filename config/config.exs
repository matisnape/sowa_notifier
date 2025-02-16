import Config
# config :tesla, adapter: Tesla.Adapter.Hackney
config :sowa_notifier, webhook_url: System.get_env("SOWA_NOTIFIER_WEBHOOK_URL")

config :ex_gram,
  token: System.get_env("TELEGRAM_BOT_TOKEN")
  token: System.get_env("TELEGRAM_BOT_TOKEN"),
  wbpicak: System.get_env("WBPICAK_CHANNEL_ID")

config :sowa_notifier, SowaScheduler,
  jobs: [
    # every minute
    # {"*/1 * * * *", {SowaScheduler, :run, []}}
    # monday through saturday between 8 and 19 every 4 minutes
    {"*/3 8-19 * * 1-6", {SowaScheduler, :run, []}}
  ]
