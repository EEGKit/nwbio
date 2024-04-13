# NWB-io EEGLAB plugin

This plugin imports data from the Neuroscience Without Borders
data format. Time series, as well as channel information and 
event information are imported. Use EEGLAB import/export menu to
import/export files, or use command line function pop_nwbimport.m
or pop_nwbexport.m

# Example

Export the tutorial EEGLAB data

```matlab
pop_nwbexport(EEG, 'test.nwb');
```

Import the file exported above

```matlab
EEG = pop_nwbimport('test.nwb');
```

# Version history

1.0 - import, and export, tested on multiple files
