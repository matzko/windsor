module Controllers.Pages exposing (home)

import Windsor.Conn as Conn exposing (Conn)
import Windsor.Error exposing (Error)
import Windsor.Task as Task exposing (Task)


home : Conn -> Task Error Conn
home conn =
    conn
        |> Conn.html "<h1>Windsor Blog</h1><p>Hello, world!</p>"
        |> Task.succeed
