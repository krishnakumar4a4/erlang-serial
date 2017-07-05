%%%-------------------------------------------------------------------
%%% @author krishnak <krishnak@inadmin-3.local>
%%% @copyright (C) 2017, krishnak
%%% @doc
%%%
%%% @end
%%% Created :  5 Jul 2017 by krishnak <krishnak@inadmin-3.local>
%%%-------------------------------------------------------------------
-module(serial_to_file).

-behaviour(gen_server).

%% API
-export([start_link/0,stop/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
 terminate/2, code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {
 serialPid,
  fileHandle
 }).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []),
    gen_server:call(?SERVER, start, infinity).

stop() ->
	gen_server:stop(?SERVER).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init([]) ->
    process_flag(trap_exit, true),
%    SerialPort = serial:start([{open, "/dev/ttyACM0"}, {speed, 9600}]),
    {{Y,M,D},{H,Min,Sec}} = calendar:local_time(),
    ToString = fun(N) -> erlang:integer_to_list(N) end,
    FileName = "serial_"++ToString(Y)++"_"++ToString(M)++"_"++ToString(D)++"_"++ToString(H)++"_"++ToString(Min)++"_"++ToString(Sec),
   % Fun = fun(Fun) -> receive
%	        % Receive data from the serial port on the caller's PID.
%	         {data, Bytes} ->
%	               io:format("~s", [Bytes]),
%		       Fun(Fun)
%	                       after
%	                           % Stop listening after 5 seconds of inactivity.
%	                               5000 ->
%	                                     io:format("~n"),
%	                                          ok
%	                                            end
%	  end,
%    erlang:spawn_link(Fun(Fun)),
    case file:open(FileName,[write,raw]) of
{ok,IoDev} ->
    {ok, #state{fileHandle = IoDev}};
_ ->
	io:format("Error: Unable to open file"),
    {ok, #state{}}
    end.
%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_call(start, _From, State) ->
    SerialPort = serial:start([{open, "/dev/ttyACM0"}, {speed, 9600}]),
    {reply, ok, State#state{serialPid = SerialPort}};
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info({data,Bytes}, State) ->
	List = erlang:binary_to_list(Bytes),
    file:write(State#state.fileHandle, List),
    {noreply, State};
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, State) ->
    State#state.serialPid ! {close},
	file:close(State#state.fileHandle),
	io:format("closed file"),
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================


