include("bone_adaptation_model.jl")

pulse(x,a,b) = (a<x)*(x<=b)
ramp(x,a,b) = (x-a)*pulse(x,a,b)
σ0_fitted = p_optimal()[3][2]
adjusted_damage(distance,speed,σ0=σ0_fitted) = damage(distance,max(1.6,speed),σ0=σ0)

###here, the output from adjusted_damage() is just the damage formation rate 

abstract type TrainingPhase end
abstract type AbstractRepeatedProgram end

struct HomogeneousProgram <: TrainingPhase
    duration::Float64
    distance_per_day::Float64
    speed::Float64
end
duration(hp::HomogeneousProgram) = hp.duration
speedfunc(hp::HomogeneousProgram) = t -> hp.speed*pulse(t,0,duration(hp))
distancefunc(hp::HomogeneousProgram) = t -> hp.distance_per_day*pulse(t,0,duration(hp))
damagefunc(hp::TrainingPhase;σ0=σ0_fitted) = t -> adjusted_damage(distancefunc(hp)(t),speedfunc(hp)(t),σ0)

struct SlowProgressiveProgram <: TrainingPhase
    duration::Float64
    distance_per_day_start::Float64
    distance_per_day_end::Float64
    speed_start::Float64
    speed_end::Float64
end
duration(spp::SlowProgressiveProgram) = spp.duration
speedfunc(spp::SlowProgressiveProgram) = t -> (
    spp.speed_start*pulse(t,0,duration(spp)) + 
    (spp.speed_end-spp.speed_start)/duration(spp)*ramp(t,0,duration(spp))
)
distancefunc(spp::SlowProgressiveProgram) = t -> (
    spp.distance_per_day_start*pulse(t,0,duration(spp)) + 
    (spp.distance_per_day_end-spp.distance_per_day_start)/duration(spp)*ramp(t,0,duration(spp))
)

struct FastProgressiveProgram <: TrainingPhase
    duration::Float64
    cumulative_distance1::Float64
    cumulative_distance2::Float64
    speed1::Float64
    speed2::Float64
end
duration(fpp::FastProgressiveProgram) = fpp.duration
speedfunc1(fpp::FastProgressiveProgram) = t -> fpp.speed1*pulse(t,0,duration(fpp))
speedfunc2(fpp::FastProgressiveProgram) = t -> fpp.speed2*pulse(t,0,duration(fpp))
speedfunc(fpp::FastProgressiveProgram) = t -> max(speedfunc1(fpp)(t), speedfunc2(fpp)(t))
total_distance(fpp::FastProgressiveProgram) = (fpp.cumulative_distance1+fpp.cumulative_distance2)/duration(fpp) #Total distance covered per day
final_distance2(fpp::FastProgressiveProgram) = fpp.cumulative_distance2*2/duration(fpp) # per day ############## using triangle rule ()
distancefunc1(fpp::FastProgressiveProgram) = t -> total_distance(fpp)*pulse(t,0,duration(fpp)) - distancefunc2(fpp)(t)
distancefunc2(fpp::FastProgressiveProgram) = t -> final_distance2(fpp)/duration(fpp)*ramp(t,0,duration(fpp))
distancefunc(fpp::FastProgressiveProgram) = t -> distancefunc1(fpp)(t) + distancefunc2(fpp)(t)
damagefunc1(fpp::FastProgressiveProgram;σ0=σ0_fitted) = t -> adjusted_damage(distancefunc1(fpp)(t),speedfunc1(fpp)(t),σ0)
damagefunc2(fpp::FastProgressiveProgram;σ0=σ0_fitted) = t -> adjusted_damage(distancefunc2(fpp)(t),speedfunc2(fpp)(t),σ0)
damagefunc(fpp::FastProgressiveProgram;σ0=σ0_fitted) = t -> damagefunc1(fpp,σ0=σ0)(t) + damagefunc2(fpp,σ0=σ0)(t)

struct RacefitProgram <: TrainingPhase
    duration::Float64
    slow_gallop_distance_per_day::Float64
    fast_gallop_distance_per_day::Float64
    race_distance_per_day::Float64
    slow_gallop_speed::Float64
    fast_gallop_speed::Float64
    race_speed::Float64
