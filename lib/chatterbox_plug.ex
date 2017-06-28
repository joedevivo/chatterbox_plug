defmodule Chatterbox.Plug.Adapter do
  @moduledoc """
  Documentation for Chatterbox.Plug.Adapter
  """

  def run, do: Chatterbox.Plug.Adapter.https(Chatterbox.Plug.AppRouter, [])

  def https(plug, opts) do
    Application.load(:chatterbox)
    Application.ensure_started(:ranch)
    Application.ensure_all_started(:ssl)
    settings = [
      stream_callback_opts: [plug, plug.init(opts)],
      port: 8081,
      ssl: true,
      ssl_options: [{:certfile, "test/fixtures/ssl/localhost.crt"},
                    {:keyfile, "test/fixtures/ssl/localhost.key"},
                    {:honor_cipher_order, false},
                    {:versions, [:'tlsv1.2']},
                    {:alpn_preferred_protocols, [<<"h2">>]}]
    ]

    Application.put_env(
      :chatterbox, :stream_callback_mod, Chatterbox.Plug.Adapter.Stream)

    Application.put_env(:chatterbox, :server_header_table_size, 4096)
    Application.put_env(:chatterbox, :server_enable_push, 1)
    Application.put_env(:chatterbox, :server_max_concurrent_streams, :unlimited)
    Application.put_env(:chatterbox, :server_initial_window_size, 65535)
    Application.put_env(:chatterbox, :server_max_frame_size, 16384)
    Application.put_env(:chatterbox, :server_max_header_list_size, :unlimited)
    Application.put_env(:chatterbox, :server_flow_control, :auto)

    for {key, value} <- settings, do: Application.put_env(:chatterbox, key, value)


    ## ensure client settings defaults
    Application.put_env(:chatterbox, :client_header_table_size, 4096)
    Application.put_env(:chatterbox, :client_enable_push, 1)
    Application.put_env(:chatterbox, :client_max_concurrent_streams, :unlimited)
    Application.put_env(:chatterbox, :client_initial_window_size, 65535)
    Application.put_env(:chatterbox, :client_max_frame_size, 16384)
    Application.put_env(:chatterbox, :client_max_header_list_size, :unlimited)
    Application.put_env(:chatterbox, :client_flow_control, :auto)

    {:ok, _} = Application.ensure_all_started(:chatterbox)

    {:ok, _RanchPid} =
        :ranch.start_listener(
          :chatterbox_ranch_protocol,
          10,
          :ranch_ssl,
          [{:port, 8081}|settings[:ssl_options]],
          :chatterbox_ranch_protocol,
          [])
  end
end
