function  GWO_result=GWO_Find(FunctionName,TH_num,RunTimes,MAX_Iterations)
% function GWO_result=GWO_Find(FunctionName,TH_num,RunTimes,MAX_Iterations)
%    The Grey Wolf Optimizer,proposed by S. Mirjalili, S. M. Mirjalili, A. Lewis   in 2013
%    Main paper:  Grey Wolf Optimizer, Advances in Engineering Software, in press,DOI: 10.1016/j.advengsoft.2013.12.007    
%    Calculating the maximum Kapur_Entropy/Between-Variance use the Grey Wolf Optimizer
% Input:
%    FunctionName:the optimized method---Kapur_Entropy/Otsu
%    TH_num:number of thresholds
%    RunTimes:the Repeat Algorithm Running Times
%    MAX_Iterations:
% Output:
%    GWO_result: is a 'Struct' containing the following result information
%        GWO_result.Fitness:
%            GWO_result.Fitness.Mean
%            GWO_result.Fitness.Variance
%            GWO_result.Fitness.Max
%            GWO_result.Fitness.Min
%        GWO_result.Success_Rate=sum(Success_FindBest_Num)/RunTimes;
%        GWO_result.BestThresholds: a vector containing 'TH_num' values
%        GWO_result.EachRunConvergenceTime:a vector containing 'RunTimes' values
%        GWO_result.MeanConvergenceTime: the mean convergence time

disp('the Grey Wolf Optimizer is running...')

%% GWO STEPS
% STEP ONE
% Initialize the GWO parameters
global LP nd st BEST_EXHAUSTIVE_FITNESS EPS Gray_image TH_Char ImageName Alg_Name;
fitness=FunctionName;
T=MAX_Iterations;
D=TH_num;
N=40;

%% 预分配内存
%记录结果
GWO_result.EachRunBestThresholds=zeros(RunTimes,TH_num);
GWO_result.EachRunBestFitness=zeros(1,RunTimes);
GWO_result.BestThresholds=zeros(1,TH_num);
GWO_result.EachRunConvergenceTime=zeros(1,RunTimes);
GWO_result.EachRunConvergenceFunCalNum=zeros(1,RunTimes);
GWO_result.EachRunEveryIterBestFitness=zeros(RunTimes,T);
GWO_result.EachRunEveryIterConvergenceTime=zeros(RunTimes,T);
%% 最外层循环，让GWO跑RunTimes次
Success_FindBest_Index=zeros(1,RunTimes);

