function value = getStructField(s, fieldName, defaultValue)
    if isfield(s, fieldName) && ~isempty(s.(fieldName))
        value = s.(fieldName);
    else
        value = defaultValue;
    end
end


