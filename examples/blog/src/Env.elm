module Env exposing (Env, decoder)

import Json.Decode as Decode exposing (Decoder)


type alias Env =
    { siteName : String
    , sessionSecret : String
    }


decoder : Decoder Env
decoder =
    Decode.map2 Env
        (optional "SITE_NAME" "Windsor Blog")
        (Decode.field "SESSION_SECRET" Decode.string)


optional : String -> String -> Decoder String
optional name default =
    Decode.maybe (Decode.field name Decode.string)
        |> Decode.map (Maybe.withDefault default)
