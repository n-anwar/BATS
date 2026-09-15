using DifferentialEquations, Sundials, DataFrames, CSV, CairoMakie, Colors
include("detailed_training_program.jl")

## Define functions
"""Run a simulation of the training program"""
function simulate_program(tp::TrainingProgram;n_seasons=4)
    # Calculate the initial condition for bone volume fraction using the steady-state value at trot speed (3.6 m/s)
    ps = p_optimal()
    fBM0 = fBM_ss(joint_stress(3.6),strain_rate_fitted(3.6),A_OBL_max=ps[1][2],A_OCL_max=ps[2][2])

    sys = ODESystem(tp)
    prog_dur = duration(tp)

    t_end = n_seasons*prog_dur
    tspan = (0.0,t_end)
    # prob = ODEProblem(sys,[fBM=>fBM0],tspan,ps,reltol=1e-9,abstol=1e-12)
    prob = ODEProblem(sys, merge(Dict(fBM=>fBM0), Dict(ps)), tspan,reltol=1e-9,abstol=1e-12)
    sol = solve(prob, CVODE_BDF())
    return sol
end


function training_periods(tp::TrainingProgram,n_seasons)
    prog_dur = duration(tp)
    rest_periods = [(i*prog_dur,i*prog_dur+tp.rest_program.duration) for i in 0:(n_seasons-1)]
    pretraining_periods = [(b,b+tp.pretraining_program.duration) for (a,b) in rest_periods]
    progressive_periods = [(b,b+progressive_program_duration(tp)) for (a,b) in pretraining_periods]
    racing_periods = [(b,b+tp.racefit_program.duration) for (a,b) in progressive_periods]
    return (rest_periods,pretraining_periods,progressive_periods,racing_periods,[])
end

function training_periods(tp::ExtendedProgram,n_seasons)
    prog_dur = duration(tp)
    n = tp.num_freshenups
    rest_periods = [(i*prog_dur,i*prog_dur+tp.rest_program.duration) for i in 0:(n_seasons-1)]
    pretraining_periods = [(b,b+duration(tp.pretraining_program)) for (a,b) in rest_periods]
    progressive_periods = [(b,b+progressive_program_duration(tp)) for (a,b) in pretraining_periods]
    start_time = racefit_start_time(tp)
    cycle_length = race_cycle_duration(tp)
    racefit_template = [(start_time+i*cycle_length, start_time+i*cycle_length+duration(tp.racefit_program)) for i in 0:n]
    freshenup_template = [(start_time+(i-1)*cycle_length+duration(tp.racefit_program), start_time+i*cycle_length) for i in 1:n]
    racefit_periods = vcat([[period .+ j*prog_dur for period in racefit_template] for j in 0:(n_seasons-1)]...)
    freshenup_periods = vcat([[period .+ j*prog_dur for period in freshenup_template] for j in 0:(n_seasons-1)]...)
    return (rest_periods,pretraining_periods,progressive_periods,racefit_periods,freshenup_periods)
end


