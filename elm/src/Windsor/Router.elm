module Windsor.Router exposing (Handler, Route, get, through)

import Url.Parser as Parser exposing (Parser)
import Windsor.Internal.Router as Internal
import Windsor.Request exposing (Method(..))
import Windsor.Task as Task


type alias Route =
    Internal.Route


type alias Handler =
    Internal.Handler


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
    List.foldl (\plug task -> Task.andThen plug task)
        (Task.succeed conn)
        plugs
        |> Task.andThen handler
