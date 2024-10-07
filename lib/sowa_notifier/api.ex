defmodule SowaNotifier.Api do
  use Tesla

  plug(Tesla.Middleware.Headers, [{"user-agent", "SowaNotifier Bot"}])
  plug(Tesla.Middleware.JSON)

  @url "https://katalog.wbp.poznan.pl/index.php?KatID=2&typ=repl&plnk=nowosci&sort=dat"

  def fetch_page do
    case get(@url) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{status: status}} ->
        {:error, "HTTP request failed with status code: #{status}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  def send_webhook(book) do
    payload = %{blocks: format_slack_message(book)}

    case post(webhook_url(), payload) do
      {:ok, %{status: 200}} ->
        IO.puts("Webhook sent successfully for #{book.title}")
        {:ok, "Webhook sent successfully"}

      {:error, reason} ->
        IO.puts("Failed to send webhook: #{inspect(reason)}")
        {:error, "Failed to send webhook: #{inspect(reason)}"}
    end
  end

  defp format_slack_message(book) do
    timestamp = DateTime.utc_now() |> DateTime.to_string()

    base_message = [
      %{
        type: "section",
        text: %{
          type: "mrkdwn",
          text: "New book added on #{book.added_on}"
        }
      },
      %{
        type: "section",
        text: %{
          type: "mrkdwn",
          text: "*<#{book.link}|#{book.title}>*\n#{book.publisher}\nStatus: #{book.available}"
        }
      },
      %{
        type: "section",
        text: %{
          type: "mrkdwn",
          text: "Run at #{timestamp}"
        }
      }
    ]

    if book.img do
      List.update_at(base_message, 1, fn section ->
        Map.put(section, :accessory, %{
          type: "image",
          image_url: book.img,
          alt_text: "Book cover"
        })
      end)
    else
      base_message
    end
  end

  defp webhook_url() do
    Application.fetch_env!(:sowa_notifier, :webhook_url)
  end
end
