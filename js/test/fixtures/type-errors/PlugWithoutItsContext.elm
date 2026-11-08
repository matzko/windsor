module PlugWithoutItsContext exposing (routes)

{-| `requireUser` reads the session, but runs where no session was loaded.
-}

import Auth
import Controllers.Pages as Pages
import Env exposing (Env)
import Url.Parser exposing (s)
import Windsor.Router as Router exposing (Route)


routes : Env -> List (Route ())
routes env =
    [ Router.scope Auth.requireUser
        [ Router.get (s "dashboard") (Pages.dashboard env) ]
    ]
