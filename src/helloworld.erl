% hello world program
-module(helloworld). 
-export([start/0]). 

start() -> 
   io:fwrite("Hello, world!\n"),
   Topic = "$c020202/abvc",
   Tmp = string:tokens(Topic,"/"),
   [A | B] = Tmp,
   Topic2 = list_to_atom(A),
   Topic2.

   % if 
   %    Tmp == 3 ->
   %       io:fwrite("Hello, world3!\n");
   %    Tmp == 4 ->
   %       io:fwrite("Hello, world5!\n")
   % end.
