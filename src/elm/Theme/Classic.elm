module Theme.Classic exposing (view)

import Engine.Types exposing (..)
import Html exposing (Html)
import Html.Attributes
import List.Extra
import String.Extra
import Svg
import Svg.Attributes
import Theme.Base.Cards


view : Model -> Html Msg
view model =
    Html.div []
        [ viewDefs
        , viewPrefetch model.pool
        , Theme.Base.Cards.view config model
        ]


viewDefs : Html Msg
viewDefs =
    Svg.svg [ Svg.Attributes.style "position: absolute; height: 0; width: 0;" ]
        [ Svg.defs [] (viewPatternDefs ++ viewShapeDefs) ]


viewPrefetch : List Int -> Html Msg
viewPrefetch pool =
    if List.length pool == 3 then
        Html.div []
            [ Html.node "link"
                [ Html.Attributes.rel "prefetch"
                , Html.Attributes.href "static/img/card-back.svg"
                ]
                []
            ]
    else
        Html.div [] []


config : Theme.Base.Cards.Config
config =
    { knowledgeToString = knowledgeToString
    , skeletonSrc = "static/img/7x5_oversized.png"
    , viewContent = viewContent
    }


knowledgeToString : Knowledge -> String
knowledgeToString knowledge =
    case knowledge of
        Unknown ->
            "No Three Collinear Points"

        NoLines ->
            "There are no three collinear points."

        SomeLineConstantIn [] ->
            "There are three collinear points that are all different."

        SomeLineConstantIn dimensions ->
            let
                attributes =
                    dimensions
                        |> List.reverse
                        |> List.map componentIndexToString
                        |> String.Extra.toSentenceOxford
            in
                "There are three collinear points that have all the same " ++ attributes ++ "."

        AllLinesFound ->
            "New Game"


componentIndexToString : Int -> String
componentIndexToString index =
    case List.Extra.getAt index componentNames of
        Just name ->
            name

        Nothing ->
            Debug.crash "Unsupported dimension"


componentNames : List String
componentNames =
    [ "shape", "quantity", "pattern", "color" ]


viewContent : Point -> List (Html Msg)
viewContent point =
    case point.components of
        [ shapeID, quantityID, patternID, colorID ] ->
            let
                symbol =
                    viewSymbol shapeID colorID patternID
            in
                List.repeat (quantityID + 1) symbol

        _ ->
            Debug.crash "Unsupported dimension"


viewSymbol : Int -> Int -> Int -> Html Msg
viewSymbol shapeID colorID patternID =
    Svg.svg
        [ Svg.Attributes.class "classic-symbol"
        , Svg.Attributes.viewBox "0 0 64 128"
        ]
        [ Svg.use
            [ Svg.Attributes.xlinkHref ("#shape-" ++ String.Extra.fromInt shapeID)
            , Svg.Attributes.fill (fill colorID patternID)
            , Svg.Attributes.stroke (color colorID)
            , Svg.Attributes.style "stroke-width: 4; stroke-linecap: round; stroke-linejoin: round;"
            ]
            []
        ]


fill : Int -> Int -> String
fill colorID patternID =
    case patternID of
        0 ->
            color colorID

        1 ->
            "url(#stripes-" ++ (toString colorID) ++ ")"

        2 ->
            "none"

        _ ->
            Debug.crash "Unsupported modulus"


color : Int -> String
color colorID =
    case colorID of
        0 ->
            "#c9245f"

        1 ->
            "#248C85"

        2 ->
            "#de8200"

        _ ->
            Debug.crash "Unsupported modulus"


viewPatternDefs : List (Html Msg)
viewPatternDefs =
    List.range 0 2 |> List.map viewPatternDef


viewPatternDef : Int -> Html Msg
viewPatternDef colorID =
    Svg.pattern
        [ Svg.Attributes.id ("stripes-" ++ (toString colorID))
        , Svg.Attributes.patternUnits "userSpaceOnUse"
        , Svg.Attributes.x "0"
        , Svg.Attributes.y "0"
        , Svg.Attributes.height "6"
        , Svg.Attributes.width "6"
        ]
        [ Svg.rect
            [ Svg.Attributes.x "0"
            , Svg.Attributes.y "0"
            , Svg.Attributes.height "2"
            , Svg.Attributes.width "6"
            , Svg.Attributes.fill (color colorID)
            ]
            []
        ]


viewShapeDefs : List (Html Msg)
viewShapeDefs =
    [ Svg.rect
        [ Svg.Attributes.id "shape-0"
        , Svg.Attributes.x "2"
        , Svg.Attributes.y "2"
        , Svg.Attributes.width "60"
        , Svg.Attributes.height "124"
        , Svg.Attributes.rx "20"
        ]
        []
    , Svg.path
        [ Svg.Attributes.id "shape-1"
        , Svg.Attributes.d "M 32,2 q 60,62 0,124 q -60,-62 0,-124"
        ]
        []
    , Svg.polygon
        [ Svg.Attributes.id "shape-2"
        , Svg.Attributes.points "4,60 54,2 40,51 60,68 10,126 24,77"
        ]
        []
    ]
