% POP_NWBIMPORT - import NWB file containing time series data as an EEGLAB dataset.
%
% Usage:
%   >> EEG = pop_nwbimport; % pop up window to input arguments
%   >> EEG = pop_nwbimport(filename, 'key', val);
%
% Optional inputs:
%   filename  - [string] dataset filename. Default pops up a graphical
%               interface to browse for a data file.
%   'typefield' - [string] indicate the NWB trial field to use for EEGLAB
%                 event type. The default is to use the first field.
%   'importspikes' - ['on'|'off'] import spikes when 'on' and when spikes
%                 are present.
%   'ElectricalSeries' - [string] name of the electrical time series to use.
%                         Default is to use the first one available.
%
% Output
%   EEG - EEG dataset structure or array of structures
%
% Author: Arnaud Delorme, UCSD
%
% See also: POP_NWBEXPORT, EEGLAB

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

function [EEG, com] = pop_nwbimport(fileName, varargin)

EEG = [];
com = '';
if nargin < 1
	[filename, filepath] = uigetfile('*.*', 'Select NWB file -- pop_nwbimport()', 'multiselect', 'off');
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
defaulttypefield = '';
if any(strmatch('type', condValues, 'exact'))
    fprintf('Event field ''type'' found, and set to EEGLAB event type\n');
    defaulttypefield = 'type';
end

if (length(condValues) > 1 || ~isempty(data.units)) && nargin < 2 && isempty(defaulttypefield)
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
    
    [~,~,~,res] = inputgui( 'geometry', geometry, 'geomvert', geomvert, 'uilist', promptstr, 'helpcom', 'pophelp(''pop_nwbimport'')', 'title', 'Import NWB data -- pop_nwbimport()');
    if isempty(res), return; end

    options = {};
    if ~isempty(condValues)
        options = [ options { 'typefield' condValues{res.typefield}  } ];
    end
    if res.spikes
        options = [ options { 'importspikes' fastif(res.spikes, 'on', 'off')  } ];
    end
else
    options = varargin;
end

opt = finputcheck(options, { 'typefield' 'string' '' defaulttypefield; 
                             'importspikes' 'string' { 'on' 'off' } 'off'; ...
                             'ElectricalSeries' 'string' '' ''});
if ischar(opt)
    error(opt);
end

EEG = eeg_emptyset;

% Scan fields to find data
keys = data.acquisition.keys;
values = data.acquisition.values;
indVal = [];
if ~isempty(opt.ElectricalSeries)
    indVal = strmatch( opt.ElectricalSeries, keys, 'exact');
else
    for iVal = 1:length(values)
        if isa(data.acquisition.values{iVal}, 'types.core.ElectricalSeries')
            fprintf('Found available ElectricalSeries: "%s"\n', keys{iVal});
            if isempty(indVal)
                indVal = iVal;
                fprintf('Selecting the ElectricalSeries "%s"\n', keys{iVal});
            else
                eeglab_warning([ 'More than one ElectricalSeries found in the file.' 10 'Using the first one. Use command line parameters to select another one.'])
            end
        end
    end
end
if isempty(indVal)
    error('No usable data (ElectricalSeries) found in file.')
end
EEG.data = values{indVal}.data.load;
if isequal(values{indVal}.data_unit, 'volts')
    disp('Converting data from volts to microvolts')
    EEG.data = EEG.data/1e6;
else
    fprintf(2, 'Warning: unknow data unit');
end

% electrodes
chans = data.general_extracellular_ephys_electrodes.toTable();
chanlabels = cell(1,size(EEG.data,1));
if ismember('label', chans.Properties.VariableNames), chanlabels = chans.label; end
if ~isempty(chanlabels{1})
    options = { 'labels', chanlabels };
    if ismember('group_name', chans.Properties.VariableNames) && ~isempty(chans.group_name), options = [ options { 'type', chans.group_name } ]; end
    if ismember('x', chans.Properties.VariableNames) && ~isempty(chans.x)                  , options = [ options { 'X', mattocell(chans.x) } ]; end
    if ismember('y', chans.Properties.VariableNames) && ~isempty(chans.y)                  , options = [ options { 'Y', mattocell(chans.y) } ]; end
    if ismember('z', chans.Properties.VariableNames) && ~isempty(chans.z)                  , options = [ options { 'Z', mattocell(chans.z) } ]; end
    EEG.chanlocs = struct(options{:});
    if isfield(EEG.chanlocs, 'X');
        EEG = eeg_checkchanlocs(EEG);
    end
end
EEG.nbchan = size(EEG.data,2);

% sampling rate
if ~isempty(values{indVal}.starting_time_rate)
    EEG.srate = values{indVal}.starting_time_rate;
else
    eeglab_warning([ 'Sampling rate not found, using the ''timestamps'' information;' 10 ...
        'computing approximate sampling rate (data will not be interpolated)' ])
    timestamps = values{indVal}.timestamps.load;
    EEG.srate = 1/mean(diff(timestamps));
end

% save NWB structure
EEG.etc.nwb = data;

% import events
if ~isempty(data.intervals_trials.start_time)
    event_lat  = EEG.srate * (data.intervals_trials.start_time.data.load) + 1;
    event_stop = EEG.srate * (data.intervals_trials.stop_time.data.load) + 1;
    event_dur  = event_stop - event_lat;

    condValues = data.intervals_trials.vectordata.keys;
    if ~isempty(condValues)
        if isempty(opt.typefield), opt.typefield = condValues{1}; end
    end
    % this section needs optimization to load all values at once
    % see channel import above where arrays are created
    for iEvent = 1:length(event_lat)
        for iVal = 1:length(condValues)
            tmpVal = get(data.intervals_trials.vectordata, condValues{iVal}).data(iEvent);
            if iscell(tmpVal)
                EEG.event(iEvent).(condValues{iVal}) = tmpVal{1};
            elseif ~isnan(tmpVal)
                EEG.event(iEvent).(condValues{iVal}) = tmpVal;
            end
            % set type
            if strcmpi(condValues{iVal}, opt.typefield)
                EEG.event(iEvent).type = EEG.event(iEvent).(condValues{iVal});
            end
        end
        EEG.event(iEvent).latency  = event_lat(iEvent);
        if event_dur(iEvent) ~= 0
            EEG.event(iEvent).duration = event_dur(iEvent);
        end
    end
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
end
EEG = eeg_checkset(EEG, 'eventconsistency');
EEG = eeg_checkset(EEG);

% history
if isempty(options)
    com = sprintf('EEG = pop_nwbimport(''%s'');', fileName);
else
    com = sprintf('EEG = pop_nwbimport(''%s'', %s);', fileName, vararg2str(options));
end

function eeglab_warning(msg)

if nargin < 1
    error('eeglab_warning needs at least one argument');
end

res = warning('backtrace');
warning('backtrace', 'off');
warning(msg)
warning('backtrace', res.state);
