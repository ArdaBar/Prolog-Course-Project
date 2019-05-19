% arda baris budak
% 2018400264
% compiling: yes
% complete: yes

:- [pokemon_data].

find_pokemon_evolution(PokemonLevel,Pokemon,EvolvedPokemon)

:-  evolution_in_range(0,PokemonLevel,Pokemon,EvolvedPokemon). %evolution_in_range(+Level1,+Level2,+Pokemon,-EvolvedPokemon)
                                            %recursive helper predicate that finds evolution of a Pokemon between two levels.

evolution_in_range(Level1,Level2,Pokemon,EvolvedPokemon)

:-  pokemon_evolution(Pokemon,InterPokemon,InterLevel),
    Level1=<InterLevel,
    InterLevel=<Level2,
    evolution_in_range(InterLevel,Level2,InterPokemon,EvolvedPokemon), ! ; % important cut to prevent multiple outputs.

    Pokemon = EvolvedPokemon. % base case for recursion.



pokemon_level_stats(PokemonLevel, Pokemon, PokemonHp, PokemonAttack, PokemonDefense)
:-  pokemon_stats(Pokemon, _, BaseHp, BaseAttack, BaseDefense),
    PokemonHp is BaseHp + 2*PokemonLevel,
    PokemonAttack is BaseAttack + PokemonLevel,
    PokemonDefense is BaseDefense + PokemonLevel.



single_type_multiplier(AttackerType, DefenderType, Multiplier)

:-  pokemon_types(TypeList),
    type_chart_attack(AttackerType, TypeMultipliers),
    kacinci(TypeList,DefenderType,N),            % defined below
    findNthElement(TypeMultipliers,N,Multiplier). % defined below
                            % finding in which place DefenderType is in the TypeList array
                            % and finding corresponding multiplier in TypeMultiers array.

kacinci(List,Element,N)  % kacinci(+List,+Element,-N)
                         % helper predicate to find in which place of List element is seen first.
:-  List = [Element|_],
    N=1, ! ;          % base case of recursion, important cut.

    List = [_|T],
    kacinci(T,Element,M),
    N is M+1.


findNthElement(List,N,Element) % findNthElement(+List,+N,-Element)
                                % helper to find Nth element of List
:-  N=1,
    List = [Element|_], ! ;  % base case of re cursion, important cut.

    List=[_|T],
    M is N-1,
    findNthElement(T,M,Element).



type_multiplier(AttackerType, DefenderTypeList, Multiplier) % recursive

:-  DefenderTypeList = [], % base case of recursion
    Multiplier = 1.0, ! ;

    DefenderTypeList = [H|T],
    single_type_multiplier(AttackerType, H, HeadMultiplier),
    type_multiplier(AttackerType, T, TailMultiplier),
    Multiplier is HeadMultiplier * TailMultiplier.



pokemon_type_multiplier(AttackerPokemon, DefenderPokemon, Multiplier)

:-  pokemon_stats(AttackerPokemon,AttackerTypeList,_,_,_),
    pokemon_stats(DefenderPokemon,DefenderTypeList,_,_,_),
    findall(M, ( member(AttType,AttackerTypeList),type_multiplier(AttType,DefenderTypeList, M) ) ,MultList), %puting all multipliers
    max_list(MultList, Multiplier).                                                     %for attacker and defender types to MultList



pokemon_attack(AttackerPokemon,AttackerPokemonLevel,DefenderPokemon,DefenderPokemonLevel,Damage)

:-  pokemon_level_stats(AttackerPokemonLevel, AttackerPokemon,_, AttackerPokemonAttack,_),
    pokemon_level_stats(DefenderPokemonLevel, DefenderPokemon,_,_,DefenderPokemonDefense),
    pokemon_type_multiplier(AttackerPokemon, DefenderPokemon, TypeMultiplier),
    Damage is (0.5 * AttackerPokemonLevel * (AttackerPokemonAttack / DefenderPokemonDefense)
    * TypeMultiplier) + 1.



