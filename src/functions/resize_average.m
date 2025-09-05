function resized_matrix=resize_average(smap_product, numcols, numrows)

original_matrix = smap_product';

target_rows = numrows;
target_cols = numcols;

% Compute scaling factors
scale_rows = size(original_matrix, 1) / target_cols;
scale_cols = size(original_matrix, 2) / target_rows;

% Initialize resized matrix
resized_matrix = NaN(target_cols, target_rows);

% Perform block averaging
for i = 1:target_cols
    for j = 1:target_rows
        % Calculate block indices for the original matrix
        row_start = floor((i-1) * scale_rows) + 1;
        row_end = floor(i * scale_rows);
        col_start = floor((j-1) * scale_cols) + 1;
        col_end = floor(j * scale_cols);
        
        % Ensure indices are within bounds
        row_end = min(row_end, size(original_matrix, 1));
        col_end = min(col_end, size(original_matrix, 2));

        % Extract block and calculate average
        block = original_matrix(row_start:row_end, col_start:col_end);
        resized_matrix(i, j) = mean(block(:), 'omitnan');
    end
end
resized_matrix=resized_matrix';

end