end
duration(rp::RacefitProgram) = rp.duration
slowgallop_program(rp::RacefitProgram) = HomogeneousProgram(duration(rp),rp.slow_gallop_distance_per_day,rp.slow_gallop_speed)
fastgallop_program(rp::RacefitProgram) = HomogeneousProgram(duration(rp),rp.fast_gallop_distance_per_day,rp.fast_gallop_speed)
race_program(rp::RacefitProgram) = HomogeneousProgram(duration(rp),rp.race_distance_per_day,rp.race_speed)
speedfunc(rp::RacefitProgram) = t -> rp.race_speed*pulse(t,0,duration(rp))
slowgallop_distancefunc(rp::RacefitProgram) = distancefunc(slowgallop_program(rp))
fastgallop_distancefunc(rp::RacefitProgram) = distancefunc(fastgallop_program(rp))
race_distancefunc(rp::RacefitProgram) = distancefunc(race_program(rp))
distancefunc(rp::RacefitProgram) = t -> slowgallop_distancefunc(rp)(t) + fastgallop_distancefunc(rp)(t) + race_distancefunc(rp)(t)
slowgallop_damagefunc(rp::RacefitProgram;σ0=σ0_fitted) = damagefunc(slowgallop_program(rp),σ0=σ0)
fastgallop_damagefunc(rp::RacefitProgram;σ0=σ0_fitted) = damagefunc(fastgallop_program(rp),σ0=σ0)
race_damagefunc(rp::RacefitProgram;σ0=σ0_fitted) = damagefunc(race_program(rp),σ0=σ0)
damagefunc(rp::RacefitProgram;σ0=σ0_fitted) = t -> slowgallop_damagefunc(rp,σ0=σ0)(t) + fastgallop_damagefunc(rp,σ0=σ0)(t) + race_damagefunc(rp,σ0=σ0)(t)

struct TrainingProgram <: AbstractRepeatedProgram
    rest_program::HomogeneousProgram
    pretraining_program::HomogeneousProgram
    slow_progressive_program::SlowProgressiveProgram
    fast_progressive_program::FastProgressiveProgram
    racefit_program::RacefitProgram
    slow_workout::HomogeneousProgram
