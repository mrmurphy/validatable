module Validatable exposing (SimpleValidatableString, Validatable(..), Validator, getErrors, getOneError, getValidValue, getValue, init, isValid, reset, runAll, runLive, validator, withDelayed, withLive)

{-| A library for storing data that can be invalid, and for checking it.

See the README for an example.


# Types

@docs Validatable, Validator, SimpleValidatableString


# For getting data onto the model initially

You can use `init`, or use the constructors for `Validatable` by hand.

@docs init


# For resetting a field's state

@docs reset


# Building validators

@docs validator, withDelayed, withLive


# For the update function

@docs runAll, runLive


# For the view function

@docs getValue, getValidValue, getOneError, isValid, getErrors

-}

import Validate as ValidateCore


{-| A basic validator that checks nothing. It's intended to be augmented with `withLive` or `withDelayed`.
-}
validator : Validator error value
validator =
    Validator
        { live = Nothing, delayed = Nothing }


{-| Augment a validator with a new live validation. Something like this:

(`ifBlank` comes from [elm-validate](http://package.elm-lang.org/packages/rtfeldman/elm-validate/1.1.3/Validate))

    emailValidator : Validator String String
    emailValidator =
        validator
            |> withLive (ifBlank "Hey, I need an email!")


    -- Don't worry. in the example for `withDelayed` we'll actually validate that it's an email.

-}
withLive : ValidateCore.Validator error value -> Validator error value -> Validator error value
withLive v (Validator other) =
    case other.live of
        Nothing ->
            Validator { other | live = Just v }

        Just prevV ->
            Validator { other | live = Just (ValidateCore.all [ prevV, v ]) }


{-| Augment a validator with a new delayed validation. Something like this:

(`ifInvalidEmail` comes from [elm-validate](http://package.elm-lang.org/packages/rtfeldman/elm-validate/1.1.3/Validate))

    emailValidator : Validator String String
    emailValidator =
        validator
            |> withLive (ifBlank "Hey, I need an email!")
            |> withDelayed (ifInvalidEmail "Sorry, that doesn't look like an email")

-}
withDelayed : ValidateCore.Validator error value -> Validator error value -> Validator error value
withDelayed v (Validator other) =
    case other.delayed of
        Nothing ->
            Validator { other | delayed = Just v }

        Just prevV ->
            Validator { other | delayed = Just (ValidateCore.all [ prevV, v ]) }


{-| Runs only the live validations. Use this immediately when your field is edited, whether it also uses delayed validations or not.
-}
runLive : Validator error value -> Validatable error value -> Validatable error value
runLive (Validator v) subject =
    let
        value =
            getValue subject

        liveErrors =
            case v.live of
                Nothing ->
                    []

                Just fn ->
                    fn value
    in
    case liveErrors of
        [] ->
            case v.delayed of
                Just _ ->
                    Debouncing value { liveErrors = [] }

                Nothing ->
                    Valid value

        errors ->
            case v.delayed of
                Just _ ->
                    Debouncing value { liveErrors = errors }

                Nothing ->
                    Invalid value errors


{-| Runs both live and delayed validations. Use this when your field has debounced.
-}
runAll : Validator error value -> Validatable error value -> Validatable error value
runAll (Validator v) subject =
    let
        value =
            getValue subject

        delayedErrors =
            case v.delayed of
                Nothing ->
                    []

                Just fn ->
                    fn value

        liveErrors =
            case v.live of
                Nothing ->
                    []

                Just fn ->
                    fn value
    in
    case liveErrors ++ delayedErrors of
        [] ->
            Valid value

        errors ->
            Invalid value errors


{-| Puts the field back into a "NotChecked" state. Good for forms that the user hasn't edited yet,
so you don't want to show any errors, but the form isn't valid, either.
-}
reset : Validatable error value -> Validatable error value
reset subject =
    let
        value =
            getValue subject
    in
    NotChecked value


{-| Returns the value of a validatable, no matter what state it's in.
-}
getValue : Validatable error value -> value
getValue subject =
    case subject of
        Valid v ->
            v

        Invalid v _ ->
            v

        Debouncing v _ ->
            v

        NotChecked v ->
            v


{-| Returns a Maybe containing the the valid value of a validatable
-}
getValidValue : Validatable error value -> Maybe value
getValidValue subject =
    case subject of
        Valid v ->
            Just v

        Invalid _ _ ->
            Nothing

        Debouncing _ _ ->
            Nothing

        NotChecked _ ->
            Nothing


{-| Gets the first error for the field, giving precedence to live errors.
-}
getOneError : Validatable error value -> Maybe error
getOneError subject =
    List.head <| getErrors subject


{-| Gets any errors for this field. If the field has no errors, produces an empty list.
-}
getErrors : Validatable error value -> List error
getErrors subject =
    case subject of
        Valid v ->
            []

        Invalid _ errors ->
            errors

        Debouncing v { liveErrors } ->
            liveErrors

        NotChecked _ ->
            []


{-| Returns True if the field has no errors, and has been debounced (if necessary). Otherwise returns tacos. Just kidding. False. Otherwise it returns False.
-}
isValid : Validatable error value -> Bool
isValid subject =
    case subject of
        Valid _ ->
            True

        _ ->
            False


{-| Puts a field into a not-checked state
-}
init : value -> Validatable error value
init =
    NotChecked


{-| A type that represents a value that can possibly be invalid, and its associated errors.
You'll want to check this value in your update function with `reset`, `runAll`, or `runLive`
-}
type Validatable error value
    = Valid value
    | Invalid value (List error)
    | Debouncing value { liveErrors : List error }
    | NotChecked value


{-| A Shortcut for `Validatable String String`. It just means that your errors are human-readable strings, and your value is a string as well, which is a common configuration.
-}
type alias SimpleValidatableString =
    Validatable String String


{-| An opaque type which represents a number of checks, both live and delayed, that can be run on a `Validatable`.
-}
type Validator error value
    = Validator
        { live : Maybe (ValidateCore.Validator error value)
        , delayed : Maybe (ValidateCore.Validator error value)
        }
