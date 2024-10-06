defmodule SowaScheduler do
  use Quantum, otp_app: :sowa_notifier

  def run do
    case SowaNotifier.fetch_and_parse() do
      {:ok, items} ->
        IO.puts("Successfully fetched and processed #{length(items)} new items")

      {:error, reason} ->
        IO.puts("Error occurred: #{inspect(reason)}")
    end
  end
end
