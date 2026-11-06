module Windsor.Internal.Task exposing
    ( Errors(..)
    , Expect(..)
    , Task(..)
    , fromConcurrent
    , toConcurrent
    )

{-| Represent a concurrent task in the Windsor framework.
-}

import ConcurrentTask exposing (ConcurrentTask)


type Task x a
    = Task (ConcurrentTask x a)


type Expect a
    = Expect (ConcurrentTask.Expect a)


type Errors x
    = Errors (ConcurrentTask.Errors x)


fromConcurrent : ConcurrentTask x a -> Task x a
fromConcurrent =
    Task


toConcurrent : Task x a -> ConcurrentTask x a
toConcurrent (Task task) =
    task
