module Windsor.Internal.Plug exposing (Step(..))

import Windsor.Internal.Conn exposing (Conn, Sent)


type Step ctx
    = Continue (Conn ctx)
    | Halt Sent
