function [len_frame_save, len_block_save]=load_min(shorter,longer);
% Usage: [len_frame_save, len_block_save]=load_min(shorter,longer)
% Find computationally efficient block and frame lengths for overlap-add scheme
% used in frame_conv.m
%------------------------------------------------------------------ 
% Copyright (C) 2004  Douglas R Campbell
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program in the MATLAB file roomsim_licence.m ; if not,
%  write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
%-------------------------------------------------------------------------
% Initialise loop
len_frame = 2.^nextpow2(shorter); % Force frame (FFT) length to a power of 2 >= shorter
len_block = len_frame - shorter + 1; % ie. (FFT)Frame length = Block length+shorter-1
no_blocks=ceil(longer/len_block);
load_new=no_blocks*(3*len_frame)*log2(len_frame); % Initial estimate of computational load
load_old=load_new;
while (load_new<=load_old), % Descend to "minimum" computational load
    % Save entry values
    load_old=load_new;
    len_frame_save=len_frame;
    len_block_save=len_block;
    % Update frame and block size
    len_frame = 2*len_frame_save; % Try double the frame length
    len_block = len_frame - shorter + 1; % New block length
    no_blocks=ceil(longer/len_block);
    if no_blocks == 1, % Frame length is >= longer+shorter-1
        break; % out of while loop
    end; 
    % Computational load estimate = Number of blocks*(6*(N/2)*log2(N))
    load_new=no_blocks*(3*len_frame)*log2(len_frame);
end;
%------------  End of load_min.m -----------------