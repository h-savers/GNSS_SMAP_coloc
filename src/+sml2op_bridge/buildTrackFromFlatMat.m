function track = buildTrackFromFlatMat(data, idx, label, parentProduct)
% BUILDTRACKFROMFLATMAT  Build one L1BProductTrack for the given constellation
% ("GPS" or "Galileo") populated from the flat HydroGNSS .mat at rows idx.
%
% Populates the properties touched by Filter.apply (track-level SPIncidenceAngle
% cascade), OceanFilter.apply (SpecularPointLat/Lon + per-channel NaN'ing), and
% L1BProductTrack.grid (lines 65-77: idx2grd via easeconv_grid3, Mean*
% aggregations, QualityFlags mode, channel.grid dispatch). Properties not in
% the flat .mat (Transmitter/Specular XYZ) are filled with NaN so the SS
% dependent getter returns NaN harmlessly.

    track = L1BProductTrack();
    track.parent = parentProduct;
    track.Name   = label;
    track.trackNumber = ifelse(label == "GPS", 1, 2);

    idx = idx(:);
    nSP = numel(idx);
    track.TrackSize = nSP;
    track.correspondences = idx;

    % Coordinates - apply the splon==180 / splon>180 wrap that the legacy
    % HydroGNSS_process.m:6-7 does before easeconv_grid3.
    lat = double(data.specularPointLat(idx));
    lon = double(data.specularPointLon(idx));
    lon(lon == 180)  = 179.66;
    lon(lon  > 180)  = lon(lon > 180) - 360;
    track.SpecularPointLat = lat(:);
    track.SpecularPointLon = lon(:);

    nanCol = nan(nSP, 1);
    track.SpecularPointPositionX = nanCol;
    track.SpecularPointPositionY = nanCol;
    track.SpecularPointPositionZ = nanCol;
    track.TransmitterPositionX   = nanCol;
    track.TransmitterPositionY   = nanCol;
    track.TransmitterPositionZ   = nanCol;

    track.SPIncidenceAngle    = readField(data, 'incidenceAngleDeg',      idx);
    track.SPAzimuthARF        = readField(data, 'spAzimuthAngleDegOrbit', idx);

    % accumarray in Track.grid needs numeric time, not datetime.
    if isfield(data, 'timeUTC')
        track.IntegrationMidPointTime = posixtime(data.timeUTC(idx));
        track.IntegrationMidPointTime = track.IntegrationMidPointTime(:);
    else
        track.IntegrationMidPointTime = nanCol;
    end

    if isfield(data, 'Landtypesub')
        track.LandType = double(data.Landtypesub(idx));
        track.LandType = track.LandType(:);
    else
        track.LandType = nanCol;
    end
    track.SnowIceCover        = nanCol;
    track.DistantFromCoastFlag = nanCol;
    track.ReflectionHeight    = nanCol;

    track.PRN = readField(data, 'pseudoRandomNoise', idx);

    % Required by Track.grid line 77 - mode over a numeric flag column.
    track.QualityFlags = zeros(nSP, 1, 'double');

    % Channel suffix-to-SML2OP-property mapping. The flat .mat uses _1_*
    % for L1/E1 and _5_* for L5/E5 regardless of constellation, but the
    % Track property name is constellation-specific.
    if label == "GPS"
        chanSpecs = { ...
            "GPS_L1_LHCP", "_1_L", "GPS_L1", "LHCP"; ...
            "GPS_L1_RHCP", "_1_R", "GPS_L1", "RHCP"; ...
            "GPS_L5_LHCP", "_5_L", "GPS_L5", "LHCP"; ...
            "GPS_L5_RHCP", "_5_R", "GPS_L5", "RHCP"};
    else
        chanSpecs = { ...
            "Galileo_E1_LHCP", "_1_L", "Galileo_E1", "LHCP"; ...
            "Galileo_E1_RHCP", "_1_R", "Galileo_E1", "RHCP"; ...
            "Galileo_E5_LHCP", "_5_L", "Galileo_E5", "LHCP"; ...
            "Galileo_E5_RHCP", "_5_R", "Galileo_E5", "RHCP"};
    end
    for c = 1:size(chanSpecs, 1)
        propName  = chanSpecs{c, 1};
        suffix    = chanSpecs{c, 2};
        signalFq  = chanSpecs{c, 3};
        polar     = chanSpecs{c, 4};
        track.(char(propName)) = sml2op_bridge.buildChannelFromFlatMat( ...
            data, idx, suffix, signalFq, polar, track);
    end
end

function v = readField(data, name, idx)
    if isfield(data, name)
        v = double(data.(name)(idx));
        v = v(:);
    else
        v = nan(numel(idx), 1);
    end
end

function out = ifelse(cond, a, b)
    if cond, out = a; else, out = b; end
end
