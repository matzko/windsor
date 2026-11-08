module HandlerWithoutResponse exposing (home)

{-| A handler that sets a header but never renders.
-}

import Windsor.Conn as Conn
import Windsor.Router exposing (Handler)
import Windsor.Task as Task


home : Handler ctx
home conn =
    conn
        |> Conn.putHeader "x-forgot" "to-render"
        |> Task.succeed
