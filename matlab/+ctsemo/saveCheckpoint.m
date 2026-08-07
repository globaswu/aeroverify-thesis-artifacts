function checkpointPath = saveCheckpoint( ...
        result, outputDirectory, status, errorInformation)
%SAVECHECKPOINT Atomically save the current cTSEMO run state.
%   PATH = ctsemo.saveCheckpoint(RESULT,DIR,STATUS) writes checkpoint.mat.
%   ERRORINFORMATION is stored when an objective or constraint evaluation
%   fails. Checkpoints are mutable; per-iteration diagnostic records are
%   written separately by ctsemo.run.

    arguments
        result (1,1) struct
        outputDirectory (1,1) string
        status (1,1) string
        errorInformation (1,1) struct = struct()
    end

    if strlength(outputDirectory) == 0
        checkpointPath = "";
        return
    end
    if ~isfolder(outputDirectory)
        mkdir(outputDirectory);
    end

    checkpoint = struct();
    checkpoint.status = status;
    checkpoint.savedAt = string(datetime("now", ...
        "Format", "yyyy-MM-dd'T'HH:mm:ss.SSSXXX"));
    checkpoint.result = result;
    checkpoint.error = errorInformation;

    temporaryPath = string(tempname(outputDirectory)) + ".mat";
    cleanup = onCleanup(@() removeTemporaryFile(temporaryPath));
    save(temporaryPath, "checkpoint", "-v7");
    checkpointPath = fullfile(outputDirectory, "checkpoint.mat");
    [moved, message] = movefile(temporaryPath, checkpointPath, "f");
    if ~moved
        error("cTSEMO:Logging:CheckpointMoveFailed", ...
            "Could not finalize checkpoint '%s': %s", ...
            checkpointPath, message);
    end
end

function removeTemporaryFile(path)
    if isfile(path)
        delete(path);
    end
end
