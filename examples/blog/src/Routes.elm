module Routes exposing (routes)

import ConcurrentTask
import Controllers.Pages as Pages
import Url.Parser exposing ((</>), int, s, top)
import Windsor.Router as Router exposing (Route)


routes : List Route
routes =
    Router.through []
        [ Router.get top Pages.home
        ]

