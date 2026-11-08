module HandlerOutsideItsScope exposing (routes)

{-| `dashboard` needs an `Authed` context, but is routed where only a
`Session` has been established.
-}

import Auth
import Controllers.Pages as Pages
import Env exposing (Env)
import Url.Parser exposing (s)
import Windsor.Router as Router exposing (Route)


routes : Env -> List (Route ())
routes env =
    [ Router.scope (Auth.loadSession env.sessionSecret)
        [ Router.get (s "dashboard") (Pages.dashboard env) ]
    ]
