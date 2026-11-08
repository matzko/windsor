module Windsor.Plug exposing (Plug, Step, continue, continueWith, halt, andThen)

{-| A plug decides whether the request continues.

@docs Plug, Step, continue, continueWith, halt, andThen

-}

import Windsor.Conn exposing (Conn, Sent)
import Windsor.Error exposing (Error)
import Windsor.Internal.Conn as InternalConn
import Windsor.Internal.Plug as Internal
import Windsor.Task as Task exposing (Task)


{-| A Plug takes a connection with context `a` and continues with context `b`.
-}
type alias Plug a b =
    Conn a -> Task Error (Step b)


{-| What a plug decided: continue to the next plug or handler, or halt with a
response. Build a step with `continue`, `continueWith`, or `halt`.
-}
type alias Step ctx =
    Internal.Step ctx


{-| Continue with the same context.
-}
continue : Conn ctx -> Task x (Step ctx)
continue =
    Task.succeed << Internal.Continue


{-| Continue with a new context.
-}
continueWith : b -> Conn a -> Task x (Step b)
continueWith ctx (InternalConn.Conn conn) =
    Task.succeed
        (Internal.Continue
            (InternalConn.Conn { request = conn.request, status = conn.status, headers = conn.headers, context = ctx })
        )


{-| Stop here and send this response; the handler never runs.
-}
halt : Sent -> Task x (Step ctx)
halt =
    Task.succeed << Internal.Halt


{-| Run one plug after another:

    loadSession secret |> Plug.andThen requireUser

-}
andThen : Plug b c -> Plug a b -> Plug a c
andThen next first conn =
    first conn
        |> Task.andThen
            (\step ->
                case step of
                    Internal.Continue c ->
                        next c

                    Internal.Halt sent ->
                        Task.succeed (Internal.Halt sent)
            )
