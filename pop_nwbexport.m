% POP_NWBEXPORT - export EEGLAB EEG structure as NWB file.
%
% Usage:
%   >> pop_nwbexport(EEG); % pop up window to input file name
%   >> pop_nwbexport(EEG, filename, 'key', val); 
%
% Input:
%   EEG - EEGLAB structure
%
% Optional inputs:
%   filename  - [string] dataset filename. Default pops up a graphical
%               interface to browse for a data file.
% 
% Optional general information (see NWB documentation):
%   'session_description'  - [string] default is "Exported from EEGLAB"
%   'identifier'           - [string] default to empty
%   'session_start_time'   - [string] (dd-mmm-yyyy HH:MM:SS) default empty
%   'timestamps_reference_time' - [string] (dd-mmm-yyyy HH:MM:SS) default empty
%   'general_experimenter' - [string] default to empty
%   'general_session_id'   - [string] default to EEG.session
%   'general_institution'  - [string] default to empty
%   'general_related_publications' - [string] default to empty
%
% Optional subject information (see NWB documentation):
%   'subject_id'  - [string] default to EEG.subject when set
%   'age'         - [string] default to EEG.age when set
%   'subjectdescription' - [string] default to empty
%   'species'     - [string]  default to empty
%   'sex'         - [string]  default to EEG.gender when set
%
% Optional device information (see NWB documentation):
%   'manufacturer'            - [string] default to empty
%   'manufacturerdescription' - [string] default to empty
%   'electrodelocations'      - [string] default to empty
%
% EEGLAB specific options:
%   'eventfields' - [cell] list of event fields to export. Default to all
%                   event fields execpt 'urevent'. 'latency' and 'duration'
%                   are not included, but they are automatically exported
%                   to NWB. If you do not want to export event, remove them
%                   before calling this function (EEG.event = []).
%   'exportlocs'  - ['on'|'off'] export (x,y,z) location of channels. Note
%                   that this is not recommended if you use template channel
%                   locations. Default is 'off'.
%
% Author: Arnaud Delorme, UCSD, 2024
%
% See also: POP_NWBIMPORT, EEGLAB

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

function com = pop_nwbexport(EEG, fileName, varargin)

if nargin < 1
    help pop_nwbexport;
    return;
end

com = '';

% file to save
if nargin < 2
	[filename, filepath] = uiputfile('*.*', 'Enter a NWB file -- pop_nwbexport()');
    if isequal(filename, 0)
        return;
    end
    fileName = fullfile(filepath, filename);
end
[tmp1,tmp2,ext] = fileparts(fileName);
if ~isequal('.nwb', lower(ext))
    fprintf('Changing extension of input file to ".nwb"\n');
    fileName = fullfile(tmp1, [ tmp2 '.nwb' ]);
end
if exist(fileName, 'file')
    fprintf('File exist, deleting it...\n')
    delete(fileName);
end

subject = EEG.subject;
if isempty(subject)
    subject = 'subject1';
end
if ~isempty(EEG.session)
    subject = [ subject '_session-' num2str(EEG.session) ];
end
if ~isempty(EEG.run)
    subject = [ subject '_run-' num2str(EEG.run) ];
end

% parameters
if isfield(EEG, 'age'), age = EEG.age; else age = ''; end
if isfield(EEG, 'gender'), sex = EEG.gender; else sex = ''; end
colnames = {};
if ~isempty(EEG.event)
    colnames = fieldnames(EEG.event);
    colnames = setdiff(colnames, { 'urevent', 'latency', 'duration' });
