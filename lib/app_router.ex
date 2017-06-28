defmodule Chatterbox.Plug.AppRouter do
  use Plug.Router
  #use Plug.ErrorHandler
  plug :match
  plug :dispatch
  get "/hello" do
    send_resp(conn, 200, "world")
  end
  match _ do
    send_resp(conn, 404, "oops")
  end
  defp handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, conn.status, "Something went wrong")
  end
end
