using ObservationSchemes
using Test
using StaticArrays, LinearAlgebra

@testset "ObservationSchemes.jl" begin
    # Write your own tests here.
    @testset "default constructor" begin
        v = @SVector [1.0, 2.0, 3.0]
        tt = 1.0
        obs = LinearGsnObs(tt, v)
        @test obs.t == tt
        @test eltype(obs) == typeof(v)
        @test size(obs) == length(v)
        @test length(obs) == length(v)
        @test fpt_info(obs) == NoFirstPassageTimes
        @test obs.obs == v
        @test obs.L == SDiagonal{3}(I)
        @test obs.μ == zero(v)
        @test obs.Σ == SDiagonal{3}(I)*1e-11
        @test obs.full_obs == false
    end

    @testset "custom constructor 1" begin
        v = @SVector [1.0, 2.0, 3.0]
        tt = 2.0
        L = @SMatrix [1.0 2.0 0.0 4.0; 3.0 4.0 0.0 0.0; 0.0 1.0 2.0 1.0]
        Σ = SDiagonal{3}(I)
        fpt = FirstPassageTimeInfo(
            (1, 2),
            (1.0, 2.0),
            (true, false),
            (false, true),
            (1.0,),
        )
        obs = LinearGsnObs(tt, v; L = L, Σ = Σ, fpt = fpt)

        @test obs.t == tt
        @test eltype(obs) == typeof(v)
        @test size(obs) == length(v)
        @test length(obs) == length(v)
        @test fpt_info(obs) == typeof(fpt)
        @test obs.obs == v
        @test obs.L == L
        @test obs.μ == zero(v)
        @test obs.Σ == Σ
        @test obs.full_obs == false
    end
end

