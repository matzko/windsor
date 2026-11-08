module WellTyped exposing (routes, view)

{-| Control: the correct version of every mistake in this directory. If this
stops compiling, the other fixtures' failures prove nothing.
-}

import Auth
import Controllers.Pages as Pages
import Env exposing (Env)
import Url.Parser exposing (s)
import Views.Posts
import Windsor.Router as Router exposing (Route)
import Windsor.View as View exposing (View)


routes : Env -> List (Route ())
routes env =
    [ Router.scope (Auth.loadSession env.sessionSecret)
        [ Router.scope Auth.requireUser
            [ Router.get (s "dashboard") (Pages.dashboard env) ]
        ]
    ]


view : View Views.Posts.Data
view =
    View.oneOf [ View.html Views.Posts.html, View.json Views.Posts.json ]
