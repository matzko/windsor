module Windsor.Internal.Router exposing (Handler, Route(..), dispatch)

import Url
import Url.Parser as Parser exposing (Parser)
import Windsor.Error exposing (Error(..))
import Windsor.Internal.Conn exposing (Conn(..))
import Windsor.Request exposing (Method)
import Windsor.Task as Task exposing (Task)


type alias Handler =
    Conn -> Task Error Conn


type Route
    = Route { method : Method, parser : Parser (Handler -> Handler) Handler }


dispatch : List Route -> Conn -> Task Error Conn
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
            Task.fail NotFound
