module Windsor.View exposing (View, html, json, text, oneOf)

{-| How a handler's data becomes a response body. Each constructor establishes the
content type, so a body can never be labelled with the wrong one.

@docs View, html, json, text, oneOf

-}

import Html.String exposing (Html)
import Json.Encode as Encode
import Windsor.Internal.View as Internal


{-| Renders a `data` in one or more formats.
-}
type alias View data =
    Internal.View data


{-| An HTML document. Text and attributes are escaped (by elm-html-string);
-}
html : (data -> Html Never) -> View data
html view =
    single "text/html" "text/html; charset=utf-8" (\data -> "<!DOCTYPE html>" ++ Html.String.toString 0 (view data))


{-| A JSON body, encoded compactly.
-}
json : (data -> Encode.Value) -> View data
json view =
    single "application/json" "application/json" (view >> Encode.encode 0)


{-| A plain-text body, sent as UTF-8.
-}
text : (data -> String) -> View data
text =
    single "text/plain" "text/plain; charset=utf-8"


{-| Offer several formats, chosen by the request's `Accept` header. Every
format must accept the same `data`, so they cannot drift apart.

    View.oneOf [ View.html Views.Post.html, View.json Views.Post.json ]

-}
oneOf : List (View data) -> View data
oneOf views =
    Internal.View (List.concatMap (\(Internal.View formats) -> formats) views)


single : String -> String -> (data -> String) -> View data
single mediaType contentType render =
    Internal.View [ { mediaType = mediaType, contentType = contentType, render = render } ]
