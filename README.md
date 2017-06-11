rlp
=====

Erlang implementation of RLP serialization. RLP serialization is widely used in Ethereum project.
Description of RLP serialization: https://github.com/ethereum/wiki/wiki/RLP

Values have to be represented as binaries. Lists consists of values and other lists.

On this implemenetation:
* Native Erlang (no NIFs)
* PropEr tests
* No tests of performance yet
* An OTP library

Build
-----

    $ rebar3 compile
