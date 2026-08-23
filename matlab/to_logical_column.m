function values = to_logical_column(values)
%TO_LOGICAL_COLUMN Convert logical, numeric, or text table values safely.

if islogical(values)
    return
end
if isnumeric(values)
    assert(all(ismember(values, [0, 1])), ...
        "Numeric logical columns must contain only zero and one.");
    values = logical(values);
    return
end

textValues = lower(strtrim(string(values)));
valid = ismember(textValues, ["true", "false", "1", "0"]);
assert(all(valid), "Text logical columns contain an unsupported value.");
values = textValues == "true" | textValues == "1";
end
