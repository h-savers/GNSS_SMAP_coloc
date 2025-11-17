function out = computeLogical_mode(x)
% computeLogical_mode - Returns the most frequent logical value (0 or 1)
% If tie or empty input, returns NaN (as single or double, depending on x)

    if isempty(x)
        out = NaN; 
        return
    end

    % Ensure input is logical or numeric 0/1
    x = logical(x);

    % Compute mode (most frequent value)
    out = mode(x);

    % Handle tie (equal number of 0 and 1)
    if sum(x) == numel(x)/2
        out = NaN;
    end

    % Return as single if input is single
    if isa(x, 'single')
        out = single(out);
    else
        out = double(out);
    end
end
