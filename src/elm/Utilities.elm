module Utilities exposing ((<&>), applyIf)

import Return exposing (Return)


(<&>) : Return msg a -> (a -> b) -> Return msg b
(<&>) =
    flip Return.map


applyIf : Bool -> (a -> a) -> a -> a
applyIf predicate =
    if predicate then
        identity
    else
        flip always
