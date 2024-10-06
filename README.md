# SowaNotifier

SowaNotifier is an Elixir application that monitors the catalog of the Wielkopolska Public Library (WBP) in Poznań for new book additions. It fetches the catalog page, parses the data, and sends notifications about new items via a webhook.

## Features

- Fetches and parses the WBP Poznań catalog page
- Detects new book additions
- Sends notifications via webhook
- Stores processed data to avoid duplicate notifications

## Installation

1. Clone the repository:
   ```
   git clone https://github.com/your-username/sowa_notifier.git
   cd sowa_notifier
   ```

2. Install dependencies:
   ```
   mix deps.get
   ```

3. Create a `.env` file in the project root with the following content:
   ```
   SOWA_NOTIFIER_WEBHOOK_URL=your_webhook_url_here
   ```
   Replace `your_webhook_url_here` with your actual webhook URL.

4. Compile the project:
   ```
   mix compile
   ```

## Configuration

The application uses environment variables for configuration. Make sure to set up the following:

- `SOWA_NOTIFIER_WEBHOOK_URL`: The URL of the webhook to send notifications to.

You can set these in your `.env` file for development or directly in your environment for production.

## Usage

To run the application:

```
mix run --no-halt
```

The application will periodically check for new books and send notifications as configured.

## Development

To run the application in interactive mode:

```
iex -S mix
```

You can then manually trigger the fetch and parse process:

```elixir
SowaNotifier.fetch_and_parse()
```

## Testing

Run the test suite with:

```
mix test
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -am 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

