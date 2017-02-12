module Main exposing (main)

import Engine.Main
import Engine.Types
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
    { engine : Engine.Types.Model
    }


init : Return Msg Model
init =
    let
        ( engine, cmd ) =
            Engine.Main.init 3 4
    in
        ( { engine = engine }, Cmd.map EngineMsg cmd )



-- UPDATE


type Msg
    = EngineMsg Engine.Types.Msg


update : Msg -> Model -> Return Msg Model
update msg model =
    case msg of
        EngineMsg message ->
            singleton model |> withEngine (Engine.Main.update message model.engine)


withEngine : Return Engine.Types.Msg Engine.Types.Model -> Return Msg Model -> Return Msg Model
withEngine ( engine, cmd ) =
    Return.mapWith (\m -> { m | engine = engine }) (Cmd.map EngineMsg cmd)



-- VIEW


view : Model -> Html Msg
view model =
    model.engine |> Theme.Classic.view |> Html.map EngineMsg
