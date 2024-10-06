defmodule SowaNotifier.Parser do
  def run(html) do
    case Floki.parse_document(html) do
      {:ok, document} ->
        books =
          document
          |> Floki.find(".record-details")
          |> Enum.map(&parse_book/1)

        {:ok, books}

      error ->
        error
    end
  end

  defp parse_book(book_element) do
    %{
      title: extract_content(book_element, ".desc-o-title"),
      publisher: extract_content(book_element, ".desc-o-publ"),
      link: extract_book_link(book_element),
      img: build_img_link(book_element),
      added_on: extract_added_on(book_element),
      available: is_available(book_element)
    }
  end

  defp extract_content(book_element, selector) do
    book_element
    |> Floki.find(selector)
    |> Floki.text()
    |> String.split()
    |> Enum.join(" ")
  end

  defp is_available(book_element) do
    book_element
    |> Floki.find(".record-av-available")
    |> case do
      [] -> ":x:"
      _ -> ":white_check_mark:"
    end
  end

  defp extract_book_link(book_element) do
    book_element
    |> Floki.find(".record-thumb-with-av div[onclick]")
    |> Floki.attribute("onclick")
    |> List.first()
    |> extract_url()
  end

  defp extract_added_on(book_element) do
    book_element
    |> Floki.find(".desc-header")
    |> Floki.text()
    |> String.split()
    |> Enum.at(2)
    |> case do
      nil -> nil
      date -> date
    end
  end

  defp extract_url(onclick) when is_binary(onclick) do
    case Regex.run(~r/location\.href='([^']+)'/, onclick) do
      [_, url] -> url
      _ -> nil
    end
  end

  defp extract_url(_), do: nil

  defp build_img_link(book_element) do
    book_element
    |> Floki.find(".record-thumb-with-av img")
    |> case do
      [img] ->
        src =
          img
          |> Floki.attribute("src")
          |> List.first()

        "https:" <> src

      _ ->
        nil
    end
  end
end