@testset "Container for all observations" begin
    struct LawA α; β; end
    struct LawB γ; β; end
    ObservationSchemes.parameter_names(P::LawA) = [:α, :β]
    ObservationSchemes.parameter_names(P::LawB) = [:γ, :β]

    all_obs = AllObservations()
    P, obs, t, x0_prior = LawA(10,20), [1.0, 2.0], 0.0, KnownStartingPt(0.0)
    P2, obs2, t2, x0_prior2 = LawB(30,40), [11.0, 12.0], 1.0, KnownStartingPt(2.0)

    @testset "recording observations" begin
        add_recording!(all_obs, (P=P, obs=obs, t0=t, x0_prior=x0_prior))
        @test all_obs.recordings[1].P == P
        @test all_obs.recordings[1].obs == obs
        @test all_obs.recordings[1].t0 == t
        @test all_obs.recordings[1].x0_prior == x0_prior

        add_recording!(all_obs, (P=P2, obs=obs2, t0=t2, x0_prior=x0_prior2))
        @test all_obs.recordings[1].P == P
        @test all_obs.recordings[1].obs == obs
        @test all_obs.recordings[1].t0 == t
        @test all_obs.recordings[1].x0_prior == x0_prior
        @test all_obs.recordings[2].P == P2
        @test all_obs.recordings[2].obs == obs2
        @test all_obs.recordings[2].t0 == t2
        @test all_obs.recordings[2].x0_prior == x0_prior2
    end

    @testset "adding dependency structure" begin
        all_obs = AllObservations()
        add_recording!(all_obs, (P=P, obs=obs, t0=t, x0_prior=x0_prior))
        add_recording!(all_obs, (P=P2, obs=obs2, t0=t2, x0_prior=x0_prior2))
        add_dependency!(all_obs, Dict(:β => [(rec=1, law_else_obs=true, p_idx=2), (rec=2, law_else_obs=true, p_idx=2)]))
        temp = all_obs.param_depend[:β][1]
        @test (temp.rec_idx, temp.param_idx, temp.param_name) == (1, 2, :β)
        temp = all_obs.param_depend[:β][2]
        @test (temp.rec_idx, temp.param_idx, temp.param_name) == (2, 2, :β)

        all_obs = AllObservations()
        add_recording!(all_obs, (P=P, obs=obs, t0=t, x0_prior=x0_prior))
        add_recording!(all_obs, (P=P2, obs=obs2, t0=t2, x0_prior=x0_prior2))
        add_dependency!(all_obs, Dict(:β => [(rec=1,law_else_obs=true,  p_name=:β), (rec=2, law_else_obs=true, p_name=:β)]))

        temp = all_obs.param_depend[:β][1]
        @test (temp.rec_idx, temp.param_idx, temp.param_name) == (1, 2, :β)
        temp = all_obs.param_depend[:β][2]
        @test (temp.rec_idx, temp.param_idx, temp.param_name) == (2, 2, :β)
    end

    @testset "splitting at full observations" begin
        obs = [
            [
                LinearGsnObs(1.0, 1.0; full_obs=false),
                LinearGsnObs(2.0, 2.0; full_obs=true),
                LinearGsnObs(3.0, 3.0; full_obs=false),
            ],
            [
                LinearGsnObs(1.3, 1.0; full_obs=true),
                LinearGsnObs(2.3, 2.0; full_obs=true),
                LinearGsnObs(3.3, 3.0; full_obs=true),
            ],
            [
                LinearGsnObs(1.5, 1.0; full_obs=false),
                LinearGsnObs(2.5, 2.0; full_obs=false),
                LinearGsnObs(3.5, 3.0; full_obs=false),
                LinearGsnObs(4.5, 4.0; full_obs=false),
                LinearGsnObs(5.5, 5.0; full_obs=false),
            ],
        ]
        recordings = [
            (
                P=LawA(10,20),
                obs=obs[1],
                t0=0.0,
                x0_prior=KnownStartingPt(2.0),
            ),
            (
                P=LawA(10,20),
                obs=obs[2],
                t0=0.3,
                x0_prior=KnownStartingPt(-2.0),
            ),
            (
                P=LawB(30,40),
                obs=obs[3],
                t0=0.5,
                x0_prior=KnownStartingPt(10.0),
            ),
        ]
        all_obs = AllObservations()
        for recording in recordings
            add_recording!(all_obs, recording)
        end
        add_dependency!(
            all_obs,
            Dict(
                :α => [
                    (rec=1, law_else_obs=true, p_name=:α),
                    (rec=2, law_else_obs=true, p_name=:α),
                ],
                :β => [
                    (rec=1, law_else_obs=true, p_name=:β),
                    (rec=2, law_else_obs=true, p_name=:β),
                    (rec=3, law_else_obs=true, p_name=:β),
                ],
            )
        )
        d = all_obs.param_depend
        @testset "pre-test α dependence $i" for i in 1:2
            @test Tuple(d[:α][i]) == (i, true, -1, 1, :α)
        end
        @testset "pre-test β dependence $i" for i in 1:3
            @test Tuple(d[:β][i]) == (i, true, -1, 2, :β)
        end
        @testset "pre-test presence of recordings $i" for i in 1:3
            @test all_obs.recordings[i] == recordings[i]
        end

        initialized_obs, old_to_new_dict = initialize!(all_obs)
        d = initialized_obs.param_depend
        @testset "new α dependence $i" for i in 1:4
            @test Tuple(d[:α][i]) == (i, true, -1, 1, :α)
        end
        @testset "new β dependence $i" for i in 1:6
            @test Tuple(d[:β][i]) == (i, true, -1, 2, :β)
        end
        @test Tuple(d[:REC3_γ][1]) == (6, true, -1, 1, :γ)

        @test length(initialized_obs.recordings) == 6

        @testset "initialized recording 1" begin
            r = initialized_obs.recordings[1]
            @test r.P == recordings[1].P
            #TODO figure out why wrong
            #@test r.obs == recordings[1].obs[1:2]
            @test r.t0 == recordings[1].t0
            @test r.x0_prior == recordings[1].x0_prior
        end
        @testset "initialized recording 2" begin
            r = initialized_obs.recordings[2]
            @test r.P == recordings[1].P
            #@test r.obs == recordings[1].obs[3:3]
            @test r.t0 == recordings[1].obs[2].t
            @test r.x0_prior == KnownStartingPt(recordings[1].obs[2].obs)
        end
        @testset "initialized recording 3" begin
            r = initialized_obs.recordings[3]
            @test r.P == recordings[2].P
            #@test r.obs == recordings[2].obs[1:1]
            @test r.t0 == recordings[2].t0
            @test r.x0_prior == recordings[2].x0_prior
        end
        @testset "initialized recording 4" begin
            r = initialized_obs.recordings[4]
            @test r.P == recordings[2].P
            #@test r.obs == recordings[2].obs[2:2]
            @test r.t0 == recordings[2].obs[1].t
            @test r.x0_prior == KnownStartingPt(recordings[2].obs[1].obs)
        end
        @testset "initialized recording 5" begin
            r = initialized_obs.recordings[5]
            @test r.P == recordings[2].P
            #@test r.obs == recordings[2].obs[3:3]
            @test r.t0 == recordings[2].obs[2].t
            @test r.x0_prior == KnownStartingPt(recordings[2].obs[2].obs)
        end
        @testset "initialized recording 6" begin
            r = initialized_obs.recordings[6]
            @test r.P == recordings[3].P
            #@test r.obs == recordings[3].obs
            @test r.t0 == recordings[3].t0
            @test r.x0_prior == recordings[3].x0_prior
        end

        @testset "packaging functions" begin
            struct Foo end
            struct Foo2 end
            struct Foo3 end
            packaged1 = package(Foo(), all_obs)
            packaged2 = package(Foo, initialized_obs)
            packaged3 = package([Foo(), Foo2(), Foo3()], old_to_new_dict, initialized_obs)
            packaged4 = package([Foo(), Foo2(), Foo3()], all_obs)
            @test packaged1 == [
                [Foo(), Foo(), Foo()],
                [Foo(), Foo(), Foo()],
                [Foo(), Foo(), Foo(), Foo(), Foo()],
            ]
            @test packaged2 == [
                [Foo, Foo],
                [Foo],
                [Foo],
                [Foo],
                [Foo],
                [Foo, Foo, Foo, Foo, Foo],
            ]
            @test packaged3 == [
                [Foo(), Foo()],
                [Foo()],
                [Foo2()],
                [Foo2()],
                [Foo2()],
                [Foo3(), Foo3(), Foo3(), Foo3(), Foo3()],
            ]
            @test packaged4 == [
                [Foo(), Foo(), Foo()],
                [Foo2(), Foo2(), Foo2()],
                [Foo3(), Foo3(), Foo3(), Foo3(), Foo3()],
            ]
        end

    end