end
progressive_program_duration(tp::AbstractRepeatedProgram) = duration(tp.slow_progressive_program) + duration(tp.fast_progressive_program)
duration(tp::TrainingProgram) = duration(tp.rest_program) + duration(tp.pretraining_program) + progressive_program_duration(tp) + duration(tp.racefit_program)
rest_start_time(tp::AbstractRepeatedProgram) = 0
pretraining_start_time(tp::AbstractRepeatedProgram) = duration(tp.rest_program)
slow_progressive_start_time(tp::AbstractRepeatedProgram) = pretraining_start_time(tp) + duration(tp.pretraining_program)
fast_progressive_start_time(tp::AbstractRepeatedProgram) = slow_progressive_start_time(tp) + duration(tp.slow_progressive_program)
racefit_start_time(tp::AbstractRepeatedProgram) = fast_progressive_start_time(tp) + duration(tp.fast_progressive_program)
speedfunc(tp::TrainingProgram) = t -> (
    tp.rest_program.speed*pulse(t,-Inf,0) +
    speedfunc(tp.rest_program)(t) + 
    speedfunc(tp.pretraining_program)(t-pretraining_start_time(tp)) + 
    speedfunc(tp.slow_progressive_program)(t-slow_progressive_start_time(tp)) + 
    speedfunc(tp.fast_progressive_program)(t-fast_progressive_start_time(tp)) + 
    speedfunc(tp.racefit_program)(t-racefit_start_time(tp))
)
rest_distancefunc(tp::AbstractRepeatedProgram) = t -> distancefunc(tp.rest_program)(t-rest_start_time(tp))
pretraining_distancefunc(tp::AbstractRepeatedProgram) = t -> distancefunc(tp.pretraining_program)(t-pretraining_start_time(tp))
slowprogressive_distancefunc(tp::AbstractRepeatedProgram) = t -> distancefunc(tp.slow_progressive_program)(t-slow_progressive_start_time(tp))
fastprogressive_distancefunc(tp::AbstractRepeatedProgram) = t -> distancefunc(tp.fast_progressive_program)(t-fast_progressive_start_time(tp))
racefit_distancefunc(tp::AbstractRepeatedProgram) = t -> distancefunc(tp.racefit_program)(t-racefit_start_time(tp))
slowworkout_distancefunc(tp::AbstractRepeatedProgram) = t -> distancefunc(tp.slow_workout)(t-slow_progressive_start_time(tp))
distancefunc(tp::TrainingProgram) = t -> (
    tp.rest_program.distance_per_day*pulse(t,-Inf,0) + rest_distancefunc(tp)(t) + pretraining_distancefunc(tp)(t) + 
    slowprogressive_distancefunc(tp)(t) + fastprogressive_distancefunc(tp)(t) + racefit_distancefunc(tp)(t) +
    slowworkout_distancefunc(tp)(t)
)
gallop_distancefunc(tp::TrainingProgram) = t -> (
    distancefunc1(tp.fast_progressive_program)(t-fast_progressive_start_time(tp)) +
    slowgallop_distancefunc(tp.racefit_program)(t-racefit_start_time(tp))
)
racespeed_distancefunc(tp::TrainingProgram) = t -> (
    distancefunc2(tp.fast_progressive_program)(t-fast_progressive_start_time(tp)) +
    fastgallop_distancefunc(tp.racefit_program)(t-racefit_start_time(tp)) +
    race_distancefunc(tp.racefit_program)(t-racefit_start_time(tp))
)
rest_damagefunc(tp::AbstractRepeatedProgram) = (t,σ0) -> damagefunc(tp.rest_program,σ0=σ0)(t-rest_start_time(tp))
pretraining_damagefunc(tp::AbstractRepeatedProgram) = (t,σ0) -> damagefunc(tp.pretraining_program,σ0=σ0)(t-pretraining_start_time(tp))
slowprogressive_damagefunc(tp::AbstractRepeatedProgram) = (t,σ0) -> damagefunc(tp.slow_progressive_program,σ0=σ0)(t-slow_progressive_start_time(tp))
fastprogressive_damagefunc(tp::AbstractRepeatedProgram) = (t,σ0) -> damagefunc(tp.fast_progressive_program,σ0=σ0)(t-fast_progressive_start_time(tp))
racefit_damagefunc(tp::AbstractRepeatedProgram) = (t,σ0) -> damagefunc(tp.racefit_program,σ0=σ0)(t-racefit_start_time(tp))
slowworkout_damagefunc(tp::AbstractRepeatedProgram) = (t,σ0) -> damagefunc(tp.slow_workout,σ0=σ0)(t-slow_progressive_start_time(tp))
damagefunc(tp::TrainingProgram;σ0=σ0_fitted) = t -> (
    adjusted_damage(tp.rest_program.distance_per_day,tp.rest_program.speed,σ0)*pulse(t,-Inf,0) +
    rest_damagefunc(tp)(t,σ0) + pretraining_damagefunc(tp)(t,σ0) + slowprogressive_damagefunc(tp)(t,σ0) +
    fastprogressive_damagefunc(tp)(t,σ0) + racefit_damagefunc(tp)(t,σ0) + slowworkout_damagefunc(tp)(t,σ0)
)
canter_damagefunc(tp::TrainingProgram) = t -> slowworkout_damagefunc(tp)(t,σ0_fitted)
transitionspeed_damagefunc(tp::TrainingProgram) = t -> slowprogressive_damagefunc(tp)(t,σ0_fitted)
gallop_damagefunc(tp::TrainingProgram;σ0=σ0_fitted) = t -> (
    damagefunc1(tp.fast_progressive_program,σ0=σ0)(t-fast_progressive_start_time(tp)) +
    slowgallop_damagefunc(tp.racefit_program,σ0=σ0)(t-racefit_start_time(tp))
)
racespeed_damagefunc(tp::TrainingProgram;σ0=σ0_fitted) = t -> (
    damagefunc2(tp.fast_progressive_program,σ0=σ0)(t-fast_progressive_start_time(tp)) +
    fastgallop_damagefunc(tp.racefit_program,σ0=σ0)(t-racefit_start_time(tp)) +
    race_damagefunc(tp.racefit_program,σ0=σ0)(t-racefit_start_time(tp))
)
multiseason(tp::AbstractRepeatedProgram,f::Function) = t -> f(tp)(rem(t,duration(tp)))

