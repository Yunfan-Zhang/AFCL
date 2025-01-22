function [miu_numer,cluster_label,Z,competition_record,z_miu] = AFCL_aggregation(x,k,miu_numer,win_count,a_c)
lim = 0.00001;
converge = 0;

x_numeric = x; 

[n, d] = size(x);  %%% n: the number of samples;   d: the number of attributes(dimensionality)
[~, d_n] = size(x_numeric);
competition_record = cell(1,k);

for i = 1:k
    competition_record{i} = zeros(1,d);
end

%% 
T_total = 1; 
epoch_record = zeros(1, T_total);
error_record = zeros(1, T_total);
time_record = zeros(1, T_total);
%% 
[m_n,m_d] = size(miu_numer);
miu_numer_pre = zeros(m_n,m_d);
z_pre = -1;
z = zeros(1,k);
z_miu = zeros(k,m_d);
z_change_record = zeros(1,T_total);
for T_times = 1:T_total

    cluster_label = zeros(n, k); %%% cluster label of each object
    
    I = zeros(1,k);

    for i = 1:n
        %% 
        class_distance = zeros(1,k);
        for l = 1:k
            count_dis = x(i,:) - miu_numer(l,:);
            class_distance(l) =  sum(count_dis .* count_dis);
        end

        I_distance = zeros(1,k);
        for l = 1:k
            count_dis = x(i,:) - miu_numer(l,:);
            I_distance(l) = win_count(l)/sum(win_count) * sum(count_dis .* count_dis);
        end
        c = find(class_distance == min(class_distance));
        c = c(1);
        win_count(c) = win_count(c) + 1;    
        cluster_label(i,c) = 1;
        %% 
        cooperating_set = [];
        for l = 1:k
            cen_dis = miu_numer(l,:) - miu_numer(c,:);
            dis = sum(cen_dis .* cen_dis);
            if(dis <= class_distance(c))
                cooperating_set = [cooperating_set l];
            end
        end
        %% update cooperating set
        for j = 1:length(cooperating_set)
            l = cooperating_set(j);
            competition_record{l} = [competition_record{l}; a_c * (x(i,:) - miu_numer(l,:))];
        end

    end

    for l = 1:k

        c = find(cluster_label(:,l) == 1);
        cluster_point = x(cluster_label(:,l) == 1,:);
        if(isempty(c))
            continue;
        end
        centroid = mean(cluster_point); 

        distances = sqrt(sum((cluster_point - centroid).^2, 2)); 
        z(l) = mean(distances); 
        z_miu(l,:) = centroid;
    end

    miu_numer_pre = miu_numer;

end

%%
for l = 1:k
    [len,~] = size(competition_record{l});

    n = len;

    if(len == 0)
        continue;
    end
    p = round((n + 1)/3);

    min_samples_per_partition = 2;
    max_samples_per_partition = fix(len/p);
    if(max_samples_per_partition == 0)
        p = len;
        min_samples_per_partition = 1;
    end
    samples_per_partition = randi([min(min_samples_per_partition,max_samples_per_partition), max(min_samples_per_partition,max_samples_per_partition)], 1, p);

    partitions = cell(1, k);

    indices = randperm(n);

    start_idx = 1;
    for i = 1:p
        num_samples = samples_per_partition(i);
        if(i == p)
            end_idx = n;
        else
            end_idx = start_idx + num_samples - 1;
        end
        
        partition_indices = indices(start_idx:end_idx);

        partitions{l} = [partitions{l}; sum(competition_record{l}(partition_indices,:),1)/(end_idx - start_idx + 1)];

        start_idx = end_idx + 1;
    end
        competition_record{l} = partitions{l};
end

[n,~] = size(x);
label = zeros(n,1);
for i = 1:n
    label(i) = find(cluster_label(i,:) == 1);
end

Z = z;
miu_numer;


