defmodule SowaNotifier do
  import SowaNotifier.Helpers

  alias SowaNotifier.Api
  alias SowaNotifier.Parser

  @doc """
  Fetches the catalog page, parses the data, sends webhooks for new items, and saves successfully sent items to a JSON file.
  """
  def fetch_and_parse do
    with {:ok, html} <- Api.fetch_page(),
         {:ok, parsed_data} <- Parser.run(html) do
      existing_data = read_json_file()
      new_items = find_new_items(existing_data, parsed_data)

      successfully_sent_items =
        Enum.reduce(new_items, [], fn item, acc ->
          case Api.send_webhook(item) do
            {:ok, _response} -> [item | acc]
            _ -> acc
          end
        end)

      save_to_json_file(existing_data, successfully_sent_items)
      {:ok, successfully_sent_items}
    else
      error -> error
    end
  end
end
