function result = frame_conv(data_1,data_2)
%frame_proc.m Convolution using FFTs and overlap-add method.
% For speed, shorter sequence should be in data_1, longer sequence is in data_2.
% If longer and shorter data sequences are not significantly different
% length then perform single, full length, FFT on each. Otherwise,
% split the longer data sequence (data_2) into non-overlapping blocks.
% Extend each block to overlap by shorter data sequence length and 
% transform using FFT to frequency domain, multiply transforms and add overlapping
% result blocks. (see Discrete Systems and Dig Sig Proc., Strum & Kirk, p437-446
% Whichever method is selected the full convolution length N=longer+shorter-1 is computed.
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
% Functions called: load_min.m
%*** Global Declarations ***

% Shorter sequence is in data_1, longer sequence is in data_2
shorter=size(data_1,1);
longer=size(data_2,1);
N=shorter+longer-1; % Length of linear convolution
result = zeros(N,1); % Declare and clear vector for result

if 2*shorter > longer, % Use full length FFTs
    len_frame = 2.^nextpow2(N); % Force frame (FFT) length to a power of 2 >= convolution length N
    H = fft(data_1,len_frame); % Zero pad and take FFT of shorter sequence
    X = fft(data_2,len_frame); % Zero pad and take FFT of longer sequence
    temp = real(ifft(X.*H)); % Convolution by spectral product and force real result
    result = temp(1:N,1); % Trim result to length of input data
    clear temp; % Free up  memory.
    
else % Sequences are of significantly different length, use block FFT overlap-add method
    data_2=[data_2(:,1); zeros(N-length(data_2),1)]; % Zero-pad longer sequence to length of convolution result
    [len_frame, len_block]=load_min(shorter,N); % Find computationally efficient block and frame lengths
    H = fft(data_1,len_frame); % FFT of shorter sequence
    no_blocks=fix(N/len_block);
    for block_no=0:no_blocks,
        s_ind = 1 + block_no*len_block; % Start index for current block
        e_ind = min(s_ind+len_block-1,N); % Prevent falling off the end of data_2
        X = fft(data_2(s_ind:e_ind),len_frame); % Zero pad to len_frame (if required) and transform to frequency domain 
        y = real(ifft(X.*H)); % Convolution by spectral product Y=X.*H        
        r_end = min(s_ind+(len_block+shorter-2),N); % Prevent falling off the end of result
        result(s_ind:r_end) = result(s_ind:r_end) + y(1:(r_end-s_ind+1)); % Overlap add and trim to length
    end;
end;
%------------  End of frame_conv.m -----------------
