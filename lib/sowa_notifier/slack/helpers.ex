defmodule SowaNotifier.Slack.Helpers do
  def format_slack_message(book) do
    timestamp = DateTime.utc_now() |> DateTime.to_string()

    base_message = [
      %{
        type: "section",
        text: %{
          type: "mrkdwn",
          text: "New book added on #{book.added_on}"
        }
      },
      %{
        type: "section",
        text: %{
          type: "mrkdwn",
          text: "*<#{book.link}|#{book.title}>*\n#{book.publisher}\nStatus: #{book.available}"
        }
      },
      %{
        type: "section",
        text: %{
          type: "mrkdwn",
          text: "Run at #{timestamp}"
        }
      }
    ]

    if book.img do
      List.update_at(base_message, 1, fn section ->
        Map.put(section, :accessory, %{
          type: "image",
          image_url: book.img,
          alt_text: "Book cover"
        })
      end)
    else
      base_message
    end
  end
end
