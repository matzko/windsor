module Windsor.Internal.Env exposing (decode)

import Json.Decode as Decode exposing (Decoder, Value)


{-| Decode the app's environment from the program flags' `env` field.

The error message never includes the decoded value, to avoid leaking secrets.

-}
decode : Decoder env -> Value -> Result String env
decode decoder flags =
    Decode.decodeValue (Decode.field "env" decoder) flags
        |> Result.mapError (\error -> "Invalid environment: " ++ describe error)


describe : Decode.Error -> String
describe error =
    case error of
        Decode.Field name inner ->
            name ++ " > " ++ describe inner

        Decode.Index index inner ->
            String.fromInt index ++ " > " ++ describe inner

        Decode.OneOf errors ->
            "one of (" ++ String.join "; " (List.map describe errors) ++ ")"

        Decode.Failure message _ ->
            message
