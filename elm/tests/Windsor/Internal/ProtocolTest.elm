module Windsor.Internal.ProtocolTest exposing (suite)

import Dict
import Expect
import Json.Decode as Decode
import Test exposing (Test, describe, test)
import Windsor.Internal.Protocol as Protocol
import Windsor.Request exposing (Method(..))


suite : Test
suite =
    describe "Windsor.Internal.Protocol"
        [ describe "envelopeDecoder"
            [ test "decodes a well-formed envelope" <|
                \_ ->
                    """
                    { "id": 7
                    , "request":
                        { "method": "get"
                        , "url": "/posts/1"
                        , "headers": { "accept": "text/html" }
                        , "body": ""
                        }
                    }
                    """
                        |> Decode.decodeString Protocol.envelopeDecoder
                        |> Expect.equal
                            (Ok
                                { id = 7
                                , request =
                                    { method = GET
                                    , url = "/posts/1"
                                    , headers = Dict.fromList [ ( "accept", "text/html" ) ]
                                    , body = ""
                                    }
                                }
                            )
            , test "fails when the request is missing" <|
                \_ ->
                    """{ "id": 7 }"""
                        |> Decode.decodeString Protocol.envelopeDecoder
                        |> Expect.err
            ]
        ]
