module Windsor.Internal.Conn exposing (Conn(..), Response, Sent(..), fromRequest, sentResponse)

import Windsor.Request exposing (Request)


{-| The connection for one request (request, status, headers, and context established by router plugs).
-}
type Conn ctx
    = Conn
        { request : Request
        , status : Int
        , headers : List ( String, String )
        , context : ctx
        }


{-| A finished response. Ensures that handlers cannot finish successfully without a well-formed response.
-}
type Sent
    = Sent Response


type alias Response =
    { status : Int
    , headers : List ( String, String )
    , body : String
    }


fromRequest : Request -> Conn ()
fromRequest request =
    Conn { request = request, status = 200, headers = [], context = () }


sentResponse : Sent -> Response
sentResponse (Sent response) =
    response
