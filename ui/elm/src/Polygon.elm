module Polygon exposing (pointsToShape, polygonCentroid, polygonToShape)

import Canvas exposing (Point, Shape, lineTo, path)
import Point2d exposing (centroid)
import Points exposing (closePolygon, convertPoints)
import Polygon2d exposing (Polygon2d, outerLoop)


pointsToShape : List Point -> Shape
pointsToShape points =
    case points of
        [] ->
            path ( 0, 0 ) []

        p0 :: ps ->
            path p0 (List.map (\p -> lineTo p) ps)


polygonToShape : Polygon2d -> Shape
polygonToShape =
    pointsToShape << convertPoints << closePolygon << outerLoop


polygonCentroid =
    centroid << outerLoop
