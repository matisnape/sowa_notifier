defmodule SowaNotifier.Telegram.Bot do
  use ExGram.Bot,
    name: :sowa_bot,
    setup_commands: true

  command("start", description: "Start the bot")
  command("help", description: "Show help message")

  def handle({:command, :start, _msg}, context) do
    answer(context, "Hello! I'm SowaBot. I can help you with library updates.")
  end

  def handle({:command, :help, _msg}, context) do
    answer(context, "Available commands:\n/start - Start the bot\n/help - Show this message")
  end

  def handle({:text, _text, _msg}, context) do
    answer(context, "hello")
  end
end
