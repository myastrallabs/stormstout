defmodule Stormstout.NFTStorage do
  @moduledoc false

  use Tesla

  @nftstorage_key Application.get_env(:stormstout, :nftstorage_key)
  @nftstorage_url "https://nftstorage.link/ipfs/"

  plug Tesla.Middleware.BaseUrl, "https://api.nft.storage/"
  plug Tesla.Middleware.JSON, engine_opts: [keys: :atoms]

  plug Tesla.Middleware.Headers, [
    {"authorization", "Bearer #{@nftstorage_key}"},
    {"content-type", "image/jpeg"}
  ]

  def upload(filepath) do
    with {:ok, filedata} <- File.read(filepath) do
      post("/upload", filedata)
    else
      _ -> {:error, "file not found"}
    end
  end

  def url(key) when is_binary(key), do: @nftstorage_url <> key
  def url({:ok, value}) when is_map(value), do: @nftstorage_url <> value.body.value.cid
  def url(value) when is_map(value), do: @nftstorage_url <> value.body.value.cid
end
