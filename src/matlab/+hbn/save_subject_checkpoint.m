function setPath = save_subject_checkpoint(EEG, outDir, task)
%SAVE_SUBJECT_CHECKPOINT Save EEG to the Phase 1 BIDS-derivative location.
%   setPath = hbn.save_subject_checkpoint(EEG, outDir, task) writes the EEG
%   set to <outDir>/<subject>/eeg/<subject>_task-<task>_desc-clean_eeg.set.
%   Creates parent directories as needed.
    arguments
        EEG struct
        outDir (1,1) string
        task (1,1) string
    end
    subjId = string(EEG.subject);
    if subjId == ""
        subjId = string(EEG.setname);
    end
    eegDir = fullfile(outDir, subjId, "eeg");
    if ~isfolder(eegDir); mkdir(eegDir); end
    setName = sprintf("%s_task-%s_desc-clean_eeg.set", subjId, task);
    pop_saveset(EEG, 'filename', char(setName), 'filepath', char(eegDir));
    setPath = fullfile(eegDir, setName);
end
