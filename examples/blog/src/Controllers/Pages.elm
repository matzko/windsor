module Controllers.Pages exposing (dashboard, home)

import Auth exposing (Authed)
import Env exposing (Env)
import Views.Pages
import Windsor.Conn as Conn
import Windsor.Router exposing (Handler)
import Windsor.Task as Task
import Windsor.View as View


{-| Needs no context, so it's polymorphic and can live in any scope.
-}
home : Env -> Handler ctx
home env conn =
    conn
        |> Conn.render (View.html Views.Pages.home) { siteName = env.siteName }
        |> Task.succeed


{-| Routable only inside `requireUser`: the user is a `User`, not a `Maybe`.
-}
dashboard : Env -> Handler Authed
dashboard env conn =
    conn
        |> Conn.render (View.html Views.Pages.dashboard)
            { siteName = env.siteName, user = (Conn.context conn).user }
        |> Task.succeed
