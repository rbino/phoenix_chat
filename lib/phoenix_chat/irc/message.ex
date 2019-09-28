defmodule PhoenixChat.IRC.Message do
  defstruct [
    :source,
    :command,
    params: [],
    tags: %{}
  ]

  alias PhoenixChat.IRC.Message

  def new(opts) do
    struct(Message, opts)
  end

  def serialize(%Message{command: command} = msg) when is_binary(command) do
    serialize_tags(msg.tags) <>
      serialize_source(msg.source) <> msg.command <> serialize_params(msg.params) <> "\r\n"
  end

  def serialize_tags(tags) when map_size(tags) == 0 do
    ""
  end

  def serialize_tags(tags) when is_map(tags) do
    tags_string =
      Enum.reduce(tags, "", fn
        {key, value}, "" ->
          # First tag, start with @

          if value == true do
            # true value just needs the key
            "@#{key}"
          else
            "@#{key}=#{value}"
          end

        {key, value}, acc ->
          # Other tag, separate with ;

          if value == true do
            # true value just needs the key
            acc <> ";#{key}"
          else
            acc <> ";#{key}=#{value}"
          end
      end)

    tags_string <> " "
  end

  def serialize_source(nil) do
    ""
  end

  def serialize_source(source) when is_binary(source) do
    ":#{source} "
  end

  def serialize_params([]) do
    ""
  end

  def serialize_params(params) when is_list(params) do
    do_serialize_params(params, [])
  end

  def do_serialize_params([trailing_param | []], acc) do
    serialized_trailing_param =
      if String.contains?(trailing_param, " ") do
        ":#{trailing_param}"
      else
        trailing_param
      end

    params_string =
      [serialized_trailing_param | acc]
      |> Enum.reverse()
      |> Enum.join(" ")

    " " <> params_string
  end

  def do_serialize_params([param | rest], acc) do
    do_serialize_params(rest, [param | acc])
  end
end
