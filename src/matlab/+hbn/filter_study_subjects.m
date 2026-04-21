function [STUDY, ALLEEG] = filter_study_subjects(STUDY, ALLEEG, keepIds)
%FILTER_STUDY_SUBJECTS Keep only datasets whose subject is in keepIds.
%   Uses std_rmdat to prune the STUDY to the requested subject set. Works
%   on both the STUDY struct and the ALLEEG array in sync.
    arguments
        STUDY struct
        ALLEEG struct
        keepIds (1,:) string
    end
    keep = cellstr(keepIds);
    [STUDY, ALLEEG] = std_rmdat(STUDY, ALLEEG, ...
        'keepvarvalues', {'subject', keep});
end