end
if nargin < 2
    promptstr    = { ...
        { 'style'  'text'       'string' 'General information' 'fontweight' 'bold' } ...
        { 'style'  'text'       'string' 'Session description' } ...
        { 'style'  'edit'       'string' 'Exported from EEGLAB'  'tag' 'session_description' } ...
        { 'style'  'text'       'string' 'Data identifier' } ...
        { 'style'  'edit'       'string' subject 'tag' 'identifier' } ...
        { 'style'  'text'       'string' 'Session start time (dd-mmm-yyyy HH:MM:SS)' } ...
        { 'style'  'edit'       'string' '' 'tag' 'session_start_time' } ...
        { 'style'  'text'       'string' 'Experimenter' } ...
        { 'style'  'edit'       'string' '' 'tag' 'general_experimenter'} ...
        { 'style'  'text'       'string' 'Session ID' } ...
        { 'style'  'edit'       'string' '' 'tag' 'general_session_id' } ...
        { 'style'  'text'       'string' 'Institution' } ...
        { 'style'  'edit'       'string' '' 'tag' 'general_institution' } ...
        { 'style'  'text'       'string' 'Related publications' } ...
        { 'style'  'edit'       'string' '' 'tag' 'general_related_publications' } ...
        {} ...
        ...
        { 'style'  'text'       'string' 'Subject information' 'fontweight' 'bold' } ...
        { 'style'  'text'       'string' 'Subject ID' } ...
        { 'style'  'edit'       'string' char(EEG.subject)  'tag' 'subject_id' } ...
        { 'style'  'text'       'string' 'Age' } ...
        { 'style'  'edit'       'string' age  'tag' 'age' } ...
        { 'style'  'text'       'string' 'Description' } ...
        { 'style'  'edit'       'string' ''  'tag' 'subjectdescription' } ...
        { 'style'  'text'       'string' 'Species' } ...
        { 'style'  'edit'       'string' ''  'tag' 'species' } ...
        { 'style'  'text'       'string' 'Sex' } ...
        { 'style'  'edit'       'string' sex  'tag' 'sex' } ...
        {} ...
        ...
        { 'style'  'text'       'string' 'Other information' 'fontweight' 'bold' } ...
        { 'style'  'text'       'string' 'EEG device' } ...
        { 'style'  'edit'       'string' ''  'tag' 'manufacturer' } ...
        { 'style'  'text'       'string' 'EEG device description' } ...
        { 'style'  'edit'       'string' ''  'tag' 'manufacturerdescription' } ...
        { 'style'  'text'       'string' 'Electrode locations' } ...
        { 'style'  'edit'       'string' ''  'tag' 'electrodelocations' } ...
        { 'style'  'text'       'string' ['Event fields to export' 10 '(latency and duration always exported)' ] } ...
        { 'style'  'listbox'    'string' colnames  'tag' 'eventfields' 'max', 2, 'value' [1:length(colnames)]} ...
        { 'style'  'checkbox'   'string' 'Export channel (x,y,z) locations' 'tag' 'exportlocs'} ...
        };

    geo = [2 1];
    geometry = {1 geo   geo   geo   geo   geo   geo   geo   1 ...
                1 geo   geo   geo   geo   geo   1 ...
                1 geo   geo   geo   geo   1 };
    geomvert = [1 1     1     1     1     1     1     1     1 ...
                1 1     1     1     1     1     1 ... 
                1 1     1     1     1.8   1 ];
    
    [~,~,~,res] = inputgui( 'geometry', geometry, 'geomvert', geomvert, 'uilist', promptstr, 'helpcom', 'pophelp(''pop_nwbimport'')', 'title', 'Import NWB data -- pop_nwbimport()');
    if isempty(res), return; end    
    if ~isempty(res.eventfields)
        res.eventfields = colnames(res.eventfields);
    end
    res.exportlocs = fastif(res.exportlocs, 'on', 'off');
    options = res;
else
    options = varargin;
end

opt = finputcheck(options, {
    'session_description' 'string' '' 'Exported from EEGLAB';
    'identifier' 'string' '' subject;
    'session_start_time' 'string' '' '';
    'timestamps_reference_time' 'string' '' '';
    'general_experimenter' 'string' '' '';
    'general_session_id' 'string' '' num2str(EEG.session);
    'general_institution' 'string' '' '';
    'general_related_publications' 'string' '' '';
    'subject_id' 'string' '' char(EEG.subject);
    'age' 'string' '' '';
    'subjectdescription' 'string' '' '';
    'species' 'string' '' '';
    'sex' 'string' '' '';
    'manufacturer' 'string' '' '';
    'manufacturerdescription' 'string' '' '';
    'electrodelocations' 'string' '' '';
    'eventfields' 'cell' {} colnames; ...
    'exportlocs'  'string' { 'on' 'off' } 'off' });
if ischar(opt), error(opt); end

if ~isempty(opt.session_start_time)
    opt.session_start_time = datetime(datenum(opt.session_start_time, 'dd-mmm-yyyy HH:MM:SS'));
end
if ~isempty(opt.timestamps_reference_time)
    opt.timestamps_reference_time = datetime(datenum(opt.timestamps_reference_time, 'dd-mmm-yyyy HH:MM:SS'));
end

nwb = NwbFile( ...
    'session_description', opt.session_description,...
    'identifier',          opt.identifier, ...
    'session_start_time',  opt.session_start_time, ...
    'timestamps_reference_time', opt.timestamps_reference_time, ...
    'general_experimenter', opt.general_experimenter, ...
    'general_session_id',   opt.general_session_id, ...
    'general_institution',  opt.general_institution, ...
    'general_related_publications', opt.general_related_publications);

