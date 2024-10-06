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
    timestamp = DateTime.utc_now() |> DateTime.to_string()

    payload = %{
      text: "Data downloaded!",
      timestamp: timestamp,
      book: book
    }

    case post(webhook_url(), payload) do
      {:ok, %{status: 200}} ->
        IO.puts("Webhook sent successfully for #{book.title}")
        {:ok, "Webhook sent successfully"}

      {:error, reason} ->
        IO.puts("Failed to send webhook: #{inspect(reason)}")
        {:error, "Failed to send webhook: #{inspect(reason)}"}
    end
  end

  defp webhook_url() do
    Application.fetch_env!(:sowa_notifier, :webhook_url)
  end
end
