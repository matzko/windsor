module Models.Post exposing (Post, find)

import Windsor.Error exposing (Error(..))
import Windsor.Task as Task exposing (Task)


type alias Post =
    { id : Int
    , title : String
    , body : String
    }


find : Int -> Task Error Post
find id =
    case List.filter (\post -> post.id == id) all of
        post :: _ ->
            Task.succeed post

        [] ->
            Task.fail NotFound


all : List Post
all =
    [ { id = 1, title = "Hello, Windsor", body = "First post." }
    , { id = 2, title = "Typed views", body = "<script>alert('escaped')</script>" }
    ]
