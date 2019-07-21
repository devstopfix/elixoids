module Points exposing (closePolygon, convertPoints, readPoints)

import Canvas exposing (Point)
import Point2d exposing (Point2d, coordinates, fromCoordinates)


readPoints : List ( Float, Float ) -> List Point2d
readPoints =
    List.map fromCoordinates



{--Convert from Geometry points to Canvas points

-}


convertPoints : List Point2d -> List Point
convertPoints =
    List.map coordinates


closePolygon list =
    case list of
        [] ->
            []

        p :: ps ->
            List.append (p :: ps) [ p ]
