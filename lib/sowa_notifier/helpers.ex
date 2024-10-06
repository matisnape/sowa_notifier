defmodule SowaNotifier.Helpers do
  @json_file_path Path.join(:code.priv_dir(:sowa_notifier), "parsed_books.json")

  def save_to_json_file(existing_data, new_items) do
    updated_data = (existing_data ++ new_items) |> Enum.map(&atom_keys_to_strings/1)
    File.write!(@json_file_path, Jason.encode!(updated_data))
  end

  def read_json_file do
    case File.read(@json_file_path) do
      {:ok, content} ->
        Jason.decode!(content)
        |> Enum.map(&string_keys_to_atoms/1)

      {:error, :enoent} ->
        []

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
end
