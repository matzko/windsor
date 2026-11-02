module Windsor.Internal.Conn exposing (Conn(..), Response, fromRequest, response)

import Windsor.Request exposing (Request)

type Conn = Conn { request : Request, response : Response }

type alias Response =
    { status : Int
    , headers : List (String, String)
    , body : String
    }

    
fromRequest : Request -> Conn
fromRequest request =
    Conn
        { request = request
        , response = { status = 200, headers = [], body = "" }
        }



response : Conn -> Response
response (Conn conn) =
    conn.response

