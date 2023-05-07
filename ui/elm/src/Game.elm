module Game exposing (Game, GameAudio, mergeGame, newGame, viewGame)

import Asteroids exposing (..)
import Audio exposing (Audio)
import Bullets exposing (..)
import Canvas exposing (..)
import Canvas.Settings exposing (fill)
import Canvas.Settings.Advanced exposing (Transform, applyMatrix)
import Color exposing (Color)
import Dict exposing (Dict)
import Explosions exposing (Explosion, explosionAudio, newExplosion, renderExplosion)
import GraphicsDecoder exposing (..)
import Html exposing (Html)
import List.FlatMap exposing (flatMap)
import Ships exposing (..)
import Stereo exposing(CalculateBalance)


type alias Dimension =
    ( Float, Float )


type alias Game =
    { dimension : Dimension
    , asteroids : Dict Int Asteroid
    , bullets : Dict Bullets.Id Bullet
    , calculateBalance : CalculateBalance
    , explosions : List Explosion
    , ships : Dict String Ship
    , spaceColor : Color
    , transform : Transform
    }


type alias GameAudio =
    (Game, List Audio)


gameDimensions : (Float, Float)
gameDimensions =
    ( 4000.0, 2250.0 )


newGame : Dimension -> Game
newGame dims =
    let
        ( canvas_width, canvas_height ) =
            dims

        ( game_x, game_y ) =
            gameDimensions
    in
    { dimension = dims
    , asteroids = Dict.empty
    , bullets = Dict.empty
    , calculateBalance = Stereo.calculateBalance game_x
    , explosions = []
    , ships = Dict.empty
    , spaceColor = Color.black
    , transform =
        applyMatrix
            { m11 = canvas_width / game_x
            , m22 = -1 * (canvas_height / game_y)
            , m12 = 0
            , m21 = 0
            , dx = 0
            , dy = canvas_height
            }
    }


viewGame : Game -> Html msg
viewGame game =
    let
        ( width, height ) =
            game.dimension

        asteroids =
            renderAsteroids game.transform (Dict.values game.asteroids)

        bullets =
            renderBullets game.transform (Dict.values game.bullets)

        explosions =
            renderExplosions game.transform game.explosions

        ships =
            renderShips game.transform (Dict.values game.ships)

        tags =
            renderTags game.transform (Dict.values game.ships)

        space =
            renderSpace game
    in
    Canvas.toHtml ( round width, round height )
        []
        (List.foldl List.append [] [ explosions, asteroids, ships, bullets, tags, space ])


renderSpace : Game -> List Renderable
renderSpace game =
    let
        ( width, height ) =
            game.dimension
    in
    [ shapes
        [ fill game.spaceColor ]
        [ rect ( 0, 0 ) width height ]
    ]


renderAsteroids : Transform -> List Asteroid -> List Renderable
renderAsteroids tf =
    List.map (renderAsteroid tf)


renderBullets : Transform -> List Bullet -> List Renderable
renderBullets tf =
    flatMap (renderBullet tf)


renderExplosions : Transform -> List Explosion -> List Renderable
renderExplosions tf =
    List.map (renderExplosion tf)


renderTags : Transform -> List Ship -> List Renderable
renderTags tf =
    flatMap (renderTag tf)


renderShips : Transform -> List Ship -> List Renderable
renderShips tf =
    List.map (renderShip tf)


mergeGame : Frame -> Game -> GameAudio
mergeGame frame game =
    let
        new_explosions = 
            List.map newExplosion frame.explosions
        audio_explosions =        
            List.map (explosionAudio game.calculateBalance) new_explosions

        bullet_audio = 
            newBulletAudio (Dict.keys game.bullets) frame.bullets

        audio = 
            bullet_audio ++ audio_explosions

        next_game = 
            { game
                | asteroids = updateAsteroids frame.asteroids game.asteroids
                , bullets = updateBullets frame.bullets game.bullets
                , explosions = List.append game.explosions new_explosions
                , ships = updateShips frame.ships game.ships
            }
    in
        (next_game, audio)


updateAsteroids : List AsteroidLocation -> Dict Int Asteroid -> Dict Int Asteroid
updateAsteroids asteroids game_asteroids =
    mergeAsteroids (toAsteroidMap asteroids) game_asteroids


mergeAsteroids : Dict Int AsteroidLocation -> Dict Int Asteroid -> Dict Int Asteroid
mergeAsteroids graphics_asteroids game_asteroids =
    Dict.merge
        (\id a -> Dict.insert id (newAsteroid id a.location))
        (\id a b -> Dict.insert id { b | position = a.location })
        (\_ _ -> identity)
        graphics_asteroids
        game_asteroids
        Dict.empty


-- input compares list of bullet ids in the previous and current frames
newBulletAudio : List Bullets.Id -> List BulletLocation -> List Audio
newBulletAudio game_ids locations =
    case locations of
        [] ->
            []
        _ ->
            case List.maximum game_ids of
                Just max_id ->
                    locations
                    |> List.filter (\b -> b.id > max_id)
                    |> List.take 4
                    |> List.map bulletAudio
                Nothing ->
                    List.map bulletAudio locations


updateBullets bullets game_bullets =
    mergeBullets (toBulletMap bullets) game_bullets


updateShips : List ShipLocation -> Dict String Ship -> Dict String Ship
updateShips ships game_ships =
    mergeShips (toShipMap ships) game_ships


mergeShips : Dict String ShipLocation -> Dict String Ship -> Dict String Ship
mergeShips graphics_ships game_ships =
    Dict.merge
        (\id a -> Dict.insert id (newShip id a.location a.theta))
        (\id a b -> Dict.insert id { b | position = a.location, theta = a.theta })
        (\_ _ -> identity)
        graphics_ships
        game_ships
        Dict.empty


toAsteroidMap : List AsteroidLocation -> Dict Asteroids.Id AsteroidLocation
toAsteroidMap =
    Dict.fromList << List.map (\a -> ( a.id, a ))


toBulletMap : List BulletLocation -> Dict Asteroids.Id BulletLocation
toBulletMap =
    Dict.fromList << List.map (\a -> ( a.id, a ))


toShipMap : List ShipLocation -> Dict String ShipLocation
toShipMap =
    Dict.fromList << List.map (\a -> ( a.id, a ))
