

lookup(Words, Formulas, Goal, ExpandedGoal) :-
	lexical_lookup(Words, Formulas, Semantics, 0, N),
	translate(Goal, [0, N]).

lexical_lookup([], [], [], N, N).
lexical_lookup([W|Ws], [F|Fs], [N0-S|Ss], N0, N) :-
    (
	lex(W, _, _)
    ->	     
        /* Lambek/Displacement entry */
	lex(W, F0, S),
	N1 is N0 + 1,
	macro_expand(F0, F1),
	translate(F1, [N0,N1], F),
	lexical_lookup(Ws, Fs, Ss, N1, N)
    ;
        lex(W, _, _, _)
    ->
        /* hybrid entry */
        lex(W, F0, L, S),
	N1 is N0 + 1,
	macro_expand(F0, F1),
	translate_hybrid(F1, L, W, N0, N1, F),
	lexical_lookup(Ws, Fs, Ss, N1, N)
    ;
        /* first-order linear logic entry */
        lex(W, _, _, _, _)
    ->
        N1 is N0 + 1,
	lex(W, F, N0, N1, S),
	lexical_lookup(Ws, Fs, Ss, N1, N)
    ;
        format(user_error, '~N{Error: No lexical entry for "~w"}~n', [W])
    ).

macro_expand(A0, A) :-
	atom(A0),
	!,
	A = at(A0).
macro_expand(at(A), at(A)).
macro_expand(at(A,B), at(A,B)).


macro_expand(forall(X,A0), forall(X,A)) :-
	macro_expand(A0, A).
macro_expand(exists(X,A0), exists(X,A)) :-
	macro_expand(A0, A).
macro_expand(impl(A0,B0), impl(A,B)) :-
	macro_expand(A0, A),
	macro_expand(B0, B).

macro_expand(p(K,A0,B0), p(K,A,B)) :-
	macro_expand(A0, A),
	macro_expand(B0, B).
macro_expand(dl(K,A0,B0), dl(K,A,B)) :-
	macro_expand(A0, A),
	macro_expand(B0, B).
macro_expand(dr(K,A0,B0), dr(K,A,B)) :-
	macro_expand(A0, A),
	macro_expand(B0, B).

macro_expand((A0*B0), p(A,B)) :-
	macro_expand(A0, A),
	macro_expand(B0, B).
macro_expand(p(A0,B0), p(A,B)) :-
	macro_expand(A0, A),
	macro_expand(B0, B).

macro_expand((A0\\B0), dl(A,B)) :-
	macro_expand(A0, A),
	macro_expand(B0, B).
macro_expand(dl(A0,B0), dl(A,B)) :-
	macro_expand(A0, A),
	macro_expand(B0, B).

macro_expand((A0/B0), dr(A,B)) :-
	macro_expand(A0, A),
	macro_expand(B0, B).
macro_expand(dr(A0,B0), dr(A,B)) :-
	macro_expand(A0, A),
	macro_expand(B0, B).


macro_expand((A0|B0), h(A,B)) :-
	!,
	macro_expand(A0, A),
	macro_expand(B0, B).

in_lexicon(W) :-
	lex(W, _, _).
in_lexicon(W) :-
	lex(W, _, _, _).