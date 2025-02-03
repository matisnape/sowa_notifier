defmodule SowaNotifier.ApiTest do
  use ExUnit.Case
  alias SowaNotifier.Api
  import Tesla.Mock

  @base_url "https://katalog.wbp.poznan.pl/index.php?KatID=2&typ=repl&plnk=nowosci&sort=dat"
  @webhook_url "https://your-webhook-url.com"

  setup do
    mock(fn
      %{method: :get, url: @base_url} ->
        %Tesla.Env{status: 200, body: "<html></html>"}

      %{method: :post, url: @webhook_url} ->
        %Tesla.Env{status: 200, body: "Webhook received"}

      _ ->
        %Tesla.Env{status: 404, body: "Not found"}
    end)

    :ok
  end

  describe "fetch_page/0" do
    test "successfully fetches the page" do
      assert {:ok, "<html></html>"} = Api.fetch_page()
    end

    test "returns error on non-200 status" do
      mock(fn
        %{method: :get, url: @base_url} ->
          %Tesla.Env{status: 404, body: "Not Found"}
      end)

      assert {:error, "HTTP request failed with status code: 404"} = Api.fetch_page()
    end

    test "returns error on network failure" do
      mock(fn
        %{method: :get, url: @base_url} ->
          {:error, :timeout}
      end)

      assert {:error, "HTTP request failed: :timeout"} = Api.fetch_page()
    end
  end

  describe "send_webhook/1" do
    test "successfully sends webhook" do
      book = %{title: "Test Book"}
      assert {:ok, "Webhook sent successfully"} = Api.send_webhook(book)
    end

    test "returns error on webhook failure" do
      book = %{title: "Test Book"}

      mock(fn
        %{method: :post, url: @webhook_url} ->
          {:error, :timeout}
      end)

      assert {:error, "Failed to send webhook: :timeout"} = Api.send_webhook(book)
    end
  end
end
