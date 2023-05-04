module Explosions exposing (Explosion, explosionAudio, newExplosion, renderExplosion, updateExplosions)

import Audio exposing (Audio, newAudioExplosion)
import Canvas exposing (..)
import Canvas.Settings exposing (fill, stroke)
import Canvas.Settings.Advanced exposing (Transform, transform, translate)
import Color exposing (Color)
import Point2d exposing (Point2d, coordinates, xCoordinate)


type alias Radius =
    Float


type alias Explosion =
    { position : Point2d, color : Color, ttl : Float, radius : Radius }


newExplosion : Point2d -> Explosion
newExplosion p =
    let
        ( x, y ) =
            coordinates p
    in
    { position = p
    , ttl = explosionDurationMS
    , color = (x + y) |> truncate |> pickColor
    , radius = 40.0
    }


updateExplosions : Float -> List Explosion -> List Explosion
updateExplosions msSincePreviousFrame =
    List.filter isActive << List.map (updateExplosion msSincePreviousFrame)


updateExplosion : Float -> Explosion -> Explosion
updateExplosion msSincePreviousFrame explosion =
    { explosion
        | radius = explosion.radius * explosionExpansion
        , ttl = explosion.ttl - msSincePreviousFrame
    }


isActive : { a | ttl : number } -> Bool
isActive explosion =
    explosion.ttl > 0


renderExplosion : Transform -> Explosion -> Renderable
renderExplosion tf explosion =
    let
        ( x, y ) =
            coordinates explosion.position

        color =
            explosion.color
    in
    shapes
        [ stroke color, fill color, transform [ tf, translate x y ] ]
        [ circle ( 0, 0 ) explosion.radius ]


pickColor : Int -> Color
pickColor n =
    case modBy 8 n of
        0 ->
            Color.rgba 1.0 1.0 1.0 1.0

        1 ->
            Color.hsla (31 / 360) 1.0 0.49 0.95

        2 ->
            Color.hsla (48 / 360) 0.9 0.5 0.95

        3 ->
            Color.hsla (204 / 360) 0.71 0.81 0.95

        _ ->
            Color.rgba 1 1 1 0.95


{-| At 60 FPS explosion is shown for 6 frames. 1.07^6 == x1.5 growth
-}
explosionExpansion : Float
explosionExpansion =
    1.07


explosionDurationMS : number
explosionDurationMS =
    100


modSamples : Int -> Int
modSamples =
    modBy 7


explosionAudio : Explosion -> Audio
explosionAudio e =
    let
        x = (xCoordinate e.position)
        index = modSamples (truncate (abs x))
    in
        newAudioExplosion index