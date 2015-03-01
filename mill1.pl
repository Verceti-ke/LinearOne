:- use_module(ordset, [ord_union/3,ord_delete/3]).
:- use_module(portray_graph_tikz, [portray_graph/1,graph_header/0,graph_footer/1]).
:- use_module(translations, [translate_lambek/3,translate_displacement/3,translate_hybrid/6]).
:- use_module(latex, [latex_proof/1,proof_header/0,proof_footer/0]).

:- dynamic '$PROOFS'/1, '$AXIOMS'/1.
:- dynamic node_formula/3.

portray(neg(F, X, L)) :-
	atom(F),
	Term =.. [F|L],
	format('-~p ~p',[Term,X]).
portray(pos(F, X, L)) :-
	atom(F),
	Term =.. [F|L],
	format('+~p ~p',[Term,X]).
portray(at(X, Vs)) :-
	atom(X),
	Term =.. [X|Vs],
	print(Term).
portray(at(X, _, _, Vs)) :-
	atom(X),
	Term =.. [X|Vs],
	print(Term).
portray(impl(A,B)) :-
	format('(~p -o ~p)', [A,B]).

prove(List, Goal, Sem) :-
	graph_header,
	retractall('$PROOFS'(_)),
	assert('$PROOFS'(0)),
	retractall('$AXIOMS'(_)),
	assert('$AXIOMS'(0)),
        unfold_sequent(List, Goal, Vs0, W, Sem0),
	copy_term(Vs0, Vs),
        prove1(Vs0, Trace),
	node_proofs(Vs),
	numbervars(Sem0, W, _),
	Sem = Sem0,
	print_trace(user_output, Trace),
	'$PROOFS'(N0),
	N is N0 + 1,
	retractall('$PROOFS'(_)),
	assert('$PROOFS'(N)),
	fail.
prove(_, _, _) :-
	'$AXIOMS'(A),
	'$PROOFS'(N),
	write_axioms(A),
	write_proofs(N),
	graph_footer(N).

node_proofs(Vs) :-
        nl(user_output),
        print(user_output, Vs),
	nl(user_output),
	telling(Stream),
        shell('rm latex_proofs.tex', _),
        tell('latex_proofs.tex'),
	proof_header,
    (
        node_proofs(Vs, Ps),
        numbervars(Ps, 0, _),
	member(P, Ps),
	latex_proof(P),
        write('\\bigskip'),
        nl,
	fail
    ;
        proof_footer,
        tell(Stream)
    ).
     
	

node_proofs([V|Vs], [P|Ps]) :-
        node_proof1(V, P),
        node_proofs(Vs, Ps).
node_proofs([], []).

node_proof1(vertex(N0, As, _, _), Proof) :-
        node_formula(N0, Pol, F),
        node_proof2(As, F, N0, Pol, Proof),
	!.

node_proof2([], F, N, _, rule(ax, [N-F], N-F, [])).
node_proof2([A|As], F, N, Pol, Proof) :-
        node_proof3(Pol, [A|As], F, N, Proof).

node_proof3(pos, L, F, N, Proof) :-
        create_pos_proof(F, N, L, [], Proof).
node_proof3(neg, L, F, N, Proof) :-
        max_neg(F, MN),
        create_neg_proof(F, N, L, [], MN, Proof).

max_neg(impl(_,_-F0), F) :-
	!,
	max_neg(F0, F).
max_neg(forall(_,_-F0), F) :-
	!,
	max_neg(F0, F).
max_neg(F, F).

create_pos_proof(N-A, L0, L, Proof) :-
	create_pos_proof(A, N, L0, L, Proof).

create_pos_proof(at(A,C,N,Vars), _, [pos(A,C,N,_,Vars)|L], L, rule(ax,[at(A,C,N,Vars)], at(A,C,N,Vars), [])) :-
	!.
create_pos_proof(exists(X,N-A), N, L0, L, rule(er, Gamma, N-exists(X,A), [ProofA])) :-
        !,
        create_pos_proof(A, N, L0, L, ProofA),
        ProofA = rule(_, Gamma, _, _).