function Trainig_model_R(program_duration_UI::Vector,program_volume_UI::Vector, program_speed_UI::Vector, n_seasons)

    rest_dur =program_duration_UI[1]
    pre_dur = program_duration_UI[2]
    prog_dur = program_duration_UI[3]
    race_dur = program_duration_UI[4]

    rest_dist_pr_day = program_volume_UI[1]
    pre_dist_pr_day = program_volume_UI[2]
    slow_progressive_distance_per_day_start = program_volume_UI[3]
    slow_progressive_distance_per_day_end = program_volume_UI[4]
    fast_progressive_speed1 = program_volume_UI[5]
    fast_progressive_speed2 = program_volume_UI[6]

    racefit_slow_gallop_distance_per_day=program_volume_UI[7]
    racefit_fast_gallop_distance_per_day=program_volume_UI[8]
    racefit_race_distance_per_day = program_volume_UI[9]

    slow_workout_distance_per_day = program_volume_UI[10]

    

    rest_speed = program_speed_UI[1]
    pretraining_speed = program_speed_UI[2]
    slow_progressive_speed_start = program_speed_UI[3]
    slow_progressive_speed_end = program_speed_UI[4]
    fast_progressive_speed1 = program_speed_UI[5]
    fast_progressive_speed2 = program_speed_UI[6]
    racefit_slow_gallop_speed = program_speed_UI[7]
    racefit_fast_gallop_speed = program_speed_UI[8]
    racefit_race_speed = program_speed_UI[9]

    slow_workout_speed = program_speed_UI[10]

    tp = construct_training_program(
            rest_duration = rest_dur,
            pretraining_duration = pre_dur,
            slow_progressive_duration = 0.4*prog_dur,
            fast_progressive_duration = 0.6*prog_dur,
            racefit_duration = race_dur,
            # 
            rest_distance_per_day = rest_dist_pr_day,
            pretraining_distance_per_day = pre_dist_pr_day,
            slow_progressive_distance_per_day_start = slow_progressive_distance_per_day_start,
            slow_progressive_distance_per_day_end = slow_progressive_distance_per_day_end,
            # racefit_slow_gallop_distance_per_day=4800/30, racefit_fast_gallop_distance_per_day=3200/30, racefit_race_distance_per_day=800/7,
            racefit_slow_gallop_distance_per_day=racefit_slow_gallop_distance_per_day,
            racefit_fast_gallop_distance_per_day= racefit_fast_gallop_distance_per_day,
            racefit_race_distance_per_day = racefit_race_distance_per_day,

            
            slow_workout_distance_per_day = slow_workout_distance_per_day,

            # 
            rest_speed=rest_speed,
            pretraining_speed=pretraining_speed,
            slow_progressive_speed_start=slow_progressive_speed_start,
            slow_progressive_speed_end=slow_progressive_speed_end,
            fast_progressive_speed1=fast_progressive_speed1,
            fast_progressive_speed2=fast_progressive_speed2,
            racefit_slow_gallop_speed = racefit_slow_gallop_speed,
            racefit_fast_gallop_speed = racefit_fast_gallop_speed,
            racefit_race_speed = racefit_race_speed,
            
            
            slow_workout_speed = slow_workout_speed


        )
    # println(tp)
    sol = simulate_program(tp,n_seasons=n_seasons)   

    sols_R= DataFrame(t=sol.t,fBM=sol[fBM], dmg=sol[dmg])
    


    # fill_color=["#8dd3c7", "#bebada","#ffffb3", "#fb8072","#80b1d3"]
    fill_color=["#99daff", "#C1E9DE","#ffe099", "#e3b5ce","#80b1d3"]  #80% saturation
    # fill_color=["#33b5ff", "#C1E9DE","#ffc033", "#c76b9e","#80b1d3"]  #60% saturation
    df_changes = DataFrame(phase=Int[],preparation=Int[],dmg_min=Float64[],dmg_max=Float64[],fBM_change=Float64[],dmg_change=Float64[],start_time=Float64[],end_time=Float64[],my_color=String[])

    (r_periods,pre_periods,prog_periods,rac_periods) = training_periods(tp,n_seasons)
        for j in 1:n_seasons
            t_start = (j-1)*duration(tp)
            t_end = j*duration(tp)
            (fBM_start,dmg_start) = sol(t_start,idxs=[fBM,dmg])                                                                                                 

            (fBM_rest,dmg_rest) = sol(t_start + pretraining_start_time(tp),idxs=[fBM,dmg])
            # fBM_min_rest = minimum(sol(t_start:.1:t_start + pretraining_start_time(tp),idxs=[fBM]))
            # fBM_max_rest = maximum(sol(t_start:.1:t_start + pretraining_start_time(tp),idxs=[fBM]))
            dmg_min_rest = minimum(sol(t_start:.1:t_start + pretraining_start_time(tp),idxs=[dmg]))
            dmg_max_rest = maximum(sol(t_start:.1:t_start + pretraining_start_time(tp),idxs=[dmg]))

            (fBM_pretrain,dmg_pretrain) = sol(t_start + slow_progressive_start_time(tp),idxs=[fBM,dmg])
            dmg_min_pre = minimum(sol(t_start + pretraining_start_time(tp):.1:t_start + slow_progressive_start_time(tp),idxs=[dmg]))
            dmg_max_pre = maximum(sol(t_start + pretraining_start_time(tp):.1:t_start + slow_progressive_start_time(tp),idxs=[dmg]))

            (fBM_prog,dmg_prog) = sol(t_start + racefit_start_time(tp),idxs=[fBM,dmg])
            dmg_min_prog = minimum(sol(t_start + slow_progressive_start_time(tp):.1:t_start + racefit_start_time(tp),idxs=[dmg]))
            dmg_max_prog = maximum(sol(t_start + slow_progressive_start_time(tp):.1:t_start + racefit_start_time(tp),idxs=[dmg]))

            (fBM_end,dmg_end) = sol(t_end,idxs=[fBM,dmg])
            dmg_min_rac = minimum(sol(t_start + racefit_start_time(tp):.1:t_end,idxs=[dmg]))
            dmg_max_rac = maximum(sol(t_start + racefit_start_time(tp):.1:t_end,idxs=[dmg]))

            dmg_min_all = minimum(sol(t_start:.1:t_end,idxs=[dmg]))
            dmg_max_all = maximum(sol(t_start:.1:t_end,idxs=[dmg]))

            df_app1 = DataFrame(phase=1, preparation=j,dmg_min=dmg_min_rest,dmg_max=dmg_max_rest, fBM_change=[fBM_rest-fBM_start], dmg_change=[dmg_rest-dmg_start],start_time=r_periods[Int(j)][1],end_time=r_periods[Int(j)][2],my_color=fill_color[1])
            df_app2 = DataFrame(phase=2, preparation=j,dmg_min=dmg_min_pre,dmg_max=dmg_max_pre, fBM_change=[fBM_pretrain-fBM_rest], dmg_change=[dmg_pretrain-dmg_rest],start_time=pre_periods[Int(j)][1],end_time=pre_periods[Int(j)][2],my_color=fill_color[2])
            df_app3 = DataFrame(phase=3, preparation=j,dmg_min=dmg_min_prog,dmg_max=dmg_max_prog, fBM_change=[fBM_prog-fBM_pretrain], dmg_change=[dmg_prog-dmg_pretrain],start_time=prog_periods[Int(j)][1],end_time=prog_periods[Int(j)][2],my_color=fill_color[3])
            df_app4 = DataFrame(phase=4, preparation=j,dmg_min=dmg_min_rac,dmg_max=dmg_max_rac, fBM_change=[fBM_end-fBM_prog], dmg_change=[dmg_end-dmg_prog],start_time=rac_periods[Int(j)][1],end_time=rac_periods[Int(j)][2],my_color=fill_color[4])
            df_app5 = DataFrame(phase=5, preparation=j,dmg_min=dmg_min_all,dmg_max=dmg_max_all, fBM_change=[fBM_end-fBM_start], dmg_change=[dmg_end-dmg_start],start_time=t_start,end_time=t_end,my_color=fill_color[5])
            append!(df_changes,df_app1,df_app2,df_app3,df_app4,df_app5)

        end
    # 

    tp_ave = construct_training_program()
    sol_ave = simulate_program(tp_ave,n_seasons=n_seasons)   
    sols_R_ave= DataFrame(t=sol_ave.t,fBM=sol_ave[fBM], dmg=sol_ave[dmg])

    result =(sols_R=sols_R, df_changes=df_changes, sols_R_ave=sols_R_ave)
    return result
end


