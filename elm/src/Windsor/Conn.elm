module Windsor.Conn exposing (Conn, html)

import Windsor.Internal.Conn as Internal


type alias Conn =
    Internal.Conn


{-| Respond with HTML.
-}
html : String -> Conn -> Conn
html body =
    putHeader "content-type" "text/html; charset=utf-8" >> putBody body


{-| Set a response header.
-}
putHeader : String -> String -> Conn -> Conn
putHeader name value =
    let
        key =
            String.toLower name
    in
    mapResponse
        (\response ->
            { response
                | headers =
                    List.filter (\( k, _ ) -> k /= key) response.headers ++ [ ( key, value ) ]
            }
        )


{-| Set the response body.
-}
putBody : String -> Conn -> Conn
putBody body =
    mapResponse
        (\response ->
            { response | body = body }
        )


{-| Apply a function to the response.
-}
mapResponse : (Internal.Response -> Internal.Response) -> Conn -> Conn
mapResponse f (Internal.Conn conn) =
    Internal.Conn { conn | response = f conn.response }
