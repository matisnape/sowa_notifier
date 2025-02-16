defmodule SowaNotifier.Telegram.Bot do
  use ExGram.Bot,
    name: :sowa_bot,
    setup_commands: true

  command("start", description: "Start the bot")
  command("help", description: "Show help message")
  command("subscribe", description: "Subscribe to library updates")

  def handle({:command, :start, _msg}, context) do
    answer(context, "Hello! I'm SowaBot. I can help you with library updates.")
  end

  def handle({:command, :help, _msg}, context) do
    answer(
      context,
      "Available commands:\n/start - Start the bot\n/help - Show this message\n/subscribe - Subscribe to library updates"
    )
  end

  def handle({:command, :subscribe, %{chat: chat}}, context) do
    SowaNotifier.Telegram.Subscription.subscribe(chat.id)

    answer(context, "Subscribed to Sowa Notifier")
  end

  def handle({:text, _text, _msg}, context) do
    answer(context, "hello")
  end

  def handle({:update, %{my_chat_member: %{chat: chat}} = _update, context}) do
    IO.puts("Bot status updated in chat: #{chat.title} (#{chat.id})")

    {:ok, context}
  end

  def notify_subscriber(item, subscribers) do
    message = format_book_message(item)

    for chat_id <- subscribers do
      if item.img do
        ExGram.send_photo(chat_id, item.img, caption: message, parse_mode: "HTML")
      else
        ExGram.send_message(chat_id, message, parse_mode: "HTML")
      end
    end

    # TODO: retries for failed messages

    {:ok, item}
  end

  defp format_book_message(book) do
    timestamp = DateTime.utc_now() |> DateTime.to_string()

    """
    🆕 <b>New book added on #{book.added_on}</b>

    <b><a href="#{book.link}">#{book.title}</a></b>
    #{book.publisher}
    Status: #{if book.available == ":white_check_mark:", do: "✅", else: "❌"}

    🕒 Run at #{timestamp}
    """
  end
end