function construct_training_program(;
    rest_duration=44, rest_distance_per_day=4000, rest_speed=3.6,
    pretraining_duration=4*7, pretraining_distance_per_day=2000, pretraining_speed=7.5,
    slow_progressive_duration=4*7,slow_progressive_distance_per_day_start=900/7, slow_progressive_distance_per_day_end=1800/7,
    slow_progressive_speed_start=11.8,slow_progressive_speed_end=13.8,
    fast_progressive_duration=38, fast_progressive_cumulative_distance1=6600, fast_progressive_cumulative_distance2=3200,
    fast_progressive_speed1=13.8, fast_progressive_speed2=16.0,
    racefit_duration=4*2*7, racefit_slow_gallop_distance_per_day=4800/30, racefit_fast_gallop_distance_per_day=3200/30, racefit_race_distance_per_day=800/7,
    racefit_slow_gallop_speed=13.8, racefit_fast_gallop_speed=16.0, racefit_race_speed=16.7,
    slow_workout_distance_per_day=2000, slow_workout_speed=7.5
    )

    rest = HomogeneousProgram(rest_duration,rest_distance_per_day,rest_speed)
    pretraining = HomogeneousProgram(pretraining_duration,pretraining_distance_per_day,pretraining_speed)
    slow_progressive = SlowProgressiveProgram(
        slow_progressive_duration,
        slow_progressive_distance_per_day_start,
        slow_progressive_distance_per_day_end,
        slow_progressive_speed_start,
        slow_progressive_speed_end
    )
    fast_progressive = FastProgressiveProgram(
        fast_progressive_duration,
        fast_progressive_cumulative_distance1,
        fast_progressive_cumulative_distance2,
        fast_progressive_speed1,
        fast_progressive_speed2
    )
    racefit = RacefitProgram(
        racefit_duration,
        racefit_slow_gallop_distance_per_day,
        racefit_fast_gallop_distance_per_day,
        racefit_race_distance_per_day,
        racefit_slow_gallop_speed,
        racefit_fast_gallop_speed,
        racefit_race_speed
    )
    slow_workout_duration = slow_progressive_duration + fast_progressive_duration + racefit_duration
    slow_workout = HomogeneousProgram(slow_workout_duration,slow_workout_distance_per_day,slow_workout_speed)
    tp = TrainingProgram(rest,pretraining,slow_progressive,fast_progressive,racefit,slow_workout)
    return tp
end

function ModelingToolkit.ODESystem(tp::AbstractRepeatedProgram)
    multiseason_speed = multiseason(tp,speedfunc)
    multiseason_damage = multiseason(tp,damagefunc)
    f_σ(t) = joint_stress(multiseason_speed(t))
    f_ϵ(t) = strain_rate_fitted(multiseason_speed(t))
    f_Dr(t) = multiseason_damage(t)
    sys = bone_adaptation_system((f_σ,f_ϵ,f_Dr),damage_input=true)
    return sys
end



struct ExtendedProgram <: AbstractRepeatedProgram
    rest_program::HomogeneousProgram
    pretraining_program::HomogeneousProgram
    slow_progressive_program::SlowProgressiveProgram
    fast_progressive_program::FastProgressiveProgram
    racefit_program::RacefitProgram
    freshenup_program::TrainingPhase
    slow_workout::HomogeneousProgram
    num_freshenups::Int
    slow_workout_pause::Float64 #duration of slow_workout_pause
