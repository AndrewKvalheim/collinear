module Theme.Base.Cards exposing (Config, view)

import Engine.Types exposing (..)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Html.Lazy
import List.Extra
import List.Split
import SingleTouch
import String.Extra
import Touch


type alias Config =
    { knowledgeToString : Knowledge -> String
    , skeletonSrc : String
    , viewContent : Point -> List (Html Msg)
    }


view : Config -> Model -> Html Msg
view config model =
    let
        rowCount =
            (List.length model.sample) // 3
    in
        Html.div [ Html.Attributes.class "classic-screen" ]
            [ Html.node "div"
                [ Html.Attributes.class "classic-table"
                , Html.Attributes.class ("row-count-" ++ (String.Extra.fromInt rowCount))
                ]
                [ Html.div
                    [ Html.Attributes.class "classic-table-inner" ]
                    (viewPoints config model.sample)
                ]
            , Html.div [ Html.Attributes.class "classic-controls" ]
                [ Html.p [] [ viewKnowledge config model ]
                , Html.p []
                    [ Html.text
                        (String.Extra.pluralize
                            "penalty"
                            "penalties"
                            model.penalties
                        )
                    ]
                , viewProgress model
                ]
            ]


viewPoints : Config -> List Point -> List (Html Msg)
viewPoints config points =
    points
        |> List.map (Html.Lazy.lazy2 viewPoint config)
        |> List.Split.chunksOfLeft 3
        |> List.Extra.intercalate [ Html.br [] [] ]


viewPoint : Config -> Point -> Html Msg
viewPoint config point =
    let
        message =
            if point.selected then
                Deselect
            else
                Select
    in
        Html.div
            [ Html.Attributes.class "classic-card-container"
            , Html.Attributes.class (imperfectionClass 5 point.id)
            ]
            [ Html.img
                [ Html.Attributes.class "classic-card-container-skeleton"
                , Html.Attributes.src config.skeletonSrc
                ]
                []
            , Html.div [ Html.Attributes.class "classic-card-container-content" ]
                [ Html.div
                    ([ Html.Attributes.classList
                        [ ( "classic-card", True )
                        , ( "classic-selected", point.selected )
                        , ( "classic-hidden", not point.visible )
                        ]
                     ]
                        ++ (onTap (message point.id))
                    )
                    (config.viewContent point)
                ]
            ]


onTap : Msg -> List (Html.Attribute Msg)
onTap message =
    [ Html.Events.onMouseDown message
    , SingleTouch.onSingleTouch Touch.TouchStart Touch.preventAndStop (\_ -> message)
    ]


imperfectionClass : Int -> Int -> String
imperfectionClass size seed =
    let
        imperfectionID =
            seed % size
    in
        "imperfection-" ++ (String.Extra.fromInt imperfectionID)


viewKnowledge : Config -> Model -> Html Msg
viewKnowledge config model =
    let
        knowledgeString =
            config.knowledgeToString model.knowledge
    in
        case model.knowledge of
            Unknown ->
                Html.button
                    ([ Html.Attributes.class "btn btn-primary"
                     ]
                        ++ (onTap DeclareNoLines)
                    )
                    [ Html.text knowledgeString ]

            AllLinesFound ->
                Html.button
                    ([ Html.Attributes.class "btn btn-primary"
                     ]
                        ++ (onTap NextEngine)
                    )
                    [ Html.text knowledgeString ]

            _ ->
                Html.text knowledgeString


viewProgress : Model -> Html Msg
viewProgress model =
    let
        maxLength =
            model.modulus ^ model.dimension

        currentLength =
            maxLength - (model.quantityFound * model.modulus)

        percentRemaining =
            100 * (toFloat currentLength) / (toFloat maxLength)
    in
        Html.div [ Html.Attributes.class "progress" ]
            [ Html.div
                [ Html.Attributes.class "progress-bar"
                , Html.Attributes.style
                    [ ( "width", (String.Extra.fromFloat percentRemaining) ++ "%" )
                    ]
                ]
                [ Html.text ((String.Extra.fromInt currentLength) ++ " / " ++ (String.Extra.fromInt maxLength))
                ]
            ]
