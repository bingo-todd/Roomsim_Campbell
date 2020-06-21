function [B,A]=hi_pass2(Fc,Fs)
% Usage: [B,A]=hi_pass2(Fc,Fs); Compute numerator B and denominator A coefficients 
% of a simple second order IIR high-pass filter with NOMINAL cut-off ( -4dB) at Fc Hz
%----------------------------------------------------------------------------------- 
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
%------------------------------------------------------------------------------------------
% Functions called:

T=1/Fs;
w=2*pi*Fc;
r1=exp(-w*T);
r2=r1;
%Numerator coefficients (fix zeros)
b1=-(1+r2);
b2=r2;
%Denominator coefficients (fix poles)
a1=2*r1*cos(w*T);
a2=-r1*r1;
%Normalisation gain
HF_Gain=(1-b1+b2)/(1+a1-a2);

B=[1 b1 b2]/HF_Gain;
A=[1 -a1 -a2];
%-------------------------- End of hi_pass2.m ------------------------------
