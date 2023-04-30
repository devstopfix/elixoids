module Audio exposing (Audio, newAudioExplosion)


type alias Audio =
    { name : String, index: Int, pan: Float}


newAudioExplosion : Audio
newAudioExplosion =
    { name = "explosion"
    ,    index = 1
    ,    pan = 0.0
    }