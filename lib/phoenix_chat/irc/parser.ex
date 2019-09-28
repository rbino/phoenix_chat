defmodule PhoenixChat.IRC.Parser do
  import NimbleParsec

  alias PhoenixChat.IRC.Message
  require Logger

  space = string(" ")

  crlf = string("\r\n")

  user = ascii_string([{:not, ?\0}, {:not, ?\r}, {:not, ?\n}, {:not, ?\s}, {:not, ?\@}], min: 1)

  nickname =
    ascii_string([?A..?Z, ?a..?z, ?[..?`, ?{..?}], 1)
    |> ascii_string([?A..?Z, ?a..?z, ?0..?9, ?-, ?[..?`, ?{..?}], min: 0)
    |> reduce({Enum, :join, [""]})

  nospcrlfcl = utf8_string([{:not, ?\0}, {:not, ?\r}, {:not, ?\n}, {:not, ?\s}, {:not, ?:}], 1)

  nospcrlf = utf8_string([{:not, ?\0}, {:not, ?\r}, {:not, ?\n}, {:not, ?\s}], min: 0)

  trailing = utf8_string([{:not, ?\0}, {:not, ?\r}, {:not, ?\n}], min: 1)

  middle =
    nospcrlfcl
    |> concat(nospcrlf)
    |> reduce({Enum, :join, [""]})

  params =
    repeat(ignore(space) |> concat(middle))
    |> optional(ignore(space) |> ignore(string(":")) |> concat(trailing))
    |> tag(:params)

  command =
    ascii_string([?A..?Z, ?a..?z], min: 1)
    |> unwrap_and_tag(:command)

  # TODO: not 100% accurate but will work for now
  host = ascii_string([?0..?9, ?A..?Z, ?a..?z, ?., ?-], min: 1)

  full_user_suffix =
    optional(string("!") |> concat(user))
    |> string("@")
    |> concat(host)

  full_user =
    nickname
    |> optional(full_user_suffix)
    |> reduce({Enum, :join, [""]})

  only_full_user_char = ascii_char([?[..?`, ?{..?}, ?!, ?@])

  # lookahead_not is needed to check if what we're parsing is a servername or a full_user.
  # To do so, we abort the choice for servername as soon as we find a character that is
  # valid only for full_user
  servername =
    host
    |> lookahead_not(only_full_user_char)

  prefix = choice([servername, full_user])

  source =
    ignore(string(":"))
    |> concat(prefix)
    |> unwrap_and_tag(:source)

  tag_key =
    optional(host |> concat(string("/")))
    |> ascii_string([?A..?Z, ?a..?z, ?-], min: 1)
    |> reduce({Enum, :join, [""]})
    |> unwrap_and_tag(:key)

  tag_value =
    ascii_string([{:not, ?\0}, {:not, ?\a}, {:not, ?\r}, {:not, ?\n}, {:not, ?;}, {:not, ?\s}],
      min: 1
    )
    |> unwrap_and_tag(:value)

  tag =
    tag_key
    |> optional(ignore(string("=")) |> concat(tag_value))
    |> wrap()

  tags =
    ignore(string("@"))
    |> concat(tag)
    |> repeat(ignore(string(";")) |> concat(tag))
    |> tag(:tags)

  message =
    optional(tags |> ignore(space))
    |> optional(source |> ignore(space))
    |> concat(command)
    |> concat(params)
    |> ignore(crlf)
    |> eos()

  defparsecp :message, message

  def parse_message(message_bytes) do
    case message(message_bytes) do
      {:ok, parse_result, _, _, _, _} ->
        {:ok, to_message(parse_result)}

      {:error, reason, _, _, _, _} ->
        Logger.warn("Message parse error: #{reason}\nMessage: #{message_bytes}")
        {:error, :invalid_message}
    end
  end

  defp to_message(parse_result) do
    Enum.reduce(parse_result, %Message{}, fn
      {:tags, tags}, msg ->
        tags_map =
          Enum.reduce(tags, %{}, fn tag, acc ->
            key = Keyword.get(tag, :key)
            value = Keyword.get(tag, :value, true)
            Map.put(acc, key, value)
          end)

        %{msg | tags: tags_map}

      {:source, source}, msg ->
        %{msg | source: source}

      {:command, command}, msg ->
        %{msg | command: command}

      {:params, params}, msg ->
        %{msg | params: params}
    end)
  end
end
