module Windsor.Conn exposing
    ( Conn, Sent
    , request, context
    , putStatus, putHeader
    , render, redirect, sendStatus
    )

{-| The connection for one request.

@docs Conn, Sent
@docs request, context
@docs putStatus, putHeader
@docs render, redirect, sendStatus

-}

import Dict
import Windsor.Internal.Conn as Internal
import Windsor.Internal.View as View
import Windsor.Request exposing (Request)
import Windsor.View exposing (View)


{-| The connection for one request (request, status, headers, and context established by router plugs).
-}
type alias Conn ctx =
    Internal.Conn ctx


{-| A finished response; the end state of every handler.
-}
type alias Sent =
    Internal.Sent


{-| The incoming request.
-}
request : Conn ctx -> Request
request (Internal.Conn conn) =
    conn.request


{-| What the enclosing scopes' plugs established.
-}
context : Conn ctx -> ctx
context (Internal.Conn conn) =
    conn.context


{-| Set the status the response will be sent with. Defaults to 200.
-}
putStatus : Int -> Conn ctx -> Conn ctx
putStatus status (Internal.Conn conn) =
    Internal.Conn { conn | status = status }


{-| Set a response header, replacing any existing header of the same name.
Names are case-insensitive and stored lowercased.
-}
putHeader : String -> String -> Conn ctx -> Conn ctx
putHeader name value (Internal.Conn conn) =
    let
        key : String
        key =
            String.toLower name
    in
    Internal.Conn { conn | headers = List.filter (\( k, _ ) -> k /= key) conn.headers ++ [ ( key, value ) ] }


{-| Respond by rendering `data` with a view, negotiating the format.
Responds 406 if the client accepts none of the view's formats.
-}
render : View data -> data -> Conn ctx -> Sent
render view data ((Internal.Conn c) as conn) =
    case View.negotiate (Dict.get "accept" c.request.headers) view of
        Just format ->
            conn
                |> putHeader "content-type" format.contentType
                |> finish (format.render data)

        Nothing ->
            conn
                |> putStatus 406
                |> putHeader "content-type" "text/plain; charset=utf-8"
                |> finish "Not Acceptable"


{-| Respond with a 302 redirect.
-}
redirect : String -> Conn ctx -> Sent
redirect location =
    putStatus 302 >> putHeader "location" location >> finish ""


{-| Respond with a status and no body, e.g. 204.
-}
sendStatus : Int -> Conn ctx -> Sent
sendStatus status =
    putStatus status >> finish ""


finish : String -> Conn ctx -> Sent
finish body (Internal.Conn conn) =
    Internal.Sent { status = conn.status, headers = conn.headers, body = body }
