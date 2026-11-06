module Routes exposing (routes)

import Controllers.Pages as Pages
import Url.Parser exposing ((</>), int, s, top)
import Windsor.Conn as Conn
import Windsor.Router as Router exposing (Route)
import Windsor.Task as Task


routes : List Route
routes =
    Router.through [ poweredBy ]
        [ Router.get top Pages.home
        ]


poweredBy : Router.Handler
poweredBy conn =
    Task.succeed (Conn.putHeader "x-powered-by" "windsor" conn)
