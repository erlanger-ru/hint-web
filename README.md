hint-web
========

web-facing frontend for HINT


The story so far
---------------

    > rebar get-deps
    > rebar compile
    > ./start-dev.sh
    1> hint:start().

Go to http://localhost:8080

That's it for now


However, you can play with `input_grammar:parse/1`.

    1> input_grammar:parse("proplists:get(b,list()) -> list().").
    ["proplists:","get","(b,list())"," -> list()",[]]

This will be used to process user input.