create_pos_proof(p(N-A,N-B), N, L0, L, rule(pr, GD, N-p(N-A,N-B), [P1,P2])) :-
        !,
        create_pos_proof(A, N, L0, L1, P1),
        create_pos_proof(B, N, L1, L, P2),
        P1 = rule(_, Gamma, _, _),
        P2 = rule(_, Delta, _, _),
        append(Gamma, Delta, GD).
% complex subformula
create_pos_proof(F, N, L, L, rule(ax, [N-F], N-F, [])).

create_neg_proof(N-A, L0, L, Neg, Proof) :-
	create_neg_proof(A, N, L0, L, Neg, Proof).
create_neg_proof(at(A,C,N,Vars), _, [neg(A,C,N,_,Vars)|L], L, at(A,C,N,Vars), rule(ax, [at(A,C,N,Vars)], at(A,C,N,Vars), [])) :-
        !.
create_neg_proof(impl(N-A,N-B), N, L0, L, Neg, rule(il, GD, B, [ProofA,ProofB])) :-
        !,
        create_neg_subproof(A, N, L0, L1, ProofA),
	create_neg_proof(B, N, L1, L, Neg, ProofB),
	ProofA = rule(_, Gamma, _, _),
	ProofB = rule(_, Delta, _, _),
	select_formula(B, N, Delta, Delta_B),
	append(Gamma, [N-impl(A,B)|Delta_B], GD).
	
create_neg_proof(forall(X,N-A), N, L0, L, Neg, rule(fl, GammaP, C, [ProofA])) :-
        !,
        create_neg_proof(A, N, L0, L, Neg, ProofA),
        ProofA = rule(_, Gamma, C, _),
	replace_list(A, N, Gamma, N-forall(X,A), GammaP),
	diagnostic(A, N, Gamma, N-forall(X,A), GammaP).	
create_neg_proof(F, N, L, L, _, rule(ax, [N-F], N-F, [])).

create_neg_subproof(at(A,C,N,Vars), _, [pos(A,C,N,_,Vars)|L], L, rule(ax, [at(A,C,N,Vars)], at(A,C,N,Vars), [])) :-
        !.
create_neg_subproof(p(N-A,N-B), N, L0, L, rule(pr, ProofA, ProofB)) :-
	!,
	create_neg_subproof(A, N, L0, L1, ProofA),
	create_neg_subproof(B, N, L1, L, ProofB).
create_neg_subproof(A, N, L, L, rule(ax, [N-A], N-A, [])).

diagnostic(A, N, G, N-F, G) :-
	!,
	format(user_error, '~nNo substitution: ~p-~p, ~p-~p~n', [N,A,N,F]),
	print_list(G).
diagnostic(_, _, _, _, _).


print_list([]).
print_list([A|As]) :-
	format(user_error, '~p~n', [A]),
	print_list(As).

select_formula(F, N, L0, L) :-
   (
        F = at(_,_,_,_)
   ->
	select(F, L0, L)
   ;
        select(N-F, L0, L)
   ).

replace_list(at(A,C,N,Vars), _, List0, R, List) :-
	!,
	replace_list(List0, at(A,C,N,Vars), R, List).
replace_list(_F, N, List0, R, List) :-
	replace_list(List0, N, R, List). 
replace_list([], _, _, []).
replace_list([A|As], C, D, [B|Bs]) :-
    (
       A = C-_
    ->
       B = D
    ;
       B = A
    ),
       replace_list(As, C, D, Bs).

write_proofs(P) :-
   (
       P =:= 0
   ->
       format(user_output, 'No proofs found!~n', [])
   ;
       P =:= 1
   ->
       format(user_output, '1 proof found.~n', [])
   ;
       format(user_output, '~p proofs found.~n', [P])
   ).
write_axioms(A) :-
   (
       A =:= 0
   ->
       format(user_output, 'No axioms performed!~n', [])
   ;
       A =:= 1
   ->
       format(user_output, '1 axiom performed.~n', [])
   ;
       format(user_output, '~p axioms performed.~n', [A])
   ).


prove1([vertex(_, [], _, [])], []) :-
        !.
