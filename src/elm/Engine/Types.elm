module Engine.Types exposing (..)


type alias Model =
    { modulus : Int
    , dimension : Int
    , pool : List Int
    , sample : List Point
    , penalties : Int
    , knowledge : Knowledge
    , quantityFound : Int
    }


type Knowledge
    = Unknown
    | NoLines
    | SomeLineConstantIn (List Int)
    | AllLinesFound


type alias Point =
    Selectable (Showable { id : Int, components : List Int })


type alias Selectable a =
    { a | selected : Bool }


type alias Showable a =
    { a | visible : Bool }


type Line
    = Collinear (List Point)


type Msg
    = ToSelf InternalMsg
    | ToParent ExternalMsg


type InternalMsg
    = DeclareNoLines
    | Deselect Int
    | LoadPool (List Int)
    | Select Int


type ExternalMsg
    = Done


type alias Translator parentMsg =
    Msg -> parentMsg


type alias TranslationDictionary parentMsg =
    { onInternalMsg : InternalMsg -> parentMsg
    , onDone : parentMsg
    }
