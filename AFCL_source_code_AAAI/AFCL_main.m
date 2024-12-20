
clc;
clear;
close all;

rand('seed',11);
%% Input the public data
cen_xx = readmatrix('./public_data/seeds.csv');

%%
[n,d] = size(cen_xx);
k_true = max(cen_xx(:,d));

%% Set the number of clients
p = 5;

xx = cell(1,p);

%% Number of runs
T = 20;

%%
k_miu_record = zeros(1,T);
CH_record = zeros(1,T);
SC_record = zeros(1,T);

[n,d] = size(cen_xx);

k_true = max(cen_xx(:,d));

ran = randi([k_true,k_true*2],[1,T]);     %The random range of k

overall_probability = [];
lim = 0.0001; %Condition of convergence
time_results = zeros(1,T);
for loop = 1:T
    %% Normalization
    for l = 1:p
        [~,d_n] = size(xx{l});
        for i=1:d_n-1
            if(min(cen_xx(:,i)) == max(cen_xx(:,i)))
                xx{l}(:,i) = 1;
            else
                xx{l}(:,i) = (xx{l}(:,i)-min(cen_xx(:,i)))./(max(cen_xx(:,i)) - min(cen_xx(:,i)));
            end
        end
    end

    [n,d] = size(cen_xx);
    for i=1:d-1
        if(min(cen_xx(:,i)) == max(cen_xx(:,i)))
            cen_xx(:,i) = 1;
        else
            cen_xx(:,i) = (cen_xx(:,i)-min(cen_xx(:,i)))./(max(cen_xx(:,i)) - min(cen_xx(:,i)));
        end
    end

    %% set k
    k = ran(loop);
    n = size(cen_xx,1);
    k_set = k;
    x = cell(1,p);
    %% create client non-IID, using k-means
    [idx,~] = kmeans(cen_xx,p);
    kmeans_x = [];
    kmeans_x_len = zeros(1,p);
    for i = 1:p
        x_index = find(idx == i);
        xx{i} = cen_xx(idx == i,:);
        [n,d] = size(xx{i});
        x{i} = xx{i}(:,1:d-1);
        x_with_index = [x_index, xx{i}];
        kmeans_x = [kmeans_x;x_with_index];
        kmeans_x_len(i) = n;
    end
    %% Save the client's data. 
    %%If you want to use the same client data in other methods, use this
    %%code to generate data in each run. This code generates the total data according to the cleint order

    %     d = size(kmeans_x, 2);
    %     A = cell(1,d);
    %     for i = 1:d-1
    %         A{i} = strcat('A',num2str(i));
    %     end
    %     A{i+1} = 'class';
    %     a=strcat(strcat(str,num2str(loop)),'.csv');
    %
    %%This code generates a csv file that holds the data owned by each cleint.
    %     data = table(kmeans_x(:,1),'VariableNames', {A{1}});
    %     for i = 1:d-1
    %         data = addvars(data,kmeans_x(:,i+1),'After',{A{i}},'NewVariableNames',{A{i+1}});
    %     end
    %     writetable(data,a);
    %     a = strcat(strcat(str),num2str(loop),'_len.csv');
    %     csvwrite(a,kmeans_x_len,0,0);
    %%
    Federated_xx = cell(1,p);
    Federated_x = cell(1,p);
    for l = 1:p
        [~,d] = size(xx{l});
        Federated_xx{l} = xx{l};
        Federated_x{l} = xx{l}(:,1:d-1);
    end
    %% Randomly initialize centroids

    federated_miu_numer = cell(1,p);

    %% initialize centroids
    tic
        miu_numer = [];
        for l = 1:p
            if(size(Federated_x{l},1) <= k)
                miu_numer = [miu_numer;Federated_x{l}];
            else
                miu_numer = [miu_numer;kmeans_plusplus_init(Federated_x{l},k)];
            end
        end
    
        cen = kmeans_plusplus_init(miu_numer,k);

    n = size(cen_xx,1);
    for l = 1:p
                federated_miu_numer{l} = cen;
    end

    %%
    miu_record = [];

    for i = 1:p
        federated_miu_numer{i};
        miu_record = [miu_record; federated_miu_numer{i}];

    end

    %% main federated process
    T_time = 100;
    a_c = 0.001;
    a_r = 0.001;
    convergent_func_count = [];
    Federated_cluster_label = cell(1,p);
    Federated_win_count = cell(1,p);
    competition = cell(1,p);
    k_record = cell(1,p);
    k_pre_record = zeros(1,p);
    for l = 1:p
        Federated_win_count{l} = ones(1, k);
        [n,d] = size(federated_miu_numer{l});
        k_record{l} = zeros(1,T_time);
        k_record{l}(1) = k_set;

    end

    Z = cell(1,p);
    Z_miu = cell(1,p);
    Z_change = zeros(1,T_time);
    Z_sum = zeros(1,T_time);
    Z_pre = -1;
    server_miu_numer = cen;
    central_xx = [];
    for i = 1:p
        central_xx = [central_xx;Federated_xx{i}];
    end
    alpha = 0.05;
    miu_plot_record = [];
    %% attribute weight
    miu_numer_pre = zeros(k, d);
    miu_dis_record = ones(1,T_time);
    W = rand(1,d);      
    w = sum(W);
    W = W/w;
    W = W .* a_r * d;

    %% balance weight
    commu_weight = zeros(1,p);
        
    %%

    one_shot_client = generate_clients(1, 3, 1, p);

    client_participate_times = zeros(1,p);

    participation_prob = rand(1, p); 
    overall_probability = [overall_probability;participation_prob];
    for t = 1:T_time
        
        for i = 1:p
            if(find(isnan(federated_miu_numer{i})==1))
                a = 1;
            end
        end

        %% setting participating clients

        participate_clients = [];
        for client = 1:p
            if rand() < participation_prob(client)
                participate_clients = [participate_clients, client];
            end
        end


        client_participate_times(participate_clients) = client_participate_times(participate_clients) + 1;

        for i = 1:p
            commu_weight(i) = 1/(1 + client_participate_times(i)/sum(client_participate_times));
        end

        %%
        for i = 1:length(participate_clients)
            federated_miu_numer{participate_clients(i)} = server_miu_numer;
        end
        for l = 1:p
            [k,~] = size(federated_miu_numer{l});

            a_c = a_r * exp(alpha * t);
            if(a_c > 0.01)
                a_c = 0.01;
            end

            if(find(participate_clients == l))
                [~,Federated_cluster_label{l},Z{l},competition{l},Z_miu{l}] = AFCL_client(Federated_x{l},k,server_miu_numer,Federated_win_count{l},a_c,W);
            else
                [~,Federated_cluster_label{l},~,~,~] = AFCL_client(Federated_x{l},k,server_miu_numer,Federated_win_count{l},a_c,W);
            end
            [k_record{l}(t),~] = size(federated_miu_numer{l});

            Federated_win_count{l};

        end

        resample_pos = find(commu_weight > mean(commu_weight));
        for i = 1:length(resample_pos)
            if(find(participate_clients == resample_pos(i)))
                resample_pos(i) = 0;
            end
        end

        resample_pos =  resample_pos(resample_pos > 0);
        if(length(resample_pos) >= 1)
            resample_pos = resample_pos(client_participate_times(resample_pos) >= 1);
            client_participate_times(resample_pos) = client_participate_times(resample_pos) + 1;
            for i = 1:length(resample_pos)
                commu_weight(resample_pos(i)) = 1/(1 + client_participate_times(resample_pos(i))/sum(client_participate_times));
                participate_clients = [resample_pos(i), participate_clients];
            end
            participate_clients = sort(participate_clients);
        end
        %%
        Z_change(t) = abs(Z_sum(t) - Z_pre);

        %% presever the number of clusters' object
        cluster_num = cell(1,p);
        Federated_cluster_record = cell(1,p);   
        for i = 1:p
            [k,~] = size(federated_miu_numer{i});
            cluster_num{i} = zeros(1,k);
        end
        for i = 1:p
            [n,~] = size(Federated_cluster_label{i});
            [k,~] = size(federated_miu_numer{i});
            Federated_cluster_record{i} = zeros(1,k);
            for j = 1:n
                cluster_num{i}(Federated_cluster_label{i}(j,:) == 1) = cluster_num{i}(Federated_cluster_label{i}(j,:) == 1) + 1;
            end
        end
        %% Federated competition
        [~,d] = size(Federated_x{1});
        count_miu = 0;
        miu_numer = [];
        for j = 1:p
            miu_numer = [miu_numer; federated_miu_numer{j}];
            count_miu = count_miu + length(federated_miu_numer{j});
        end

        competition_record = cell(1,count_miu);
        miu_numer_updated = zeros(count_miu,d);
        l = 1;
        for i = 1:length(participate_clients)
            g = participate_clients(i);
            [count_m,~] = size(federated_miu_numer{g});
            for j = 1:count_m
                competition_record{l} = competition{g}{j};
            end
            l = l + count_m;
        end

        [m_n,~] = size(miu_numer);
        miu_record = miu_numer;
        %% aggregation
        client_label = cell(1,p);
        for i = 1:p
            [n,~] = size(Federated_xx{i});

            client_label{i} = zeros(n,1);
        end
        func_miu = miu_record;
        [pos_k_record,~] = size(miu_record);    
        central_miu_numer = cell(1,1);
        central_miu_numer{1} = func_miu;
        for l = 1:1
            [m_n,~] = size(central_miu_numer{l});
            positions = zeros(m_n,m_n);

            for i = 1:m_n

                current_positions = i;

                for j = i+1:m_n

                    diff_vector = abs(central_miu_numer{l}(i,:) - central_miu_numer{l}(j,:));

                    if all(diff_vector < 0.001)
                        current_positions = [current_positions, j];
                    end
                end

                if numel(current_positions) > 1
                    [~,d_p] = size(current_positions);
                    positions(i,1:d_p) = current_positions;
                end

                unique_positions = unique(positions(:), 'stable');

            end

            miu_update = [];
            unique_positions = unique(positions(:), 'stable');
            unique_positions = unique_positions(unique_positions > 0);
            for i = 1:m_n
                if(find(unique_positions == i))

                else
                    miu_update = [miu_update; central_miu_numer{l}(i,:)];
                end
            end
            unique_record = cell(1,1);

            for i = 1:m_n
                loca_rep = 1;
                flag = 0;
                unique_positions = unique(positions(i,:));
                unique_positions = unique_positions(unique_positions > 0);
                for j = 1:length(unique_record)         
                    for g = 1:length(unique_positions)
                        if(find(unique_record{j} == unique_positions(g)))
                            loca_rep = j;
                            flag = 1;
                        end
                    end
                end

                if(~isempty(unique_positions))
                    if(flag == 0 && isempty(unique_record{1}))
                        loca_rep = 1;
                    end

                    if(flag == 0 && ~isempty(unique_record{1}))
                        loca_rep = length(unique_record) + 1;
                        unique_record{loca_rep} = unique_positions;
                        unique_record{loca_rep} = unique(unique_record{loca_rep});
                        continue;
                    end

                    unique_record{loca_rep} = [unique_record{loca_rep} unique_positions];
                    unique_record{loca_rep} = unique(unique_record{loca_rep});
                end
            end
            if(~isempty(unique_record{1}))
                for i = 1:length(unique_record)
                    miu_update = [miu_update; central_miu_numer{l}(unique_record{i}(1),:)];
                end
            end
            [miu_n,~] = size(miu_update);
            central_miu_numer{l} = miu_update;
        end
        [central_k,~] = size(central_miu_numer{1}); 

        for i = 1:p
            k_pre_record(i) = k_record{i}(t);
        end


        %% aggregation
        combine = [];
        count = 0;
        total_sum = 0;
        k_sum = 0;
        coun_cen = zeros(1,central_k);
        intracluster_distances = zeros(central_k, 1);

        intracluster_distances_count = zeros(central_k, 1);
        z_miu = zeros(central_k,size(central_miu_numer{1},2));

        for j = 1:p

            total_sum = k_pre_record(j) + total_sum;
            k_sum = [k_sum, total_sum];
        end
        for i = 1:length(unique_record)
            pos = unique_record{i};
            z_record = [];
            intra_dis = zeros(1,length(pos));
            count_cen = zeros(1,length(pos));
            for j = 1:length(unique_record{i})
                client = find(pos(j) > k_sum, 1, 'last' );
                centriod = pos(j) - k_sum(client);   
                count_cen(j) = length(find(Federated_cluster_label{client}(:,centriod) == 1));

                client_label{client}(Federated_cluster_label{client}(:,centriod) == 1) = i;
                count_local = length(find(Federated_cluster_label{client}(:,centriod) == 1));

                if(~isempty(find(participate_clients == client, 1)))
                    if(Z{client}(centriod) ~= 0)

                        intracluster_distances(i) = intracluster_distances(i) + Z{client}(centriod) * commu_weight(client);
                        intra_dis(j) = Z{client}(centriod);
                        intracluster_distances_count(i) = intracluster_distances_count(i) + 1;
                    end
                end
            end

            for j = 1:length(pos)
                client = find(pos(j) > k_sum, 1, 'last' );
                if(~isempty(find(participate_clients == client, 1)))

                    centriod = pos(j) - k_sum(client);   
                
                    z_miu(i,:) = z_miu(i,:) + count_cen(j)/sum(count_cen) * Z_miu{client}(centriod,:) * commu_weight(client);
                    intracluster_distances(i) = intracluster_distances(i) + count_cen(j)/sum(count_cen) * Z{client}(centriod) * commu_weight(client);
                end
            end
            if(intracluster_distances_count(i) == 0)
                continue;
            end

            count = count + length(unique_record{i});   
            combine = [combine unique_record{i}];   
        end

        %% calculate converge
        intercluster_distances = zeros(central_k);
        for i = 1:central_k
            for j = 1:central_k
                if i ~= j
                    intercluster_distances(i, j) = sqrt(sum((z_miu(i, :) - z_miu(j, :)).^2)); 
                end
            end
        end

        %% 
        DB = zeros(central_k, 1);
        for i = 1:central_k
            max_DB = 0;
            for j = 1:central_k
                if i ~= j
                    DB(i) = (intracluster_distances(i) + intracluster_distances(j)) / intercluster_distances(i, j);
                    if DB(i) > max_DB
                        max_DB = DB(i);
                    end
                end
            end
            DB(i) = max_DB; 
        end

        count_DBI = mean(DB);
        if(count_DBI ~= 0)
            convergent_func_count = [convergent_func_count count_DBI];
        else
            convergent_func_count = [convergent_func_count NaN];
        end

        %% check converge
        miu_plot_record = [miu_plot_record;server_miu_numer];
        Z_change(t) = abs(Z_pre - convergent_func_count(t));
        if(Z_change(t) <= lim)
            break;
        end
        Z_pre = convergent_func_count(t);

        %% 
        [f_k,~] = size(miu_numer);    

        Federated_cluster_label_pre = cell(1,p);
        for i = 1:p
            Federated_cluster_label_pre{i} = Federated_cluster_label{i};
        end

        %% server-side seeds interaction
        miu_numer = server_miu_numer;

        times = 1;


        [server_miu_numer] = AFCL_server(times,federated_miu_numer,competition,lim,miu_numer,length(participate_clients),a_c,participate_clients,W,commu_weight);
        miu_record = server_miu_numer;
        miu_numer_pre = server_miu_numer;
        %% 
        num = 1;
        k_count = 0;
        for l = 1:p   
            [k,~] = size(federated_miu_numer{l});
            if(find(l == participate_clients))
                k_count = k_count + k;
                federated_miu_numer{l} = server_miu_numer;
                num = num + k;
            end

            Federated_win_count{l} = ones(1, k);
        end

        location = cell(1,p);
        %%
        for l = 1:p
            [m_n,~] = size(federated_miu_numer{l});
            
            positions = zeros(m_n,m_n);
            
            for i = 1:m_n
                
                current_positions = i;
                
                for j = i+1:m_n
                    
                    diff_vector = abs(federated_miu_numer{l}(i,:) - federated_miu_numer{l}(j,:));
                    
                    if all(diff_vector < 0.001)
                        current_positions = [current_positions, j];
                    end
                end
               
                if numel(current_positions) > 1
                    [~,d_p] = size(current_positions);
                    positions(i,1:d_p) = current_positions;
                end
                
                unique_positions = unique(positions(:), 'stable');

            end

            miu_update = [];
            unique_positions = unique(positions(:), 'stable');
            unique_positions = unique_positions(unique_positions > 0);
            for i = 1:m_n
                if(find(unique_positions == i))

                else
                    miu_update = [miu_update; federated_miu_numer{l}(i,:)];
                end
            end
            unique_record = cell(1,1);

            for i = 1:m_n
                loca_rep = 1;
                flag = 0;
                unique_positions = unique(positions(i,:));
                unique_positions = unique_positions(unique_positions > 0);
                for j = 1:length(unique_record)         
                    for g = 1:length(unique_positions)
                        if(find(unique_record{j} == unique_positions(g)))
                            loca_rep = j;
                            flag = 1;
                        end
                    end
                end


                if(~isempty(unique_positions))
                    if(flag == 0 && isempty(unique_record{1}))
                        loca_rep = 1;
                    end
                    if(flag == 0 && ~isempty(unique_record{1}))
                        loca_rep = length(unique_record) + 1;
                        unique_record{loca_rep} = unique_positions;
                        unique_record{loca_rep} = unique(unique_record{loca_rep});
                        continue;
                    end

                    unique_record{loca_rep} = [unique_record{loca_rep} unique_positions];
                    unique_record{loca_rep} = unique(unique_record{loca_rep});
                end
            end
            if(~isempty(unique_record{1}))
                for i = 1:length(unique_record)
                    miu_update = [miu_update; federated_miu_numer{l}(unique_record{i}(1),:)];
                end
            end

            [miu_n,~] = size(federated_miu_numer{l});
            k_record{l}(t) = miu_n;
        end

        %% update attribute weight
        d = size(cen_xx,2) - 1;     
        D = zeros(1,d);
        for l = 1:length(participate_clients)
            for i = 1:k
                Nor = zeros(1,d);
                for g = 1:size(competition{participate_clients(l)}{i},1)
                    Nor = Nor + sqrt(competition{participate_clients(l)}{i}(g,:) .* competition{participate_clients(l)}{i}(g,:));
                end
                for j = 1:d
                    D(j) = D(j) + Nor(j);
                end
            end
        end

        belta = 7;
        h = find(D ~= 0);
        for j = 1:d
            if(D(j) == 0)
                W(j) = 0;
            else
                weight = 0;
                for l = 1:length(h)
                    weight = weight + (D(j)/D(h(l)))^(1/belta);
                end
                W(j) = 1/weight;
            end
        end
        W = W .* a_r * d;
        W_sum = sum(W);
        a = 1;

        %%
        [m_n,~] = size(miu_numer);

        for i = 1:p
            k_pre_record(i) = k_record{i}(t);
        end
    end
    %% aggregation
    miu_numer = server_miu_numer;

    federated_miu_numer = cell(1,1);
    [pos_k_record,~] = size(miu_numer);
    federated_miu_numer{1} = miu_numer;
    for l = 1:1
        [m_n,~] = size(federated_miu_numer{l});
        positions = zeros(m_n,m_n);

        for i = 1:m_n

            current_positions = i;

            for j = i+1:m_n

                diff_vector = abs(federated_miu_numer{l}(i,:) - federated_miu_numer{l}(j,:));

                if all(diff_vector < 0.001)
                    current_positions = [current_positions, j];
                end
            end

            if numel(current_positions) > 1
                [~,d_p] = size(current_positions);
                positions(i,1:d_p) = current_positions;
            end

            unique_positions = unique(positions(:), 'stable');

        end

        miu_update = [];
        unique_positions = unique(positions(:), 'stable');
        unique_positions = unique_positions(unique_positions > 0);
        for i = 1:m_n
            if(find(unique_positions == i))

            else
                miu_update = [miu_update; federated_miu_numer{l}(i,:)];
            end
        end
        unique_record = cell(1,1);

        for i = 1:m_n
            loca_rep = 1;
            flag = 0;
            unique_positions = unique(positions(i,:));
            unique_positions = unique_positions(unique_positions > 0);
            for j = 1:length(unique_record)         
                for g = 1:length(unique_positions)
                    if(find(unique_record{j} == unique_positions(g)))
                        loca_rep = j;
                        flag = 1;
                    end
                end
            end


            if(~isempty(unique_positions))
                if(flag == 0 && isempty(unique_record{1}))
                    loca_rep = 1;
                end
                if(flag == 0 && ~isempty(unique_record{1}))
                    loca_rep = length(unique_record) + 1;
                    unique_record{loca_rep} = unique_positions;
                    unique_record{loca_rep} = unique(unique_record{loca_rep});
                    continue;
                end

                unique_record{loca_rep} = [unique_record{loca_rep} unique_positions];
                unique_record{loca_rep} = unique(unique_record{loca_rep});
            end
        end
        if(~isempty(unique_record{1}))
            for i = 1:length(unique_record)
                miu_update = [miu_update; federated_miu_numer{l}(unique_record{i}(1),:)];
            end
        end
        [miu_n,~] = size(miu_update);
        federated_miu_numer{l} = miu_update;
    end


    %% aggregation
    for i = 1:p
        Federated_win_count{i} = ones(1, miu_n);
        [~,Federated_cluster_label{i},~,~,~] = AFCL_aggregation(Federated_x{i},miu_n,federated_miu_numer{1},Federated_win_count{i},a_c);
        for j = 1:miu_n
            client_label{i}(Federated_cluster_label{i}(:,j) == 1) = j;
        end
    end
    %%
    central_label = [];
    for i = 1:p
        central_label = [central_label; client_label{i}];
    end


    %% evaluation
    [~,d] = size(Federated_xx{1});
    SC = evalclusters(central_xx(:,1:d-1),central_label,'silhouette');
    CH = evalclusters(central_xx(:,1:d-1),central_label,'CalinskiHarabasz');
    SC_record(loop) = SC.CriterionValues;
    CH_record(loop) = CH.CriterionValues;
    [k_miu_record(loop),~] = size(federated_miu_numer{1});

end

b = find(k_miu_record == k_true);
if(isempty(b))
    b = find(k_miu_record > 1);
end
SC_mean = mean(SC_record(b))
SC_std = std(SC_record(b))
CH_mean = mean(CH_record(b))
CH_std = std(CH_record(b))

