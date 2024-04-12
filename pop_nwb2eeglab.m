% pop_nwb2eeglab() - import NWB file containing time series data as an EEGLAB dataset.
%
% Usage:
%   >> EEG = pop_nwb2eeglab; % pop up window to input arguments
%   >> EEG = pop_nwb2eeglab(filename); % import a given file
%
% Optional inputs:
%   filename  - [string] dataset filename. Default pops up a graphical
%               interface to browse for a data file.
%
% Output
%   EEG - EEG dataset structure or array of structures
%
% Author: Arnaud Delorme, UCSD
%
% See also: eeglab()

% Copyright (C) 2024 Arnaud Delorme, UCSD
%
% This file is part of EEGLAB, see https://urldefense.com/v3/__http://www.eeglab.org__;!!Mih3wA!FEwHgHjctkJ2D0Ove-79slevEDsE1K2jouFDmdOkovvn1Kvf81VoHnoq4zw64tfGlyoLA0vXGN7Y$ 
% for the documentation and details.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
% this list of conditions and the following disclaimer in the documentation
% and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
% THE POSSIBILITY OF SUCH DAMAGE.

function [EEG, com] = pop_nwb2eeglab(fileName)

EEG = [];
com = '';
if nargin < 1
	[filename, filepath] = uigetfile('*.*', 'Select NWB file -- pop_nwb2eeglab()', 'multiselect', 'off');
    if isequal(filename, 0)
        return;
    end
    fileName = fullfile(filepath, filename);
end

data = nwbRead(fileName);

EEG = eeg_emptyset;
EEG.data = data.acquisition.get('ecephys.ieeg').data.load;

% electrodes
chans = data.general_extracellular_ephys_electrodes.toTable();
EEG.chanlocs = struct('labels', chans.label, 'type', chans.group_name, 'x', mattocell(chans.x), 'y', mattocell(chans.y), 'z', mattocell(chans.z));
EEG.nbchan = size(EEG.data,2);
EEG = eeg_checkset(EEG);

% sampling rate
timestamps = data.acquisition.get('ecephys.ieeg').timestamps.load;
EEG.srate = 1/mean(diff(timestamps));
EEG.etc.nwb = data;

% events
event_lat = data.intervals_trials.timeseries.data.load.idx_start+1;
event_len = data.intervals_trials.timeseries.data.load.count;
conditions = get(data.intervals_trials.vectordata, 'condition').data.load;
for iEvent = 1:length(event_lat)
    EEG.event(iEvent).type     = conditions{iEvent};
    EEG.event(iEvent).latency  = event_lat(iEvent);
    EEG.event(iEvent).duration = event_len(iEvent);
end
EEG = eeg_checkset(EEG);

com = sprintf('EEG = pop_nwb2eeglab(%s);', fileName);