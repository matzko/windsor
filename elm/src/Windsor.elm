module Windsor exposing
    ( Config
    , Model
    , Msg
    , Ports
    , Program
    , application
    )

import ConcurrentTask
import Json.Decode as Decode exposing (Value)
import Json.Encode as Encode
import Windsor.Error as Error exposing (Error(..))
import Windsor.Internal.Conn as Conn exposing (Conn(..))
import Windsor.Internal.Protocol as Protocol
import Windsor.Internal.Router as Router
import Windsor.Internal.Task as Task
import Windsor.Router exposing (Route)


{-| -}
type alias Program =
    Platform.Program Value Model Msg


{-| -}
type alias Config =
    { ports : Ports
    , routes : List Route
    , renderError : Error -> Conn -> Conn
    }


{-| -}
type alias Ports =
    { request : (Value -> Msg) -> Sub Msg
    , respond : Value -> Cmd Msg
    , taskSend : Value -> Cmd Msg
    , taskReceive : (Value -> Msg) -> Sub Msg
    }


{-| -}
type Model
    = Model { pool : ConcurrentTask.Pool Msg }


{-| -}
type Msg
    = GotRequest Value
    | OnProgress ( ConcurrentTask.Pool Msg, Cmd Msg )
    | Completed Int (ConcurrentTask.Response Never Conn)


{-| -}
application : Config -> Program
application config =
    Platform.worker
        { init = \_ -> ( Model { pool = ConcurrentTask.pool }, config.ports.respond Encode.null )
        , update = update config
        , subscriptions = subscriptions config
        }


{-| Update the model based on incoming messages.
-}
update : Config -> Msg -> Model -> ( Model, Cmd Msg )
update config msg (Model model) =
    case msg of
        GotRequest raw ->
            case Decode.decodeValue Protocol.envelopeDecoder raw of
                Ok { id, request } ->
                    let
                        conn =
                            Conn.fromRequest request

                        pureConn =
                            conn |> (\(Conn c) -> c)

                        ( pool, cmd ) =
                            Router.dispatch config.routes conn
                                |> Task.toConcurrent
                                |> ConcurrentTask.onError (\error -> ConcurrentTask.succeed (config.renderError error conn))
                                |> ConcurrentTask.attempt
                                    { pool = model.pool
                                    , send = config.ports.taskSend
                                    , onComplete = Completed id
                                    }
                    in
                    ( Model { model | pool = pool }, cmd )

                Err error ->
                    ( Model model
                    , config.ports.respond
                        (Protocol.encodeMalformed
                            (Decode.decodeValue (Decode.field "id" Decode.int) raw |> Result.toMaybe)
                            (Decode.errorToString error)
                        )
                    )

        OnProgress ( pool, cmd ) ->
            ( Model { model | pool = pool }, cmd )

        Completed id result ->
            let
                response =
                    case result of
                        ConcurrentTask.Success conn ->
                            Conn.response conn

                        ConcurrentTask.Error never ->
                            Basics.never never

                        ConcurrentTask.UnexpectedError error ->
                            errorResponse 500 (describeUnexpected error)
            in
            ( Model model, config.ports.respond (Protocol.encodeResponse id response) )


errorResponse : Int -> String -> Conn.Response
errorResponse status message =
    { status = status
    , headers = [ ( "content-type", "application/json" ) ]
    , body = Encode.encode 0 (Encode.object [ ( "error", Encode.string message ) ])
    }


renderError : Config -> Error -> Conn -> Conn
renderError config error conn =
    config.renderError error conn


describeUnexpected : ConcurrentTask.UnexpectedError -> String
describeUnexpected unexpected =
    case unexpected of
        ConcurrentTask.UnhandledJsException { function, message } ->
            function ++ " threw: " ++ message

        ConcurrentTask.ResponseDecoderFailure { function, error } ->
            function ++ " returned unexpected data: " ++ Decode.errorToString error

        ConcurrentTask.ErrorsDecoderFailure { function, error } ->
            function ++ " returned unexpected error data: " ++ Decode.errorToString error

        ConcurrentTask.MissingFunction function ->
            "No JS task registered for " ++ function

        ConcurrentTask.InternalError message ->
            "elm-concurrent-task internal error: " ++ message


{-| Set up subscriptions
-}
subscriptions : Config -> Model -> Sub Msg
subscriptions config (Model { pool }) =
    Sub.batch
        [ config.ports.request GotRequest
        , ConcurrentTask.onProgress
            { send = config.ports.taskSend
            , receive = config.ports.taskReceive
            , onProgress = OnProgress
            }
            pool
        ]
