module Windsor.RequestTest exposing (suite)

import Expect
import Fuzz
import Test exposing (Test, describe, fuzz, test)
import Windsor.Request as Request exposing (Method(..))


knownMethods : List Method
knownMethods =
    [ GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS ]


suite : Test
suite =
    describe "Windsor.Request"
        [ describe "methodFromString"
            [ test "parses known methods case-insensitively" <|
                \_ ->
                    Request.methodFromString "post"
                        |> Expect.equal POST
            , test "falls back to Other for unknown methods" <|
                \_ ->
                    Request.methodFromString "PROPFIND"
                        |> Expect.equal (Other "PROPFIND")
            ]
        , fuzz (Fuzz.oneOfValues knownMethods) "known methods round-trip through strings" <|
            \method ->
                method
                    |> Request.methodToString
                    |> Request.methodFromString
                    |> Expect.equal method
        ]