pokemon_fight(Pokemon1, Pokemon1Level, Pokemon2, Pokemon2Level, Pokemon1Hp, Pokemon2Hp, Rounds)

:-  pokemon_level_stats(Pokemon1Level, Pokemon1, Pokemon1InitHp, _, _),
    pokemon_level_stats(Pokemon2Level, Pokemon2, Pokemon2InitHp, _, _),
    pokemon_attack(Pokemon1,Pokemon1Level,Pokemon2,Pokemon2Level,Damageto2),
    pokemon_attack(Pokemon2,Pokemon2Level,Pokemon1,Pokemon1Level,Damageto1),
    how_many_rounds(Pokemon1InitHp,Pokemon2InitHp,Damageto1,Damageto2,Rounds), % defined below
    Pokemon1Hp is Pokemon1InitHp - Rounds * Damageto1,
    Pokemon2Hp is Pokemon2InitHp - Rounds * Damageto2.


how_many_rounds(Pokemon1Hp,Pokemon2Hp,Damageto1,Damageto2,Rounds) %how_many_rounds(+Pokemon1Hp,+Pokemon2Hp,+Damageto1,+Damageto2,-Rounds)
                                                                  % recursive predicate to find how many rounds a fight will take
:-  Pokemon1Hp =< 0, Rounds = 0,!;                                % given HP's and Damage points.
    Pokemon2Hp =< 0, Rounds = 0,!;  /* it's over when a Pokemon gets to 0 or negative HP,
                                      not interested in who won at this point.*/
    how_many_rounds(Pokemon1Hp-Damageto1,Pokemon2Hp-Damageto2,Damageto1,Damageto2,R),
    Rounds is R+1.



pokemon_tournament(PokemonTrainer1, PokemonTrainer2, WinnerTrainerList)

:-  pokemon_trainer(PokemonTrainer1,PokeList1,LevelList1),
    pokemon_trainer(PokemonTrainer2,PokeList2,LevelList2),
    tourn_helper(PokemonTrainer1,PokemonTrainer2,PokeList1,PokeList2,LevelList1,LevelList2,WinnerTrainerList). % defined below


tourn_helper(Trainer1,Trainer2,PokeList1,PokeList2,LevelList1,LevelList2,WinnerTrainerList)
                                            % tourn_helper(+Trainer1,+Trainer2,+PokeList1,+PokeList2,+LevelList1,+LevelList2,-WinnerTrainerList)
:-  PokeList1 = [],                         % recursive helper to find Winner Trainer List in a tournament.
    WinnerTrainerList = []; % base-case

    PokeList1 = [HPoke1|TPoke1],
    PokeList2 = [HPoke2|TPoke2],
    LevelList1 = [HLevel1|TLevel1],
    LevelList2 = [HLevel2|TLevel2],
    WinnerTrainerList = [HWinner|TWinner],
    find_pokemon_evolution(HLevel1,HPoke1,Evolved1), % evolve before tournament.
    find_pokemon_evolution(HLevel2,HPoke2,Evolved2),
    pokemon_fight(Evolved1, HLevel1, Evolved2, HLevel2, Pokemon1Hp, Pokemon2Hp,_),
    (
        Pokemon2Hp =< Pokemon1Hp,
        HWinner = Trainer1;         % finding who won the fight by comparing HP's.

        Pokemon2Hp > Pokemon1Hp,
        HWinner = Trainer2
    ),
    tourn_helper(Trainer1,Trainer2,TPoke1,TPoke2,TLevel1,TLevel2,TWinner).



best_pokemon(EnemyPokemon, LevelCap, RemainingHP, BestPokemon)

:-  findall( -(Hp,Pokemon), (pokemon_stats(Pokemon,_,_,_,_), pokemon_fight(Pokemon,LevelCap,EnemyPokemon,LevelCap,Hp,_,_) ), List),
    keysort(List,Sorted),                          %finding all Pokemon's HP's after fighting the EnemyPokemon in a List of pairs
    last(Sorted,-(RemainingHP,BestPokemon)).       %and finding this List's max element by sorting and taking the last element.



