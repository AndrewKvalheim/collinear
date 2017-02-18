module Engine.Utilities
    exposing
        ( allSame
        , combinations
        , listPadLeft
        , setSelected
        , setVisible
        , transpose
        , unsafe
        , updateAt
        )

import List.Extra


allSame : List a -> Bool
allSame xs =
    case xs of
        [] ->
            True

        x :: _ ->
            List.all ((==) x) xs


combinations : Int -> List a -> List (List a)
combinations n xs =
    if n == 0 then
        [ [] ]
    else
        case xs of
            [] ->
                []

            x :: xs ->
                (List.map ((::) x) (combinations (n - 1) xs)) ++ (combinations n xs)


listPadLeft : Int -> a -> List a -> List a
listPadLeft n x xs =
    (List.repeat (n - (List.length xs)) x) ++ xs


setSelected : Bool -> { a | selected : Bool } -> { a | selected : Bool }
setSelected selected selectable =
    { selectable | selected = selected }


setVisible : Bool -> { a | visible : Bool } -> { a | visible : Bool }
setVisible visible showable =
    { showable | visible = visible }


transpose : List (List a) -> List (List a)
transpose lists =
    case lists of
        [] ->
            []

        [] :: xss ->
            transpose xss

        (x :: xs) :: xss ->
            let
                heads =
                    List.filterMap List.head xss

                tails =
                    List.filterMap List.tail xss
            in
                (x :: heads) :: transpose (xs :: tails)


unsafe : Maybe a -> a
unsafe assumedJust =
    case assumedJust of
        Nothing ->
            Debug.crash "Unsafely unwrapped Nothing"

        Just value ->
            value


updateAt : (a -> b) -> b -> (a -> a) -> List a -> List a
updateAt accessor value update xs =
    xs
        |> List.Extra.updateIf (accessor >> ((==) value)) update
