module Windsor.Router exposing (Route, through, Handler, get)

import Windsor.Internal.Router as Internal
import Url.Parser as Parser exposing (Parser)
import Windsor.Request exposing (Method(..))
import ConcurrentTask

type alias Route = Internal.Route
type alias Handler = Internal.Handler

{-| Run plugs, in order, before each of the given routes' handlers.
-}
through : List Handler -> List Route -> List Route
through plugs =
    List.map
        (\(Internal.Route r) ->
            Internal.Route { r | parser = Parser.map (withPlugs plugs) r.parser }
        )

get : Parser handler Handler -> handler -> Route
get =
    route GET

{-| A route for any method.
-}
route : Method -> Parser handler Handler -> handler -> Route
route method parser handler =
    Internal.Route { method = method, parser = Parser.map handler parser }




withPlugs : List Handler -> Handler -> Handler
withPlugs plugs handler conn =
    List.foldl (\plug task -> ConcurrentTask.andThen plug task)
        (ConcurrentTask.succeed conn)
        plugs
        |> ConcurrentTask.andThen handler

