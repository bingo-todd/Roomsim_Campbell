function [matrixResult, cellResult] = getExcelSetup(filename, sheetname)
% Usage [matrixResult, cellResult] = getExcelSetup(filename, sheetname); Read Excel spreadsheet (XLS) file.
%--------------------------------------------------------------------------
% This is a modified version of the MATLAB standard m file xlsread.m
% which is Copyright 1984-2002 The MathWorks, Inc.
%   $Revision: 1.23 $  $Date: 2002/06/07 21:43:18 $
% It has been changed to extract only text data and items have been removed 
% to avoid errors in compilation of stand alone code.
%----------------------------------------------------------------------------- 
% This version Copyright (C) 2003  Douglas R Campbell
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
%-------------------------------------------------------------------------------
% Functions called: biffread.m, biffparse.dll

% validate input and output args
error(nargchk(1,2,nargin));
error(nargoutchk(1,2,nargout));

% Get Filename
if ~isstr(filename), error('Filename must be a string.'); end

% do some validation
if isempty(filename), error('Filename must not be empty.'); end

% put extension on
if all(filename~='.'), filename = [filename '.xls']; end

% look for file on path
if exist(filename,'file') ~= 2,  error('File not found'); end

biffvector = biffread(filename);

% try to read this sheet
[matrixResult, cellResult] = biffparse(biffvector, sheetname);
%------------------------------ End of GetExcelSetup.m ---------------------------------------------
