defmodule Elixoids.TagTest do
  use ExUnit.Case, async: true
  use ExCheck

  alias Elixoids.Server.WebsocketShipHandler
  import :triq_dom, except: [atom: 0], only: :functions

  property :valid_tags do
    for_all tag in gen_tag() do
      {:ok, tag3} = WebsocketShipHandler.valid_player_tag?(tag)
      assert tag == tag3
    end
  end

  property :short_tags_are_invalid do
    for_all tag in gen_short_tag() do
      assert false == WebsocketShipHandler.valid_player_tag?(tag), tag
    end
  end

  property :long_tags_are_trimmed do
    for_all tag in gen_long_tag() do
      assert {:ok, tag3} = WebsocketShipHandler.valid_player_tag?(tag), tag
      assert String.starts_with?(tag, tag3)
    end
  end

  # This can occasionally generate false positives!
  @tag iterations: 10
  property :other_strings_are_invalid do
    for_all tag in bind(unicode_string(), &to_string/1) do
      assert false == WebsocketShipHandler.valid_player_tag?(tag), tag
    end
  end

  test "ÅSA" do
    assert {:ok, "ÅSA"} = WebsocketShipHandler.valid_player_tag?("ÅSA")
  end

  test "Sing" do
    assert {:ok, "ΆΔΩ"} = WebsocketShipHandler.valid_player_tag?("άδω")
    assert {:ok, "ΆΔΩ"} = WebsocketShipHandler.valid_player_tag?("ΆΔΩ")
  end

  test "Donkey" do
    assert {:ok, "ÀNE"} = WebsocketShipHandler.valid_player_tag?("ÀNE")
  end

  test "Polish RICHARD" do
    assert {:ok, "RYŚ"} = WebsocketShipHandler.valid_player_tag?("RYŚ")
  end

  test "ŁYÊ" do
    assert {:ok, "ŁYÊ"} = WebsocketShipHandler.valid_player_tag?("ŁYÊ")
  end

  test "Cyrillic ДАЛ" do
    assert {:ok, "ДАЛ"} = WebsocketShipHandler.valid_player_tag?("ДАЛ")
  end

  test "Dalian 大连市" do
    assert {:ok, "大连市"} = WebsocketShipHandler.valid_player_tag?("大连市")
  end

  def gen_ascii, do: oneof(Enum.map(?A..?Z, fn x -> <<x::utf8>> end))
  def gen_danish, do: "ÆØÅ" |> String.graphemes() |> oneof()
  def gen_french, do: "ÇÉÂÊÎÔÛÀÈÙËÏÜ" |> String.graphemes() |> oneof()
  def gen_greek, do: "ΑΒΓΔΕΖΗΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ" |> String.graphemes() |> oneof()
  def gen_polish, do: "ĄĆĘŁŃÓŚŹŻ" |> String.graphemes() |> oneof()
  def gen_swedish, do: "ÅÄÖ" |> String.graphemes() |> oneof()

  def gen_letter,
    do: oneof([gen_ascii(), gen_danish(), gen_french(), gen_greek(), gen_polish(), gen_swedish()])

  def gen_tag_length(letter, length) when is_integer(length) do
    length |> vector(letter) |> bind(&Enum.join/1)
  end

  def gen_tag_length(letter, range) do
    range
    |> Enum.to_list()
    |> oneof()
    |> bind(fn l -> gen_tag_length(letter, l) end)
  end

  def gen_short_tag, do: gen_tag_length(gen_letter(), 1..2)

  def gen_long_tag, do: gen_tag_length(gen_letter(), 4..6)

  def gen_tag, do: gen_tag_length(gen_letter(), 3)
end
