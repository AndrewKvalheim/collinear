module Engine.Geometry
    exposing
        ( columnsOfLine
        , decompose
        , findLines
        , isCollinear
        , pointsInLine
        )

import Arithmetic
import Engine.Types exposing (..)
import Engine.Utilities exposing (..)


columnsOfLine : Line -> List (List Int)
columnsOfLine line =
    line
        |> pointsInLine
        |> List.map .components
        |> transpose


decompose : Int -> Int -> Int -> List Int
decompose modulus dimension id =
    id
        |> Arithmetic.toBase modulus
        |> listPadLeft dimension 0


findLines : Int -> List Point -> List Line
findLines modulus points =
    points
        |> combinations modulus
        |> List.filter (isCollinear modulus)
        |> List.map Collinear


isCollinear : Int -> List Point -> Bool
isCollinear modulus points =
    points
        |> List.map .components
        |> transpose
        |> List.all (List.sum >> flip (%) modulus >> (==) 0)


pointsInLine : Line -> List Point
pointsInLine line =
    case line of
        Collinear points ->
            points
