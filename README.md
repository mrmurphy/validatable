# Validatable

A library for storing data that can be invalid, and for checking it with live and delayed checks.


# Example

This library uses <http://package.elm-lang.org/packages/rtfeldman/elm-validate> under the hood, and in some of its exposed types. Maybe in the future we'll bring those functions in to the library so you don't have to use two. But hey! this is a minimum-viable-package!

Here's a basic example of how you might use this library:

Very first, I'm going to make a type alias called `Error` just to make the type signatures more
understandable. I want my errors to be strings, so the alias will just point `Error` to `String`.

    type alias Error =
        String

Next, build a validator:

    emailValidator : Validator Error String
    emailValidator =
        validator
            |> withLive (ifBlank "Hey, I need an email!")
            |> withDelayed (ifInvalidEmail "Sorry, that doesn't look like an email")

Then store a `Validatable` on your model:

    type alias Model =
        { email : Validatable Error String
        }

    init =
        { email =
        }

After that we can add two message types, for when the field is changed, and for when the field
is debounced. (Meaning, when the user has stopped editing a field for some lenth of time)

On the topic of debouncing, there are a number of Elm libraries available to do debouncing inside of the Elm Applicaiton Architecture, or you can build a [Web component](https://www.youtube.com/watch?v=ar3TakwE8o0) for an input that will fire an event after some debounce interval. Or, _if you know what you're doing and you're okay with very very fragile hackery_, you can **dangerously** hand-code an "onchange" attribute for your input div and debounce in there, firing a custom event when the debounce happens. But that's the least-safe way to do it.

    type Msg
        = ChangedEmail String
        | DebouncedEmail

Then, in your update function, you can check live errors when the field is changed, and check all errors when the debounce comes through. Remember that when a new value for the field comes through, you'll want to re-create the field state before running the validations with `init`.

    update msg model =
        case msg of
            ChangedEmail val ->
                { model | email = runLive emailValidator (init val) } ! []

            DebouncedEmail ->
                { model | email = runAll emailValidator model.email } ! []

Then, in your view, you can use the `firstError`, `getValue`, and `isValid` to build a little form.
(I'm making up pretend functions here that will take arguments and render nice HTML controls, so that we don't muddy up the ReadMe too much.)

    view model =
        div []
            [ input
                { errorMessage = getOneError model.email
                , value = getValue model.email
                }
            , button
                { disabled = not <| isValid model.email
                , text = "GO!"
                }
            ]

