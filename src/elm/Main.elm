port module Main exposing (main)

import Engine.Main as Engine
import Engine.Storage
import Engine.Types as Engine
import Html exposing (Html)
import Json.Decode
import Json.Encode
import Return exposing (Return, effect_, command, singleton)
import Task
import Theme.Classic
import Time exposing (Time)
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
    , history : List Event
    }


type alias Event =
    { time : Time
    , msg : Engine.InternalMsg
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
        [ ( "history", model.history |> List.map encodeEvent |> Json.Encode.list ) ]


encodeEvent : Event -> Json.Encode.Value
encodeEvent event =
    Json.Encode.object
        [ ( "time", event.time |> Json.Encode.float )
        , ( "msg", event.msg |> Engine.Storage.encodeInternalMsg )
        ]


decode : Json.Decode.Decoder Model
decode =
    Json.Decode.field "history" (Json.Decode.list decodeEvent)
        |> Json.Decode.andThen decodeWithHistory


decodeEvent : Json.Decode.Decoder Event
decodeEvent =
    Json.Decode.map2 Event
        (Json.Decode.field "time" Json.Decode.float)
        (Json.Decode.field "msg" Engine.Storage.decodeInternalMsg)


decodeWithHistory : List Event -> Json.Decode.Decoder Model
decodeWithHistory history =
    let
        updateEngineModel msg model =
            Engine.update msg model |> Tuple.first

        engine =
            history
                |> List.map .msg
                |> List.foldr updateEngineModel (Tuple.first initEngine)
    in
        Json.Decode.map2 Model
            (Json.Decode.succeed engine)
            (Json.Decode.succeed history)



-- UPDATE


type Msg
    = EngineDone
    | EngineMsg Engine.InternalMsg
    | LogEvent Engine.InternalMsg Time


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
            singleton model
                <&> (\m -> { m | history = [] })
                |> withEngine initEngine

        EngineMsg engineMsg ->
            singleton model
                |> logEvent engineMsg
                |> withEngine (Engine.update engineMsg model.engine)

        LogEvent engineMsg time ->
            let
                event =
                    { time = time
                    , msg = engineMsg
                    }
            in
                singleton { model | history = event :: model.history }
                    |> effect_ persist


initEngine : Return Engine.Msg Engine.Model
initEngine =
    Engine.init 3 4


logEvent : Engine.InternalMsg -> Return Msg Model -> Return Msg Model
logEvent engineMsg =
    command (Task.perform (LogEvent engineMsg) (delayAfter 500 Time.now))


persist : Model -> Cmd Msg
persist model =
    model |> encode |> Json.Encode.encode 0 |> setState


withEngine : Return Engine.Msg Engine.Model -> Return Msg Model -> Return Msg Model
withEngine ( engine, cmd ) =
    Return.mapWith (\m -> { m | engine = engine }) (Cmd.map engineTranslator cmd)



-- VIEW


view : Model -> Html Msg
view model =
    model.engine |> Theme.Classic.view |> Html.map engineTranslator