% export subject information
options = { 'subject_id',   opt.subject_id, ...
            'species',      opt.species, ...
            'description',  opt.subjectdescription, ...
            'age',          opt.age, ...
            'sex',          opt.sex};
nwb.general_subject = types.core.Subject(options{:});

% export event information
if ~isempty(EEG.event)
    colnames = opt.eventfields;
    colnames = [ {'start_time', 'stop_time' }'; colnames ];
    options = { 'colnames', colnames, 'description', 'Events exported from EEGLAB', ...
        'id', types.hdmf_common.ElementIdentifiers('data', 0:length(EEG.event)-1) };
    
    if isfield(EEG.event, 'duration')
        duration   = { EEG.event.duration };
        duration(cellfun(@isempty, duration)) = { 0 };
        duration = [ duration{:} ];
    else
        duration = zeros(1, length(EEG.event));
    end
    start_time = types.hdmf_common.VectorData( 'data', ([EEG.event.latency]-1)/EEG.srate, 'description','start time of trial in seconds');
    stop_time  = types.hdmf_common.VectorData( 'data', ([EEG.event.latency]-1 + duration)/EEG.srate, 'description','end time of trial in seconds');
    options = [ options { 'start_time', start_time, 'stop_time', stop_time }];

    % custom columns
    for iCol = 3:length(colnames)
        values = { EEG.event.(colnames{iCol}) };
        if ~ischar(EEG.event(1).(colnames{iCol}))
            values(cellfun(@isempty, values)) = { NaN };
            values = [ values{:} ];
        end
        options = [ options { colnames{iCol}, types.hdmf_common.VectorData( 'data', values, 'description', colnames{iCol}) } ];
    end

    trials = types.core.TimeIntervals(options{:});
    nwb.intervals_trials = trials;
end

% export channel information
% there is an option to use shanks, should this be used to export channel types? 
% probably not, channel types should be in different time series
chanlocs = struct([]);
if ~isempty(EEG.chanlocs)
    chanlocs = EEG.chanlocs;
else
    % create labels
    for iChan = 1:EEG.nbchan
        chanlocs(iChan).labels = sprintf('E%d', iChan);
    end
end

if strcmpi(opt.exportlocs, 'on')
    colnames = {'location', 'group', 'group_name', 'label', 'x', 'y', 'z'};
else
    colnames = {'location', 'group', 'group_name', 'label'};
end
ElectrodesDynamicTable = types.hdmf_common.DynamicTable(...
    'colnames', colnames, 'description', 'all electrodes');

Device = types.core.Device(...
    'description', opt.manufacturerdescription, ...
    'manufacturer', opt.manufacturer);

nwb.general_devices.set('array', Device);
shankGroupName = 'all_electrodes';
EGroup = types.core.ElectrodeGroup( ...
    'description', 'all electrodes', ...
    'location', opt.electrodelocations, ...
    'device', types.untyped.SoftLink(Device) ...
    );

nwb.general_extracellular_ephys.set(shankGroupName, EGroup);
for iChan = 1:length(chanlocs)
    options = {};
    if strcmpi(opt.exportlocs, 'on')
        options = { 'x' chanlocs(iChan).X 'y' chanlocs(iChan).Y 'z' chanlocs(iChan).Z };
    end
    ElectrodesDynamicTable.addRow( ...
        'location', chanlocs(iChan).labels, ...
        'group', types.untyped.ObjectView(EGroup), ...
        'group_name', char(chanlocs(iChan).type), ...
        'label', chanlocs(iChan).labels, options{:});
end
nwb.general_extracellular_ephys_electrodes = ElectrodesDynamicTable;
%ElectrodesDynamicTable.toTable()

% create electrode table
electrode_table_region = types.hdmf_common.DynamicTableRegion( ...
    'table', types.untyped.ObjectView(ElectrodesDynamicTable), ...
    'description', 'all electrodes', ...
    'data', (0:length(ElectrodesDynamicTable.id.data)-1)');

% export data
electrical_series = types.core.ElectricalSeries( ...
    'starting_time', 0.0, ... % seconds
    'starting_time_rate', EEG.srate, ... % Hz
    'data', EEG.data*1e6, ...
    'electrodes', electrode_table_region, ...
    'data_unit', 'volts');
nwb.acquisition.set('ElectricalSeries', electrical_series);
nwbExport(nwb, fileName);

% history
com = sprintf('EEG = pop_nwbexport(''%s'');', fileName);
