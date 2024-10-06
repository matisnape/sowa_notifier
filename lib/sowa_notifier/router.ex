defmodule SowaNotifier.Router do
  use Plug.Router

  plug(Plug.Static,
    at: "/",
    from: {:sowa_notifier, "public/static"},
    only: ~w(index.html goodbye.html),
    only_matching: ["index"]
  )

  plug(:match)
  plug(:dispatch)

  get "/" do
    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> send_file(200, "public/static/index.html")
  end

  get "/goodbye" do
    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> send_file(200, "public/static/goodbye.html")
  end

  match _ do
    conn
    |> put_resp_header("location", "/")
    |> send_resp(302, "")
  end
end
