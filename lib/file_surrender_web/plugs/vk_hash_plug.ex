defmodule FileSurrenderWeb.Plugs.VKHash do
  import Plug.Conn

  def init(options) do
    options
  end

  def call(%Plug.Conn{params: %{"hash" => hash, "provider" => "vk"} = params} = conn, _opts) do
    put_in(conn.params, params |> Map.put("code", hash))
  end

  def call(conn, _opts) do
    conn
  end
end
