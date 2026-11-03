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
import Windsor.Internal.Conn as Conn exposing (Conn(..))
import Windsor.Internal.Protocol as Protocol
import Windsor.Internal.Router as Router
import Windsor.Router exposing (Route)


{-| -}
type alias Program =
    Platform.Program Value Model Msg


{-| -}
type alias Config =
    { ports : Ports
    , routes : List Route
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
                                -- |> ConcurrentTask.onError (\error -> ConcurrentTask.succeed (renderError error conn))
                                |> ConcurrentTask.onError (\error -> ConcurrentTask.succeed (Conn { pureConn | response = errorResponse 500 "some request error" }))
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
                            -- errorResponse 500 (describeUnexpected error)
                            errorResponse 500 "some error"
            in
            ( Model model, config.ports.respond (Protocol.encodeResponse id response) )


errorResponse : Int -> String -> Conn.Response
errorResponse status message =
    { status = status
    , headers = [ ( "content-type", "application/json" ) ]
    , body = Encode.encode 0 (Encode.object [ ( "error", Encode.string message ) ])
    }


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
