defmodule SowaNotifier.Helpers do
  # @data_file get_data_file_path()
  # @json_file_path
  @data_file Path.join(:code.priv_dir(:sowa_notifier), "parsed_books.json")

  def init_file do
    File.mkdir_p!(Path.dirname(@data_file))

    unless File.exists?(@data_file) do
      File.write!(@data_file, "[]")
    end
  end

  def save_to_json_file(existing_data, new_items) do
    updated_data = (existing_data ++ new_items) |> Enum.map(&atom_keys_to_strings/1)

    # File.mkdir_p!(Path.dirname(@json_file_path))
    File.write!(@data_file, Jason.encode!(updated_data))
  end

  def read_json_file do
    case File.read(@data_file) do
      {:ok, content} ->
        content
        |> Jason.decode!()
        |> Enum.map(&string_keys_to_atoms/1)
        |> then(&{:ok, &1})

      {:error, :enoent} ->
        {:ok, []}

      {:error, reason} ->
        raise "Error reading JSON file: #{inspect(reason)}"
    end
  end

  def find_new_items(existing_data, new_data) do
    existing_links = MapSet.new(existing_data, & &1.link)
    Enum.filter(new_data, fn item -> not MapSet.member?(existing_links, item.link) end)
  end

  defp string_keys_to_atoms(map) do
    for {key, val} <- map, into: %{}, do: {String.to_existing_atom(key), val}
  end

  defp atom_keys_to_strings(map) do
    for {key, val} <- map, into: %{}, do: {Atom.to_string(key), val}
  end

  defp get_data_file_path() do
    case System.get_env("MIX_ENV") do
      "prod" -> "/app/data/parsed_books.json"
      _ -> Path.join(File.cwd!(), "priv/parsed_books.json")
    end
  end
end
