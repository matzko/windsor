module Windsor.Internal.EnvTest exposing (suite)

import Expect
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Test exposing (Test, describe, test)
import Windsor.Internal.Env as Env


type alias Env =
    { secret : String, port_ : Int }


decoder : Decoder Env
decoder =
    Decode.map2 Env
        (Decode.field "SESSION_SECRET" Decode.string)
        (Decode.field "PORT" (Decode.string |> Decode.andThen toInt))


toInt : String -> Decoder Int
toInt s =
    String.toInt s
        |> Maybe.map Decode.succeed
        |> Maybe.withDefault (Decode.fail "PORT must be a number")


flags : List ( String, String ) -> Encode.Value
flags vars =
    Encode.object [ ( "env", Encode.object (List.map (Tuple.mapSecond Encode.string) vars) ) ]


expectErrContaining : String -> Result String a -> Expect.Expectation
expectErrContaining fragment result =
    case result of
        Err message ->
            String.contains fragment message
                |> Expect.equal True
                |> Expect.onFail ("Expected the error to mention " ++ fragment ++ ", got: " ++ message)

        Ok _ ->
            Expect.fail "Expected an error"


expectErrOmitting : String -> Result String a -> Expect.Expectation
expectErrOmitting fragment result =
    case result of
        Err message ->
            String.contains fragment message
                |> Expect.equal False
                |> Expect.onFail ("The error leaked " ++ fragment ++ ": " ++ message)

        Ok _ ->
            Expect.fail "Expected an error"


suite : Test
suite =
    describe "Windsor.Internal.Env.decode"
        [ test "decodes the flags' env field" <|
            \_ ->
                flags [ ( "SESSION_SECRET", "s3cret" ), ( "PORT", "8080" ) ]
                    |> Env.decode decoder
                    |> Expect.equal (Ok { secret = "s3cret", port_ = 8080 })
        , test "names a missing variable" <|
            \_ ->
                flags [ ( "PORT", "8080" ) ]
                    |> Env.decode decoder
                    |> expectErrContaining "SESSION_SECRET"
        , test "fails when the flags have no env" <|
            \_ ->
                Encode.null
                    |> Env.decode decoder
                    |> Expect.err
        , describe "never includes values in the error"
            [ test "of other variables, when one is missing" <|
                \_ ->
                    flags [ ( "PORT", "8080" ), ( "DATABASE_PASSWORD", "hunter2" ) ]
                        |> Env.decode decoder
                        |> expectErrOmitting "hunter2"
            , test "of the variable that failed" <|
                \_ ->
                    flags [ ( "SESSION_SECRET", "s3cret" ), ( "PORT", "hunter2" ) ]
                        |> Env.decode decoder
                        |> Expect.all
                            [ expectErrContaining "PORT must be a number"
                            , expectErrOmitting "hunter2"
                            , expectErrOmitting "s3cret"
                            ]
            ]
        ]