for RepeatTimes=1:RunTimes
    rng(sum(RepeatTimes*nd*3000), 'twister');
    
    tic
    FunCount=0;
    EachRunFunCalNum=zeros(1,T);
    % STEP TWO
    % initialize alpha, beta, and delta_pos
    Alpha_pos=zeros(1,D);
    Alpha_score=inf; %change this to -inf for maximization problems
    Beta_pos=zeros(1,D);
    Beta_score=inf; %change this to -inf for maximization problems
    Delta_pos=zeros(1,D);
    Delta_score=inf; %change this to -inf for maximization problems
    
    %------Initialize the GWO swarm's position and velocity------------
    x=zeros(N,D);
    for i=1:N
        for j=1:D
            x(i,j)=(j-1)*floor(nd/D)+floor(rand*floor(nd/D));           %randomized position                               
        end
    end

    % STEP THREE
    %------the GWO main iterations ------------
    Each_Iterate_BestFitness=zeros(1,T);
    Each_Iterate_BestThresholds=zeros(T,D);
    Iterates=1;
    Success_FindBest_Index(RepeatTimes)=0;
    while(~Success_FindBest_Index(RepeatTimes) && Iterates<=T)  
        
        for i=1:N 
           % Return back the search agents that go beyond the boundaries of the search space
            Flag4ub=x(i,:)>nd;
            Flag4lb=x(i,:)<st;
            x(i,:)=(x(i,:).*(~(Flag4ub+Flag4lb)))+nd.*Flag4ub+st.*Flag4lb;               
            x(i,:)=round(x(i,:));
            % Calculate objective function for each search agent
            Fit=1/fitness(LP,x(i,:));
            FunCount=FunCount+1;
            % Update Alpha, Beta, and Delta
            if Fit<Alpha_score 
                Alpha_score=Fit; % Update alpha
                Alpha_pos=x(i,:);
            end
            if Fit>Alpha_score && Fit<Beta_score 
                Beta_score=Fit; % Update beta
                Beta_pos=x(i,:);
            end
            if Fit>Alpha_score && Fit>Beta_score && Fit<Delta_score 
                Delta_score=Fit; % Update delta
                Delta_pos=x(i,:);
            end
        end
        
        % iterations
        Each_Iterate_BestFitness(Iterates)=Alpha_score;
        Each_Iterate_BestThresholds(Iterates,:)=Alpha_pos;
        if (abs(fitness(LP,Each_Iterate_BestThresholds(Iterates,:))-BEST_EXHAUSTIVE_FITNESS)<=EPS)
            GWO_result.EachRunEveryIterConvergenceTime(RepeatTimes,Iterates)=toc;
            EachRunFunCalNum(Iterates)=FunCount;
            Success_FindBest_Index(RepeatTimes)=1;
            break;
        end      
        
        a=2-Iterates*((2)/MAX_Iterations);  % a decreases linearly fron 2 to 0   
        % Update the Position of search agents including omegas
        for i=1:N
            for j=1:D   

                r1=rand();  % r1 is a random number in [0,1]
                r2=rand();  % r2 is a random number in [0,1]
                A1=2*a*r1-a;    % Equation (3.3)
                C1=2*r2;        % Equation (3.4)   
                D_alpha=abs(C1*Alpha_pos(j)-x(i,j));    % Equation (3.5)-part 1
                X1=Alpha_pos(j)-A1*D_alpha;             % Equation (3.6)-part 1

                r1=rand();
                r2=rand();
                A2=2*a*r1-a;    % Equation (3.3)
                C2=2*r2;        % Equation (3.4)
                D_beta=abs(C2*Beta_pos(j)-x(i,j));  % Equation (3.5)-part 2
                X2=Beta_pos(j)-A2*D_beta;           % Equation (3.6)-part 2       

                r1=rand();
                r2=rand(); 
                A3=2*a*r1-a;    % Equation (3.3)
                C3=2*r2;        % Equation (3.4)
                D_delta=abs(C3*Delta_pos(j)-x(i,j));    % Equation (3.5)-part 3
                X3=Delta_pos(j)-A3*D_delta;             % Equation (3.5)-part 3             

                x(i,j)=(X1+X2+X3)/3;    % Equation (3.7)

            end
        end
    
        GWO_result.EachRunEveryIterConvergenceTime(RepeatTimes,Iterates)=toc;
        EachRunFunCalNum(Iterates)=FunCount;
        Iterates=Iterates+1;
    end % End "while(~Success_FindBest_Index(RepeatTimes) || Iterates<=T)"   
    
%% 记录实验结果
    Each_Iterate_BestFitness(Each_Iterate_BestFitness==0)=10.^9;        %去除零元素
    GWO_result.EachRunEveryIterBestFitness(RepeatTimes,:)=1./Each_Iterate_BestFitness;
    [~,MinFitIndex]=min(Each_Iterate_BestFitness);
    GWO_result.EachRunBestFitness(RepeatTimes)=fitness(LP,Each_Iterate_BestThresholds(MinFitIndex,:));
    GWO_result.EachRunBestThresholds(RepeatTimes,:)=Each_Iterate_BestThresholds(MinFitIndex,:);
    GWO_result.EachRunConvergenceTime(RepeatTimes)=GWO_result.EachRunEveryIterConvergenceTime(RepeatTimes,MinFitIndex);
    GWO_result.EachRunConvergenceFunCalNum(RepeatTimes)=EachRunFunCalNum(MinFitIndex);
end % End "for RepeatTimes=1:RunTimes"
    
disp('Statistic Metrics is Calculating...')
%% 统计实验结果
    % 计算适应度值并统计
    [GWO_result.Fitness.Max,GWOFMax_Index]=max(GWO_result.EachRunBestFitness);
    [GWO_result.Fitness.Min,~]=min(GWO_result.EachRunBestFitness);
    GWO_result.Fitness.Mean=mean(GWO_result.EachRunBestFitness);
    GWO_result.Fitness.Variance=var(GWO_result.EachRunBestFitness);
    GWO_result.BestThresholds=sort(GWO_result.EachRunBestThresholds(GWOFMax_Index,:));
    % 计算“成功查找率”,“平均每次实验收敛时间”并统计
    GWO_result.Success_Rate=sum(Success_FindBest_Index)/RunTimes;
    GWO_result.MeanConvergenceTime=mean(GWO_result.EachRunConvergenceTime);
    
disp('Statistic Metrics is Calculated !')

% 保存PSO结果：ImageNmae_THChar_GWO_result.mat
    FILENAME=strcat(Alg_Name,'_',ImageName,'_',TH_Char,'_GWO_result.mat');
    save(FILENAME,'GWO_result');     

disp('the Grey Wolf Optimizer is accomplised !!!')



end