module Ships exposing (Ship, newShip, renderShip, renderTag)

import Canvas exposing (..)
import Canvas.Settings exposing (fill, stroke)
import Canvas.Settings.Advanced exposing (Transform, rotate, transform, translate)
import Canvas.Settings.Line exposing (lineWidth)
import Canvas.Settings.Text exposing (TextAlign(..), align, font)
import Circle2d exposing (Circle2d, centerPoint, radius)
import Color exposing (Color)
import Point2d exposing (coordinates, origin)
import Points exposing (readPoints)
import Polygon exposing (polygonCentroid, polygonToShape)
import Polygon2d exposing (scaleAbout, singleLoop, translateBy)
import Vector2d exposing (from)


type alias Id =
    String


type alias Radius =
    Float


type alias Theta =
    Float


type alias Ship =
    { id : Id, position : Circle2d, theta : Theta, color : Color, tagColor : Color, shape : Shape }


shipRadius : Radius
shipRadius =
    20.0


newShip : Id -> Circle2d -> Theta -> Ship
newShip id position theta =
    { id = id
    , color = Color.rgb255 251 255 251
    , tagColor = Color.rgba 1 1 1 0.8
    , position = position
    , shape = shipOrSaucer id (radius position)
    , theta = theta
    }


shipOrSaucer : Id -> Float -> Shape
shipOrSaucer id radius =
    case id of
        "SČR" ->
            saucerWithRadius radius

        _ ->
            shipWithRadius radius


renderShip : Transform -> Ship -> Renderable
renderShip tf ship =
    let
        ( x, y ) =
            coordinates (centerPoint ship.position)

        transformations =
            [ tf, translate x y, rotate ship.theta ]
    in
    shapes
        [ stroke ship.color, transform transformations, lineWidth 2.0 ]
        [ ship.shape ]


renderTag : Transform -> Ship -> List Renderable
renderTag tf ship =
    let
        ( x, y ) =
            coordinates (centerPoint ship.position)

        tag =
            trimTag ship.id

        color =
            ship.tagColor

        tagTheta =
            offset90deg ship.theta

        tagDY =
            tagOffset (radius ship.position)

        transformations =
            [ tf, translate x y, rotate tagTheta, translate -x -y, translate 0 tagDY ]
    in
    [ text [ stroke tagColor, fill tagColor, transform transformations, font { size = 36, family = tagFont }, align Center ] ( x, y ) tag ]


offset90deg =
    (+) (pi / 2)


tagOffset =
    (*) 3.0


tagFont =
    "Source Code Pro,monospace"


trimTag =
    String.left 3 << String.trim


tagColor =
    Color.rgb 0.6 0.6 0.6


shipWithRadius : Float -> Shape
shipWithRadius r =
    arcadeShipEast |> scaleAbout origin r |> polygonToShape


arcadeShipEast =
    [ ( 24, 0 ), ( -24, -16 ), ( -16, -8 ), ( -16, 8 ), ( -24, 16 ), ( 24, 0 ) ]
        |> readPoints
        |> singleLoop
        |> scaleAbout origin (1.0 / 24.0)
        |> centreAboutMass


saucerWithRadius : Float -> Shape
saucerWithRadius r =
    saucerShip |> scaleAbout origin r |> polygonToShape


saucerShip =
    [ ( 0.22, 0.61 ), ( 0.39, 0.17 ), ( 1.0, -0.17 ), ( 0.39, -0.5 ), ( -0.39, -0.5 ), ( -1.0, -0.17 ), ( -0.39, 0.17 ), ( -0.22, 0.61 ) ]
        |> readPoints
        |> singleLoop
        |> centreAboutMass


centreAboutMass ship =
    case polygonCentroid ship of
        Nothing ->
            ship

        Just c ->
            translateBy (from c origin) ship