prove1(G0, [ax(N0,AtV0,AtO0,N1,AtV1,AtO1)|Rest0]) :-
        nl,
        nl,
        portray_graph(G0),
        select(vertex(N0, [A|As0], FVs0, []), G0, G1),
        select(neg(At,AtV0,AtO0,X,Vars), [A|As0], As),
	!,
	select(vertex(N1, [B|Bs0], FVs1, Ps), G1, G2),
	select(pos(At,AtV1,AtO1,X,Vars), [B|Bs0], Bs),
        \+ cyclic(Ps, G2, N0),
	'$AXIOMS'(Ax0),
	Ax is Ax0 + 1,
	retractall('$AXIOMS'(_)),
	assert('$AXIOMS'(Ax)),
	append(As, Bs, Cs),
	merge_fvs(FVs0, FVs1, FVs),
	replace(G2, N0, N1, G3),
	replace_pars(Ps, N0, N1, Rs),
	G4 = [vertex(N1,Cs,FVs,Rs)|G3],
        portray_graph(G4),
	contract(G4, G, Rest0, Rest),
	connected(G),
	prove1(G, Rest).
prove1(G1, _) :-
        format('~nFailed!~n', []),
        portray_graph(G1),
        fail.

% test for cyclicity
% G2 contains unvisited nodes
% P contains paths from current node
% N is the node to reach for a cycle.

cyclic([P|_], G2, N) :-
    cyclic1(P, G2, N).
cyclic([_|Ps], G2, N) :-
    cyclic(Ps, G2, N).

cyclic1(par(M,P), G2, N) :-
    (
       N =:= M
    ;
       N =:= P
    ;
       select(vertex(M,_,_,Ps), G2, G3),
       cyclic(Ps, G3, N)
    ;
       P \== M,
       select(vertex(P,_,_,Ps), G2, G3),
       cyclic(Ps, G3, N)
    ).
cyclic1(univ(_,M), G2, N) :-
    (
       N =:= M
     ;
       select(vertex(M,_,_,Ps), G2, G3),
       cyclic(Ps, G3, N)
    ).        

% = connected(+Graph)
%
% true if Graph is connected or at least can be made connected
% by vertex identifications (corresponding to axioms)

connected([V|Vs]) :-
   (
       Vs = []
   ->
       /* a single-node graph is connected */
       true
   ;
       connected1([V|Vs])
   ).

connected1([]).
connected1([vertex(_,As,_,Ps)|Vs]) :-
    (
        As = []
    ->  /* in a multiple-node graph, if a node has no */
        /* atoms, it must have a link */
        Ps = [_|_]
    ;
        true
    ),
    connected1(Vs).

% merge two sets of free variables
% remove variables already instantiated (these have an integer value)
% we need to sort again (since variable instantiations/unifications may
% have changed term order)

merge_fvs(Vs0, Ws0, Zs) :-
    reduce_fvs(Vs0, Vs1),
    sort(Vs1, Vs),
    reduce_fvs(Ws0, Ws1),
    sort(Ws1, Ws),
    ord_union(Vs, Ws, Zs).

reduce_fvs([], []).
reduce_fvs([V|Vs], Ws) :-
    (
        integer(V)
    ->
        reduce_fvs(Vs, Ws)
    ;
        Ws = [V|Ws0],
        reduce_fvs(Vs, Ws0)
    ).

% = contract(+InGraph,-OutGraph)
%
% perform all valid contractions on InGraph producing OutGraph;
% these are Danos-style contractions, performed in a first-found
% search.

contract(G0, G, L0, L) :-
        contract1(G0, G1, L0, L1),
        nl,
        nl,
        portray_graph(G1),
        !,
        contract(G1, G, L1, L).
contract(G, G, L, L).

% par contraction
contract1(G0, [vertex(N1,Cs,FVs,Rs)|G], [N0-par(N1)|Rest], Rest) :-
        select(vertex(N0, As, FVsA, Ps0), G0, G1),
        select(par(N1, N1), Ps0, Ps),
	select(vertex(N1, Bs, FVsB, Qs), G1, G2),
	\+ cyclic(Qs, G2, N0),
	!,
	append(As, Bs, Cs),
	append(Ps, Qs, Rs0),
	merge_fvs(FVsA, FVsB, FVs),
	replace_pars(Rs0, N0, N1, Rs),
	replace(G2, N0, N1, G).
