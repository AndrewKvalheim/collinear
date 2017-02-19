module Engine.Storage exposing (encodeInternalMsg, decodeInternalMsg)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Engine.Types exposing (..)


decodeInternalMsg : Decoder InternalMsg
decodeInternalMsg =
    Decode.field "tag" Decode.string |> Decode.andThen decodeInternalMsgByTag


decodeInternalMsgByTag : String -> Decoder InternalMsg
decodeInternalMsgByTag tag =
    case tag of
        "DeclareNoLines" ->
            Decode.succeed DeclareNoLines

        "Deselect" ->
            Decode.map Deselect
                (Decode.field "id" Decode.int)

        "LoadPool" ->
            Decode.map LoadPool
                (Decode.field "ids" (Decode.list Decode.int))

        "Select" ->
            Decode.map Select
                (Decode.field "id" Decode.int)

        _ ->
            Decode.fail (tag ++ " is not a recognized tag for InternalMsg")


encodeInternalMsg : InternalMsg -> Encode.Value
encodeInternalMsg msg =
    case msg of
        DeclareNoLines ->
            Encode.object
                [ ( "tag", "DeclareNoLines" |> Encode.string ) ]

        Deselect id ->
            Encode.object
                [ ( "tag", "Deselect" |> Encode.string )
                , ( "id", id |> Encode.int )
                ]

        LoadPool ids ->
            Encode.object
                [ ( "tag", "LoadPool" |> Encode.string )
                , ( "ids", ids |> List.map Encode.int |> Encode.list )
                ]

        Select id ->
            Encode.object
                [ ( "tag", "Select" |> Encode.string )
                , ( "id", id |> Encode.int )
                ]
