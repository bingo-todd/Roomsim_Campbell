function [max_n_isources, max_order, max_H_length] = check_memory(Fs,c,room_size,n_sources);
%Usage: [max_n_isources, max_order, max_H_length] = check_memory(Fs,c,room_size,n_sources);
% Attempts to estimate the maximum value of order and impulse response length
% to avoid MATLAB OUT OF MEMORY errors.
%------------------------------------------------------------------ 
% Copyright (C) 2003  Douglas R Campbell
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
% Functions called:

%*** Global Declarations ***
global log_fid; % Identifier of logfile. This is defined in roomsim.m

Fs_c=Fs/c;

% Estimate the biggest array size 
mem_error=false;
n=0;
while ~mem_error,
    n=n+1;
    try,
        TEMP=zeros(500000,n);
    catch,
        mem_error=true;
        [rows, columns]=size(TEMP);
        biggest=rows*columns
    end;
end;

%Estimate the largest value of order and H_length
max_n_isources = fix(biggest./((10+2.*n_sources))); % Max value of n_isources allowed
max_order = fix(0.5.*(0.5.*(max_n_isources).^(1/3) -1)); % Max allowable value of order to keep memory required < biggest
max_H_length = ceil((2.*max_order+1).*max(room_size).*Fs_c); % Max allowable impulse response length in samples
Max_Imp_resp_T = max_H_length/Fs; % Equivelant longest impulse response time.

%Record these in the logfile
fprintf(log_fid,'\n\n Estimate of maximum order allowed for this problem by this system = %i',max_order); % Print to the log file
fprintf(log_fid,'\n\n Equivelant impulse response length = %i samples)',max_H_length);
fprintf(log_fid,'\n\n Equivelant impulse response duration = %8.4g s)',Max_Imp_resp_T);
