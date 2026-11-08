module Views.Posts exposing (Data, html, json)

import Html.String as Html exposing (Html)
import Json.Encode as Encode
import Models.Post exposing (Post)
import Views.Layout exposing (layout)


type alias Data =
    { siteName : String
    , post : Post
    }


html : Data -> Html Never
html { siteName, post } =
    layout { siteName = siteName, title = post.title }
        [ Html.h1 [] [ Html.text post.title ]
        , Html.p [] [ Html.text post.body ]
        ]


json : Data -> Encode.Value
json { post } =
    Encode.object
        [ ( "id", Encode.int post.id )
        , ( "title", Encode.string post.title )
        , ( "body", Encode.string post.body )
        ]
