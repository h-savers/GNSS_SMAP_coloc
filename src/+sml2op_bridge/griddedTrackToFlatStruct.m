function outStruct = griddedTrackToFlatStruct(griddedTrack, track, data, hydrognss_vars, label, numcols, numrows)
% GRIDDEDTRACKTOFLATSTRUCT  Convert an L1BProductTrackGrid into a flat
% per-variable struct keyed by the legacy HydroGNSS variable names.
%
% Each output field is a column vector of length numcols*numrows that
% drops into the legacy stacking loop in Combining_Hydro.m. Values come
% from three sources:
%   1) SML2OP-native grids for lat/lon/incidence/time/SS and the per-channel
%      SNR + ReflectivityDb (these are the variables SML2OP grids inside
%      Track.grid / Measurement.grid).
%   2) For per-channel measurement properties SML2OP doesn't grid
%      (rxAntennaGain, coherencyRatio, powerRatio, NBRCS, etc.), we re-grid
%      from `track.<channel>.Coherent.<property>` which is post-Filter and
%      post-OceanFilter.
%   3) For track-level fields not declared on L1BProductTrack
%      (Onboardspeclat, EIRP_1/5, dayOfYear, secondOfDay, etc.), we look up
%      the corresponding rows in `data` via track.correspondences and
%      accumarray @Utilities.compute_mean. This is the same aggregation the
%      legacy HydroGNSS_process.m used.
%
% Inputs
%   griddedTrack    : L1BProductTrackGrid from product.grid()
%   track           : the parent L1BProductTrack (post-filter)
%   data            : the flat HydroGNSS struct (pre-filter, for non-Track fields)
%   hydrognss_vars  : cellstr/string of all field names expected in output
%   label           : "GPS" or "Galileo"
%   numcols,numrows : grid dimensions (1388, 584 for 25 km EASE)
%
% Output: struct with one field per name in hydrognss_vars; each value is a
% (numcols*numrows)x1 column vector. Empty/all-filtered tracks return all-NaN.

    outStruct = struct();
    Ncells = numcols * numrows;

    % validSP is the same gate Track.grid uses (Track.m:59).
    if isempty(track.SpecularPointLat)
        validSP = false(0, 1);
    else
        validSP = ~(isnan(track.SpecularPointLat) | isnan(track.SpecularPointLon));
    end

    if any(validSP)
        lat = track.SpecularPointLat(validSP);
        lon = track.SpecularPointLon(validSP);
        [idxCols, idxRows] = Utilities.easeconv_grid3(lat, lon, 25);
        absIdxValid = track.correspondences(validSP);
        hasData = true;
    else
        idxCols = []; idxRows = []; absIdxValid = []; hasData = false;
    end

    % Map (suffix, polarisation) -> Track channel property name.
    if label == "GPS"
        chanMap = struct( ...
            'L1L', "GPS_L1_LHCP", 'L1R', "GPS_L1_RHCP", ...
            'L5L', "GPS_L5_LHCP", 'L5R', "GPS_L5_RHCP");
    else
        chanMap = struct( ...
            'L1L', "Galileo_E1_LHCP", 'L1R', "Galileo_E1_RHCP", ...
            'L5L', "Galileo_E5_LHCP", 'L5R', "Galileo_E5_RHCP");
    end

    % Cache per-channel gridded SNR / ReflectivityDb from SML2OP.
    chanGridded = struct();
    chanGridded.L1L = pickChannelGrid(griddedTrack, chanMap.L1L);
    chanGridded.L1R = pickChannelGrid(griddedTrack, chanMap.L1R);
    chanGridded.L5L = pickChannelGrid(griddedTrack, chanMap.L5L);
    chanGridded.L5R = pickChannelGrid(griddedTrack, chanMap.L5R);

    vars = string(hydrognss_vars);
    for i = 1:numel(vars)
        v = vars(i);

        switch v
            case "specularPointLat"
                outStruct.(char(v)) = column(griddedTrack.MeanLatitude, Ncells);
            case "specularPointLon"
                outStruct.(char(v)) = column(griddedTrack.MeanLongitude, Ncells);
            case "incidenceAngleDeg"
                outStruct.(char(v)) = column(griddedTrack.MeanIncidenceAngle, Ncells);
            case "timeUTC"
                outStruct.(char(v)) = column(griddedTrack.MeanIntegrationMidPointTime, Ncells);
            case "constellation"
                % Skipped by HydroGNSS_process.m:51 - return empty placeholder.
                outStruct.(char(v)) = repmat("", Ncells, 1);
            case "SixHourDir"
                outStruct.(char(v)) = repmat("", Ncells, 1);
            otherwise
                % SNR_<suffix> / reflectivityLinear_<suffix> from SML2OP grids.
                [isSNR, suffixKey] = matchPrefix(v, "SNR");
                if isSNR
                    g = chanGridded.(suffixKey);
                    if isstruct(g) && isfield(g, 'SNR')
                        outStruct.(char(v)) = column(g.SNR, Ncells);
                    else
                        outStruct.(char(v)) = nan(Ncells, 1);
                    end
                    continue
                end

                [isRefl, suffixKey] = matchPrefix(v, "reflectivityLinear");
                if isRefl
                    g = chanGridded.(suffixKey);
                    if isstruct(g) && isfield(g, 'ReflectivityDb')
                        outStruct.(char(v)) = column(10.^(g.ReflectivityDb/10), Ncells);
                    else
                        outStruct.(char(v)) = nan(Ncells, 1);
                    end
                    continue
                end

                if ~hasData
                    outStruct.(char(v)) = nan(Ncells, 1);
                    continue
                end

                % All remaining variables: re-grid via accumarray @compute_mean
                % using the same idxCols/idxRows that SML2OP used.
                src = fetchPostFilterValues(v, track, data, absIdxValid, chanMap);
                if isempty(src)
                    outStruct.(char(v)) = nan(Ncells, 1);
                else
                    g = accumarray([idxCols, idxRows], src, [numcols, numrows], ...
                                   @Utilities.compute_mean, NaN);
                    outStruct.(char(v)) = g(:);
                end
        end
    end
