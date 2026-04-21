function [STUDY, ALLEEG] = import_bids_study(bidsRoot, task, outDir)
%IMPORT_BIDS_STUDY Wrap bids-matlab-tools pop_importbids for a single task.
%   [STUDY, ALLEEG] = hbn.import_bids_study(bidsRoot, task, outDir) imports
%   every subject's `task` run into an EEGLAB STUDY. bidsevent=on so the
%   BIDS events.tsv drives EEG.event; bidschanloc=off because the local
%   dataset has no electrodes.tsv (channel locations attach in Phase 2
%   via pop_dipfit_settings).
%
%   Errors with hbn:import_bids_study:empty if pop_importbids returns no
%   datasets, which would otherwise propagate as a cryptic failure inside
%   downstream std_rmdat / EEG loops.
    arguments
        bidsRoot (1,1) string
        task (1,1) string
        outDir (1,1) string
    end
    if ~isfolder(outDir); mkdir(outDir); end
    [STUDY, ALLEEG] = pop_importbids(char(bidsRoot), ...
        'eventtype','value', ...
        'bidsevent','on', ...
        'bidschanloc','off', ...
        'outputdir',char(outDir), ...
        'bidstask',{char(task)}, ...
        'studyName',char(task));
    if isempty(ALLEEG)
        error("hbn:import_bids_study:empty", ...
            "pop_importbids returned no datasets (bidsRoot=%s task=%s)", ...
            bidsRoot, task);
    end
end
