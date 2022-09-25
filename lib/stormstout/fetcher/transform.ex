defmodule Stormstout.Fetcher.Transform do
  @moduledoc false

  alias Stormstout.Fetcher.TaskData

  def integerfy(id) when is_binary(id), do: String.to_integer(id)
  def integerfy(id), do: id

  def stringfy(v) when is_binary(v), do: v
  def stringfy(v) when is_integer(v), do: to_string(v)
  def stringfy(v) when is_atom(v), do: to_string(v)
  def stringfy(v), do: v

  def params_set(event_list, task_data) do
    event_params = event_params_set(event_list, task_data)
    order_params = order_params_set(event_list)
    token_params = token_params_set(event_list)
    # collections

    {:ok,
     %{
       events: %{params: event_params},
       orders: %{params: order_params},
       tokens: %{params: token_params}
     }}
  end

  def token_params_set(event_list) do
    event_list
    |> Enum.group_by(&get_token_id(&1))
    |> Enum.map(fn {token_id, _} ->
      %{
        property_version: token_id.property_version,
        token_id: token_id,
        collection_name: token_id.token_data_id.collection,
        creator: token_id.token_data_id.creator,
        name: token_id.token_data_id.name
      }
    end)
  end

  def order_params_set(event_list) do
    event_list
    |> Enum.map(&to_elixir/1)
    |> Enum.map(&order_to_params(&1))
    |> Enum.reject(&is_nil/1)
  end

  def event_params_set(event_list, task_data) do
    event_list
    |> Enum.map(&to_elixir/1)
    |> Enum.map(&event_to_params(&1, task_data))
  end

  defp to_elixir(event), do: Enum.into(event, %{}, &entry_to_elixir/1)

  defp entry_to_elixir({key, value}) when key in ~w(sequence_number version), do: {key, integerfy(value)}
  defp entry_to_elixir(entry), do: entry

  defp event_to_params(event_data, task_data) do
    %{
      sequence_number: event_data.sequence_number,
      token_id: get_token_id(event_data),
      event_handle_id: TaskData.event_handle_id(task_data),
      data: event_data.data,
      account: task_data.account,
      version: event_data.version,
      type: event_data.type,
      key: event_data.key
    }
  end

  defp order_to_params(%{type: "0x1deec95982be38fe32d02e0c3018a7c6730df74c71b838f40aebcc6d48f6472b::marketplace::ListTokenEvent"} = event_data) do
    %{
      data: event_data.data,
      version: event_data.version,
      type: event_data.type,
      sequence_number: event_data.sequence_number,
      key: event_data.key,
      token_id: get_token_id(event_data),
      status: "ongoing",
      price: event_data.data.price,
      maker: event_data.data.seller,
      taker: get_in(event_data, [:data, :buyer]),
      timestamp: event_data.data.timestamp,
      order_id: event_data.data.offer_id
    }
  end

  defp order_to_params(%{type: "0x1deec95982be38fe32d02e0c3018a7c6730df74c71b838f40aebcc6d48f6472b::marketplace::BuyTokenEvent"} = event_data) do
    %{
      data: event_data.data,
      version: event_data.version,
      type: event_data.type,
      sequence_number: event_data.sequence_number,
      key: event_data.key,
      token_id: get_token_id(event_data),
      price: event_data.data.price,
      maker: event_data.data.seller,
      taker: get_in(event_data, [:data, :buyer]),
      timestamp: event_data.data.timestamp,
      order_id: event_data.data.offer_id,
      status: "finished"
    }
  end

  defp order_to_params(_event_data), do: nil

  defp get_token_id(event_data), do: get_in(event_data, [:data, :id]) || get_in(event_data, [:data, :token_id])
end