end

% ------------------------------------------------------------
function out = column(M, Ncells)
    if isempty(M)
        out = nan(Ncells, 1);
    else
        out = M(:);
        if numel(out) ~= Ncells
            tmp = nan(Ncells, 1);
            n = min(numel(out), Ncells);
            tmp(1:n) = out(1:n);
            out = tmp;
        end
    end
end

function g = pickChannelGrid(griddedTrack, propName)
    g = [];
    if ~isprop(griddedTrack, char(propName))
        return
    end
    chan = griddedTrack.(char(propName));
    if isempty(chan) || isa(chan, 'cell')
        return
    end
    if ~isprop(chan, 'Coherent') || isempty(chan.Coherent)
        return
    end
    meas = chan.Coherent;
    g = struct('SNR', meas.SNR, 'ReflectivityDb', meas.ReflectivityDb);
end

function [matched, suffixKey] = matchPrefix(varName, prefix)
    matched = false;
    suffixKey = '';
    p = char(prefix);
    if startsWith(varName, p)
        rest = char(extractAfter(varName, p));
        switch rest
            case '_1_L', matched = true; suffixKey = 'L1L';
            case '_1_R', matched = true; suffixKey = 'L1R';
            case '_5_L', matched = true; suffixKey = 'L5L';
            case '_5_R', matched = true; suffixKey = 'L5R';
        end
    end
end

function src = fetchPostFilterValues(varName, track, data, absIdxValid, chanMap)
% Try, in order:
%   (1) Per-channel suffix: pull from track.<chan>.Coherent.<sml2opProp>
%       post-filter (mapping suffix-style names to SML2OP property names).
%   (2) Track property: track.(varName) when the property exists on L1BProductTrack.
%   (3) Fallback: data.(varName)(absIdxValid) (pre-filter for fields not
%       declared on the Track class).
% Returns column vector aligned with absIdxValid, or [] if no source.

    src = [];
    v = char(varName);

    % (1) Per-channel suffix mapping.
    suffixes = struct( ...
        '_1_L', 'L1L', '_1_R', 'L1R', '_5_L', 'L5L', '_5_R', 'L5R');
    sfxNames = fieldnames(suffixes);
    for k = 1:numel(sfxNames)
        sfx = sfxNames{k};
        if endsWith(v, sfx)
            base = v(1:end-length(sfx));
            sml2opProp = mapBaseToMeasurementProp(base);
            if ~isempty(sml2opProp)
                chanProp = chanMap.(suffixes.(sfx));
                chan = track.(char(chanProp));
                if ~isempty(chan) && ~isempty(chan.Coherent) && ...
                        isprop(chan.Coherent, sml2opProp)
                    val = chan.Coherent.(sml2opProp);
                    if ~isempty(val) && numel(val) >= numel(track.SpecularPointLat)
                        % Subset using the same validSP as caller would compute.
                        validSP = ~(isnan(track.SpecularPointLat) | isnan(track.SpecularPointLon));
                        val = val(validSP);
                        src = double(val(:));
                        % For reflectivity, SML2OP stores dB; legacy outputs
                        % linear. Caller handles that for the gridded
                        % reflectivityLinear variable; here we don't reach
                        % refl/SNR since they are dispatched earlier.
                        return
                    end
                end
            end
            % Suffix matched but no SML2OP analogue: fall through to data lookup.
            break
        end
    end

    % (2) Track-level direct property.
    if isprop(track, v)
        val = track.(v);
        if ~isempty(val) && numel(val) >= numel(track.SpecularPointLat)
            validSP = ~(isnan(track.SpecularPointLat) | isnan(track.SpecularPointLon));
            src = double(val(validSP));
            src = src(:);
            return
        end
    end

    % (3) Fallback to raw data (no SML2OP filtering applied to this field).
    if isfield(data, v)
        rawVal = data.(v);
        if isnumeric(rawVal) || islogical(rawVal)
            src = double(rawVal(absIdxValid));
            src = src(:);
        elseif isdatetime(rawVal)
            src = posixtime(rawVal(absIdxValid));
            src = src(:);
        end
    end
end

function p = mapBaseToMeasurementProp(base)
    % Maps "rxAntennaGain", "coherencyRatio", etc. -> SML2OP measurement property names.
    switch base
        case 'rxAntennaGain',     p = 'AntennaGainTowardsSpecularPoint';
        case 'coherencyRatio',    p = 'Coherency';
        case 'powerRatio',        p = 'PowerSpreadRatio';
        case 'NBRCS',             p = 'Sigma0';
        otherwise,                p = '';
    end
end
