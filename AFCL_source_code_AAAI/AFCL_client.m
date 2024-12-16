function [miu_numer,cluster_label,Z,competition_record,z_miu] = AFCL_client(x,k,miu_numer,win_count,a_c,W)
lim = 0.00001;

x_numeric = x; 

[n, d] = size(x);  %%% n: the number of samples;   d: the number of attributes(dimensionality)
[~, d_n] = size(x_numeric);
competition_record = cell(1,k);

for i = 1:k
    competition_record{i} = zeros(1,d);
end

%% Implementation of RPCCL algorithm %%%%%
T_total = 1; 
%% Randomly initialize the k seed points(one for each class) %%%%%
[m_n,m_d] = size(miu_numer);
miu_numer_pre = zeros(m_n,m_d);
z_pre = -1;
z = zeros(1,k);
z_miu = zeros(k,m_d);
for T_times = 1:T_total

    cluster_label = zeros(n, k); %%% cluster label of each object

    I = zeros(1,k);

    for i = 1:n
        %% cal distance
        class_distance = zeros(1,k);
        for l = 1:k
            count_dis = x(i,:) - miu_numer(l,:);
            class_distance(l) =  sum(count_dis .* count_dis);
        end
        %% calculate winner
        I_distance = zeros(1,k);
        for l = 1:k
            count_dis = x(i,:) - miu_numer(l,:);
            I_distance(l) = win_count(l)/sum(win_count) * sum(count_dis .* count_dis);
        end
        c = find(class_distance == min(class_distance));

        c = c(1);
        win_count(c) = win_count(c) + 1;    
        cluster_label(i,c) = 1;
        %% preserver update information
        competition_record{c} = [competition_record{c}; W .* (x(i,:) - miu_numer(c,:))];
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
[n,~] = size(x);
label = zeros(n,1);
for i = 1:n
    label(i) = find(cluster_label(i,:) == 1);
end

Z = z;
miu_numer;



