module Windsor.Error exposing (Error(..))

{-| An error occuring in the application. 

@docs Error

-}


{-| An error occuring in a Windsor application. 
-}
type Error
    = NotFound
    | BadRequest String
