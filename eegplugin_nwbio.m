% eegplugin_nwbio() - EEGLAB plugin for importing nwb 
%             (Neuroscience Without Borders) data file 
%
% Usage:
%   >> eegplugin_nwbio(fig, trystrs, catchstrs);
%
% Inputs:
%   fig        - [integer]  EEGLAB figure
%   trystrs    - [struct] "try" strings for menu callbacks.
%   catchstrs  - [struct] "catch" strings for menu callbacks.
%
% Author: Arnaud Delorme, SCCN, INC, UCSD

% Copyright (C) 2024 Arnaud Delorme
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function vers = eegplugin_nwbio(fig, trystrs, catchstrs)

    vers = 'nwbio1.2';
    if nargin < 3
        error('eegplugin_nwbio requires 3 arguments');
    end
    
    % add folder to path
    % ------------------
    p = which('nwbRead.m');
    if isempty(p)
        p = which('eegplugin_nwbio.m');
        p = p(1:findstr(p,'eegplugin_nwbio.m')-1);
        addpath( p );
        addpath( fullfile(p, 'matnwb') );
    end
    
    % find import data menu
    % ---------------------
    menui1 = findobj(fig, 'tag', 'import data');
    menui2 = findobj(fig, 'tag', 'export');
    
    % menu callbacks
    % --------------
    comcnt1 = [ trystrs.no_check '[EEGTMP, LASTCOM] = pop_nwbimport;'  catchstrs.new_non_empty ];
    comcnt2 = [ trystrs.no_check '[LASTCOM] = pop_nwbexport(EEG);'     catchstrs.add_to_hist ];
                
    % create menus
    % ------------
    uimenu( menui1, 'label', 'From NWB file', 'separator', 'on', 'callback', comcnt1);
    uimenu( menui2, 'label', 'To NWB file', 'separator', 'on', 'callback', comcnt2);
