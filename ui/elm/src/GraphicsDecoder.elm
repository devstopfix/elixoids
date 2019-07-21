module GraphicsDecoder exposing (AsteroidLocation, BulletLocation, Frame, Id, ShipLocation, gameDecoder)

import BoundingBox2d exposing (BoundingBox2d, from)
import Circle2d exposing (Circle2d, withRadius)
import Json.Decode as Decode exposing (Decoder, andThen, at, fail, field, float, int, list, map3, map5, maybe, string, succeed)
import Point2d exposing (Point2d, fromCoordinates, origin)


type alias Frame =
    { asteroids : List AsteroidLocation
    , bullets : List BulletLocation
    , dimensions : Maybe BoundingBox2d
    , explosions : List Point2d
    , ships : List ShipLocation
    }


type alias Id =
    Int


type alias AsteroidLocation =
    { id : Id, location : Circle2d }


type alias BulletLocation =
    { id : Id, location : Point2d }


type alias Tag =
    String


type alias Theta =
    Float


type alias ShipLocation =
    { id : Tag, location : Circle2d, theta : Theta }


gameDecoder : Decoder Frame
gameDecoder =
    map5 Frame
        (field "a" asteroidsDecoder)
        (field "b" bulletsDecoder)
        (maybe (field "dim" dimDecoder))
        (field "x" explosionsDecoder)
        (field "s" shipsDecoder)


asteroidsDecoder : Decoder (List AsteroidLocation)
asteroidsDecoder =
    list asteroidDecoder


asteroidDecoder : Decoder AsteroidLocation
asteroidDecoder =
    field "0" int
        |> andThen
            (\id ->
                field "1" float
                    |> andThen
                        (\x ->
                            field "2" float
                                |> andThen
                                    (\y ->
                                        field "3" float
                                            |> andThen (\r -> succeed { location = withRadius r (fromCoordinates ( x, y )), id = id })
                                    )
                        )
            )


bulletsDecoder : Decoder (List BulletLocation)
bulletsDecoder =
    list bulletDecoder


bulletDecoder : Decoder BulletLocation
bulletDecoder =
    field "0" int
        |> andThen
            (\id ->
                field "1" float
                    |> andThen
                        (\x ->
                            field "2" float
                                |> andThen (\y -> succeed { id = id, location = fromCoordinates ( x, y ) })
                        )
            )


dimDecoder : Decoder BoundingBox2d
dimDecoder =
    list float |> andThen dimHelp


dimHelp : List Float -> Decoder BoundingBox2d
dimHelp fs =
    case fs of
        [ x, y ] ->
            succeed (from origin (fromCoordinates ( x, y )))

        _ ->
            fail "Expecting 2 floats"


explosionsDecoder : Decoder (List Point2d)
explosionsDecoder =
    list explosionDecoder


explosionDecoder : Decoder Point2d
explosionDecoder =
    field "0" float
        |> andThen
            (\x ->
                field "1" float
                    |> andThen (\y -> succeed (fromCoordinates ( x, y )))
            )


shipsDecoder : Decoder (List ShipLocation)
shipsDecoder =
    list shipDecoder


shipDecoder : Decoder ShipLocation
shipDecoder =
    field "0" string
        |> andThen
            (\tag ->
                field "1" float
                    |> andThen
                        (\x ->
                            field "2" float
                                |> andThen
                                    (\y ->
                                        field "3" float
                                            |> andThen
                                                (\r ->
                                                    field "4" float
                                                        |> andThen (\theta -> succeed { location = withRadius r (fromCoordinates ( x, y )), id = tag, theta = theta })
                                                )
                                    )
                        )
            )
