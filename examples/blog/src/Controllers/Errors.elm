module Controllers.Errors exposing (render)

import Env exposing (Env)
import Views.Errors
import Windsor.Conn as Conn exposing (Conn, Sent)
import Windsor.Error exposing (Error(..))
import Windsor.View as View exposing (View)


view : View Views.Errors.Data
view =
    View.oneOf [ View.html Views.Errors.html, View.json Views.Errors.json ]


render : Env -> Error -> Conn () -> Sent
render env error conn =
    let
        ( status, message ) =
            case error of
                NotFound ->
                    ( 404, "Not found" )

                BadRequest detail ->
                    ( 400, detail )
    in
    conn
        |> Conn.putStatus status
        |> Conn.render view { siteName = env.siteName, status = status, message = message }