% forall contraction
contract1(G0, [vertex(N1,Cs,FVs,Rs)|G], [N0-univ(U,N1)|Rest], Rest) :-
        select(vertex(N0, As, FVsA, Ps0), G0, G1),
        select(univ(U, N1), Ps0, Ps),
	select(vertex(N1, Bs, FVsB, Qs), G1, G2),
	no_occurrences1(FVsA, U),
	no_occurrences(G2, U),
	!,
	append(As, Bs, Cs),
	append(Ps, Qs, Rs0),
	merge_fvs(FVsA, FVsB, FVs),
	replace_pars(Rs0, N0, N1, Rs),
	replace(G2, N0, N1, G).


% = no_occurrences(+Graph, +VarNum)
%
% walks through +Graph and checks that none of its vertices
% has the variable +VarNum in their list of free variables.

no_occurrences([], _).
no_occurrences([vertex(_, _, FVs, _)|Rest], U) :-
        no_occurrences1(FVs, U),
        no_occurrences(Rest, U).

no_occurrences1([], _).
no_occurrences1([V|Vs], U) :-
        var(U) \== V,
        no_occurrences1(Vs, U).


% = replace(+InGraph,+InNodeNum,+OutNodeNum,+Outgraph)
%
% renumbers InNode for OutNode throughout Graph.

replace([], _, _, []).
replace([vertex(N,As,FVs,Ps0)|Rest0], N0, N1, [vertex(N,As,FVs,Ps)|Rest]) :-
        replace_pars(Ps0, N0, N1, Ps),
        replace(Rest0, N0, N1, Rest).

replace_pars([], _, _, []).
replace_pars([P0|Ps0], N0, N1, [P|Ps]) :-
        replace_par(P0, N0, N1, P),
        replace_pars(Ps0, N0, N1, Ps).

replace_par(par(X,Y), N0, N1, par(V,W)) :-
        replace_item(X, N0, N1, V),
        replace_item(Y, N0, N1, W).
replace_par(univ(M,X), N0, N1, univ(M,Y)) :-
        replace_item(X, N0, N1, Y).

replace_item(X, N0, N1, Y) :-
    (
	X = N0
    ->
	Y = N1
    ;
        Y = X
    ).

% = unfolding
%
% transforms sequents, antecedents and (polarized) formulas into graphs

unfold_sequent(List, Goal, Vs0, W, Sem) :-
        retractall(node_formula(_,_,_)),
	unfold_antecedent(List, 0, W, 0, N0, 0, M, Vs0, [vertex(N0,As,FVsG,Es)|Vs1]),
	N is N0 + 1,
	number_subformulas_pos(Goal, N0, N, _, _-NGoal),
        assert(node_formula(N0, pos, NGoal)),
	free_vars_p(Goal, FVsG),
	unfold_pos(NGoal, Sem, M, _, As, [], Es, [], Vs1, []).

unfold_antecedent([], W, W, N, N, M, M, Vs, Vs).
unfold_antecedent([F|Fs], W0, W, N0, N, M0, M, [vertex(N0,As,FVsF,Es)|Vs0], Vs) :-
        N1 is N0 + 1,
        W1 is W0 + 1,
	free_vars_n(F, FVsF),
	number_subformulas_neg(F, N0, N1, N2, _-NF),
        assert(node_formula(N0, neg, NF)),
	unfold_neg(NF, '$VAR'(W0), M0, M1, As, [], Es, [], Vs0, Vs1),
	unfold_antecedent(Fs, W1, W, N2, N, M1, M, Vs1, Vs).

% = number_subformulas_neg(+Formula, +CurrentNodeNumber, +NextNodeNumberIn, -NextNodeNumberOut, -NumberFormula)
%
% assigns node numbers to all subformulas of Formula, allowing us to designate
% all (sub-)formula occurrences in a sequent by a unique node number, and in the
% case of atomic formulas a combination of node-index (where index is a
% left-to-right numbering of the atomic subformulas at a node).

number_subformulas_neg(F, C, N0, N, NF) :-
        number_subformulas_neg(F, C, N0, N, 1, _, NF).

