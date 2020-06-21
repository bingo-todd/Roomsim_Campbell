function sound_out(Fs, data);
% Usage: sound_out(Fs, data);
% Offer sound output to 32 bit Windows systems
%------------------------------------------------------------------------------- 
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
%-----------------------------------------------------------------------------------
% Functions called:

max_data = max(max(abs(data))); %Find max of (two) channel data
data=data/max_data;  %Scale into range +/- < 1
msg_title='sound_out: Wavplay';
message='A Windows PC user can play the result now';
button_order='Play';
while strcmp(button_order,'Play'),
    button_order = questdlg(message,msg_title,'Play','Cancel','Play'); %
    if strcmp(button_order,'Play'),
        wavplay(data,Fs,'sync'); % Windows PC user can listen to data contents now
        message='Play again ?';
    end;
end;
%--------- End of sound_out.m -----------------