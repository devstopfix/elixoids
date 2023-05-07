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


newBulletExplosion : a -> Balance -> { name : String, index : a, pan : Float }
newBulletExplosion index balance =
    { name = "bullet"
    ,    index = index
    ,    pan = balance
    }