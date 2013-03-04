-module(input_parser).
-export([transform/3]).

%% Add clauses to this function to transform syntax nodes
%% from the parser into semantic output.
transform(module, [], _Index) ->
  "_:";
transform(module, [[], <<":">>], _Index) ->
  "_:";
transform(module, Node, _Index) ->
  lists:flatten(io_lib:format("~s", [Node]));
transform(function, Node, _Index) ->
  lists:flatten(io_lib:format("~s", [Node]));
transform(arglist, Node, _Index) ->
  lists:flatten(io_lib:format("~s", [Node]));
transform(return, Node, _Index) ->
  lists:flatten(io_lib:format("~s", [Node]));
transform(where, Node, _Index) ->
  lists:flatten(io_lib:format("~s", [Node]));
transform(dot, _Node, _Index) ->
  "";
transform(Symbol, Node, _Index) when is_atom(Symbol) ->
  Node.
