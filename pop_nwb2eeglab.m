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
% This file is part of EEGLAB, see http://www.eeglab.org 
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

function [EEG, com] = pop_nwb2eeglab(fileName, varargin)

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

try
    condValues = data.intervals_trials.vectordata.keys;
catch
    condValues = {};
end

if (length(condValues) > 1 || ~isempty(data.units)) && nargin < 2
    promptstr    = { ...
        { 'style'  'text'       'string' ['Which event information is primary' 10 '(this will define EEG event types):'] } ...
        { 'style'  'popupmenu'  'string' condValues 'tag' 'typefield' 'value' 1 'enable', fastif(isempty(condValues), 'off', 'on') } ...
        { 'style'  'checkbox'   'string' 'Import skipe latencies as events' 'tag' 'spikes' 'value' 0 'enable' fastif(isempty(data.units), 'off', 'on')} ...
        };
    geometry = {1 1 1};
    geomvert = [1.5 1 1];
    if isempty(condValues)
        promptstr{2} = { 'style' 'text' 'string' '      No event condition found' };
    end
    
    [~,~,~,res] = inputgui( 'geometry', geometry, 'geomvert', geomvert, 'uilist', promptstr, 'helpcom', 'pophelp(''pop_nwb2eeglab'')', 'title', 'Import NWB data -- pop_nwb2eeglab()');
    if isempty(res), return; end

    options = {};
    if ~isempty(condValues)
        options = [ options { 'typefield' condValues{res.typefield}  } ];
    end
    if res.spikes
        options = [ options { 'importspikes' fastif(res.spikes, 'on', 'off')  } ];
    end
end

opt = finputcheck(options, { 'typefield' 'string' '' ''; 'importspikes' 'string' { 'on' 'off' } 'off'});
if ischar(opt)
    error(opt);
end

EEG = eeg_emptyset;

% Scan fields to find data
values = data.acquisition.values;

for iVal = 1:length(values)
    if isa(data.acquisition.values{iVal}, 'types.core.ElectricalSeries')
        indVal = iVal;
        fprintf('Selecting the ElectricalSeries at position %d\n', iVal);
        break;
    end
end
EEG.data = values{indVal}.data.load;

% electrodes
chans = data.general_extracellular_ephys_electrodes.toTable();
chanlabels = cell(1,size(EEG.data,1));
if isfield(chans, 'label'), chanlabels = chans.label; end
if ~isempty(chanlabels{1})
    options = { 'labels', chanlabels };
    if isfield(chans, 'group_name') && ~isempty(chans.group_name), options = [ options { 'type', chans.group_name } ]; end
    if isfield(chans, 'x') && ~isempty(chans.x)                  , options = [ options { 'x', mattocell(chans.x) } ]; end
    if isfield(chans, 'y') && ~isempty(chans.y)                  , options = [ options { 'y', mattocell(chans.y) } ]; end
    if isfield(chans, 'z') && ~isempty(chans.z)                  , options = [ options { 'z', mattocell(chans.z) } ]; end
    EEG.chanlocs = struct(options{:});
end
EEG.nbchan = size(EEG.data,2);
EEG = eeg_checkset(EEG);

% sampling rate
if ~isempty(values{indVal}.starting_time_rate)
    EEG.srate = 1/values{indVal}.starting_time_rate;
else
    fprintf('Sampling rate not found, using the ''timestamps'' information\n')
    fprintf('and computing approximate sampling rate (data will not be interpolated)\n')
    timestamps = values{indVal}.timestamps.load;
    EEG.srate = 1/mean(diff(timestamps));
end

% save NWB structure
EEG.etc.nwb = data;

% import events
if ~isempty(data.intervals_trials.timeseries)
    event_lat = EEG.srate * (data.intervals_trials.start_time.data.load+1);
    event_len = EEG.srate * (data.intervals_trials.stop_time.data.load+1);

    condValues = data.intervals_trials.vectordata.keys;
    if ~isempty(condValues)
        if isempty(opt.typefield), opt.typefield = condValues{1}; end
    end
    for iEvent = 1:length(event_lat)
        for iVal = 1:length(condValues)
            tmpVal = get(data.intervals_trials.vectordata, condValues{iVal}).data(iEvent);
            EEG.event(iEvent).(condValues{iVal}) = tmpVal{1};
            % set type
            if strcmpi(condValues{iVal}, opt.typefield)
                EEG.event(iEvent).type = EEG.event(iEvent).(condValues{iVal});
            end
        end
        EEG.event(iEvent).latency  = event_lat(iEvent);
        EEG.event(iEvent).duration = event_len(iEvent);
    end
    EEG = eeg_checkset(EEG);
end

% import spikes 
if strcmpi(opt.importspikes, 'on')
    fprintf('Importing Spike information...\n')
    unitsId = data.units.id.data.load;
    numUnits = length(unitsId);

    eventFields = fieldnames(EEG.event);
    eventFields = setdiff(eventFields(:), { 'latency', 'type' });
    eventFields(:,2) = { [] };
    eventFields = eventFields';
    for iUnit = 1:numUnits
        spikeData = getRow(data.units, iUnit);
        spikeLatency = EEG.srate * spikeData.spike_times{1} + 1;
        
        spikeStr = sprintf('SpikeUnit#%d', unitsId(iUnit));
        eventTmp = struct('type', spikeStr, 'latency', mattocell(spikeLatency),  eventFields{:});
        EEG.event = [ EEG.event eventTmp' ];
    end

    % sort events
    eventLat = [ EEG.event.latency ];
    [~,inds] = sort(eventLat);
    EEG.event = EEG.event(inds);
end

% history
if isempty(options)
    com = sprintf('EEG = pop_nwb2eeglab(''%s'');', fileName);
else
    com = sprintf('EEG = pop_nwb2eeglab(''%s'', %s);', fileName, vararg2str(options));
end