end
#=
struct LawA α; β; end
struct LawB γ; β; end
ObservationSchemes.parameter_names(P::LawA) = [:α, :β]
ObservationSchemes.parameter_names(P::LawB) = [:γ, :β]

all_obs = AllObservations()
P, obs, t, x0_prior = LawA(10,20), [1.0, 2.0], 0.0, KnownStartingPt(0.0)
P2, obs2, t2, x0_prior2 = LawB(30,40), [11.0, 12.0], 1.0, KnownStartingPt(2.0)

@testset "recording observations" begin
    add_recording!(all_obs, (P=P, obs=obs, t0=t, x0_prior=x0_prior))
    @test all_obs.recordings[1].P == P
    @test all_obs.recordings[1].obs == obs
    @test all_obs.recordings[1].t0 == t
    @test all_obs.recordings[1].x0_prior == x0_prior

    add_recording!(all_obs, (P=P2, obs=obs2, t0=t2, x0_prior=x0_prior2))
    @test all_obs.recordings[1].P == P
    @test all_obs.recordings[1].obs == obs
    @test all_obs.recordings[1].t0 == t
    @test all_obs.recordings[1].x0_prior == x0_prior
    @test all_obs.recordings[2].P == P2
    @test all_obs.recordings[2].obs == obs2
    @test all_obs.recordings[2].t0 == t2
    @test all_obs.recordings[2].x0_prior == x0_prior2
