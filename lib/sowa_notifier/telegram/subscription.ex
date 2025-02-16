defmodule SowaNotifier.Telegram.Subscription do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, MapSet.new(initial_subscribers())}
  end

  def subscribe(chat_id) do
    GenServer.cast(__MODULE__, {:subscribe, chat_id})
  end

  def get_subscribers do
    GenServer.call(__MODULE__, :get_subscribers)
  end

  def handle_cast({:subscribe, chat_id}, subscribers) do
    {:noreply, MapSet.put(subscribers, chat_id)}
  end

  def handle_call(:get_subscribers, _from, subscribers) do
    {:reply, MapSet.to_list(subscribers), subscribers}
  end

  defp initial_subscribers do
    [Application.fetch_env!(:ex_gram, :wbpicak)]
  end
end
