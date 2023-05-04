module Audio exposing (Audio, newAudioExplosion)


type alias Audio =
    { name : String, index: Int, pan: Float}


newAudioExplosion : Int -> Audio
newAudioExplosion index =
    { name = "explosion"
    ,    index = index
    ,    pan = 0.0
    }