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
import Vector2d exposing (..)


type alias Id =
    Int


type alias Bullet =
    { id : Id, position : Point2d, tail : Maybe Vector2d, shape : Shape }


newBullet : Id -> Point2d -> Bullet
newBullet id position =
    { id = id
    , position = position
    , shape = circle ( 0, 0 ) 4
    , tail = Nothing
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
    in
    Just
        (shapes
            [ stroke warheadColor, fill warheadColor, transform [ tf, translate x y ] ]
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
            in
            shapes
                [ stroke tailColor, lineWidth 2.0, transform [ tf ] ]
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


tailColor : Color
tailColor =
    Color.hsl (199 / 360) 0.96 0.82


warheadColor : Color
warheadColor =
    Color.hsl (199 / 360) 0.96 0.9


longestTail : Float
longestTail =
    80.0 * 80.0

modSamples : Int -> Int
modSamples =
    modBy 8


bulletAudio : BulletLocation -> Audio
bulletAudio b =
    let
        x = 
            xCoordinate b.location
        index = 
            modSamples (truncate (abs x))
    in
        newBulletExplosion index