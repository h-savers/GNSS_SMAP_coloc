function data = apply_general_filter(data, suffixes, seaMask)
% APPLY_GENERAL_FILTER  Pre-gridding filters on the flat HydroGNSS struct,
% ported from SML2OP's L1B Filter / OceanFilter pipeline.
%
% Mirrors SML2OP/src/logic/processors/Processor.m::filter: each enabled
% threshold is applied as a NaN-on-match filter and cascades across the
% sibling numeric fields at the same hierarchy level. Records are NaN'd
% in place rather than removed so the specular-point coordinates remain
% usable as a validity mask downstream (same reason SML2OP's Filter.m /
% OceanFilter.m keep ProtectedProperties intact). A NaN threshold
% disables a filter, matching Processor.applyFilter.
%
% Hierarchy mapping for the flat struct:
%   - Measurement-level: fields ending in a channel suffix
%     (SNR_1_L, reflectivityLinear_5_R, ...). A measurement filter
%     cascades only across fields sharing that suffix, matching the
%     Filter.filter loop over one measurement's properties.
%   - Track-level: numeric fields without a channel suffix
%     (incidenceAngleDeg, dayOfYear, ...). A track-level filter only
%     cascades across other non-suffix fields, matching SML2OP's
%     Filter.apply, which stops descending once it has filtered at
%     track level.
%   - Ocean filter: cascades across every non-protected numeric field
%     (track and channels), matching OceanFilter.apply which walks
%     track -> channels -> Coherent/Incoherent.
%
% Inputs:
%   data       Flat struct of column vectors (timeUTC may be datetime).
%   suffixes   Channel suffixes the SNR/Refl filters run on
%              (e.g. ["_1_L","_5_L"]). Each suffix uses the same
%              threshold, matching SML2OP applying one ThrSNR/ThrRefl
%              uniformly to every channel.
%   seaMask    25-km EASE-Grid 2.0 sea mask, NaN over water and finite
%              over land (SML2OP OceanFilter convention). Pass [] to
%              skip the ocean filter.
%   opts       (optional) struct overriding any SML2OP-style knob:
%                .ThrSNR             default 0.5  (< filter; input is dB)
%                .ThrRefl            default -45  (< filter; dB)
%                .ThrIncidenceAngle  default 45   (> filter; degrees)
%                .gridSize           default [1388 584]   (25-km grid)
%                .gridResolutionKm   default 25
%                .protectedFields    string array of field names that
%                                    must survive every filter
%              Set any threshold to NaN to disable that filter.
%
% See SML2OP/src/utils/Filter.m, SML2OP/src/utils/OceanFilter.m,
%     SML2OP/src/logic/processors/Processor.m for the reference impl.

    if nargin < 4 || isempty(opts), opts = struct(); end

    % Defaults preserve the historical collocation-pipeline behaviour.
    % SML2OP's Thr_Refl is also -45 dB; ThrSNR=0.5 reflects this pipeline
    % (SML2OP's default of 2 is for a differently-defined SNR variable).
    % Incidence is kept active at 45 deg even though SML2OP's shipped
    % config sets it NaN — the collocation pipeline has historically
    % applied this cap.
    opts = setdefault(opts, 'ThrSNR',            0.5);
    opts = setdefault(opts, 'ThrRefl',           -45);
    opts = setdefault(opts, 'ThrIncidenceAngle', 45);
    opts = setdefault(opts, 'gridSize',          [1388, 584]);
    opts = setdefault(opts, 'gridResolutionKm',  25);
    % Flat-struct analogues of SML2OP Filter.ProtectedProperties. Any
    % field listed here is NEVER NaN'd, so downstream easeconv_grid3 /
    % sub2ind on coordinate arrays still works.
    opts = setdefault(opts, 'protectedFields', [ ...
        "specularPointLat", "specularPointLon", ...   % SpecularPointLat/Lon
        "Onboardspeclat",   "Onboardspeclon",   ...   % onboard coord fallback
        "spAzimuthAngleDegOrbit",               ...   % == SML2OP SPAzimuthARF
        "qualityFlags", "qualityFlags_2"]);           % SML2OP QualityFlags

    % All HydroGNSS measurement-level suffixes. Track-level filters must
    % NOT cascade across these (matches SML2OP Filter.apply: a filter on
    % a track property only NaNs track-level properties).
    channelSuffixes = ["_1_L", "_1_R", "_5_L", "_5_R"];

    refSize = findReferenceSize(data);
    if isempty(refSize)
        warning('apply_general_filter:noNumericField', ...
                'No numeric field found. No filtering applied.');
        return
    end

    fields = string(fieldnames(data));

    % --- 1. SNR  (Processor.m line 48: DDMSNRAtPeakSingleDDM < ThrSNR)
    if ~isnan(opts.ThrSNR)
        for s = 1:numel(suffixes)
            snrField = "SNR" + suffixes(s);
            if ~isfield(data, snrField), continue; end
            mask = data.(snrField) < opts.ThrSNR;   % NaN < x is false
            data = nanFields(data, fields, mask, refSize, ...
                             opts.protectedFields, ...
                             @(fn) endsWith(fn, suffixes(s)));
        end
    end

    % --- 2. Reflectivity  (Processor.m line 49: ReflectionCoefficientAtSP < ThrRefl)
    %     Stored linear here; threshold is dB. The refl > 0 guard avoids
    %     log10 returning -Inf / complex for non-positive values, which
    %     SML2OP doesn't need to deal with because its variable is in dB.
    if ~isnan(opts.ThrRefl)
        for s = 1:numel(suffixes)
            reflField = "reflectivityLinear" + suffixes(s);
            if ~isfield(data, reflField), continue; end
            refl = data.(reflField);
            mask = false(size(refl));
            valid = refl > 0;
            mask(valid) = 10*log10(refl(valid)) < opts.ThrRefl;
            mask = mask | ~valid;       % non-positive refl is unusable
            data = nanFields(data, fields, mask, refSize, ...
                             opts.protectedFields, ...
                             @(fn) endsWith(fn, suffixes(s)));
        end
    end

    % --- 3. Incidence angle  (Processor.m line 51: SPIncidenceAngle > ThrSPIncidenceAngle)
    %     Track-level: cascades across non-suffix fields only.
    if ~isnan(opts.ThrIncidenceAngle) && isfield(data, 'incidenceAngleDeg')
        mask = data.incidenceAngleDeg > opts.ThrIncidenceAngle;
        data = nanFields(data, fields, mask, refSize, ...
                         opts.protectedFields, ...
                         @(fn) ~endsWith(fn, channelSuffixes));
    end

    % --- 4. Ocean  (OceanFilter.m, applied last so it cascades across
    %     both track-level and channel fields).
    if ~isempty(seaMask) ...
            && isfield(data, 'specularPointLat') ...
            && isfield(data, 'specularPointLon')

        validLL = ~(isnan(data.specularPointLat) | isnan(data.specularPointLon));

        if any(validLL)

            [idxCols, idxRows] = easeconv_grid3( ...
                data.specularPointLat(validLL), ...
                data.specularPointLon(validLL), ...
                opts.gridResolutionKm);

            linearIdx = sub2ind(opts.gridSize, idxCols, idxRows);

            % SML2OP convention: NaN cell == water, finite == land.
            isOcean = isnan(seaMask(linearIdx));

            validIdx  = find(validLL);
            oceanMask = false(refSize);
            oceanMask(validIdx(isOcean)) = true;

            data = nanFields(data, fields, oceanMask, refSize, ...
                             opts.protectedFields, @(fn) true);
        end
    end

end

% ------------------------------------------------------------
% helpers
% ------------------------------------------------------------

function opts = setdefault(opts, name, value)
    if ~isfield(opts, name) || isempty(opts.(name))
        opts.(name) = value;
    end
end

function refSize = findReferenceSize(data)
    refSize = [];
    if isfield(data, 'incidenceAngleDeg')
        refSize = size(data.incidenceAngleDeg);
        return
    end
    fns = fieldnames(data);
    for i = 1:numel(fns)
        if isnumeric(data.(fns{i}))
            refSize = size(data.(fns{i}));
            return
        end
    end
end

function data = nanFields(data, fields, mask, refSize, protected, gate)
    % NaN `mask` indices across every field for which `gate(fieldName)`
    % is true, skipping protected, non-numeric, and shape-mismatched
    % fields. Same shape gate as SML2OP Filter.filter (lines 76-95).
    if ~any(mask), return; end
    for i = 1:numel(fields)
        fn = fields(i);
        if ~gate(fn),                          continue; end
        if any(strcmp(fn, protected)),         continue; end
        if ~isnumeric(data.(fn)),              continue; end
        if ~isequal(size(data.(fn)), refSize), continue; end
        data.(fn)(mask) = NaN;
    end
end
