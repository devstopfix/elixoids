module Audio exposing (Audio, newAudioExplosion, newBulletExplosion)


import Stereo exposing (Balance)

type alias Audio =
    { name : String, index: Int, pan: Float}


newAudioExplosion : Int -> Balance -> Audio
newAudioExplosion index balance =
    { name = "explosion"
    ,    index = index
    ,    pan = balance
    }


newBulletExplosion : a -> { name : String, index : a, pan : Float }
newBulletExplosion index =
    { name = "bullet"
    ,    index = index
    ,    pan = 0.0
    }