module Windsor.ConnTest exposing (suite)

import Dict
import Expect
import Html.String as Html
import Json.Encode as Encode
import Test exposing (Test, describe, test)
import Windsor.Conn as Conn exposing (Conn, Sent)
import Windsor.Internal.Conn as Internal
import Windsor.Request exposing (Method(..))
import Windsor.View as View exposing (View)


connAccepting : Maybe String -> Conn ()
connAccepting accept =
    Internal.fromRequest
        { method = GET
        , url = "/"
        , headers =
            accept
                |> Maybe.map (\value -> Dict.singleton "accept" value)
                |> Maybe.withDefault Dict.empty
        , body = ""
        }


htmlOrJson : View String
htmlOrJson =
    View.oneOf
        [ View.html (\s -> Html.p [] [ Html.text s ])
        , View.json Encode.string
        ]


response : Sent -> Internal.Response
response =
    Internal.sentResponse


suite : Test
suite =
    describe "Windsor.Conn"
        [ describe "render"
            [ test "renders HTML as a document with an HTML content type" <|
                \_ ->
                    connAccepting Nothing
                        |> Conn.render htmlOrJson "hi"
                        |> response
                        |> Expect.equal
                            { status = 200
                            , headers = [ ( "content-type", "text/html; charset=utf-8" ) ]
                            , body = "<!DOCTYPE html><p>hi</p>"
                            }
            , test "renders JSON when the client asks for it" <|
                \_ ->
                    connAccepting (Just "application/json")
                        |> Conn.render htmlOrJson "hi"
                        |> response
                        |> Expect.equal
                            { status = 200
                            , headers = [ ( "content-type", "application/json" ) ]
                            , body = "\"hi\""
                            }
            , test "escapes text in HTML" <|
                \_ ->
                    connAccepting Nothing
                        |> Conn.render htmlOrJson "<script>alert(1)</script>"
                        |> response
                        |> .body
                        |> Expect.equal "<!DOCTYPE html><p>&lt;script&gt;alert(1)&lt;/script&gt;</p>"
            , test "renders plain text" <|
                \_ ->
                    connAccepting Nothing
                        |> Conn.render (View.text identity) "hi"
                        |> response
                        |> Expect.equal
                            { status = 200
                            , headers = [ ( "content-type", "text/plain; charset=utf-8" ) ]
                            , body = "hi"
                            }
            , test "keeps the status and headers set before rendering" <|
                \_ ->
                    connAccepting Nothing
                        |> Conn.putStatus 201
                        |> Conn.putHeader "X-Request-Id" "abc"
                        |> Conn.render htmlOrJson "hi"
                        |> response
                        |> Expect.all
                            [ .status >> Expect.equal 201
                            , .headers
                                >> Expect.equal
                                    [ ( "x-request-id", "abc" )
                                    , ( "content-type", "text/html; charset=utf-8" )
                                    ]
                            ]
            , test "responds 406 when no format is acceptable" <|
                \_ ->
                    connAccepting (Just "image/png")
                        |> Conn.render htmlOrJson "hi"
                        |> response
                        |> Expect.equal
                            { status = 406
                            , headers = [ ( "content-type", "text/plain; charset=utf-8" ) ]
                            , body = "Not Acceptable"
                            }
            ]
        , test "putHeader replaces an existing header case-insensitively" <|
            \_ ->
                connAccepting Nothing
                    |> Conn.putHeader "X-Thing" "one"
                    |> Conn.putHeader "x-thing" "two"
                    |> Conn.sendStatus 204
                    |> response
                    |> .headers
                    |> Expect.equal [ ( "x-thing", "two" ) ]
        , test "redirect responds 302 with a location and no body" <|
            \_ ->
                connAccepting Nothing
                    |> Conn.redirect "/login"
                    |> response
                    |> Expect.equal { status = 302, headers = [ ( "location", "/login" ) ], body = "" }
        , test "sendStatus responds with no body" <|
            \_ ->
                connAccepting Nothing
                    |> Conn.sendStatus 204
                    |> response
                    |> Expect.equal { status = 204, headers = [], body = "" }
        ]
