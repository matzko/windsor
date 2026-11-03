module Windsor.Internal.Router exposing (Handler, Route(..), dispatch)

import ConcurrentTask exposing (ConcurrentTask)
import Url
import Url.Parser as Parser exposing (Parser)
import Windsor.Error exposing (Error(..))
import Windsor.Internal.Conn exposing (Conn(..))
import Windsor.Request exposing (Method)


type alias Handler =
    Conn -> ConcurrentTask Error Conn


type Route
    = Route { method : Method, parser : Parser (Handler -> Handler) Handler }


dispatch : List Route -> Conn -> ConcurrentTask Error Conn
dispatch routes ((Conn { request }) as conn) =
    let
        parsers =
            List.filterMap
                (\(Route route) ->
                    if route.method == request.method then
                        Just route.parser

                    else
                        Nothing
                )
                routes
    in
    case
        Url.fromString ("http://localhost" ++ request.url)
            |> Maybe.andThen (Parser.parse (Parser.oneOf parsers))
    of
        Just handler ->
            handler conn

        Nothing ->
            ConcurrentTask.fail NotFound
