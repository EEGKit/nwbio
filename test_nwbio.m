% test with the tutorial EEGLAB dataset
eeglab cont
pop_nwbexport(EEG, 'test.nwb', 'exportlocs', 'on');
EEG2 = pop_nwbimport('test.nwb');

pop_nwbexport(EEG2, 'test2.nwb', 'exportlocs', 'on');
EEG3 = pop_nwbimport('test2.nwb');

disp(' ')
disp('Comparing export with original dataset')
disp('**************************************')
eeg_compare(EEG, EEG2);

disp(' ')
disp('Comparing re-export with original dataset')
disp('*****************************************')
eeg_compare(EEG2, EEG3);

return

% try with iEEG file
EEG = pop_nwbimport('~/data/data/nwb000576/sub-01/sub-01_ses-20140828T132700_ecephys+image.nwb');
pop_nwbexport(EEG, 'test.nwb', 'exportlocs', 'on');
EEG2 = pop_nwbimport('test.nwb');

pop_nwbexport(EEG2, 'test2.nwb', 'exportlocs', 'on');
EEG3 = pop_nwbimport('test2.nwb');

disp(' ')
disp('Comparing export with original dataset')
disp('**************************************')
eeg_compare(EEG, EEG2);

disp(' ')
disp('Comparing re-export with original dataset')
disp('*****************************************')
eeg_compare(EEG2, EEG3);


