module Controllers.Posts exposing (show)

import Env exposing (Env)
import Models.Post as Post
import Views.Posts
import Windsor.Conn as Conn
import Windsor.Router exposing (Handler)
import Windsor.Task as Task
import Windsor.View as View exposing (View)


{-| HTML or JSON, by `Accept`.
-}
view : View Views.Posts.Data
view =
    View.oneOf [ View.html Views.Posts.html, View.json Views.Posts.json ]


show : Env -> Int -> Handler ctx
show env id conn =
    Post.find id
        |> Task.map (\post -> Conn.render view { siteName = env.siteName, post = post } conn)
