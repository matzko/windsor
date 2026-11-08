module Windsor.Internal.ViewTest exposing (suite)

import Expect
import Html.String as Html
import Json.Encode as Encode
import Test exposing (Test, describe, test)
import Windsor.Internal.View as Internal
import Windsor.View as View exposing (View)


htmlOrJson : View String
htmlOrJson =
    View.oneOf
        [ View.html (\s -> Html.text s)
        , View.json Encode.string
        ]


negotiated : Maybe String -> View data -> Maybe String
negotiated accept view =
    Internal.negotiate accept view |> Maybe.map .mediaType


suite : Test
suite =
    describe "Windsor.Internal.View.negotiate"
        [ test "uses the first format when there is no Accept header" <|
            \_ ->
                negotiated Nothing htmlOrJson
                    |> Expect.equal (Just "text/html")
        , test "matches an exact media type" <|
            \_ ->
                negotiated (Just "application/json") htmlOrJson
                    |> Expect.equal (Just "application/json")
        , test "prefers the client's earlier ranges" <|
            \_ ->
                negotiated (Just "application/json, text/html") htmlOrJson
                    |> Expect.equal (Just "application/json")
        , test "treats */* as the first format" <|
            \_ ->
                negotiated (Just "*/*") htmlOrJson
                    |> Expect.equal (Just "text/html")
        , test "matches a type wildcard" <|
            \_ ->
                negotiated (Just "application/*") htmlOrJson
                    |> Expect.equal (Just "application/json")
        , test "ignores parameters" <|
            \_ ->
                negotiated (Just "image/png, application/json;q=0.9") htmlOrJson
                    |> Expect.equal (Just "application/json")
        , test "is case-insensitive" <|
            \_ ->
                negotiated (Just "Application/JSON") htmlOrJson
                    |> Expect.equal (Just "application/json")
        , test "finds nothing when no range matches" <|
            \_ ->
                negotiated (Just "image/png") htmlOrJson
                    |> Expect.equal Nothing
        ]