number_subformulas_neg(at(A,Vars), C, N, N, M0, M, C-at(A,C,M0,Vars)) :-
        M is M0 + 1.
number_subformulas_neg(forall(X,A), C, N0, N, M0, M, C-forall(X,NA)) :-
	number_subformulas_neg(A, C, N0, N, M0, M, NA).
number_subformulas_neg(exists(X,A), C, N0, N, M0, M, C-exists(X,NA)) :-
	N1 is N0 + 1,
	number_subformulas_neg(A, N0, N1, N, M0, M, NA).
number_subformulas_neg(p(A,B), C, N0, N, M0, M, C-p(NA,NB)) :-
	N1 is N0 + 1,
	N2 is N1 + 1,
	number_subformulas_neg(A, N0, N2, N3, M0, M1, NA),
	number_subformulas_neg(B, N1, N3, N, M1, M, NB).
number_subformulas_neg(impl(A,B), C, N0, N, M0, M, C-impl(NA,NB)) :-
	number_subformulas_pos(A, C, N0, N1, M0, M1, NA),
	number_subformulas_neg(B, C, N1, N, M1, M, NB).

number_subformulas_pos(F, C, N0, N, NF) :-
        number_subformulas_pos(F, C, N0, N, 1, _, NF).

number_subformulas_pos(at(A,Vars), C, N, N, M0, M, C-at(A,C,M0,Vars)) :-
	M is M0 + 1.
number_subformulas_pos(forall(X,A), C, N0, N, M0, M, C-forall(X,NA)) :-
	N1 is N0 + 1,
	number_subformulas_pos(A, N0, N1, N, M0, M, NA).
number_subformulas_pos(exists(X,A), C, N0, N, M0, M, C-exists(X,NA)) :-
	number_subformulas_pos(A, C, N0, N, M0, M, NA).
number_subformulas_pos(p(A,B), C, N0, N, M0, M, C-p(NA,NB)) :-
	number_subformulas_pos(A, C, N0, N1, M0, M1, NA),
	number_subformulas_pos(B, C, N1, N, M1, M, NB).
number_subformulas_pos(impl(A,B), C, N0, N, M0, M, C-impl(NA,NB)) :-
	N1 is N0 + 1,
	N2 is N1 + 1,	
	number_subformulas_neg(A, N0, N2, N3, M0, M1, NA),
	number_subformulas_pos(B, N1, N3, N, M1, M, NB).

%= unfold(+Formula, Sem, VertexNo, VarNo, AtomsDL, EdgesDL, VerticesDL)

%unfold_neg(N-F, X, M0, M, As0, As, Es0, Es, Vs0, Vs) :-
%        unfold_neg(F, N, X, M0, M, As0, As, Es0, Es, Vs0, Vs).

unfold_neg(at(A,C,N,Vars), X, M, M, [neg(A,C,N,X,Vars)|As], As, Es, Es, Vs, Vs).
unfold_neg(forall(_,_-A), X, M0, M, As0, As, Es0, Es, Vs0, Vs) :-
	unfold_neg(A, X, M0, M, As0, As, Es0, Es, Vs0, Vs).
unfold_neg(exists(var(M0),N-A), X, M0, M, As, As, [univ(M0,N)|Es], Es, [vertex(N,Bs,FVsA,Fs)|Vs0], Vs) :-
        assert(node_formula(N, neg, A)),
        free_vars_n(A, FVsA),
	M1 is M0 + 1,
	unfold_neg(A, X, M1, M, Bs, [], Fs, [], Vs0, Vs).
unfold_neg(p(N0-A,N1-B), X, M0, M, As, As, [par(N0,N1)|Es], Es, [vertex(N0,Bs,FVsA,Fs),vertex(N1,Cs,FVsB,Gs)|Vs0], Vs) :-
        assert(node_formula(N0, neg, A)),
        assert(node_formula(N1, neg, B)),
        free_vars_n(A, FVsA),
        free_vars_n(B, FVsB),
	unfold_neg(A, pi1(X), M0, M1, Bs, [], Fs, [], Vs0, Vs1),
	unfold_neg(B, pi2(X), M1, M, Cs, [], Gs, [], Vs1, Vs).