end

@testset "adding dependency structure" begin
    all_obs = AllObservations()
    add_recording!(all_obs, (P=P, obs=obs, t0=t, x0_prior=x0_prior))
    add_recording!(all_obs, (P=P2, obs=obs2, t0=t2, x0_prior=x0_prior2))
    add_dependency!(all_obs, Dict(:β => [(rec=1, law_else_obs=true, p_idx=2), (rec=2, law_else_obs=true, p_idx=2)]))
    temp = all_obs.param_depend[:β][1]
    @test (temp.rec_idx, temp.param_idx, temp.param_name) == (1, 2, :β)
    temp = all_obs.param_depend[:β][2]
    @test (temp.rec_idx, temp.param_idx, temp.param_name) == (2, 2, :β)

    all_obs = AllObservations()
    add_recording!(all_obs, (P=P, obs=obs, t0=t, x0_prior=x0_prior))
    add_recording!(all_obs, (P=P2, obs=obs2, t0=t2, x0_prior=x0_prior2))
    add_dependency!(all_obs, Dict(:β => [(rec=1,law_else_obs=true,  p_name=:β), (rec=2, law_else_obs=true, p_name=:β)]))

    temp = all_obs.param_depend[:β][1]
    @test (temp.rec_idx, temp.param_idx, temp.param_name) == (1, 2, :β)
    temp = all_obs.param_depend[:β][2]
    @test (temp.rec_idx, temp.param_idx, temp.param_name) == (2, 2, :β)
end

obs = [
    [
        LinearGsnObs(1.0, 1.0; full_obs=false),
        LinearGsnObs(2.0, 2.0; full_obs=true),
        LinearGsnObs(3.0, 3.0; full_obs=false),
    ],
    [
        LinearGsnObs(1.3, 1.0; full_obs=true),
        LinearGsnObs(2.3, 2.0; full_obs=true),
        LinearGsnObs(3.3, 3.0; full_obs=true),
    ],
    [
        LinearGsnObs(1.5, 1.0; full_obs=false),
        LinearGsnObs(2.5, 2.0; full_obs=false),
        LinearGsnObs(3.5, 3.0; full_obs=false),
        LinearGsnObs(4.5, 4.0; full_obs=false),
        LinearGsnObs(5.5, 5.0; full_obs=false),
    ],
]
recordings = [
    (
        P=LawA(10,20),
        obs=obs[1],
        t0=0.0,
        x0_prior=KnownStartingPt(2.0),
    ),
    (
        P=LawA(10,20),
        obs=obs[2],
        t0=0.3,
        x0_prior=KnownStartingPt(-2.0),
    ),
    (
        P=LawB(30,40),
        obs=obs[3],
        t0=0.5,
        x0_prior=KnownStartingPt(10.0),
    ),
]
all_obs = AllObservations()
for recording in recordings
    add_recording!(all_obs, recording)
end
add_dependency!(
    all_obs,
    Dict(
        :α => [
            (rec=1, law_else_obs=true, p_name=:α),
            (rec=2, law_else_obs=true, p_name=:α),
        ],
        :β => [
            (rec=1, law_else_obs=true, p_name=:β),
            (rec=2, law_else_obs=true, p_name=:β),
            (rec=3, law_else_obs=true, p_name=:β),
        ],
    )
)
d = all_obs.param_depend
@testset "pre-test α dependence $i" for i in 1:2
    @test Tuple(d[:α][i]) == (i, true, -1, 1, :α)
