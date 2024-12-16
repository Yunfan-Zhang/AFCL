function [miu_numer] = AFCL_server(times,federated_miu_numer,competition,lim,miu_numer,p,a_c, participate_clients,W, commu_weight)
[f_k,~] = size(miu_numer);
central_win_count = ones(f_k,1);
W(W ==0) = 1;
lim = 0.0001;
flag = 0;

miu_record = zeros(size(miu_numer));
W_record = W;
for time = 1:times
    f_j = 0;
    for v = 1:length(participate_clients)
        i = participate_clients(v);
        [k,~] = size(federated_miu_numer{i});
        W = W_record;
        W = W * commu_weight(i);

        for j = 1:k
            [n_c,~] = size(competition{i}{j});
            f_j = f_j + 1;
            for g = 1:n_c
                class_distance = zeros(1,f_k);
                object = competition{i}{j}(g,:)./W + federated_miu_numer{i}(j,:);
                for l = 1:f_k
                    count_dis = object - miu_numer(l,:);
                    class_distance(l) =  sum(count_dis .* count_dis);
                end
                for l = 1:f_k
                    count_dis = object - miu_numer(l,:);
                    I_distance(l) = central_win_count(l)/sum(central_win_count) * sum(count_dis .* count_dis);
                end
                c = find(I_distance == min(I_distance));

                c = c(1);

                central_win_count(c) = central_win_count(c) + 1;
                %% find the cooperating set
                cooperating_set = [];
                
                dis = zeros(1,f_k);
                for l = 1:f_k
                    cen_dis = miu_numer(l,:) - miu_numer(c,:);    
                    dis(l) = sum(sum(cen_dis .* cen_dis));
                    if(dis(l) <= class_distance(c))    %CCS
                        cooperating_set = [cooperating_set l];
                    end
                end
                cooperating_set = [cooperating_set find(dis <= 0.0001)];
                dis(dis <= 0.0001) = 100;


                cooperating_set = unique(cooperating_set);

                for h = 1:length(cooperating_set)
                    l = cooperating_set(h);
                    miu_numer(l,:) = miu_numer(l,:) + W .* (object - miu_numer(l,:));

                end

                miu_dis_record = 0;
                for l = 1:k
                    miu_dis_record = miu_dis_record + sum(sum(sqrt((miu_numer - miu_record).*(miu_numer - miu_record))));
                end

                if(miu_dis_record <= 0.0001)
                    flag = 1;
                    return 
                end
            end
        end
    end
end