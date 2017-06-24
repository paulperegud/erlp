-module(test_examples).

-include_lib("eunit/include/eunit.hrl").

-import(rlp, [encode/1, decode/1]).


throw_test() ->
    Data = [{encoding_of_value_is_too_short, <<16#83, $d, $o>>}
           ,{encoding_of_length_is_too_short, <<16#c7, 16#c0, 16#c1, 16#c0, 16#c3, 16#c0, 16#c1>>}
           ],
    [ ?assertError(R, decode(Enc))
      || {R, Enc} <- Data ].

example_test() ->
    run(examples()).

examples() ->
    [{<<"dog">>, <<16#83, $d, $o, $g>>}
    ,{[<<"cat">>, <<"dog">>], <<16#c8, 16#83, $c, $a, $t, 16#83, $d, $o, $g >>}
    ,{<<>>, <<16#80>>}
    ,{[], <<16#c0>>}
    ,{i(15), <<15>>}
    ,{i(1024), <<16#82, 16#4, 16#0>>}
    ,{[ [], [[]], [ [], [[]] ] ], <<16#c7, 16#c0, 16#c1, 16#c0, 16#c3, 16#c0, 16#c1, 16#c0>>}
    ].

run(Data) ->
    [ begin
          ?assertEqual(encode(D), E),
          ?assertEqual(D, decode(E))
      end || {D, E} <- Data ].

i(I) when is_integer(I) ->
    binary:encode_unsigned(I, big).
