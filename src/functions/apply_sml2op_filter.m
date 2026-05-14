function data = apply_sml2op_filter(data, suffixes, seaMask)

    % All HydroGNSS channel suffixes (used for incidence-mask cascade
    % protection). Distinct from `suffixes`, which selects which channels
    % get the per-channel SNR/reflectivity threshold filter.
    channelSuffixes = ["_1_L", "_1_R", "_5_L", "_5_R"];

    % Coordinates must survive every filter so downstream gridding can use
    % them as the validity mask (mirrors SML2OP's ProtectedProperties).
    protectedFields = ["specularPointLat", "specularPointLon"];

    % ------------------------------------------------------------
    % 1. Find reference size for the masks
    % ------------------------------------------------------------
    refField = "";

    if isfield(data, 'incidenceAngleDeg')
        refField = "incidenceAngleDeg";
    else
        fields = fieldnames(data);
        for i = 1:numel(fields)
            if isnumeric(data.(fields{i}))
                refField = string(fields{i});
                break
            end
        end
    end

    if refField == ""
        warning('No numeric field found. No filtering applied.');
        return
    end

    refSize = size(data.(refField));

    % ------------------------------------------------------------
    % 2. Incidence-angle mask (NOT cascaded to channel fields,
    %    matching SML2OP Filter.apply which does not propagate
    %    track-level failures into channel measurements)
    % ------------------------------------------------------------
    incidenceMask = false(refSize);
    if isfield(data, 'incidenceAngleDeg')
        incidenceMask = data.incidenceAngleDeg > 45;
    end

    % ------------------------------------------------------------
    % 3. Ocean mask (cascaded through every non-protected field,
    %    matching SML2OP OceanFilter which walks into channels)
    % ------------------------------------------------------------
    oceanMask = false(refSize);
    if isfield(data, 'specularPointLat') && isfield(data, 'specularPointLon')

        validLL = ~(isnan(data.specularPointLat) | isnan(data.specularPointLon));

        if any(validLL)

            [idxCols, idxRows] = easeconv_grid3( ...
                data.specularPointLat(validLL), ...
                data.specularPointLon(validLL), ...
                25);

            linearIdx = sub2ind([1388, 584], idxCols, idxRows);

            isOceanValid = isnan(seaMask(linearIdx));

            validIdx = find(validLL);

            oceanIdx = validIdx(isOceanValid);

            oceanMask(oceanIdx) = true;

        end
    end

    % ------------------------------------------------------------
    % 4. Per-(channel, polarization) SNR & reflectivity filters
    %    Each violation NaNs ONLY fields whose name ends with this suffix.
    % ------------------------------------------------------------
    fields = fieldnames(data);

    for s = 1:numel(suffixes)

        suf = suffixes(s);

        snrField  = "SNR" + suf;
        reflField = "reflectivityLinear" + suf;

        chanMask = false(refSize);

        % ---- SNR filter (data is still in dB at this point) ----
        if isfield(data, snrField)
            chanMask = chanMask | (data.(snrField) < 0.5);
        end

        % ---- Reflectivity filter (input is linear; threshold is dB) ----
        if isfield(data, reflField)
            refl_dB = 10 * log10(data.(reflField));
            chanMask = chanMask | (refl_dB < -45);
        end

        if ~any(chanMask)
            continue;
        end

        % NaN only fields whose name ends with this suffix
        for i = 1:numel(fields)
            fn = fields{i};
            if endsWith(fn, suf) ...
               && isnumeric(data.(fn)) ...
               && isequal(size(data.(fn)), refSize)
                data.(fn)(chanMask) = NaN;
            end
        end

    end

    % ------------------------------------------------------------
    % 5a. Apply incidence mask to non-channel, non-protected fields only
    % ------------------------------------------------------------
    for i = 1:numel(fields)

        fn = fields{i};

        if any(strcmp(fn, protectedFields));   continue; end
        if endsWith(fn, channelSuffixes);      continue; end
        if ~isnumeric(data.(fn));              continue; end
        if ~isequal(size(data.(fn)), refSize); continue; end

        data.(fn)(incidenceMask) = NaN;

    end

    % ------------------------------------------------------------
    % 5b. Apply ocean mask to every non-protected numeric field
    %     (cascades through channel measurements at SPs over water)
    % ------------------------------------------------------------
    for i = 1:numel(fields)

        fn = fields{i};

        if any(strcmp(fn, protectedFields));   continue; end
        if ~isnumeric(data.(fn));              continue; end
        if ~isequal(size(data.(fn)), refSize); continue; end

        data.(fn)(oceanMask) = NaN;

    end

end