unfold_neg(impl(_-A,_-B), X, M0, M, As0, As, Es0, Es, Vs0, Vs) :-
	unfold_pos(A, Y, M0, M1, As0, As1, Es0, Es1, Vs0, Vs1),
	unfold_neg(B, appl(X,Y), M1, M, As1, As, Es1, Es, Vs1, Vs).

unfold_pos(at(A,C,N,Vars), X, M, M, [pos(A,C,N,X,Vars)|As], As, Es, Es, Vs, Vs).
unfold_pos(forall(var(M0),N0-A), X, M0, M, As, As, [univ(M0,N0)|Es], Es, [vertex(N0,Bs,FVsA,Fs)|Vs0], Vs) :-
        assert(node_formula(N0, pos, A)),
        free_vars_p(A, FVsA),
	M1 is M0 + 1,
	unfold_pos(A, X, M1, M, Bs, [], Fs, [], Vs0, Vs).
unfold_pos(exists(_,_-A), X, M0, M, As0, As, Es0, Es, Vs0, Vs) :-
	unfold_pos(A, X, M0, M, As0, As, Es0, Es, Vs0, Vs).
unfold_pos(p(_-A,_-B), pair(X,Y), M0, M, As0, As, Es0, Es, Vs0, Vs) :-
	unfold_pos(A, X, M0, M1, As0, As1, Es0, Es1, Vs0, Vs1),
	unfold_pos(B, Y, M1, M, As1, As, Es1, Es, Vs1, Vs).
unfold_pos(impl(N0-A,N1-B), lambda(X,Y), M0, M, As, As, [par(N0,N1)|Es], Es, [vertex(N0,Bs,FVsA,Fs),vertex(N1,Cs,FVsB,Gs)|Vs0], Vs) :-
        assert(node_formula(N0, neg, A)),
        assert(node_formula(N1, pos, B)),
        free_vars_n(A, FVsA),
        free_vars_p(B, FVsB),
	unfold_neg(A, X, M0, M1, Bs, [], Fs, [], Vs0, Vs1),
	unfold_pos(B, Y, M1, M, Cs, [], Gs, [], Vs1, Vs).

% = free_vars_n(+Formula, -SetOfFreeVars)
%
% true if Formula (of negative polariy) has
% SetOfFreeVars, but with a slight twist: all
% variables bound by a tensor prefix are
% considered free. For example, a prefix of
% universal quantifiers is removed (and, in
% general, any negative forall/impl and
% postive exists/prod); this is the implicit
% tensor contraction rule).

free_vars_n(_-A, Vars) :-
        free_vars_n(A, Vars).
free_vars_n(at(_, Vars0), Vars) :-
        sort(Vars0, Vars). 
free_vars_n(at(_, _, _, Vars0), Vars) :-
	sort(Vars0, Vars).
free_vars_n(p(A,B), Vars) :-
        free_vars(A, Vars1),
        free_vars(B, Vars2),
        ord_union(Vars1, Vars2, Vars).
free_vars_n(impl(A,B), Vars) :-
        free_vars_p(A, Vars1),
        free_vars_n(B, Vars2),
        ord_union(Vars1, Vars2, Vars).
free_vars_n(forall(_,A), Vars) :-
        free_vars_n(A, Vars).
free_vars_n(exists(X,A), Vars) :-
       free_vars(A, Vars0),
       ord_delete(Vars0, X, Vars).

% = free_vars_p(+Formula, -SetOfFreeVars)
%
% true if Formula (of positive polariy) has
% SetOfFreeVars, but with a slight twist: all
% variables bound by a tensor prefix are
% considered free (this is the implicit tensor
% contraction rule).

free_vars_p(_-A, Vars) :-
        free_vars_p(A, Vars).
free_vars_p(at(_, Vars0), Vars) :-
        sort(Vars0, Vars). 
free_vars_p(at(_, _, _, Vars0), Vars) :-
	sort(Vars0, Vars).
free_vars_p(p(A,B), Vars) :-
        free_vars_p(A, Vars1),
        free_vars_p(B, Vars2),
        ord_union(Vars1, Vars2, Vars).
free_vars_p(impl(A,B), Vars) :-
        free_vars(A, Vars1),
        free_vars(B, Vars2),
        ord_union(Vars1, Vars2, Vars).
