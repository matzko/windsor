module Windsor.Router exposing (Route, Handler, get, post, scope)

{-|

@docs Route, Handler, get, post, scope

-}

import Url.Parser as Parser exposing (Parser)
import Windsor.Internal.Router as Internal
import Windsor.Plug exposing (Plug)
import Windsor.Request exposing (Method(..))


{-| A route whose handler expects context `ctx`.
-}
type alias Route ctx =
    Internal.Route ctx


{-| -}
type alias Handler ctx =
    Internal.Handler ctx


{-| -}
get : Parser handler (Handler ctx) -> handler -> Route ctx
get =
    route GET


{-| -}
post : Parser handler (Handler ctx) -> handler -> Route ctx
post =
    route POST


{-| Run a plug before every route inside, converting the outer context into
the one those routes' handlers expect. Scopes nest.
-}
scope : Plug parent child -> List (Route child) -> Route parent
scope plug children =
    Internal.Route
        (List.concatMap
            (\(Internal.Route entries) ->
                List.map
                    (\entry -> { method = entry.method, match = entry.match >> Maybe.map (Internal.through plug) })
                    entries
            )
            children
        )


route : Method -> Parser handler (Handler ctx) -> handler -> Route ctx
route method parser handler =
    Internal.Route [ { method = method, match = Parser.parse (Parser.map handler parser) } ]
