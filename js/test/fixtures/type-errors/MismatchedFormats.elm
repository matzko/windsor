module MismatchedFormats exposing (view)

{-| The JSON format renders different data from the HTML format.
-}

import Views.Errors
import Views.Posts
import Windsor.View as View exposing (View)


view : View Views.Posts.Data
view =
    View.oneOf [ View.html Views.Posts.html, View.json Views.Errors.json ]