end
duration(tp::ExtendedProgram) = duration(tp.rest_program) + duration(tp.pretraining_program) + progressive_program_duration(tp) + (tp.num_freshenups+1)*duration(tp.racefit_program) + tp.num_freshenups*duration(tp.freshenup_program)
rest_start_time(tp::ExtendedProgram) = 0
freshenup_start_time(tp::ExtendedProgram) = racefit_start_time(tp) + duration(tp.racefit_program)
race_cycle_duration(tp::ExtendedProgram) = duration(tp.racefit_program) + duration(tp.freshenup_program)
race_cycle_speed_func(tp::ExtendedProgram) = t -> speedfunc(tp.freshenup_program)(t) + speedfunc(tp.racefit_program)(t-duration(tp.freshenup_program))  # the first racefit_prog is. not part of the cycle. each cycle is freshen_up+racefit
speedfunc(tp::ExtendedProgram) = t -> (
    tp.rest_program.speed*pulse(t,-Inf,0) +
    speedfunc(tp.rest_program)(t) + 
    speedfunc(tp.pretraining_program)(t-pretraining_start_time(tp)) +
    speedfunc(tp.slow_progressive_program)(t-slow_progressive_start_time(tp)) + 
    speedfunc(tp.fast_progressive_program)(t-fast_progressive_start_time(tp)) + 
    speedfunc(tp.racefit_program)(t-racefit_start_time(tp)) +
    sum(race_cycle_speed_func(tp)(t - freshenup_start_time(tp) - i*race_cycle_duration(tp)) for i in 0:tp.num_freshenups-1)
)
race_cycle_distancefunc(tp::ExtendedProgram) = t -> distancefunc(tp.freshenup_program)(t) + distancefunc(tp.racefit_program)(t-duration(tp.freshenup_program))
slowworkout_distancefunc(tp::ExtendedProgram) = t -> (
    distancefunc(tp.slow_workout)(t-slow_progressive_start_time(tp)) * 
    prod(1-pulse(t,freshenup_start_time(tp)+i*race_cycle_duration(tp),freshenup_start_time(tp)+i*race_cycle_duration(tp)+tp.slow_workout_pause) for i in 0:tp.num_freshenups-1)
)

distancefunc(tp::ExtendedProgram) = t -> (
    tp.rest_program.distance_per_day*pulse(t,-Inf,0) + rest_distancefunc(tp)(t) + pretraining_distancefunc(tp)(t) + 
    slowprogressive_distancefunc(tp)(t) + fastprogressive_distancefunc(tp)(t) + racefit_distancefunc(tp)(t) +
    slowworkout_distancefunc(tp)(t) +
    sum(race_cycle_distancefunc(tp)(t - freshenup_start_time(tp) - i*race_cycle_duration(tp)) for i in 0:tp.num_freshenups-1)
)

slowworkout_damagefunc(tp::ExtendedProgram) = (t,σ0) -> (
    damagefunc(tp.slow_workout,σ0=σ0)(t-slow_progressive_start_time(tp)) * 
    prod(1-pulse(t,freshenup_start_time(tp)+i*race_cycle_duration(tp),freshenup_start_time(tp)+i*race_cycle_duration(tp)+tp.slow_workout_pause) for i in 0:tp.num_freshenups-1)
)
race_cycle_damagefunc(tp::ExtendedProgram) = (t,σ0) -> damagefunc(tp.freshenup_program,σ0=σ0)(t) + damagefunc(tp.racefit_program,σ0=σ0)(t-duration(tp.freshenup_program))
damagefunc(tp::ExtendedProgram;σ0=σ0_fitted) = t -> (
    adjusted_damage(tp.rest_program.distance_per_day,tp.rest_program.speed,σ0)*pulse(t,-Inf,0) + 
    rest_damagefunc(tp)(t,σ0) + pretraining_damagefunc(tp)(t,σ0) + slowprogressive_damagefunc(tp)(t,σ0) +
    fastprogressive_damagefunc(tp)(t,σ0) + racefit_damagefunc(tp)(t,σ0) + slowworkout_damagefunc(tp)(t,σ0) +
    sum(race_cycle_damagefunc(tp)(t-freshenup_start_time(tp)-i*race_cycle_duration(tp),σ0) for i in 0:tp.num_freshenups-1)
)

short_freshenup(duration=14) = HomogeneousProgram(duration,1800/7,11.8)

struct LongFreshenup <: TrainingPhase
    program_rest::HomogeneousProgram
    program_canter::HomogeneousProgram
    program_gallop::HomogeneousProgram
