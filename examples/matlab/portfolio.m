clear all

disp('------------------------------------------------------------')
disp('WARNING: this can take a very long time to run.')
disp('It may also crash/run out of memory.')
disp('Set run_cvx = false if you just want to run scs.')
disp('------------------------------------------------------------')

save_results = false;
run_cvx = false;
cvx_use_solver = 'sdpt3';
run_scs_direct = true;
run_scs_indirect = true;

ns = [100000, 1000000, 1000000];
ms = [10, 100, 1000];

density = 0.1;

time_pat_cvx = 'Total CPU time \(secs\)\s*=\s*(?<total>[\d\.]+)';

for i = 1:length(ns)
    seedstr = sprintf('scs_portfolio_ex_%i',i);
    randn('seed',sum(seedstr));rand('seed',sum(seedstr))
    
    n = ns(i);
    m = ms(i);
    
    mu = exp(0.1*randn(n,1));
    D = rand(n,1);
    F = sprandn(n,m,density);
    gamma = 1;
    B = n;
    %%
    if run_scs_direct
        
        tic
        cvx_begin
        cvx_solver scs
        cvx_solver_settings('eps',1e-3,'scale',5)
        variable x(n)
        maximize (mu'*x - gamma*(sum_square(F'*x) + sum_square(D.*x)))
        sum(x) == B
        x >= 0
        if (save_results)
            output = evalc('cvx_end')
        else
            output='';
            cvx_end
        end
        toc
        
        scs_direct.x{i} = x;
        scs_direct.x_viol{i} = min(x);
        scs_direct.budget_viol{i} = abs(1-sum(x));
        scs_direct.obj(i) = (mu'*x - gamma*(sum_square(F'*x) + sum_square(D.*x)));
        scs_direct.output{i} = output;
        
        if (save_results); save('data/portfolio_scs_direct', 'scs_direct'); end
    end
    if run_scs_indirect
        %%
        tic
        cvx_begin
        cvx_solver scs
        cvx_solver_settings('use_indirect',1,'eps',1e-3,'scale',5,'cg_rate',1.5)
        variable x(n)
        maximize (mu'*x - gamma*(sum_square(F'*x) + sum_square(D.*x)))
        sum(x) == B
        x >= 0
        if (save_results)
            output = evalc('cvx_end')
        else
            output='';
            cvx_end
        end
        toc
        
        scs_indirect.x{i} = x;
        scs_indirect.x_viol{i} = min(x);
        scs_indirect.budget_viol{i} = abs(1-sum(x));
        scs_indirect.obj(i) = (mu'*x - gamma*(sum_square(F'*x) + sum_square(D.*x)));
        scs_indirect.output{i} = output;
        
        
        if (save_results); save('data/portfolio_scs_indirect', 'scs_indirect'); end
    end
    %%
    if run_cvx
        try
            tic
            cvx_begin
            cvx_solver(cvx_use_solver)
            variable x(n)
            maximize (mu'*x - gamma*(sum_square(F'*x) + sum_square(D.*x)))
            sum(x) == B
            x >= 0
            if (save_results)
                output = evalc('cvx_end')
            else
                output='';
                cvx_end
            end
            toc
            
            cvx.x{i} = x;
            cvx.x_viol{i} = min(x);
            cvx.budget_viol{i} = abs(1-sum(x));
            cvx.obj(i) = (mu'*x - gamma*(sum_square(F'*x) + sum_square(D.*x)));
            timing = regexp(output, time_pat_cvx, 'names');
            cvx.time{i} = str2num(timing.total);
            cvx.output{i} = output;
            cvx.err{i} = 0;
            
        catch err
            cvx.time{i} = toc;
            cvx.err{i} = err;
        end
        
        if (save_results); save('data/portfolio_cvx', 'cvx'); end
        
    end
end
