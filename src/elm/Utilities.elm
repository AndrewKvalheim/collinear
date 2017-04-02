module Utilities exposing ((<&>), applyIf, delayAfter)

import Process
import Return exposing (Return)
import Task exposing (Task)
import Time exposing (Time)


(<&>) : Return msg a -> (a -> b) -> Return msg b
(<&>) =
    flip Return.map


applyIf : Bool -> (a -> a) -> a -> a
applyIf predicate =
    if predicate then
        identity
    else
        flip always


delayAfter : Time -> Task error result -> Task error result
delayAfter time task =
    Task.map2 always task (Process.sleep time)
