module Windsor.Internal.Router exposing (Entry, Handler, Route(..), dispatch, through)

import Url exposing (Url)
import Windsor.Error exposing (Error(..))
import Windsor.Internal.Conn exposing (Conn(..), Sent)
import Windsor.Internal.Plug exposing (Step(..))
import Windsor.Request exposing (Method)
import Windsor.Task as Task exposing (Task)


type alias Handler ctx =
    Conn ctx -> Task Error Sent


{-| Nested routes.
-}
type Route ctx
    = Route (List (Entry ctx))


type alias Entry ctx =
    { method : Method
    , match : Url -> Maybe (Handler ctx)
    }


through : (Conn a -> Task Error (Step b)) -> Handler b -> Handler a
through plug handler conn =
    plug conn
        |> Task.andThen
            (\step ->
                case step of
                    Continue c ->
                        handler c

                    Halt sent ->
                        Task.succeed sent
            )


dispatch : List (Route ()) -> Conn () -> Task Error Sent
dispatch routes ((Conn { request }) as conn) =
    case Url.fromString ("http://localhost" ++ request.url) of
        Nothing ->
            Task.fail NotFound

        Just url ->
            case firstMatch url (List.filter (\e -> e.method == request.method) (List.concatMap entries routes)) of
                Just handler ->
                    handler conn

                Nothing ->
                    Task.fail NotFound


entries : Route ctx -> List (Entry ctx)
entries (Route es) =
    es


firstMatch : Url -> List (Entry ctx) -> Maybe (Handler ctx)
firstMatch url list =
    case list of
        [] ->
            Nothing

        entry :: rest ->
            case entry.match url of
                Just handler ->
                    Just handler

                Nothing ->
                    firstMatch url rest
