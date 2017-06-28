defmodule Chatterbox.Plug.Adapter.Conn do
  @behaviour Plug.Conn.Adapter
  @moduledoc false

  def conn(headers, stream) do
    %Plug.Conn{
      adapter: {__MODULE__, stream},
      owner: self(),
      req_headers: headers,
    }
    |> safe_put(:host, List.keyfind(headers, ":host", 0))
    |> safe_put(:method, List.keyfind(headers, ":method", 0))
    |> safe_put(:request_path, List.keyfind(headers, ":path", 0))
    |> safe_put(:scheme, List.keyfind(headers, ":scheme", 0, "https"))
    |> Map.put(:path_info, split_path(elem(List.keyfind(headers, ":path", 0), 1)))
  end

  def chunk(stream, body) do
    :h2_connection.send_body(stream.h2pid, stream.id, body,
      [{:send_end_stream, :false}])
    :ok
  end

  def read_req_body(stream, _opts \\ []) do
    {:ok, stream.req_body, stream}
  end

  def send_chunked(stream, status, headers) do
    headers = [{":status", Integer.to_string(status)} | headers]
    :h2_connection.send_headers(stream.h2pid, stream.id, headers)
    { :ok, nil, stream }
  end

  def send_file(stream, _status, _headers, _path, _offset, _length) do
    {:ok, nil, stream}
  end

  def send_resp(stream, status, headers, body) do
    headers = [
      {":status", Integer.to_string(status)} | headers]
    :h2_connection.send_headers(stream.h2pid, stream.id, headers)
    :h2_connection.send_body(stream.h2pid, stream.id, body)
    {:ok, nil, stream}
  end

  defp safe_put(conn, _key, nil) do
    conn
  end

  defp safe_put(conn, key, {_http2_header_name, value}) do
    Map.put(conn, key, value)
  end

  defp split_path(path) do
    segments = :binary.split(path, "/", [:global])
    for segment <- segments, segment != "", do: segment
  end
end
