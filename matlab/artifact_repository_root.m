function root = artifact_repository_root()
%ARTIFACT_REPOSITORY_ROOT Return the package root without machine paths.
root = fileparts(fileparts(mfilename("fullpath")));
end

