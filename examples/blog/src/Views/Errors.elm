module Views.Errors exposing (Data, html, json)

import Html.String as Html exposing (Html)
import Json.Encode as Encode
import Views.Layout exposing (layout)


type alias Data =
    { siteName : String
    , status : Int
    , message : String
    }


html : Data -> Html Never
html { siteName, message } =
    layout { siteName = siteName, title = message }
        [ Html.h1 [] [ Html.text message ] ]


json : Data -> Encode.Value
json { status, message } =
    Encode.object
        [ ( "status", Encode.int status )
        , ( "error", Encode.string message )
        ]