end
long_freshenup() = LongFreshenup(
    HomogeneousProgram(14,2000,6), # increased to trot/canter speed (6 m/s) [previous speed = 3.6 m/s], new distance per week = 2000 [previous = 4000]
    HomogeneousProgram(7,2000,7.5),
    HomogeneousProgram(7,1800/7,11.8)
)
duration(tp::LongFreshenup) = duration(tp.program_rest)+ duration(tp.program_canter) + duration(tp.program_gallop)
canter_start_time(tp::LongFreshenup) = duration(tp.program_rest)
gallop_start_time(tp::LongFreshenup) = canter_start_time(tp::LongFreshenup) + duration(tp.program_canter)
speedfunc(tp::LongFreshenup) = t -> speedfunc(tp.program_rest)(t) + speedfunc(tp.program_canter)(t-canter_start_time(tp)) + speedfunc(tp.program_gallop)(t-gallop_start_time(tp))
distancefunc(tp::LongFreshenup) = t -> distancefunc(tp.program_rest)(t) + distancefunc(tp.program_canter)(t-canter_start_time(tp)) + distancefunc(tp.program_gallop)(t-gallop_start_time(tp))

function construct_extended_training_program(;
    rest_duration=6*7, rest_distance_per_day=4000, rest_speed=3.6,
    pretraining_duration=4*7, pretraining_distance_per_day=2000, pretraining_speed=7.5,
    progressive_duration = 10*7,slow_progressive_distance_per_day_start=900/7, slow_progressive_distance_per_day_end=1800/7,
    slow_progressive_speed_start=11.8,slow_progressive_speed_end=13.8,
    total_distance_per_day=1805/7, distance2_per_day_end=1179/7, # Todo: add function for default values
    fast_progressive_speed1=13.8, fast_progressive_speed2=16.0,
    racefit_duration=4.5*7, racefit_slow_gallop_distance_per_day=4800/30, racefit_fast_gallop_distance_per_day=3200/30, racefit_race_distance_per_day=800/7,
    racefit_slow_gallop_speed=13.8, racefit_fast_gallop_speed=16.0, racefit_race_speed=16.7,
    freshenup_program=long_freshenup(), num_freshenups=3,
    slow_workout_distance_per_day=2000, slow_workout_speed=7.5, slow_workout_pause=14
    )
    

    rest = HomogeneousProgram(rest_duration,rest_distance_per_day,rest_speed)
    pretraining = HomogeneousProgram(pretraining_duration,pretraining_distance_per_day,pretraining_speed)
    slow_progressive_duration = 0.4*progressive_duration
    slow_progressive = SlowProgressiveProgram(
        slow_progressive_duration,
        slow_progressive_distance_per_day_start,
        slow_progressive_distance_per_day_end,
        slow_progressive_speed_start,
        slow_progressive_speed_end
    )
    fast_progressive_duration = 0.6*progressive_duration
    (fast1_prog_distance,fast2_prog_distance) = fast_phase_distances(total_distance_per_day,distance2_per_day_end,fast_progressive_duration)
    fast_progressive = FastProgressiveProgram(
        fast_progressive_duration,
        fast1_prog_distance,
        fast2_prog_distance,
        fast_progressive_speed1,
        fast_progressive_speed2
    )
    racefit = RacefitProgram(
        racefit_duration,
        racefit_slow_gallop_distance_per_day,
        racefit_fast_gallop_distance_per_day,
        racefit_race_distance_per_day,
        racefit_slow_gallop_speed,
        racefit_fast_gallop_speed,
        racefit_race_speed
    )
    slow_workout_duration = slow_progressive_duration + fast_progressive_duration + racefit_duration + num_freshenups*(racefit_duration + duration(freshenup_program))
    slow_workout = HomogeneousProgram(slow_workout_duration,slow_workout_distance_per_day,slow_workout_speed)
    tp = ExtendedProgram(rest,pretraining,slow_progressive,fast_progressive,racefit,freshenup_program,slow_workout,num_freshenups,slow_workout_pause)
    return tp
end








function fast_phase_distances(total_distance_per_day,fast_gallop_distance_per_day_end,program_duration)
    total_fast_prog_distance = total_distance_per_day*program_duration
    fast2_prog_distance = fast_gallop_distance_per_day_end*program_duration/2
    fast1_prog_distance = total_fast_prog_distance - fast2_prog_distance
    return (fast1_prog_distance,fast2_prog_distance)
end