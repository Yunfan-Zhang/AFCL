function centroids = kmeans_plusplus_init(X, k)
    % X: data
    % k: number of seeds
    
    centroids = X(randi(size(X, 1)), :);
    
    for i = 2:k

        distances = min(pdist2(X, centroids), [], 2);
        
        probabilities = distances.^2 / sum(distances.^2);
        
        next_centroid_index = randsample(size(X, 1), 1, true, probabilities);
        next_centroid = X(next_centroid_index, :);
        
        centroids = [centroids; next_centroid];
    end
end
