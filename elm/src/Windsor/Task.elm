module Windsor.Task exposing
    ( Task
    , succeed, fail, fromResult
    , map, map2, map3, map4, map5, andMap
    , andThen, return, sequence, batch
    , mapError, onError, toResult
    , define, Expect, expectJson, expectString, expectWhatever
    , Errors, expectThrows, expectErrors, expectNoErrors
    )

{-| Describe asynchronous computations that may fail.

@docs Task


# Basics

@docs succeed, fail, fromResult


# Transforming and combining

@docs map, map2, map3, map4, map5, andMap


# Chaining

@docs andThen, return, sequence, batch


# Errors

@docs mapError, onError, toResult


# Handling various return types

@docs define, Expect, expectJson, expectString, expectWhatever
@docs Errors, expectThrows, expectErrors, expectNoErrors

-}

import ConcurrentTask
import Json.Decode exposing (Decoder)
import Json.Encode as Encode
import Windsor.Internal.Task as Internal


{-| A task that either fails with an `x` or succeeds with an `a`.
-}
type alias Task x a =
    Internal.Task x a


{-| -}
succeed : a -> Task x a
succeed =
    Internal.Task << ConcurrentTask.succeed


{-| -}
fail : x -> Task x a
fail =
    Internal.Task << ConcurrentTask.fail


{-| -}
fromResult : Result x a -> Task x a
fromResult =
    Internal.Task << ConcurrentTask.fromResult


{-| -}
map : (a -> b) -> Task x a -> Task x b
map f (Internal.Task a) =
    Internal.Task (ConcurrentTask.map f a)


{-| Run two tasks concurrently and combine their results.
-}
map2 : (a -> b -> c) -> Task x a -> Task x b -> Task x c
map2 f (Internal.Task a) (Internal.Task b) =
    Internal.Task (ConcurrentTask.map2 f a b)


{-| -}
map3 : (a -> b -> c -> d) -> Task x a -> Task x b -> Task x c -> Task x d
map3 f (Internal.Task a) (Internal.Task b) (Internal.Task c) =
    Internal.Task (ConcurrentTask.map3 f a b c)


{-| -}
map4 : (a -> b -> c -> d -> e) -> Task x a -> Task x b -> Task x c -> Task x d -> Task x e
map4 f (Internal.Task a) (Internal.Task b) (Internal.Task c) (Internal.Task d) =
    Internal.Task (ConcurrentTask.map4 f a b c d)


{-| -}
map5 : (a -> b -> c -> d -> e -> f) -> Task x a -> Task x b -> Task x c -> Task x d -> Task x e -> Task x f
map5 f (Internal.Task a) (Internal.Task b) (Internal.Task c) (Internal.Task d) (Internal.Task e) =
    Internal.Task (ConcurrentTask.map5 f a b c d e)


{-| Pipeline-friendly combining for more than five tasks:

    Task.succeed Dashboard
        |> Task.andMap users
        |> Task.andMap posts

-}
andMap : Task x a -> Task x (a -> b) -> Task x b
andMap (Internal.Task a) (Internal.Task f) =
    Internal.Task (ConcurrentTask.andMap a f)


{-| -}
andThen : (a -> Task x b) -> Task x a -> Task x b
andThen f (Internal.Task a) =
    Internal.Task (ConcurrentTask.andThen (f >> Internal.toConcurrent) a)


{-| Run a task for its effect, then succeed with the given value:

    Log.info "Created post"
        |> Task.return conn

-}
return : a -> Task x b -> Task x a
return value (Internal.Task task) =
    Internal.Task (ConcurrentTask.return value task)


{-| Run tasks one after another, collecting their results.
-}
sequence : List (Task x a) -> Task x (List a)
sequence =
    Internal.Task << ConcurrentTask.sequence << List.map Internal.toConcurrent


{-| Run tasks concurrently, collecting their results in order.
-}
batch : List (Task x a) -> Task x (List a)
batch =
    Internal.Task << ConcurrentTask.batch << List.map Internal.toConcurrent


{-| -}
mapError : (x -> y) -> Task x a -> Task y a
mapError f (Internal.Task a) =
    Internal.Task (ConcurrentTask.mapError f a)


{-| Recover from a failure.
-}
onError : (x -> Task y a) -> Task x a -> Task y a
onError f (Internal.Task a) =
    Internal.Task (ConcurrentTask.onError (f >> Internal.toConcurrent) a)


{-| Turn a failure into a successful `Err`, e.g. to treat a missing row as
`Nothing` rather than a 404.
-}
toResult : Task x a -> Task y (Result x a)
toResult (Internal.Task a) =
    Internal.Task (ConcurrentTask.toResult a)



-- CUSTOM JS TASKS


{-| How to read a JS function's return value.
-}
type alias Expect a =
    Internal.Expect a


{-| -}
expectJson : Decoder a -> Expect a
expectJson =
    Internal.Expect << ConcurrentTask.expectJson


{-| -}
expectString : Expect String
expectString =
    Internal.Expect ConcurrentTask.expectString


{-| Ignore the return value.
-}
expectWhatever : Expect ()
expectWhatever =
    Internal.Expect ConcurrentTask.expectWhatever


{-| How a JS function reports failure.
-}
type alias Errors x =
    Internal.Errors x


{-| The function throws; the exception's message becomes an `x`.
-}
expectThrows : (String -> x) -> Errors x
expectThrows =
    Internal.Errors << ConcurrentTask.expectThrows


{-| The function returns `{ error: ... }`, decoded into an `x`.
-}
expectErrors : Decoder x -> Errors x
expectErrors =
    Internal.Errors << ConcurrentTask.expectErrors


{-| The function never fails. An exception becomes a 500 response.
-}
expectNoErrors : Errors x
expectNoErrors =
    Internal.Errors ConcurrentTask.expectNoErrors


{-| Call a JS task by name:

    -- windsor.config.js: tasks: { "slugify": ({ title }) => slugify(title) }
    slugify : String -> Task Error String
    slugify title =
        Task.define
            { function = "slugify"
            , expect = Task.expectString
            , errors = Task.expectThrows InternalError
            , args = Encode.object [ ( "title", Encode.string title ) ]
            }

-}
define :
    { function : String
    , expect : Expect a
    , errors : Errors x
    , args : Encode.Value
    }
    -> Task x a
define options =
    let
        (Internal.Expect expect) =
            options.expect

        (Internal.Errors errors) =
            options.errors
    in
    Internal.Task
        (ConcurrentTask.define
            { function = options.function
            , expect = expect
            , errors = errors
            , args = options.args
            }
        )
