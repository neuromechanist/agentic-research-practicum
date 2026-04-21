function subjects = list_eligible_subjects(bidsRoot, task)
%LIST_ELIGIBLE_SUBJECTS Return subject IDs with `task == "available"` in participants.tsv.
%   subjects = hbn.list_eligible_subjects(bidsRoot, task) reads
%   <bidsRoot>/participants.tsv and returns a string array of
%   participant_id values whose entry in the task column equals
%   "available". "caution" and "unavailable" rows are excluded.
    arguments
        bidsRoot (1,1) string
        task (1,1) string
    end
    tsv = fullfile(bidsRoot, "participants.tsv");
    if ~isfile(tsv)
        error("hbn:list_eligible_subjects:missing_tsv", ...
            "participants.tsv not found at %s", tsv);
    end
    t = readtable(tsv, "FileType","text", "Delimiter","\t", ...
        "TextType","string", "VariableNamingRule","preserve");
    if ~ismember(task, string(t.Properties.VariableNames))
        error("hbn:list_eligible_subjects:missing_task_col", ...
            "task column '%s' missing in participants.tsv", task);
    end
    mask = t.(task) == "available";
    subjects = string(t.participant_id(mask));
end
