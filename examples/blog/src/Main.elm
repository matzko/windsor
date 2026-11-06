port module Main exposing (main)

import Json.Decode exposing (Value)
import Routes
import Windsor
import Windsor.Conn as Conn exposing (Conn)
import Windsor.Error exposing (Error(..))


port windsorRequest : (Value -> msg) -> Sub msg


port windsorRespond : Value -> Cmd msg


port windsorTaskSend : Value -> Cmd msg


port windsorTaskReceive : (Value -> msg) -> Sub msg


main : Windsor.Program
main =
    Windsor.application
        { ports =
            { request = windsorRequest
            , respond = windsorRespond
            , taskSend = windsorTaskSend
            , taskReceive = windsorTaskReceive
            }
        , routes = Routes.routes
        , renderError = renderError
        }


renderError : Error -> Conn -> Conn
renderError error conn =
    case error of
        NotFound ->
            conn
                |> Conn.putStatus 404
                |> Conn.html "<h1>Not found</h1>"

        BadRequest message ->
            conn
                |> Conn.putStatus 400
                |> Conn.html ("<h1>Bad request</h1><p>" ++ message ++ "</p>")
