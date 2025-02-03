defmodule SowaNotifier.ParserTest do
  use ExUnit.Case
  alias SowaNotifier.Parser

  @sample_html """
  <div class="record-details">
    <div class="desc-o-title">Sample Book</div>
    <div class="desc-o-publ">Sample Publisher</div>
    <div class="record-thumb-with-av">
      <div onclick="location.href='/sample-link'"></div>
      <img src="//sample-image.jpg" />
    </div>
    <div class="desc-header">Added on 2023-04-20</div>
    <div class="record-av-available"></div>
  </div>
  """

  describe "run/1" do
    test "successfully parses HTML" do
      assert {:ok, [parsed_book]} = Parser.run(@sample_html)
      assert parsed_book.title == "Sample Book"
      assert parsed_book.publisher == "Sample Publisher"
      assert parsed_book.link == "/sample-link"
      assert parsed_book.img == "https://sample-image.jpg"
      assert parsed_book.added_on == "2023-04-20"
      assert parsed_book.available == ":white_check_mark:"
    end
  end
end
