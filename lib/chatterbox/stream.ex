defmodule Chatterbox.Plug.Adapter.Stream do
  @moduledoc false
  @connection Chatterbox.Plug.Adapter.Conn
  @behaviour :h2_stream
  @already_sent {:plug_conn, :sent}

  @spec init(pid, non_neg_integer, list)
  :: {:ok, :h2_stream.callback_state}
  def init(pid, stream_id, [plug, opts]) do
    {:ok, %{h2pid: pid, id: stream_id, headers: nil,
            req_body: "", conn: nil, plug: plug, opts: opts}}
  end

  @spec on_receive_request_headers(:hpack.headers, :h2_stream.callback_state)
  :: {:ok, :h2_stream.callback_state}
  def on_receive_request_headers(headers, state) do
    {:ok, %{state| headers: headers, conn: @connection.conn(headers, state)}}
  end

  @spec on_send_push_promise(:hpack.headers, :h2_stream.callback_state)
  :: {:ok, :h2_stream.callback_state}
  def on_send_push_promise(_headers, state) do
    ## TODO: Push Promise?
    {:ok, state}
  end

  @spec on_receive_request_data(iodata, :h2_stream.callback_state)
  :: {:ok, :h2_stream.callback_state}
  def on_receive_request_data(body, state) do
     {:ok, %{state | req_body: state.req_body <> body}}
  end

  @spec on_request_end_stream(:h2_stream.callback_state)
  :: {:ok, :h2_stream.callback_state}
  def on_request_end_stream(state) do
    try do
      %{adapter: {@connection, state}} =
        state.conn
        |> state.plug.call(state.opts)
        |> maybe_send(state.plug)
      {:ok, state}
    catch
      _, _ ->
        IO.puts "Doh!"
    after
      receive do
        @already_sent -> :ok
      after
        0 -> :ok
      end
    end
  end


  defp maybe_send(%Plug.Conn{state: :unset}, _plug),      do: raise Plug.Conn.NotSentError
  defp maybe_send(%Plug.Conn{state: :set} = conn, _plug), do: Plug.Conn.send_resp(conn)
  defp maybe_send(%Plug.Conn{} = conn, _plug),            do: conn
  defp maybe_send(other, plug) do
    raise "Chatterbox adapter expected #{inspect plug} to return Plug.Conn but got: #{inspect other}"
  end
end