best_pokemon_team(OpponentTrainer, PokemonTeam)

:-  pokemon_trainer(OpponentTrainer, OppTeam, OppLevels),
    best_team_helper(OpponentTrainer,OppTeam,OppLevels,PokemonTeam). % defined below


best_team_helper(OpponentTrainer,OppTeam,OppLevels,PokemonTeam) % best_team_helper(+OpponentTrainer,+OppTeam,+OppLevels,-PokemonTeam)
                                                                % recursive helper that gives finds the best team.
:-  OppTeam = [],
    PokemonTeam = []; % base-case of recursion.

    OppTeam = [OppPokemon|OppTeamTail],
    OppLevels = [OppLevel|OppLevelsTail],
    best_team_helper(OpponentTrainer,OppTeamTail,OppLevelsTail,PokemonTeamTail),
    best_pokemon(OppPokemon, OppLevel, _, BestPokemon),
    PokemonTeam = [ BestPokemon | PokemonTeamTail ].



pokemon_types(TypeList, InitialPokemonList, PokemonList)

:-  findall(Poke, (member(Poke,InitialPokemonList), member(SomeType,TypeList), pokemon_stats(Poke,PokeTypes,_,_,_),member(SomeType,PokeTypes) ) ,FirstList),
    sort(0,@<,FirstList,PokemonList). % sorting to remove duplcates from findall result.



generate_pokemon_team(LikedTypes, DislikedTypes, Criterion, Count, PokemonTeam)

:-  findall([Poke,HP,Attack,Defense] , ( pokemon_stats(Poke,PokeTypes,HP,Attack,Defense), pokemon_types(DislikedTypes,[Poke], []), member(SomeType,PokeTypes) , member(SomeType,LikedTypes) ) , LikedNotDislikedList ),
    predsort(Criterion,LikedNotDislikedList,SortedList), % Predicates h, a, d are defined below
    takeFirstN(Count, SortedList, PokemonTeam). % defined below


h(Delta,E1,E2) % h(-Delta,+E1,+E2)
                % predicate for comparing by HP values
:-  findNthElement(E1,2,HP1),
    findNthElement(E2,2,HP2),  % this predicate was defined for single_type_multiplier predicate.
    (
        HP1 < HP2,
        Delta = '>';  % order is changed in order to sort in descending order

        HP1 > HP2,
        Delta = '<';

        HP1 =:= HP2,
        Delta = '<'  % this is not unified to '=', so duplicates aren't removed
    ).

a(Delta,E1,E2) % a(-Delta,+E1,+E2)
                % predicate for comparing by Attack values
:-  findNthElement(E1,3,HP1),
    findNthElement(E2,3,HP2),   % this predicate was defined for single_type_multiplier predicate.
    (
        HP1 < HP2,
        Delta = '>';  % order is changed in order to sort in descending order

        HP1 > HP2,
        Delta = '<';

        HP1 =:= HP2,
        Delta = '<'  % this is not unified to '=', so duplicates aren't removed
    ).

d(Delta,E1,E2)  % d(-Delta,+E1,+E2)
                % predicate for comparing by Defense values
:-  findNthElement(E1,4,HP1),    % this predicate was defined for single_type_multiplier predicate.
    findNthElement(E2,4,HP2),
    (
        HP1 < HP2,
        Delta = '>';  % order is changed in order to sort in descending order

        HP1 > HP2,
        Delta = '<';

        HP1 =:= HP2,
        Delta = '<'  % this is not unified to '=', so duplicates aren't removed
    ).


takeFirstN(N, BigList, Result)  % takeFirstN(+N, +BigList, -Result)
                                % to put first N elements of BigList to Result
:-  N=0,
    Result=[];  % base-case of recursion

    R is N-1,
    BigList = [H|T],
    takeFirstN(R, T, ResultTail),
    Result = [H|ResultTail].
