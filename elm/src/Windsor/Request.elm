module Windsor.Request exposing (Request, Method(..), methodToString, methodFromString)

{-| The incoming HTTP request.

@docs Request

-}

import Dict exposing (Dict)

{-| An incoming request.
-}
type alias Request = 
    { method : Method
    , url : String
    , headers : Dict String String
    , body : String
    }


{-| An HTTP method.
-}
type Method
    = GET
    | POST
    | PUT
    | PATCH
    | DELETE
    | HEAD
    | OPTIONS
    | Other String

methodToString : Method -> String
methodToString method =
    case method of
        GET ->
            "GET"

        POST ->
            "POST"

        PUT ->
            "PUT"

        PATCH ->
            "PATCH"

        DELETE ->
            "DELETE"

        HEAD ->
            "HEAD"

        OPTIONS ->
            "OPTIONS"

        Other other ->
            other


methodFromString : String -> Method
methodFromString string =
    case String.toUpper string of
        "GET" ->
            GET

        "POST" ->
            POST

        "PUT" ->
            PUT

        "PATCH" ->
            PATCH

        "DELETE" ->
            DELETE

        "HEAD" ->
            HEAD

        "OPTIONS" ->
            OPTIONS

        other ->
            Other other

