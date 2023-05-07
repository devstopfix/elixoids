module Stereo exposing (CalculateBalance, Balance, calculateBalance)

import Point2d exposing (Point2d, xCoordinate)


type alias CalculateBalance = 
    Point2d -> Balance

type alias Balance =
    Float


panLeft : Float
panLeft = 
    -1.0

panRight : Float
panRight =
    1.0

calculateBalance : Float -> Point2d -> Balance
calculateBalance sx point =
    let
        px = xCoordinate point
    in
        if px <= 0 then
            panLeft
        else if px >= sx then
            panRight
        else
            let
                mid = 
                    sx / 2
                frac =
                    (px - mid) / mid
                pan = 
                    frac * frac * frac
            in
                toFloat(truncate (pan * 100)) / 100
