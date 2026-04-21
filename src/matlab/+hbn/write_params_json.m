function jsonPath = write_params_json(outDir, opts, extra)
%WRITE_PARAMS_JSON Dump phase options plus environment metadata to JSON.
%   jsonPath = hbn.write_params_json(outDir, opts) writes
%   <outDir>/params.json with all fields from `opts` plus MATLAB version,
%   EEGLAB version, git SHA (if resolvable), and an ISO timestamp.
%
%   jsonPath = hbn.write_params_json(outDir, opts, extra) merges `extra`
%   (a struct of scalars / strings) into the output.
    arguments
        outDir (1,1) string
        opts struct
        extra struct = struct()
    end
    if ~isfolder(outDir); mkdir(outDir); end
    jsonPath = fullfile(outDir, "params.json");

    payload = opts;
    fn = fieldnames(extra);
    for k = 1:numel(fn)
        payload.(fn{k}) = extra.(fn{k});
    end
    payload.matlab_version = version;
    try
        payload.eeglab_version = eeg_getversion;
    catch
        payload.eeglab_version = "unknown";
    end
    try
        [st, sha] = system('git rev-parse HEAD');
        if st == 0
            payload.git_sha = strtrim(sha);
        else
            payload.git_sha = "unknown";
        end
    catch
        payload.git_sha = "unknown";
    end
    payload.timestamp_iso = string(datetime('now','TimeZone','UTC','Format',"yyyy-MM-dd'T'HH:mm:ss'Z'"));

    fid = fopen(jsonPath, "w");
    if fid < 0
        error("hbn:write_params_json:open_failed", "could not open %s", jsonPath);
    end
    cleanup = onCleanup(@() fclose(fid));
    fwrite(fid, jsonencode(payload, "PrettyPrint", true));
end
