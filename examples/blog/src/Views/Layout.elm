module Views.Layout exposing (layout)

import Html.String as Html exposing (Html)


layout : { siteName : String, title : String } -> List (Html Never) -> Html Never
layout { siteName, title } content =
    Html.node "html"
        []
        [ Html.node "head" [] [ Html.node "title" [] [ Html.text (title ++ " · " ++ siteName) ] ]
        , Html.node "body" [] content
        ]
