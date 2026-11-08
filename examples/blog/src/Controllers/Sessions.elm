module Controllers.Sessions exposing (new)

import Auth exposing (Session)
import Env exposing (Env)
import Views.Pages
import Windsor.Conn as Conn
import Windsor.Router exposing (Handler)
import Windsor.Task as Task
import Windsor.View as View


new : Env -> Handler Session
new env conn =
    Task.succeed <|
        case (Conn.context conn).user of
            Just _ ->
                Conn.redirect "/dashboard" conn

            Nothing ->
                Conn.render (View.html Views.Pages.login) { siteName = env.siteName } conn