end
@testset "pre-test β dependence $i" for i in 1:3
    @test Tuple(d[:β][i]) == (i, true, -1, 2, :β)
end
@testset "pre-test presence of recordings $i" for i in 1:3
    @test all_obs.recordings[i] == recordings[i]
end

initialized_obs, old_to_new_dict = initialize!(all_obs)
d = initialized_obs.param_depend
@testset "new α dependence $i" for i in 1:4
    @test Tuple(d[:α][i]) == (i, true, -1, 1, :α)
end
@testset "new β dependence $i" for i in 1:6
    @test Tuple(d[:β][i]) == (i, true, -1, 2, :β)
end
@test Tuple(d[:REC3_γ][1]) == (6, true, -1, 1, :γ)

@test length(initialized_obs.recordings) == 6
r = initialized_obs.recordings[1]
r.obs == recordings[1].obs[1:2]
@testset "initialized recording 1" begin
    r = initialized_obs.recordings[1]
    @test r.P == recordings[1].P
    #@test r.obs == recordings[1].obs[1:2]
    @test r.t0 == recordings[1].t0
    @test r.x0_prior == recordings[1].x0_prior
end
@testset "initialized recording 2" begin
    r = initialized_obs.recordings[2]
    @test r.P == recordings[1].P
    #@test r.obs == recordings[1].obs[3:3]
    @test r.t0 == recordings[1].obs[2].t
    @test r.x0_prior == KnownStartingPt(recordings[1].obs[2].obs)
end
@testset "initialized recording 3" begin
    r = initialized_obs.recordings[3]
    @test r.P == recordings[2].P
    #@test r.obs == recordings[2].obs[1:1]
    @test r.t0 == recordings[2].t0
    @test r.x0_prior == recordings[2].x0_prior
end
@testset "initialized recording 4" begin
    r = initialized_obs.recordings[4]
    @test r.P == recordings[2].P
    #@test r.obs == recordings[2].obs[2:2]
    @test r.t0 == recordings[2].obs[1].t
    @test r.x0_prior == KnownStartingPt(recordings[2].obs[1].obs)
end
@testset "initialized recording 5" begin
    r = initialized_obs.recordings[5]
    @test r.P == recordings[2].P
    #@test r.obs == recordings[2].obs[3:3]
    @test r.t0 == recordings[2].obs[2].t
    @test r.x0_prior == KnownStartingPt(recordings[2].obs[2].obs)
end
@testset "initialized recording 6" begin
    r = initialized_obs.recordings[6]
    @test r.P == recordings[3].P
    #@test r.obs == recordings[3].obs
    @test r.t0 == recordings[3].t0
    @test r.x0_prior == recordings[3].x0_prior
end

@testset "packaging functions" begin
    struct Foo end
    struct Foo2 end
    struct Foo3 end
    packaged1 = package(Foo(), all_obs)
    packaged2 = package(Foo, initialized_obs)
    packaged3 = package([Foo(), Foo2(), Foo3()], old_to_new_dict, initialized_obs)
    packaged4 = package([Foo(), Foo2(), Foo3()], all_obs)
    @test packaged1 == [
        [Foo(), Foo(), Foo()],
        [Foo(), Foo(), Foo()],
        [Foo(), Foo(), Foo(), Foo(), Foo()],
    ]
    @test packaged2 == [
        [Foo, Foo],
        [Foo],
        [Foo],
        [Foo],
        [Foo],
        [Foo, Foo, Foo, Foo, Foo],
    ]
    @test packaged3 == [
        [Foo(), Foo()],
        [Foo()],
        [Foo2()],
        [Foo2()],
        [Foo2()],
        [Foo3(), Foo3(), Foo3(), Foo3(), Foo3()],
    ]
    @test packaged4 == [
        [Foo(), Foo(), Foo()],
        [Foo2(), Foo2(), Foo2()],
        [Foo3(), Foo3(), Foo3(), Foo3(), Foo3()],
    ]
end

=#
