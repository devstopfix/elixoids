module Audio exposing (Audio, newAudioExplosion, newBulletExplosion)


type alias Audio =
    { name : String, index: Int, pan: Float}


newAudioExplosion : Int -> Audio
newAudioExplosion index =
    { name = "explosion"
    ,    index = index
    ,    pan = 0.0
    }


newBulletExplosion : a -> { name : String, index : a, pan : Float }
newBulletExplosion index =
    { name = "bullet"
    ,    index = index
    ,    pan = 0.0
    }