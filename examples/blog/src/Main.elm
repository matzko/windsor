port module Main exposing (main)

import Controllers.Errors as Errors
import Env
import Json.Decode exposing (Value)
import Routes
import Windsor


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
        , envDecoder = Env.decoder
        , routes = Routes.routes
        , renderError = Errors.render
        }
