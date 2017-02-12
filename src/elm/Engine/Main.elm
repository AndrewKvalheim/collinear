module Engine.Main exposing (init, translator, update)

import Engine.Geometry as Geometry
import Engine.Types exposing (..)
import Engine.Utilities exposing (..)
import Infix exposing ((>>=))
import List.Extra
import Return exposing (Return, singleton)
import Random
import Random.List
import Utilities exposing (..)


-- MODEL


init : Int -> Int -> Return Msg Model
init modulus dimension =
    let
        model =
            { modulus = modulus
            , dimension = dimension
            , pool = []
            , sample = []
            , penalties = 0
            , knowledge = Unknown
            , quantityFound = 0
            }

        poolGenerator =
            List.range 0 (modulus ^ dimension - 1)
                |> Random.List.shuffle
    in
        ( model, Random.generate (ToSelf << LoadPool) poolGenerator )


initPoint : Int -> Int -> List Int -> Int -> Point
initPoint modulus dimension pool id =
    { id = id
    , components = Geometry.decompose modulus dimension id
    , selected = False
    , visible = pool /= []
    }



-- UPDATE


translator : TranslationDictionary parentMsg -> Translator parentMsg
translator translationDictionary msg =
    case msg of
        ToSelf internalMsg ->
            translationDictionary.onInternalMsg internalMsg

        ToParent Done ->
            translationDictionary.onDone


update : InternalMsg -> Model -> Return Msg Model
update msg model =
    case msg of
        DeclareNoLines ->
            case Geometry.findLines model.modulus model.sample of
                [] ->
                    if model.pool == [] then
                        singleton model <&> revealHiddenPoints <&> allFound
                    else
                        singleton model <&> overstock

                lines ->
                    singleton model <&> missedLines lines

        Deselect pointID ->
            singleton model <&> deselect pointID

        LoadPool pool ->
            singleton { model | pool = pool } <&> stock 12

        Select pointID ->
            singleton model <&> select pointID >>= evaluateCollinearity


allFound : Model -> Model
allFound model =
    { model | knowledge = AllLinesFound }


deselect : Int -> Model -> Model
deselect id model =
    { model | sample = model.sample |> updateAt .id id (setSelected False) }


evaluateCollinearity : Model -> Return Msg Model
evaluateCollinearity model =
    let
        selection =
            model.sample |> List.filter .selected
    in
        if List.length selection == model.modulus then
            if Geometry.isCollinear model.modulus selection then
                singleton model <&> recordFind <&> restock
            else
                singleton model <&> penalize <&> resetSelection
        else
            singleton model


missedLines : List Line -> Model -> Model
missedLines lines model =
    case lines |> List.filter (Geometry.pointsInLine >> List.all .visible) of
        [] ->
            model |> penalize |> revealHiddenPoints

        visibleLines ->
            model |> penalize |> showHint visibleLines


overstock : Model -> Model
overstock model =
    model |> stock 3


penalize : Model -> Model
penalize model =
    { model | penalties = model.penalties + 1 }


recordFind : Model -> Model
recordFind model =
    { model | quantityFound = model.quantityFound + 1 }


removeAt : Int -> Model -> Model
removeAt index model =
    { model | sample = model.sample |> List.Extra.removeAt index }
        |> resetKnowledge


resetKnowledge : Model -> Model
resetKnowledge model =
    { model | knowledge = Unknown }


resetSelection : Model -> Model
resetSelection model =
    { model | sample = model.sample |> List.Extra.updateIf (.selected) (setSelected False) }


restock : Model -> Model
restock model =
    if model.pool == [] then
        model |> restockTo (List.length model.sample - 3)
    else
        model |> restockTo 12


restockTo : Int -> Model -> Model
restockTo quantity model =
    if model.sample == [] then
        model |> allFound
    else
        case List.Extra.findIndex .selected model.sample of
            Nothing ->
                model

            Just index ->
                if index < quantity then
                    case List.Extra.getAt quantity model.sample of
                        Nothing ->
                            case model.pool of
                                [] ->
                                    model |> removeAt index |> restockTo quantity

                                id :: pool ->
                                    let
                                        point =
                                            initPoint model.modulus model.dimension pool id
                                    in
                                        { model | pool = pool } |> setAt index point |> restockTo quantity

                        Just point ->
                            model |> setAt index point |> removeAt quantity |> restockTo quantity
                else
                    model |> removeAt index |> restockTo quantity


revealHiddenPoints : Model -> Model
revealHiddenPoints model =
    { model | sample = model.sample |> List.Extra.updateIf (.visible >> not) (setVisible True) }


select : Int -> Model -> Model
select id model =
    { model | sample = model.sample |> updateAt .id id (setSelected True) }


setAt : Int -> Point -> Model -> Model
setAt index point model =
    { model | sample = List.Extra.setAt index point model.sample |> unsafe }
        |> resetKnowledge


showHint : List Line -> Model -> Model
showHint lines model =
    case
        lines
            |> List.map (Geometry.columnsOfLine >> List.Extra.findIndices allSame)
            |> List.Extra.maximumBy List.length
    of
        Nothing ->
            { model | knowledge = NoLines }

        Just dimensions ->
            { model | knowledge = SomeLineConstantIn dimensions }


stock : Int -> Model -> Model
stock n model =
    if n == 0 then
        model
    else
        case model.pool of
            [] ->
                model

            id :: pool ->
                let
                    point =
                        initPoint model.modulus model.dimension pool id
                in
                    { model
                        | pool = pool
                        , sample = model.sample ++ [ point ]
                    }
                        |> resetKnowledge
                        |> stock (n - 1)
