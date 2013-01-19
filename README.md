Fjalar - a Ragnarok Online server
=================================
Because the world needs a decent Ragnarok Online server, doesn't it?

Choices
-------
The server will be implemented in Elixir, because it has the goodies of Erlang
with the goodies of homoiconicity and metaprogramming.

The game logic will be implemented directly in Elixir, using some helper macros
to make it look decent.

To allow distribution to multiple machine each map will be implemented as a
process, and that process might be on a different machine.

A single master server will handle connections and game logic definition,
sharing it through mnesia.

Game state and everything will also be stored in mensia. *(maybe think about
Riak too?)*
