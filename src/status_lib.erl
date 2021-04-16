-module(status_lib).

%% API
-export([register_handler/1, status/0]).

%% Helpers
-export([node_connectivity/1, node_connectivity/2, process_status/1, process_status/2]).

-type category() :: connectivity | process_status.
-type status_item() ::
        #{label := binary(), category := category(), status := ok | {error, binary()}}.

-export_type([status_item/0, category/0]).

%%==============================================================================================
%% Callbacks
%%==============================================================================================

-callback status() -> [status_item()].

%%==============================================================================================
%% API
%%==============================================================================================

-spec register_handler(module()) -> ok.
register_handler(Mod) -> persistent_term:put({status_lib, handler}, Mod).

-spec status() -> [status_item()].
status() ->
  case persistent_term:get({status_lib, handler}, undefined) of
    undefined -> [];
    Mod -> Mod:status()
  end.

%%==============================================================================================
%% Helpers
%%==============================================================================================

-spec node_connectivity(node()) -> status_item().
node_connectivity(Node) -> node_connectivity(Node, atom_to_binary(Node, utf8)).

-spec node_connectivity(node(), binary()) -> status_item().
node_connectivity(Node, Label) ->
  #{ label => Label
   , category => connectivity
   , status => status_from_bool(net_kernel:hidden_connect_node(Node), <<"no connection">>)
   }.

-spec process_status(atom()) -> status_item().
process_status(RegName) -> process_status(RegName, atom_to_binary(RegName, utf8)).

-spec process_status(atom(), binary()) -> status_item().
process_status(RegName, Label) ->
  Status = case erlang:whereis(RegName) of
             undefined -> {error, <<"Process not registered">>};
             Pid when is_pid(Pid) -> ok;
             Port when is_port(Port) -> {error, <<"Name refers to port, not pid">>}
           end,
  #{label => Label, category => process_status, status => Status}.

%%==============================================================================================
%% Internal functions
%%==============================================================================================

-spec status_from_bool(boolean(), binary()) -> ok | {error, binary()}.
status_from_bool(true, _) -> ok;
status_from_bool(false, Error) -> {error, Error}.

%% Local variables:
%% mode: erlang
%% erlang-indent-level: 2
%% indent-tabs-mode: nil
%% fill-column: 96
%% coding: utf-8
%% End:
