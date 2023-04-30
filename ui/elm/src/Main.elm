port module Main exposing (main)

import Asteroids exposing (rotateAsteroids)
import Browser
import Browser.Events exposing (onAnimationFrameDelta)
import Canvas exposing (..)
import Dict exposing (Dict)
import Explosions exposing (updateExplosions)
import Game exposing (Game, NextGameState, mergeGame, newGame, viewGame)
import GraphicsDecoder exposing (Frame, gameDecoder)
import Html exposing (Html, div, p, text)
import Html.Attributes exposing (style)
import Json.Decode as Decode exposing (..)
import Json.Encode as E


port graphicsIn : (E.Value -> msg) -> Sub msg

-- type alias Bundle = (String, Int, Float)
port playAudio : String -> Cmd msg


port addGame : (E.Value -> msg) -> Sub msg


type alias FrameInput =
    { id : Int
    , frame : String
    }


type alias NewGameInput =
    { id : Int
    , width : Int
    , height : Int
    }


-- Model is a map of game number to game allowing us to render multiple games
type alias Model =
    Dict Int Game


type Msg
    = Frame Float
    | GraphicsIn E.Value
    | AddGame E.Value


main : Program () Model Msg
main =
    Browser.element
        { init =
            \() -> cmdNone Dict.empty
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ graphicsIn GraphicsIn
        , onAnimationFrameDelta Frame
        , addGame AddGame
        ]


view : Model -> Html msg
view games =
    div []
        (List.map Game.viewGame (Dict.values games))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg games =
    case msg of
        Frame msSincePreviousFrame ->
            cmdNone
                (Dict.map (updateGame msSincePreviousFrame) games)

        GraphicsIn frame_json ->
            (handleFrame frame_json games)

        AddGame input ->
            case Decode.decodeValue newGameInputDecoder input of
                Ok g ->
                    cmdNone (Dict.insert g.id (newGame ( toFloat g.width, toFloat g.height )) games)

                Err _ ->
                    cmdNone games


handleFrame : E.Value -> Model -> ( Model, Cmd Msg )
handleFrame framev games =
    case Decode.decodeValue frameInputDecoder framev of
        Ok frame ->
            case Dict.get frame.id games of
                Just game ->
                    let
                        next_game =
                            mergeGraphics frame.frame game
                        next_games=
                            Dict.insert frame.id next_game games
                    in
                        cmdNone next_games

                _ ->
                    cmdNone games
        Err _ ->
            cmdNone games


mergeGraphics : String -> Game -> NextGameState
mergeGraphics state_json game =
    case Decode.decodeString gameDecoder state_json of
        Ok frame ->
            mergeGame frame game

        Err _ ->
            (game, [])


updateGame : Float -> Int -> Game -> Game
updateGame msSincePreviousFrame game_id game =
    { game
        | asteroids = rotateAsteroids msSincePreviousFrame game.asteroids
        , explosions = updateExplosions msSincePreviousFrame game.explosions
    }


cmdNone msg =
    ( msg, Cmd.none )


frameInputDecoder : Decoder FrameInput
frameInputDecoder =
    Decode.map2
        FrameInput
        (Decode.field "id" Decode.int)
        (Decode.field "frame" Decode.string)


newGameInputDecoder : Decoder NewGameInput
newGameInputDecoder =
    Decode.map3
        NewGameInput
        (Decode.field "id" Decode.int)
        (Decode.field "width" Decode.int)
        (Decode.field "height" Decode.int)
