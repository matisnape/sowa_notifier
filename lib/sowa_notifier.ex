defmodule SowaNotifier do
  import SowaNotifier.Helpers

  alias SowaNotifier.Api
  alias SowaNotifier.Telegram.Bot
  alias SowaNotifier.Parser

  @doc """
  Fetches the catalog page, parses the data, sends webhooks for new items, and saves successfully sent items to a JSON file.
  """
  def fetch_and_parse() do
    with {:ok, html} <- Api.fetch_page(url()),
         {:ok, parsed_data} <- Parser.run(html),
         {:existing_data, {:ok, existing_data}} <- {:existing_data, read_json_file()},
         {:new_items, new_items} <- {:new_items, find_new_items(existing_data, parsed_data)},
         {:notified, successfully_sent_items} <- {:notified, notify_all(new_items)} do
      save_to_json_file(existing_data, successfully_sent_items)

      {:ok, successfully_sent_items}
    else
      error -> error
    end
  end

  defp notify_all([]), do: []

  defp notify_all(items) do
    items
    |> notify_slack()
    |> notify_telegram_subscribers()
  end

  defp notify_slack(items) do
    Enum.reduce(items, [], fn item, acc ->
      case Api.send_webhook(item) do
        {:ok, _response} ->
          Process.sleep(5000)
          [item | acc]

        _ ->
          acc
      end
    end)
  end

  defp notify_telegram_subscribers(items) do
    subscribers = SowaNotifier.Telegram.Subscription.get_subscribers()

    Enum.reduce(items, [], fn item, acc ->
      case Bot.notify_subscriber(item, subscribers) do
        {:ok, _response} ->
          # TODO: 30 messages per second limit https://core.telegram.org/bots/faq#my-bot-is-hitting-limits-how-do-i-avoid-this
          Process.sleep(5000)
          [item | acc]

        _ ->
          acc
      end
    end)
  end

  defp url() do
    Application.fetch_env!(:sowa_notifier, :libraries)
    |> Keyword.fetch!(:wbpicak)
    |> Keyword.fetch!(:url)
  end
end
