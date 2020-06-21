function [data_1, data_2] = check_swap(data_1,data_2)
% Find shorter data sequence, swap shorter into data_1 if necessary
d1_rows=size(data_1,1);
d2_rows=size(data_2,1);
if d1_rows > d2_rows, % swap
    temp = data_2;
    data_2 = data_1; % Longer sequence is in data_2
    data_1 = temp; % Shorter sequence is in data_1
end; % Shorter sequence is in data_1, longer sequence is in data_2
%-------- End of check_swap.m ------------------
