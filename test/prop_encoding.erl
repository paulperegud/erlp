-module(prop_encoding).

-include_lib("proper/include/proper.hrl").
-include_lib("eunit/include/eunit.hrl").

-import(rlp, [encode/1, decode/1, encode_length/2, decode_length/2]).

-type lol(T) :: list(lol(T)) | T.

prop_length() ->
    ?FORALL(Int, integer(1, inf),
            begin
                {Len, Enc} = encode_length(Int, 128),
                Len = size(Enc),
                {DecLen, DecInt, _} = decode_length(Enc, 128),
                DecLen = size(Enc),
                Int =:= DecInt
            end).

prop_value() ->
    ?FORALL(L, binary(),
            begin
                Encoded = encode(L),
                Decoded = decode(Encoded),
                L =:= Decoded
            end).

prop_list() ->
    ?FORALL(L, lol(binary()),
            begin
                Encoded = encode(L),
                Decoded = decode(Encoded),
                L =:= Decoded
            end).

prop_decode() ->
    ?FORALL(E, binary(),
            begin
                try decode(E) of
                    L -> E =:= encode(L)
                catch
                    error:{trailing_data, _} -> true;
                    error:encoding_of_value_is_too_short -> true;
                    error:encoding_of_length_is_too_short -> true;
                    error:{badmatch, _} -> true
                end
            end).
