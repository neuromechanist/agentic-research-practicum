function csvPath = write_qa_channels_csv(outDir, row)
%WRITE_QA_CHANNELS_CSV Append a QA row to the per-phase CSV log.
%   csvPath = hbn.write_qa_channels_csv(outDir, row) appends one row to
%   <outDir>/qa_channels.csv. If the file does not exist, the header is
%   written first. `row` is a struct with fields matching the header:
%     participant_id, n_channels_before, n_channels_after,
%     rejected_channels, srate, cleanline_status, duration_s.
    arguments
        outDir (1,1) string
        row struct
    end
    if ~isfolder(outDir); mkdir(outDir); end
    csvPath = fullfile(outDir, "qa_channels.csv");

    header = ["participant_id","n_channels_before","n_channels_after", ...
        "rejected_channels","srate","cleanline_status","duration_s"];
    needsHeader = ~isfile(csvPath);

    fid = fopen(csvPath, "a");
    if fid < 0
        error("hbn:write_qa_channels_csv:open_failed", "could not open %s", csvPath);
    end
    cleanup = onCleanup(@() fclose(fid));

    if needsHeader
        fprintf(fid, "%s\n", strjoin(header, ","));
    end
    rejected = "";
    if isfield(row, 'rejected_channels') && ~isempty(row.rejected_channels)
        rejected = strjoin(string(row.rejected_channels), ";");
    end
    fprintf(fid, "%s,%d,%d,%s,%d,%s,%.3f\n", ...
        string(row.participant_id), ...
        row.n_channels_before, ...
        row.n_channels_after, ...
        rejected, ...
        row.srate, ...
        string(row.cleanline_status), ...
        row.duration_s);
end
