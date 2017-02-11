module Utilities exposing ((<&>))

import Return exposing (Return)


(<&>) : Return msg a -> (a -> b) -> Return msg b
(<&>) =
    flip Return.map
