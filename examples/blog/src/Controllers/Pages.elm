module Controllers.Pages exposing (home)

import ConcurrentTask exposing (ConcurrentTask)
import Windsor.Conn as Conn exposing (Conn)
import Windsor.Error exposing (Error)


home : Conn -> ConcurrentTask Error Conn
home conn =
    conn
        |> Conn.html "<h1>Windsor Blog</h1><p>Hello, world!</p>"
        |> ConcurrentTask.succeed
