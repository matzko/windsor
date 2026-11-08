module Windsor.Internal.Protocol exposing
    ( encodeFatal
    , encodeMalformed
    , encodeResponse
    , envelopeDecoder
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Windsor.Internal.Conn exposing (Response)
import Windsor.Request as Request exposing (Request)


envelopeDecoder : Decoder { id : Int, request : Request }
envelopeDecoder =
    Decode.map2 (\id request -> { id = id, request = request })
        (Decode.field "id" Decode.int)
        (Decode.field "request" requestDecoder)


requestDecoder : Decoder Request
requestDecoder =
    Decode.map4 Request
        (Decode.field "method" (Decode.map Request.methodFromString Decode.string))
        (Decode.field "url" Decode.string)
        (Decode.field "headers" (Decode.dict Decode.string))
        (Decode.field "body" Decode.string)


encodeResponse : Int -> Response -> Encode.Value
encodeResponse id response =
    Encode.object
        [ ( "type", Encode.string "response" )
        , ( "id", Encode.int id )
        , ( "status", Encode.int response.status )
        , ( "headers", Encode.list (\( k, v ) -> Encode.list Encode.string [ k, v ]) response.headers )
        , ( "body", Encode.string response.body )
        ]


encodeMalformed : Maybe Int -> String -> Encode.Value
encodeMalformed id error =
    Encode.object
        [ ( "type", Encode.string "malformed" )
        , ( "id", Maybe.map Encode.int id |> Maybe.withDefault Encode.null )
        , ( "error", Encode.string error )
        ]


{-| The app cannot run (e.g. bad environment); the host should exit.
-}
encodeFatal : String -> Encode.Value
encodeFatal error =
    Encode.object
        [ ( "type", Encode.string "fatal" )
        , ( "error", Encode.string error )
        ]
