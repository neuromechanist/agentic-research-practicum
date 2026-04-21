function [STUDY, ALLEEG] = filter_study_subjects(STUDY, ALLEEG, keepIds)
%FILTER_STUDY_SUBJECTS Keep only datasets whose subject is in keepIds.
%   Uses std_rmdat rather than hand-trimming ALLEEG because std_rmdat
%   updates STUDY.datasetinfo and STUDY.subject in lockstep with the
%   ALLEEG array; a naive loop would leave STUDY pointing at dropped
%   indices and break every downstream std_* call.
    arguments
        STUDY struct
        ALLEEG struct
        keepIds (1,:) string
    end
    keep = cellstr(keepIds);
    [STUDY, ALLEEG] = std_rmdat(STUDY, ALLEEG, ...
        'keepvarvalues', {'subject', keep});
end
