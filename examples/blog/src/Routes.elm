module Routes exposing (routes)

import Auth
import Controllers.Pages as Pages
import Controllers.Posts as Posts
import Controllers.Sessions as Sessions
import Env exposing (Env)
import Url.Parser exposing ((</>), int, s, top)
import Windsor.Conn as Conn
import Windsor.Plug as Plug exposing (Plug)
import Windsor.Router as Router exposing (Route)


routes : Env -> List (Route ())
routes env =
    [ Router.scope poweredBy
        [ Router.get top (Pages.home env)
        , Router.get (s "posts" </> int) (Posts.show env)
        , Router.scope (Auth.loadSession env.sessionSecret)
            [ Router.get (s "login") (Sessions.new env)
            , Router.scope Auth.requireUser
                [ Router.get (s "dashboard") (Pages.dashboard env)
                ]
            ]
        ]
    ]


{-| Leaves the context alone, so it works in any scope.
-}
poweredBy : Plug ctx ctx
poweredBy conn =
    Plug.continue (Conn.putHeader "x-powered-by" "windsor" conn)
