module Views.Pages exposing (dashboard, home, login)

import Auth exposing (User)
import Html.String as Html exposing (Html)
import Html.String.Attributes as Attr
import Views.Layout exposing (layout)


home : { siteName : String } -> Html Never
home { siteName } =
    layout { siteName = siteName, title = "Home" }
        [ Html.h1 [] [ Html.text siteName ]
        , Html.p [] [ Html.a [ Attr.href "/posts/1" ] [ Html.text "Read the first post" ] ]
        ]


dashboard : { siteName : String, user : User } -> Html Never
dashboard { siteName, user } =
    layout { siteName = siteName, title = "Dashboard" }
        [ Html.h1 [] [ Html.text ("Welcome back, " ++ user.name) ] ]


login : { siteName : String } -> Html Never
login { siteName } =
    layout { siteName = siteName, title = "Log in" }
        [ Html.h1 [] [ Html.text "Log in" ] ]
