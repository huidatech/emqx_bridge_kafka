% hello world program
-module(helloworld). 
-export([start/0]). 

start() -> 
   io:fwrite("Hello, world!\n"),
   Topic = "$c020202/abvc",
   % string:chr(Topic,$$)==1.
   LinkFlag = string:chr(Topic,$$),
   OtherFlag = string:chr(Topic,$/),
   if 
      LinkFlag == 1 ->
         ProduceTopic = "linktrace";
      OtherFlag /= 0 ->
         Tmp = string:tokens(Topic,"/"),
         [A | B] = Tmp,
         ProduceTopic = A
   end.
   %  ProduceTopic.

   % if 
   %    Tmp == 3 ->
   %       io:fwrite("Hello, world3!\n");
   %    Tmp == 4 ->
   %       io:fwrite("Hello, world5!\n")
   % end.
% start(A, B) ->
%     if 
%         A == 5 ->
%             io:format("A == 5~n", []),
%             a_equals_5;
%         B == 6 ->
%             io:format("B == 6~n", []),
%             b_equals_6;
%         A == 2, B == 3 ->                      %That is A equals 2 and B equals 3
%             io:format("A == 2, B == 3~n", []),
%             a_equals_2_b_equals_3;
%         A == 1 ; B == 7 ->                     %That is A equals 1 or B equals 7
%             io:format("A == 1 ; B == 7~n", []),
%             a_equals_1_or_b_equals_7
%     end.