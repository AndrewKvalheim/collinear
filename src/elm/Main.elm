port module Main exposing (main)

import Engine.Main as Engine
import Engine.Storage
import Engine.Types as Engine
import Html exposing (Html)
import Infix exposing ((>>=))
import Json.Decode
import Json.Encode
import Return exposing (Return, singleton)
import Theme.Classic
import Utilities exposing (..)


-- PORTS


port setState : String -> Cmd msg



-- APP


type alias Flags =
    { hot : Bool
    , state : Maybe String
    }


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = hotLoadable init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }


hotLoadable : (Flags -> Return Msg Model) -> (Flags -> Return Msg Model)
hotLoadable f flags =
    f flags |> applyIf flags.hot Return.dropCmd



-- MODEL


type alias Model =
    { engine : Engine.Model
    , history : List Engine.InternalMsg
    }


init : Flags -> Return Msg Model
init flags =
    case flags.state of
        Nothing ->
            let
                ( engine, cmd ) =
                    initEngine

                model =
                    { engine = engine
                    , history = []
                    }
            in
                ( model, Cmd.map engineTranslator cmd )

        Just json ->
            case Json.Decode.decodeString decode json of
                Ok state ->
                    singleton state

                Err error ->
                    let
                        _ =
                            Debug.log error json
                    in
                        init { flags | state = Nothing }


encode : Model -> Json.Encode.Value
encode model =
    Json.Encode.object
        [ ( "history", model.history |> List.map Engine.Storage.encodeInternalMsg |> Json.Encode.list ) ]


decode : Json.Decode.Decoder Model
decode =
    Json.Decode.field "history" (Json.Decode.list Engine.Storage.decodeInternalMsg)
        |> Json.Decode.andThen decodeWithHistory


decodeWithHistory : List Engine.InternalMsg -> Json.Decode.Decoder Model
decodeWithHistory history =
    let
        updateEngineModel msg model =
            Engine.update msg model |> Tuple.first

        engine =
            history |> List.foldr updateEngineModel (Tuple.first initEngine)
    in
        Json.Decode.map2 Model
            (Json.Decode.succeed engine)
            (Json.Decode.succeed history)



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
    (case msg of
        EngineDone ->
            singleton model <&> (\m -> { m | history = [] }) |> withEngine initEngine

        EngineMsg engineMsg ->
            singleton model <&> recordHistory engineMsg |> withEngine (Engine.update engineMsg model.engine)
    )
        >>= persist


initEngine : Return Engine.Msg Engine.Model
initEngine =
    Engine.init 3 4


persist : Model -> Return Msg Model
persist model =
    ( model, model |> encode |> Json.Encode.encode 0 |> setState )


recordHistory : Engine.InternalMsg -> Model -> Model
recordHistory msg model =
    { model | history = msg :: model.history }


withEngine : Return Engine.Msg Engine.Model -> Return Msg Model -> Return Msg Model
withEngine ( engine, cmd ) =
    Return.mapWith (\m -> { m | engine = engine }) (Cmd.map engineTranslator cmd)



-- VIEW


view : Model -> Html Msg
view model =
    model.engine |> Theme.Classic.view |> Html.map engineTranslator
