module Main exposing (main)

import Engine.Main as Engine
import Engine.Types as Engine
import Html exposing (Html)
import Return exposing (Return, singleton)
import Theme.Classic
import Utilities exposing (..)


-- APP


main : Program { hot : Bool } Model Msg
main =
    Html.programWithFlags
        { init = hotLoadable init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }


hotLoadable : Return Msg Model -> { hot : Bool } -> Return Msg Model
hotLoadable return { hot } =
    return |> applyIf hot Return.dropCmd



-- MODEL


type alias Model =
    { engine : Engine.Model
    }


init : Return Msg Model
init =
    let
        ( engine, cmd ) =
            initEngine
    in
        ( { engine = engine }, Cmd.map engineTranslator cmd )



-- UPDATE


type Msg
    = EngineDone
    | EngineMsg Engine.InternalMsg


engineTranslator : Engine.Translator Msg
engineTranslator =
    Engine.translator
        { onInternalMsg = EngineMsg
        , onDone = EngineDone
        }


update : Msg -> Model -> Return Msg Model
update msg model =
    case msg of
        EngineDone ->
            singleton model |> withEngine initEngine

        EngineMsg message ->
            singleton model |> withEngine (Engine.update message model.engine)


initEngine : Return Engine.Msg Engine.Model
initEngine =
    Engine.init 3 4


withEngine : Return Engine.Msg Engine.Model -> Return Msg Model -> Return Msg Model
withEngine ( engine, cmd ) =
    Return.mapWith (\m -> { m | engine = engine }) (Cmd.map engineTranslator cmd)



-- VIEW


view : Model -> Html Msg
view model =
    model.engine |> Theme.Classic.view |> Html.map engineTranslator
