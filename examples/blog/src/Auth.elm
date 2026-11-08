module Auth exposing (Authed, Session, User, loadSession, requireUser)

import Dict
import Windsor.Conn as Conn
import Windsor.Plug as Plug exposing (Plug)


type alias User =
    { name : String }


{-| Context for routes that know about the session but don't require login.
-}
type alias Session =
    { user : Maybe User }


{-| Context for routes behind `requireUser`: the user is guaranteed.
-}
type alias Authed =
    { user : User }


loadSession : String -> Plug ctx Session
loadSession secret conn =
    let
        user : Maybe User
        user =
            (Conn.request conn).headers
                |> Dict.get "cookie"
                |> Maybe.andThen (cookie "session")
                |> Maybe.andThen (verify secret)
                |> Maybe.map User
    in
    Plug.continueWith { user = user } conn


requireUser : Plug Session Authed
requireUser conn =
    case (Conn.context conn).user of
        Just user ->
            Plug.continueWith { user = user } conn

        Nothing ->
            Plug.halt (Conn.redirect "/login" conn)


cookie : String -> String -> Maybe String
cookie name header =
    header
        |> String.split ";"
        |> List.filterMap
            (\pair ->
                case String.split "=" (String.trim pair) of
                    [ key, value ] ->
                        if key == name then
                            Just value

                        else
                            Nothing

                    _ ->
                        Nothing
            )
        |> List.head


{-| Stand-in for a real signature check: the token is `<name>.<secret>`.
-}
verify : String -> String -> Maybe String
verify secret token =
    case String.split "." token of
        [ name, signature ] ->
            if signature == secret then
                Just name

            else
                Nothing

        _ ->
            Nothing
