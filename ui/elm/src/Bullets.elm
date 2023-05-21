module Bullets exposing (Bullet, Id, bulletAudio, mergeBullets, newBullet, renderBullet)

import Audio exposing (Audio, newBulletExplosion)
import Canvas exposing (..)
import Canvas.Settings exposing (fill, stroke)
import Canvas.Settings.Advanced exposing (Transform, transform, translate)
import Canvas.Settings.Line exposing (lineWidth)
import Color exposing (Color)
import Dict exposing (..)
import GraphicsDecoder exposing (BulletLocation)
import Point2d exposing (Point2d, coordinates, xCoordinate)
import Stereo exposing (CalculateBalance)
import Vector2d exposing (..)


type alias Id =
    Int

type alias WarheadTailColor =
    ( Color, Color )


type alias Bullet =
    { id : Id, position : Point2d, tail : Maybe Vector2d, shape : Shape, color : WarheadTailColor }


newBullet : Id -> Point2d -> Bullet
newBullet id position =
    { id = id
    , position = position
    , shape = circle ( 0, 0 ) 4
    , tail = Nothing
    , color = bulletColor id
    }


renderBullet : Transform -> Bullet -> List Renderable
renderBullet tf bullet =
    List.filterMap identity
        [ renderTail tf bullet
        , renderWarhead tf bullet
        ]


renderWarhead tf bullet =
    let
        ( x, y ) =
            coordinates bullet.position

        ( color, _ ) =
            bullet.color
    in
    Just
        (shapes
            [ stroke color, fill color, transform [ tf, translate x y ] ]
            [ bullet.shape ]
        )


renderTail : Transform -> Bullet -> Maybe Renderable
renderTail tf bullet =
    Maybe.map
        (\tail ->
            let
                ( ox, oy ) =
                    coordinates bullet.position

                ( x, y ) =
                    components tail

                ( _, color) = 
                    bullet.color
            in
            shapes
                [ stroke color, lineWidth 2.0, transform [ tf ] ]
                [ path ( ox, oy ) [ lineTo ( ox - x, oy - y ) ] ]
        )
        bullet.tail


mergeBullets graphics_bullets game_bullets =
    Dict.merge
        (\id f -> Dict.insert id (newBullet id f.location))
        (\id f b -> Dict.insert id (bulletAndTail f b))
        (\_ _ -> identity)
        graphics_bullets
        game_bullets
        Dict.empty


bulletAndTail f b =
    let
        tail =
            from b.position f.location
    in
    if squaredLength tail > longestTail then
        { b | position = f.location, tail = Nothing }

    else
        { b | position = f.location, tail = Just tail }


bulletColor : Id -> WarheadTailColor
bulletColor id =
    let 
        hue = case modBy 3 (id // 64) of
            0 -> 
                199 / 360
            1 ->
                120 / 360
            _ -> 
                300 / 360

    in
    ((Color.hsl hue 0.96 0.82), (Color.hsl hue 0.96 0.82))


longestTail : Float
longestTail =
    80.0 * 80.0

modSamples : Int -> Int
modSamples =
    modBy 8


bulletAudio : CalculateBalance -> BulletLocation -> Audio
bulletAudio calculateBalance b =
    let
        x = 
            xCoordinate b.location
        index = 
            modSamples (truncate (abs x))
        balance = 
            calculateBalance b.location
    in
        newBulletExplosion index balance


-- hashPlayerName : String -> Int
-- hashPlayerName name = 
--     String.toList name
--     |> List.indexedMap (\i c -> (i + 1) * 256 * Char.toCode c)
--     |> List.sum
