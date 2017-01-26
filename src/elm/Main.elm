module Main exposing (main)

import Engine.Main
import Engine.Types
import Html exposing (Html)
import Random
import Theme.Classic


-- APP


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }



-- MODEL


type alias Model =
    { engine : Maybe Engine.Types.Model
    }


init : ( Model, Cmd Msg )
init =
    { engine = Nothing } ! [ Random.generate InitEngine (Random.int Random.minInt Random.maxInt) ]



-- UPDATE


type Msg
    = EngineMsg Engine.Types.Msg
    | InitEngine Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EngineMsg message ->
            { model | engine = model.engine |> Maybe.map (Engine.Main.update message) } ! []

        InitEngine seed ->
            { model | engine = Just (Engine.Main.init 3 4 (Random.initialSeed seed)) } ! []



-- VIEW


view : Model -> Html Msg
view model =
    case model.engine of
        Nothing ->
            Html.text "Loading"

        Just engine ->
            engine |> Theme.Classic.view |> Html.map EngineMsg
