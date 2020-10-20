
% hello world program
-module(helloworld). 
-export([start/0]). 

start() -> 
%    io:fwrite(os:timestamp()).
    {M, S, _} = os:timestamp(),
    M * 1000000 + S.

