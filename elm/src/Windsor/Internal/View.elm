module Windsor.Internal.View exposing (Format, View(..), negotiate)


type View data
    = View (List (Format data))


type alias Format data =
    { mediaType : String
    , contentType : String
    , render : data -> String
    }


{-| Find the first matching format for an `Accept` header.
-}
negotiate : Maybe String -> View data -> Maybe (Format data)
negotiate accept (View formats) =
    case accept of
        Nothing ->
            List.head formats

        Just header ->
            header
                |> String.split ","
                |> List.map (String.split ";" >> List.head >> Maybe.withDefault "" >> String.trim >> String.toLower)
                |> maybeFirstMatch (\range -> find (matches range) formats)


matches : String -> Format data -> Bool
matches range format =
    range
        == "*/*"
        || range
        == format.mediaType
        || (String.endsWith "/*" range && String.startsWith (String.dropRight 1 range) format.mediaType)


find : (a -> Bool) -> List a -> Maybe a
find predicate =
    List.filter predicate >> List.head


maybeFirstMatch : (a -> Maybe b) -> List a -> Maybe b
maybeFirstMatch f list =
    case list of
        [] ->
            Nothing

        x :: rest ->
            case f x of
                Just y ->
                    Just y

                Nothing ->
                    maybeFirstMatch f rest
