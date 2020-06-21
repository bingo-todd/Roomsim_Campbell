function [answer,source_polar]=man_inp_sources; 
% Usage: [answer,source_polar]=man_inp_sources;
% Prompted manual input for Source location(s)
%-------------------------------------------------------------------------------- 
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
%--------------------------------------------------------------------------------------
% Functions called:

prefix='man_inp__sources: ';
error_title=[prefix ' Error'];

%Declare and clear source polar coordinates
R_s=[]; alpha=[]; beta=[]; source_polar=[];

banner = 'Source position(s) relative to Receiver (Polar Co-ordinates)';
prompt = {'Enter Source radial distance(s) [R1 R2 R3 ..] (m) :'...
        ,'Enter Source azimuth(s) [az1 az2 az3 ..] (-180<deg<180) :'...
        ,'Enter Source elevation(s) [el1 el2 el3 ..] (-90<deg<90) :'};
lines = 1;
def = {'[1]','[0]','[0]'}; %Default values
beep;
answer={};
answer = inputdlg(prompt,banner,lines,def,'on');
if ~isempty(answer),% Trap CANCEL button operation
    R_s=str2num(answer{1});
    alpha=str2num(answer{2});
    beta=str2num(answer{3});
    if (size(R_s,2)==size(alpha,2))&(size(R_s,2)==size(beta,2)), % Test for equal number of columns
        source_polar=[R_s;alpha;beta]; % Pack up source(s) coordinates into column vector.
    else,
        h=errordlg('Sources data input cancelled. Each parameter must have the same number of entries.',error_title);
        beep;
        uiwait(h); % Wait for user response
        answer={}; % Clear answer flag for test on return
    end;
end;

%------------- End of man_inp_sources.m -------------------------
