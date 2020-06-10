defmodule TdDfLib.Masks do
  @moduledoc """
  Utility module to detect and mask rich text and inline encoded data in dynamic
  content.
  """

  @doc """
  Applies a mask to a dynamic content value in the following caases:

   - Rich text markup document
   - Data URI encoded with length > 100 bytes
   - Any value with length > 255 bytes
  """
  def mask(data)

  def mask("data:" <> data) when byte_size(data) > 100 do
    case media_type(data) do
      {["base64"], types} -> types ++ ["base64"]
      _ -> "[data]"
    end
  end

  def mask(data) when byte_size(data) > 255 do
    String.slice(data, 0, 254) <> "…"
  end

  def mask(%{"document" => %{}}), do: "[markup]"

  def mask(value), do: value

  defp media_type(data) do
    with [headers, _data] <- String.split(data, ",", parts: 2) do
      headers
      |> String.split(";")
      |> Enum.split_with(&(&1 == "base64"))
    end
  end
end
