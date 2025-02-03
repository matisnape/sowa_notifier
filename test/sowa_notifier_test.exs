defmodule SowaNotifierTest do
  use ExUnit.Case
  alias SowaNotifier
  import Mock

  describe "fetch_and_parse/0" do
    test "successfully fetches, parses, and sends webhooks" do
      html = "<html><div class='record-details'>...</div></html>"
      parsed_data = [%{title: "New Book", link: "new-link"}]

      with_mocks [
        {SowaNotifier.Api, [],
         [
           fetch_page: fn -> {:ok, html} end,
           send_webhook: fn _ -> {:ok, "Webhook sent successfully"} end
         ]},
        {SowaNotifier.Parser, [], [run: fn _ -> {:ok, parsed_data} end]},
        {SowaNotifier.Helpers, [],
         [
           read_json_file: fn -> [] end,
           save_to_json_file: fn _, _ -> :ok end
         ]}
      ] do
        assert {:ok, [%{title: "New Book", link: "new-link"}]} = SowaNotifier.fetch_and_parse()
      end
    end

    test "returns error when fetch fails" do
      with_mock SowaNotifier.Api, fetch_page: fn -> {:error, "Failed to fetch"} end do
        assert {:error, "Failed to fetch"} = SowaNotifier.fetch_and_parse()
      end
    end
  end
end
