module Asteroids exposing (Asteroid, newAsteroid, renderAsteroid, rotateAsteroids)

import Canvas exposing (..)
import Circle2d exposing (Circle2d, centerPoint, radius)
import Color exposing (Color)
import Dict exposing (Dict)
import Point2d exposing (coordinates, origin)
import Points exposing (convertPoints, readPoints)
import Polygon exposing (pointsToShape, polygonToShape)
import Polygon2d exposing (Polygon2d, outerLoop, scaleAbout, singleLoop)


type alias Id =
    Int


type alias Theta =
    Float


type alias Radius =
    Float


type alias Asteroid =
    { id : Id, position : Circle2d, theta : Theta, shape : Shape, color : Color }


newAsteroid : Id -> Circle2d -> Asteroid
newAsteroid id position =
    let
        shape =
            rockWithRadius (chooseShape id) (radius position)
    in
    { id = id
    , position = position
    , theta = modBy 628 id |> toFloat
    , shape = shape
    , color = granite
    }


granite =
    Color.rgb255 5 8 9


chooseShape : Int -> RockType
chooseShape i =
    case modBy 5 i of
        0 ->
            Classic1

        1 ->
            Classic2

        2 ->
            Classic3

        3 ->
            Classic4

        _ ->
            Modern5


rotateAsteroids : Float -> Dict Int Asteroid -> Dict Int Asteroid
rotateAsteroids msSincePreviousFrame =
    Dict.map (\_ -> rotateAsteroid msSincePreviousFrame)


rotateAsteroid : Float -> Asteroid -> Asteroid
rotateAsteroid msSincePreviousFrame asteroid =
    let
        delta_t =
            msSincePreviousFrame / 1000

        delta_theta =
            (pi * 2) * delta_t / 30
    in
    { asteroid | theta = asteroid.theta + delta_theta }


cycle : Int -> Theta
cycle t =
    let
        framesPerRevolution =
            960

        n =
            modBy framesPerRevolution t

        f =
            toFloat n / framesPerRevolution
    in
    f * 2 * pi


renderAsteroid : Transform -> Asteroid -> Renderable
renderAsteroid tf asteroid =
    let
        ( x, y ) =
            coordinates (centerPoint asteroid.position)

        transformations =
            [ tf, translate x y, rotate asteroid.theta ]
    in
    shapes
        [ stroke Color.gray, fill asteroid.color, transform transformations, lineWidth 4.0 ]
        [ asteroid.shape ]


rockWithRadius : RockType -> Float -> Shape
rockWithRadius rt radius =
    let
        rock =
            lookup rt
    in
    scaleAbout origin radius rock |> polygonToShape


{-| <http://computerarcheology.com/Arcade/Asteroids/VectorROM.html>
-}
type RockType
    = Classic1
    | Classic2
    | Classic3
    | Classic4
    | Modern5


classicRockPolygon1 =
    polygon [ ( 0.5, 1.0 ), ( 1.0, 0.5 ), ( 0.75, 0.0 ), ( 1.0, -0.5 ), ( 0.25, -1.0 ), ( -0.5, -1.0 ), ( -1.0, -0.5 ), ( -1.0, 0.5 ), ( -0.5, 1.0 ), ( 0.0, 0.5 ) ]


classicRockPolygon2 =
    polygon [ ( 1.0, 0.5 ), ( 0.5, 1.0 ), ( 0.0, 0.75 ), ( -0.5, 1.0 ), ( -1.0, 0.5 ), ( -0.75, 0.0 ), ( -1.0, -0.5 ), ( -0.5, -1.0 ), ( -0.25, -0.75 ), ( 0.5, -1.0 ), ( 1.0, -0.25 ), ( 0.5, 0.25 ) ]


classicRockPolygon3 =
    polygon [ ( -1.0, -0.25 ), ( -0.5, -1.0 ), ( 0.0, -0.25 ), ( 0.0, -1.0 ), ( 0.5, -1.0 ), ( 1.0, -0.25 ), ( 1.0, 0.25 ), ( 0.5, 1.0 ), ( -0.25, 1.0 ), ( -1.0, 0.25 ), ( -0.5, 0.0 ) ]


classicRockPolygon4 =
    polygon [ ( 1.0, 0.25 ), ( 1.0, 0.5 ), ( 0.25, 1.0 ), ( -0.5, 1.0 ), ( -0.25, 0.5 ), ( -1.0, 0.5 ), ( -1.0, -0.25 ), ( -0.5, -1.0 ), ( 0.25, -0.75 ), ( 0.5, -1.0 ), ( 1.0, -0.5 ), ( 0.25, 0.0 ) ]


modernRockPolygon5 =
    polygon [ ( -1, 0 ), ( -0.5, 0.7 ), ( -0.3, 0.4 ), ( 0.1, 1 ), ( 0.5, 0.4 ), ( 1, 0 ), ( 0.5, -0.6 ), ( 0.2, -1 ), ( -0.4, -1 ), ( -0.4, -0.5 ) ]


lookup rockType =
    case rockType of
        Classic1 ->
            classicRockPolygon1

        Classic2 ->
            classicRockPolygon2

        Classic3 ->
            classicRockPolygon3

        Classic4 ->
            classicRockPolygon4

        Modern5 ->
            modernRockPolygon5


polygon : List ( Float, Float ) -> Polygon2d
polygon =
    singleLoop << readPoints