free_vars_p(exists(_,A), Vars) :-
        free_vars_p(A, Vars).
free_vars_p(forall(X,A), Vars) :-
        free_vars(A, Vars0),
        ord_delete(Vars0, X, Vars).

% = free_vars(+Formula, -SetOfFreeVars)
%
% true if Formula has SetOfFreeVars under the
% standard interpretation of free/bound.

free_vars(_-A, Vars) :-
        free_vars(A, Vars).
free_vars(at(_, Vars0), Vars) :-
        sort(Vars0, Vars). 
free_vars(at(_, _, _, Vars0), Vars) :-
	sort(Vars0, Vars).
free_vars(p(A,B), Vars) :-
        free_vars(A, Vars1),
        free_vars(B, Vars2),
        ord_union(Vars1, Vars2, Vars).
free_vars(impl(A,B), Vars) :-
        free_vars(A, Vars1),
        free_vars(B, Vars2),
        ord_union(Vars1, Vars2, Vars).
free_vars(exists(X,A), Vars) :-
        free_vars(A, Vars0),
	ord_delete(Vars0, X, Vars).
free_vars(forall(X,A), Vars) :-
        free_vars(A, Vars0),
        ord_delete(Vars0, X, Vars).

% = print_trace(+Stream, +List).

print_trace(Stream, [A|As]) :-
        format(Stream, '~n= Proof trace =~n', []),
        print_trace(As, A, Stream).

print_trace([], A, Stream) :-
        format(Stream, '~p~n= End of trace =~2n', [A]).
print_trace([B|Bs], A, Stream) :-
        format(Stream, '~p~n', [A]),
        print_trace(Bs, B, Stream).


% = some test predicates

test(Sem) :-
	prove([forall(X,exists(Y,at(f,[X,Y])))], exists(V,forall(W,at(f,[W,V]))), Sem).
test0(Sem) :-
	prove([exists(X,forall(Y,at(f,[X,Y])))], forall(V,exists(W,at(f,[W,V]))), Sem).

test2(Sem) :-
	prove([at(np,[0,1]),forall(X,impl(at(np,[X,1]),at(s,[X,2])))], at(s,[0,2]), Sem).

test3(Sem) :-
	prove([forall(Y,forall(Z,impl(impl(at(np,[0,1]),at(s,[Y,Z])),at(s,[Y,Z])))),forall(X,impl(at(np,[X,1]),at(s,[X,2])))], at(s,[0,2]), Sem).


% = test translations

test_d1(F) :-
	/* generalized quantifier */
	translate_displacement(dl(>,dr(>,at(s),at(np)),at(s)), [1,2], F).
test_d2(F) :-
	/* did */
	translate_displacement(dl(dr(dr(>,at(vp),at(vp)),at(vp)),dr(>,at(vp),at(vp))), [4,5], F).
test_d3(F) :-
	/* himself */
	translate_displacement(dl(<,dr(<,dr(>,at(vp),at(np)),at(np)),dr(>,at(vp),at(np))), [3,4], F).

test_h1(F) :-
	translate_hybrid(h(at(s),at(np)), lambda(P,lambda(Z,appl(P,appl(walks,Z)))), walks, 1, 2, F).
test_h2(F) :-
	translate_hybrid(h(at(s),h(at(s),at(np))), lambda(P,lambda(Z,appl(appl(P,everyone),Z))), everyone, 0, 1, F).

% = I need a better axiom selection strategy

test_jlbmd(Sem) :-
	translate_displacement(at(np), [0,1], John),
	translate_displacement(dl(at(np),at(s)), [1,2], Left),
	translate_displacement(dr(dl(dl(at(np),at(s)),dl(at(np),at(s))),at(s)), [2,3], Before),
	translate_displacement(at(np), [3,4], Mary),
	translate_displacement(dl(dr(dr(>,dl(at(np),at(s)),dl(at(np),at(s))),dl(at(np),at(s))),dr(>,dl(at(np),at(s)),dl(at(np),at(s)))), [4,5], Did),
	prove([John,Left,Before,Mary,Did], at(s,[0,5]), Sem).
	
