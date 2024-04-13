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

