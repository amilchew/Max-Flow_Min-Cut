/-
Copyright (c) 2023 Aleksandar Milchev, Leo Okawa Ericson, Viggo Laakshoharju. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Aleksandar Milchev, Leo Okawa Ericson, Viggo Laakshoharju
-/


import data.real.basic
import data.set.basic
import tactic
import data.finset.basic
import tactic.induction

/-!
# Max flow Min cut theorem

In this file we will prove the max-flow min-cut theorem,
stating that if a maximum flow exists in a flow network,
then its value is equal to the capacity of a minimum cut in the same network.

## Main results

- `weak_duality`         : the value of every flow is less than or equal to the capacity of every cut.

  direct consequences    :
  - the value of a max flow is always less than or equal to the capacity of a min cut.
  - `max_flow_criterion` : if a flow value is equal to a cut capacity in the same flow network, then the flow is maximum.
  - `min_cut_criterion`  : if a capacity of a cut is equal to a flow value in the same network, then the cut is minimum.

- `no_augm_path`         : if the active flow gives a maximum flow, then there is no augmenting path in the residual network.
- `existence_of_a_cut`   : there exists a cut with a capacity equal to the value of the maximum flow.
- `max_flow_min_cut`     : if f is a max flow and c is a min cut in the same network, then their valies are equal (max flow min cut theorem).

## Notation

- Type V is used for the set of all vertices in our graph.

## References

- Some of the structure ideas and lemmas can be seen in https://github.com/Zetagon/maxflow-mincut.

-/

open finset


open_locale big_operators
open_locale classical

notation ` V' ` := univ

/-!
  We now define our flow network. Our goal will be to prove weak_duality.
  As direct consequences, `max_flow_criterion` and `min_cut_criterion` will be proven.
-/

structure strange_digraph (V : Type*) [inst : fintype V] :=
  (is_edge : V → V → Prop)
  (hnonsymmetric : ∀ u v : V, ¬ ((is_edge u v) ∧ (is_edge v u)))

structure capacity (V : Type*) [inst : fintype V]
  extends strange_digraph V :=
  (c : V -> V -> ℝ)
  (non_neg_capacity : ∀ u v : V, c u v ≥ 0)
  (vanishes : ∀ u v : V, ¬ (is_edge u v) → c u v = 0)

structure flow_network (V : Type*) [inst : fintype V]
  extends capacity V :=
  (source : V)
  (sink : V)

noncomputable
def mk_in {V : Type* } [inst : fintype V]
  (f : V -> V -> ℝ) (S : finset V) : ℝ := ∑ x in finset.univ \ S, ∑ y in S, f x y

noncomputable
def mk_out {V : Type* } [inst : fintype V]
  (f : V -> V -> ℝ) (S : finset V) : ℝ := ∑ x in S, ∑ y in finset.univ \ S, f x y

structure active_flow_network (V : Type*)  [fintype V] :=
  (network : flow_network V)
  (f : V -> V -> ℝ)
  (sourceNotSink: network.source ≠ network.sink)
  (non_neg_flow : ∀ u v : V, f u v ≥ 0)
  (no_overflow : ∀ u v : V, f u v ≤ network.c u v)
  (noEdgesInSource : ∀ u : V, ¬ (network.is_edge u network.source))
  (noEdgesOutSink : ∀ u: V, ¬ (network.is_edge network.sink u))
  (conservation : ∀ v : V,
                  v ∈ (V' : finset V) \ {network.source, network.sink} →
                  mk_out f {v} = mk_in f {v})

noncomputable
def F_value {V : Type*}  [fintype V] :
                  active_flow_network V -> ℝ :=
λ N, mk_out N.f {N.network.source} - mk_in N.f {N.network.source}

structure cut (V : Type*)  [fintype V] :=
  (network : flow_network V)
  (S : finset V)
  (T : finset V )
  (sins : network.source ∈ S)
  (tint : network.sink ∈ T)
  (Tcomp : T = univ \ S)

noncomputable
def cut_cap {V : Type*}  [inst' : fintype V] -- stays for capacity of the cut
    (c : cut V) : ℝ := mk_out c.network.c c.S

lemma f_vanishes_outside_edge {V : Type*} [fintype V]
  (afn : active_flow_network V) (u : V) (v : V) (not_edge: ¬afn.network.is_edge u v) :
  afn.f u v = 0 :=
  begin
    have cap_is_zero: afn.network.c u v = 0 :=
      begin
        exact afn.network.vanishes u v not_edge,
      end,
    have bar := afn.no_overflow u v,
    have foo := afn.non_neg_flow u v,
    linarith,
  end

lemma x_not_in_s {V : Type*} [fintype V]
  (c : cut V)  : ∀ x : V, x ∈ c.T -> x ∉ ({c.network.source} : finset V) :=
begin
  intros x hxinS,
  cases c,
  simp only [mem_singleton] at *,
  rw c_Tcomp at hxinS,
  have foo : univ \ c_S ∩ c_S = ∅ := sdiff_inter_self c_S univ,
  have foo : disjoint (univ \ c_S)  c_S  := sdiff_disjoint,
  have bar : c_network.source ∈ c_S := c_sins,
  exact disjoint_iff_ne.mp foo x hxinS c_network.source c_sins
end

lemma foobar { a b : ℝ } : a + - b = a - b := rfl

lemma f_zero_zero {V : Type*}  [inst' : fintype V]
  (afn : active_flow_network V) (x : V) : afn.f x x = 0 :=
begin
  have hnonsymm : _ := afn.network.hnonsymmetric x x,
  have hvanish: _ := afn.network.vanishes x x,
  simp only [not_and, imp_not_self] at hnonsymm,
  have hnon_edge := hnonsymm, clear hnonsymm,
  have hcapacity_zero := hvanish hnon_edge,
  have hno_overflow := afn.no_overflow x x,
  rw hcapacity_zero at hno_overflow,
  have hnon_neg_flow := afn.non_neg_flow x x,
  linarith,
end


lemma mk_in_single_node { V : Type* }  [fintype V]
  (p : V) (afn : active_flow_network V) :
  mk_in (afn.f) {p} = ∑ v in finset.univ, (afn.f) v p :=
begin
  rw @sum_eq_sum_diff_singleton_add _ _ _ _ univ p (by simp only [mem_univ]) (λ x, afn.f x p),
  have foo : (λ (x : V), afn.f x p) p = afn.f p p := rfl,
  simp only [congr_fun],
  rw f_zero_zero afn p,
  have bar : ∑ (x : V) in univ \ {p}, afn.f x p + 0 =
  (λ p', ∑ (x : V) in univ \ {p'}, afn.f x p') p := by simp only [add_zero],
  rw bar, clear bar,
  rw ← @finset.sum_singleton _ _ p (λp', ∑ (x : V) in univ \ {p'}, afn.f x p' ) _,
  simp only [mk_in, sum_singleton],
end

@[simp] lemma mk_in_single_node' { V : Type* }  [fintype V]
  (p : V) (afn : active_flow_network V) :
  ∑ v in finset.univ, (afn.f) v p = mk_in (afn.f) {p} := by rw mk_in_single_node

lemma mk_out_single_node { V : Type* }  [fintype V]
  (p : V) (afn : active_flow_network V) :
  mk_out afn.f {p} = ∑ v in finset.univ, (afn.f) p v :=
begin
  rw @sum_eq_sum_diff_singleton_add _ _ _ _ univ p (by simp only [mem_univ]) (λ x, afn.f p x),
  have foo : (λ (x : V), afn.f p x) p = afn.f p p := rfl,
  simp only [congr_fun],
  rw f_zero_zero afn p,
  have bar : ∑ (x : V) in univ \ {p}, afn.f p x + 0 =
  (λ p', ∑ (x : V) in univ \ {p'}, afn.f p' x) p := by simp only [add_zero],
  rw bar, clear bar,
  rw ← @finset.sum_singleton _ _ p (λp', ∑ (x : V) in univ \ {p'}, afn.f p' x) _,
  simp only [mk_out, sum_singleton],
end

@[simp] lemma mk_out_single_node' { V : Type* }  [fintype V]
  (p : V) (afn : active_flow_network V) :
  ∑ v in finset.univ, (afn.f) p v = mk_out afn.f {p} := by rw mk_out_single_node

lemma break_out_neg (a b : ℝ) : (-a) + -(b) = -(a + b) := by ring

noncomputable
def edge_flow {V : Type*}  [inst' : fintype V]
  (afn : active_flow_network V) (x : V) : ℝ := (mk_out afn.f {x} - mk_in afn.f {x})

lemma edge_flow_conservation {V: Type*} [inst' : fintype V]
  (afn : active_flow_network V) (x : V) :
  x ∈ (V' : finset V) \ {afn.network.source, afn.network.sink} -> edge_flow afn x = 0 :=
begin
  intro hx,
  unfold edge_flow,
  rw afn.conservation x,
  {ring},
  {exact hx,}
end

lemma sub_comm_zero (a b : ℝ) : a - b = 0 → b - a = 0 :=
begin
  intro eq,
  rw ← add_left_inj (a),
  rw sub_add_cancel, rw zero_add,
  rw ← add_left_inj (-b),
  rw add_neg_self,
  rw ← sub_eq_add_neg,
  rw eq_comm,
  exact eq
end

lemma set_flow_conservation {V : Type*}  [inst' : fintype V]
  (afn : active_flow_network V) (S : finset V) :
S ⊆ finset.univ \ {afn.network.source, afn.network.sink} -> mk_in afn.f S = mk_out afn.f S :=
begin
  intro hin,
  rw ← add_left_inj (- mk_out afn.f S),
  simp only [add_right_neg],
  rw ← add_zero (mk_in afn.f S),
  nth_rewrite 0 ← add_neg_self (∑ u in S, (∑ v in S, afn.f u v)),
  rw ← add_assoc,
  have tmp : mk_in afn.f S + ∑ u in S, ∑ v in S, afn.f u v = ∑ u in S, ∑ v in V', afn.f v u :=
  begin
    unfold mk_in,
    have h: S ⊆ V' := finset.subset_univ S,
    have hyp:
    ∑ (x : V) in V' \ S, ∑ (y : V) in S, afn.f x y + ∑ (u : V) in S, ∑ (v : V) in S, afn.f u v
    = ∑ u in V', ∑ v in S, afn.f u v := finset.sum_sdiff h,
    have fin: ∑ u in V', ∑ v in S, afn.f u v = ∑ u in S, ∑ v in V', afn.f v u := finset.sum_comm,
    rw hyp,
    exact fin,
  end,
  have tmp2: mk_out afn.f S + (∑ u in S, ∑ v in S, afn.f u v) = ∑ u in S, ∑ v in V', afn.f u v :=
  begin
    unfold mk_out,
    rw finset.sum_comm,
    have h: S ⊆ V' := finset.subset_univ S,
    have hyp:
    ∑ (y : V) in V' \ S, ∑ (x : V) in S, afn.f x y + ∑ (u : V) in S, ∑ (v : V) in S, afn.f v u =
    ∑ u in V', ∑ v in S, afn.f v u := finset.sum_sdiff h,
    have obvs: ∑ (u : V) in S, ∑ (v : V) in S, afn.f v u =
    ∑ (u : V) in S, ∑ (v : V) in S, afn.f u v := finset.sum_comm,
    have fin: ∑ u in V', ∑ v in S, afn.f v u = ∑ u in S, ∑ v in V', afn.f u v := finset.sum_comm,
    rw obvs at hyp,
    rw hyp,
    exact fin,
  end,
  rw tmp,
  rw add_assoc,
  rw break_out_neg,
  nth_rewrite 1 add_comm,
  rw tmp2,
  clear tmp tmp2,
  rw foobar,
  rw ← @sum_sub_distrib _ _ S _ _ _,
  simp only [mk_in_single_node', mk_out_single_node'],
  have hseq : S = S := rfl,
  have h : ∀ (x : V), x ∈ S -> - edge_flow afn x = 0 :=
  begin
    intros x hx,
    unfold edge_flow,
    rw afn.conservation x,
    { ring, },
    { exact finset.mem_of_subset hin hx,}
  end,
  have foo := finset.sum_congr hseq h,
  unfold edge_flow at foo,
  simp at foo,
  rw ← foo,
  simp,
end

lemma move_right (a b : ℝ) : b = a → a - b = 0 :=
begin
  intro eq,
  rw eq_comm,
  rw ← add_left_inj (b),
  simp, exact eq
end

lemma set_flow_conservation_eq {V : Type*}  [inst' : fintype V]
  (afn : active_flow_network V) (S : finset V) :
S ⊆ finset.univ \ {afn.network.source, afn.network.sink} -> mk_out afn.f S - mk_in afn.f S = 0 :=
begin
  intro hip,
  have h: mk_in afn.f S = mk_out afn.f S := set_flow_conservation afn S hip,
  rw eq_comm at h,
  rw ← add_left_inj (-mk_in afn.f S) at h,
  rw add_neg_self(mk_in afn.f S) at h, exact h
end

lemma add_zero_middle (a b c: ℝ): c = 0 → a + c - b = a - b := by {intro eq, linarith}

lemma group_minus (a b c d : ℝ): a + b - c - d = a + b - (c + d) := by ring

lemma same_source_and_sink {V: Type*} [inst' : fintype V]
  (afn: active_flow_network V) (ct : cut V) (same_net : afn.network = ct.network):
  afn.network.source = ct.network.source ∧ afn.network.sink = ct.network.sink :=
begin
  rw same_net,
  split,
  {simp},
  simp
end

lemma flow_value_global_ver {V : Type*}  [inst' : fintype V]
  (afn : active_flow_network V) (ct : cut V)
  (same_net : afn.network = ct.network) :
  mk_out afn.f {afn.network.source} - mk_in afn.f {afn.network.source} =
  mk_out afn.f ct.S - mk_in afn.f ct.S :=
begin
  set S := ct.S,
  set T := ct.T,
  set s := afn.network.source,
  set t := afn.network.sink,
  set f := afn.f,
  have same: s = s := by {simp},
  have hs : s = afn.network.source := rfl,
  have hT : T = ct.T := rfl,
  have singleton: s ∈ {s} := finset.mem_singleton.2 same,
  have sInS: s ∈ S :=
  begin
    have same_source: s = ct.network.source := (same_source_and_sink afn ct same_net).1,
    rw same_source,
    exact ct.sins,
  end,
  have hS: {s} ⊆  S := (finset.singleton_subset_iff).2 sInS,
  have disjS: disjoint {s} (S \ {s}) :=
    begin 
      have sOut: s ∉ (S \ {s}) := finset.not_mem_sdiff_of_mem_right singleton,
      exact finset.disjoint_singleton_left.2 sOut,
    end,
  have sInCompl: {s} ⊆ V' \ (S \ {s}) :=
  begin
    have sIn: {s} ⊆ V' := finset.subset_univ {s},
    have conj: {s} ⊆ V' ∧ disjoint {s} (S \ {s}) := and.intro sIn disjS,
    exact finset.subset_sdiff.2 conj,
  end,
  have tNotS: t ≠ s :=
  begin 
    by_contradiction h,
    have contr: s = t := by rw ← h,
    exact absurd contr afn.sourceNotSink,
  end,
  have tNotInS: t ∉ S :=
  begin
    have same_sink: t = ct.network.sink := (same_source_and_sink afn ct same_net).2,
    have tInT: t ∈ T := by {rw same_sink, exact ct.tint},
    have Tcomp : T = univ \ S := ct.Tcomp,
    have foo: S = univ \ (univ \ S) :=
    by {simp only [sdiff_sdiff_right_self, finset.inf_eq_inter, finset.univ_inter]},
    have Scomp : S = univ \ T := by {rw ← Tcomp at foo, exact foo},
    rw Scomp at *,
    exact finset.not_mem_sdiff_of_mem_right tInT,
  end,
  have seteq: V' \ (S \ {s}) \ {s} = V' \ S :=
  begin
    ext x,
    have eq1: V' \ (S \ {s}) \ {s} = V' \ (S \ {s}) ∩ (V' \ {s}) := 
    finset.sdiff_sdiff_left' V' (S \ {s}) {s},
    rw eq1,
    have xIn: x ∈ V' := finset.mem_univ x,
    split,
    {
      intro hyp,
      have xIn1: x ∈ V' \ (S \ {s}) := (finset.mem_inter.1 hyp).1,
      have xIn2: x ∈ V' \ {s} := (finset.mem_inter.1 hyp).2,
      have xOut: x ∉ S := 
      begin
        have xOut1: x ∉ (S \ {s}) := (finset.mem_sdiff.1 xIn1).2,
        have xOut2: x ∉ {s} := (finset.mem_sdiff.1 xIn2).2,
        have xOutAnd: x ∉ (S \ {s}) ∧ x ∉ {s} := and.intro xOut1 xOut2,
        have eq2: S = (S \ {s}) ∪ {s} :=
        begin
          have inter: S ∩ {s} = {s} := finset.inter_singleton_of_mem sInS,
          have eq3: (S \ {s}) ∪ S ∩ {s} = S := by rw finset.sdiff_union_inter S {s},
          calc 
            S 
                = (S \ {s}) ∪ S ∩ {s} : eq_comm.1 eq3
            ... = (S \ {s}) ∪ {s} : by rw inter,
        end,
        rw eq2,
        exact finset.not_mem_union.2 xOutAnd, 
      end,
      have concl: x ∈ V' ∧ x ∉ S := and.intro xIn xOut,
      exact finset.mem_sdiff.2 concl,
    },
    intro hyp,
    have xOutS: x ∉ S := (finset.mem_sdiff.1 hyp).2,
    have xOut: x ∉ S \ {s} :=
    begin
      by_contradiction h,
      have contr: x ∈ S := (finset.mem_sdiff.1 h).1,
      exact absurd contr xOutS,
    end,
    have h1: x ∈ V' ∧ x ∉ S \ {s} := and.intro xIn xOut,
    have xIn1: x ∈ V' \ (S \ {s}) := finset.mem_sdiff.2 h1,
    have xNots: x ∉ {s} :=
    begin
      by_contradiction h,
      have contr: x ∈ S := finset.mem_of_subset hS h,
      exact absurd contr xOutS,
    end,
    have concl: x ∈ V' ∧ x ∉ {s} := and.intro xIn xNots,
    have xIn2: x ∈ V' \ {s} := finset.mem_sdiff.2 concl,
    have member: x ∈ V' \ (S \ {s}) ∧ x ∈ V' \ {s} := and.intro xIn1 xIn2,
    exact finset.mem_inter.2 member,
  end,
  have union: V' \ S ∪ S \ {s} = V' \ {s} :=
  begin
    ext x,
    have xIn: x ∈ V' := finset.mem_univ x,
    split,
    {
      intro hyp,
      have h1: x ∈ V' \ S ∨ x ∈ S \ {s} := finset.mem_union.1 hyp,
      have h2: x ∈ V' \ S → x ∈ V' \ {s} :=
      begin
        intro hip,
        have xOutS: x ∉ S := (finset.mem_sdiff.1 hip).2,
        have xNots: x ∉ {s} :=
        begin
          by_contradiction h,
          have contr: x ∈ S := finset.mem_of_subset hS h,
          exact absurd contr xOutS,
        end,
        have concl: x ∈ V' ∧ x ∉ {s} := and.intro xIn xNots, 
        exact finset.mem_sdiff.2 concl,
      end,
      have h3: x ∈ S \ {s} → x ∈ V' \ {s} :=
      begin
        intro hypo,
        have xNots: x ∉ {s} := (finset.mem_sdiff.1 hypo).2,
        have concl: x ∈ V' ∧ x ∉ {s} := and.intro xIn xNots,
        exact finset.mem_sdiff.2 concl,
      end,
      exact or.elim h1 h2 h3,
    },
    intro hyp,
    have xNots: x ∉ {s} := (finset.mem_sdiff.1 hyp).2,
    by_cases h' : x ∈ S,
    { 
      have and: x ∈ S ∧ x ∉ {s} := and.intro h' xNots, 
      have xInSs: x ∈ S \ {s} := finset.mem_sdiff.2 and,
      have conj: x ∈ V' \ S ∨ x ∈ S \ {s} := or.intro_right (x ∈ V' \ S) xInSs,
      exact finset.mem_union.2 conj,
    },
    {
      have and: x ∈ V' ∧ x ∉ S := and.intro xIn h',
      have xInVS: x ∈ V' \ S := finset.mem_sdiff.2 and,
      have conj: x ∈ V' \ S ∨ x ∈ S \ {s} := or.intro_left (x ∈ S \ {s}) xInVS,
      exact finset.mem_union.2 conj,
    },
  end,
  have disj: disjoint (V' \ S) (S \ {s}) :=
  begin
    have h1: (V' \ S) ∩ (S \ {s}) = ∅ := 
    begin
      have noMembers: ∀ (v : V), v ∉ (V' \ S) ∩ (S \ {s}) := 
      begin
      intro v,
      by_contradiction h,
      have vInVS: v ∈ (V' \ S) := (finset.mem_inter.1 h).1,
      have vNotS: v ∉ S := (finset.mem_sdiff.1 vInVS).2,
      have vInSs: v ∈ (S \ {s}) := (finset.mem_inter.1 h).2,
      have vInS: v ∈ S := (finset.mem_sdiff.1 vInSs).1,
      exact absurd vInS vNotS,
      end,
      exact finset.eq_empty_of_forall_not_mem noMembers,
    end,
    have h2: ¬ ((V' \ S) ∩ (S \ {s})).nonempty :=
    begin
      by_contradiction h,
      have contr: (V' \ S) ∩ (S \ {s}) ≠ ∅ := finset.nonempty.ne_empty h,
      exact absurd h1 contr,
    end,
    by_contradiction notDisjoint,
    have contr: ((V' \ S) ∩ (S \ {s})).nonempty := finset.not_disjoint_iff_nonempty_inter.1 notDisjoint,
    exact absurd contr h2,
  end,
  have disjTS: disjoint {t} {s} := finset.disjoint_singleton.2 (tNotS),
  have expand: mk_out afn.f {s} + (mk_out afn.f (S \ {s}) - mk_in afn.f (S \ {s})) - mk_in afn.f {s}
  =  mk_out afn.f {s} - mk_in afn.f {s} :=
  begin
    have h3: s ∉ S \ {s} := finset.not_mem_sdiff_of_mem_right singleton,
    have eq: mk_out afn.f (S \ {s}) - mk_in afn.f (S \ {s}) = 0 :=
    begin
      have h: (S \ {s}) ⊆ finset.univ \ {s,t} :=
      begin
        intros x xInSet,
        have xIn: x ∈ V' := finset.mem_univ x,
        have xInS: x ∈ S:= ((finset.mem_sdiff).1 xInSet).1,
        have xNotInT: x ∉ {t} :=
        begin
          by_contradiction h,
          have eq: x = t := finset.mem_singleton.1 h,
          rw eq at xInS,
          contradiction,
        end,
        have union: ({s}: finset V) ∪ {t} = {s,t} := by refl,
        have xNotInS: x ∉ {s} := ((finset.mem_sdiff).1 xInSet).2,
        have xOut: x ∉ {s,t} :=
        begin
          by_contradiction h,
          rw ← union at h, 
          have inUnion: x ∈ {s} ∨ x ∈ {t} := finset.mem_union.1 h,
          have contr1: x ∈ {s} → false := 
          begin
            intro assumption,
            exact absurd assumption xNotInS,
          end,
          have contr2: x ∈ {t} → false := 
          begin
            intro assumption,
            exact absurd assumption xNotInT,
          end,
          exact or.elim inUnion contr1 contr2,
        end,
        have and: x ∈ V' ∧ x ∉ {s,t} := and.intro xIn xOut,
        exact finset.mem_sdiff.2 and,
      end,
      exact set_flow_conservation_eq afn (S \ {s}) h,
    end,
    exact add_zero_middle (mk_out afn.f {s}) (mk_in afn.f {s}) (mk_out afn.f (S \ {s}) - mk_in afn.f (S \ {s})) eq,
  end,
  have sum1: mk_out afn.f {s} + mk_out afn.f (S \ {s}) = 
  mk_out afn.f S + ∑ u in (S \ {s}), afn.f s u + ∑ u in (S \ {s}), afn.f u s :=
  begin
    unfold mk_out,
    have eq1: ∑ (x : V) in S, ∑ (y : V) in V' \ S, afn.f x y = 
    ∑ (x : V) in (S \ {s}) , ∑ (y : V) in V' \ S, afn.f x y + ∑ (x : V) in {s}, ∑ (y : V) in V' \ S, afn.f x y := 
    by {rw finset.sum_sdiff hS},
    have eq2: ∑ (x : V) in {s}, ∑ (y : V) in V' \ S, afn.f x y = ∑ (y : V) in V' \ S, afn.f s y := by simp,
    have eq3: ∑ (x : V) in (S \ {s}), ∑ (y : V) in V' \ (S \ {s}), afn.f x y = 
    ∑ (x : V) in (S \ {s}), afn.f x s + ∑ (x : V) in (S \ {s}), ∑ (y : V) in V' \ S, afn.f x y :=
    begin
      have obvs: ∑ (x : V) in (S \ {s}), ∑ (y : V) in V' \ (S \ {s}), f x y = 
      ∑ (y : V) in V' \ (S \ {s}), ∑ (x : V) in (S \ {s}), f x y := finset.sum_comm,
      have sdiff: ∑ (y : V) in V' \ (S \ {s}), ∑ (x : V) in (S \ {s}), f x y = 
      ∑ (y : V) in V' \ S, ∑ (x : V) in (S \ {s}), f x y + ∑ (y : V) in {s}, ∑ (x : V) in (S \ {s}), f x y :=
      by {rw ← finset.sum_sdiff sInCompl, rw seteq},
      have obs: ∑ (y : V) in {s}, ∑ (x : V) in (S \ {s}), f x y = ∑ (x : V) in (S \ {s}), f x s := by {simp},
      have swap: ∑ (y : V) in V' \ S, ∑ (x : V) in S \ {s}, f x y = 
      ∑ (x : V) in S \ {s}, ∑ (y : V) in V' \ S, f x y := finset.sum_comm,
      rw obs at sdiff,
      rw [obvs, sdiff, add_comm, swap],
    end,
    have eq4: ∑ (x : V) in {s}, ∑ (y : V) in V' \ {s}, afn.f x y = 
    ∑ (y : V) in V' \ S, afn.f s y + ∑ (u : V) in S \ {s}, afn.f s u :=
    begin
      have obvs: ∑ (x : V) in {s}, ∑ (y : V) in V' \ {s}, afn.f x y = 
      ∑ (y : V) in V' \ {s}, afn.f s y := by {simp},
      rw obvs,
      rw ← union,
      exact finset.sum_union disj,
    end,
    linarith
  end,
  have sum2: mk_in afn.f (S \ {s}) + mk_in afn.f {s} = 
  mk_in afn.f S + ∑ u in (S \ {s}), afn.f s u + ∑ u in (S \ {s}), afn.f u s :=
  begin
    unfold mk_in,
    have eq1: ∑ (x : V) in V' \ S, ∑ (y : V) in S, afn.f x y =
    ∑ (x : V) in V' \ S, ∑ (y : V) in (S \ {s}), afn.f x y + ∑ (x : V) in V' \ S, ∑ (y : V) in {s}, afn.f x y :=
    begin
      have obvs: ∑ (x : V) in V' \ S, ∑ (y : V) in S, afn.f x y = ∑ (y : V) in S, ∑ (x : V) in V' \ S, afn.f x y := finset.sum_comm,
      have sdiff: ∑ (y : V) in S, ∑ (x : V) in V' \ S, afn.f x y = 
      ∑ (y : V) in (S \ {s}), ∑ (x : V) in V' \ S, afn.f x y + ∑ (y : V) in {s}, ∑ (x : V) in V' \ S, afn.f x y := 
      by {rw finset.sum_sdiff hS},
      have swap: ∑ (y : V) in (S \ {s}), ∑ (x : V) in V' \ S, afn.f x y + ∑ (y : V) in {s}, ∑ (x : V) in V' \ S, afn.f x y = 
      ∑ (x : V) in V' \ S, ∑ (y : V) in (S \ {s}), afn.f x y + ∑ (x : V) in V' \ S, ∑ (y : V) in {s}, afn.f x y := 
      begin 
        have eq11: ∑ (y : V) in (S \ {s}), ∑ (x : V) in V' \ S, afn.f x y = 
        ∑ (x : V) in V' \ S, ∑ (y : V) in (S \ {s}), afn.f x y := finset.sum_comm,
        have eq12: ∑ (y : V) in {s}, ∑ (x : V) in V' \ S, afn.f x y =
        ∑ (x : V) in V' \ S, ∑ (y : V) in {s}, afn.f x y := finset.sum_comm,
        linarith,
      end,
      linarith,
    end,
    have eq2: ∑ (x : V) in V' \ S, ∑ (y : V) in {s}, afn.f x y = ∑ (u : V) in V' \ S, afn.f u s := by {simp},
    have eq3: ∑ (x : V) in V' \ (S \ {s}), ∑ (y : V) in S \ {s}, afn.f x y =
    ∑ (x : V) in V' \ S, ∑ (y : V) in S \ {s}, afn.f x y + ∑ (u : V) in S \ {s}, afn.f s u :=
    begin
      have eq31: ∑ (x : V) in V' \ (S \ {s}), ∑ (y : V) in S \ {s}, afn.f x y = 
      ∑ (x : V) in V' \ S, ∑ (y : V) in S \ {s}, afn.f x y + ∑ (x : V) in {s}, ∑ (y : V) in S \ {s}, afn.f x y :=
      by {rw ← finset.sum_sdiff sInCompl, rw seteq},
      have eq32: ∑ (x : V) in {s}, ∑ (y : V) in S \ {s}, afn.f x y = ∑ (u : V) in S \ {s}, afn.f s u := by {simp},
      linarith,
    end,
    have eq4: ∑ (x : V) in V' \ {s}, ∑ (y : V) in {s}, afn.f x y =
    ∑ (u : V) in V' \ S, f u s + ∑ (u : V) in S \ {s}, afn.f u s :=
    begin
      have obvs: ∑ (u : V) in V' \ S, afn.f u s = 
      ∑ (x : V) in V' \ S, ∑ (y : V) in {s}, afn.f x y := by {simp},
      have obs: ∑ (u : V) in S \ {s}, afn.f u s = 
      ∑ (x : V) in S \ {s}, ∑ (y : V) in {s}, afn.f x y := by {simp},
      rw ← union,
      rw [obvs,obs],
      exact finset.sum_union disj,
    end,
    linarith,
  end,
  rw ← expand,
  rw add_sub,
  rw group_minus (mk_out afn.f {s}) (mk_out afn.f (S \ {s})) (mk_in afn.f (S \ {s})) (mk_in afn.f {s}),
  linarith
end

/-!
  Here is our first big lemma, weak duality.
  Every flow is less than or equal to the capacity of every cut in the same network.
-/

lemma weak_duality {V: Type*} [inst' : fintype V]
  (afn: active_flow_network V) (ct : cut V) (same_net : afn.network = ct.network):
  F_value afn ≤ cut_cap ct :=
begin
  set S := ct.S,
  set T:= ct.T,
  set s := afn.network.source,
  set t := afn.network.sink,
  unfold cut_cap,
  have same: s = s := by {simp},
  have hs : s = afn.network.source := rfl,
  have hT : T = ct.T := rfl,
  have singleton: s ∈ {s} := finset.mem_singleton.2 same,
  have sInS: s ∈ S :=
  begin
    have same_source: s = ct.network.source := (same_source_and_sink afn ct same_net).1,
    rw same_source,
    exact ct.sins,
  end,
  have hS: {s} ⊆  S := (finset.singleton_subset_iff).2 sInS,
  have sInCompl: {s} ⊆ V' \ (S \ {s}) :=
  begin
    have sIn: {s} ⊆ V' := finset.subset_univ {s},
    have disjS: disjoint {s} (S \ {s}) :=
    begin 
      have sOut: s ∉ (S \ {s}) := finset.not_mem_sdiff_of_mem_right singleton,
      exact finset.disjoint_singleton_left.2 sOut,
    end,
    have conj: {s} ⊆ V' ∧ disjoint {s} (S \ {s}) := and.intro sIn disjS,
    exact finset.subset_sdiff.2 conj,
  end,
  have tNotInS: t ∉ S :=
  begin
    have same_sink: t = ct.network.sink := (same_source_and_sink afn ct same_net).2,
    have tInT: t ∈ T := by {rw same_sink, exact ct.tint},
    have Tcomp : T = univ \ S := ct.Tcomp,
    have foo: S = univ \ (univ \ S) :=
    by {simp only [sdiff_sdiff_right_self, finset.inf_eq_inter, finset.univ_inter]},
    have Scomp : S = univ \ T := by {rw ← Tcomp at foo, exact foo},
    rw Scomp at *,
    exact finset.not_mem_sdiff_of_mem_right tInT,
  end,
  have lemma1: F_value afn = mk_out afn.f S - mk_in afn.f S :=
  begin
    unfold F_value,
    exact flow_value_global_ver afn ct same_net,
  end,
  have lemma2: mk_out afn.f S ≤  mk_out ct.network.to_capacity.c S :=
  begin
    have no_overflow: mk_out afn.f S ≤ mk_out afn.network.to_capacity.c S :=
    begin
      unfold mk_out,
      have flowLEcut: ∀ (x y : V), (x ∈ V' \ S ∧ y ∈ S) → 
      (afn.f x y ≤ afn.network.to_capacity.c x y) :=
      begin
        intros x y hyp,
        exact afn.no_overflow x y,
      end,
      sorry,
      -- exact finset.sum_le_sum flowLEcut,
    end,
    unfold mk_out,
    unfold mk_out at no_overflow,
    rw same_net at no_overflow,
    exact no_overflow,
  end,
  have lemma3: F_value afn ≤ mk_out afn.f S :=
  begin
    rw lemma1,
    have obs: mk_out afn.f S = mk_out afn.f S + 0 := by rw [add_zero],
    rw obs,
    simp,
    unfold mk_in,
    have nonneg_flow: ∀ (u v : V), (u ∈ V' \ S ∧ v ∈ S) → afn.f u v ≥ 0 :=
    begin
      intros u v hyp,
      exact afn.non_neg_flow u v,
    end,
    sorry,
    -- exact finset.sum_nonneg nonneg_flow,
  end,
  apply le_trans lemma3 lemma2,
end

lemma zero_left_move {a b c d : ℝ} : (0 = a + b - c - d) -> (d - b = a - c) :=
by {intro h, linarith}

def is_max_flow_network  {V : Type*}  [inst' : fintype V]
  (fn: active_flow_network V) : Prop :=
  ∀ fn' : active_flow_network V, fn.network = fn'.network → F_value fn' ≤ F_value fn

def is_min_cut {V : Type*}  [inst' : fintype V]
  (fn: cut V) : Prop := ∀ fn' : cut V, fn.network = fn'.network → cut_cap fn ≤ cut_cap fn'

lemma max_flow_criterion  {V : Type*}  [inst' : fintype V]
  (afn : active_flow_network V) (ct : cut V) (hsame_network: afn.network = ct.network):
  cut_cap ct = F_value afn -> is_max_flow_network afn :=
begin
  intro eq,
  intro fn,
  intro same_net,
  rw ← eq,
  have same_network: fn.network = ct.network := by {rw ← same_net, exact hsame_network,},
  exact weak_duality (fn) (ct) (same_network),
end

lemma min_cut_criterion  {V : Type*}  [inst' : fintype V]
  (afn : active_flow_network V) (ct : cut V) (same_net: afn.network = ct.network) :
  cut_cap ct = F_value afn -> is_min_cut ct :=
begin
  intro eq,
  intros cut eq_net,
  rw eq,
  have h: afn.network = cut.network := by {rw same_net, exact eq_net,},
  exact weak_duality (afn) (cut) (h),
end

/-!
  We now define our residual network. Our goal is to prove no_augm_path.
-/

noncomputable
def mk_rsf {V : Type*}  [inst' : fintype V] -- stays for residual flow
  (afn : active_flow_network V)
  (u v : V) : ℝ :=
  if  afn.network.is_edge u v
  then afn.network.c  u v - afn.f u v
  else if afn.network.is_edge v u
        then afn.f v u
        else 0

structure residual_network  (V : Type*)  [inst' : fintype V] :=
  (afn : active_flow_network V)
  (f' : V -> V -> ℝ)
  (f_def : f' = mk_rsf afn)
  (is_edge : V -> V -> Prop)
  (is_edge_def : is_edge = λ u v, f' u v > 0 )

noncomputable
def mk_rsn {V : Type*} [fintype V] -- stays for residual network
  (afn : active_flow_network V) : residual_network V :=
  ⟨afn, mk_rsf afn, rfl, λ u v, mk_rsf afn u v > 0 , rfl ⟩

universe u

/-
  We define a path structure indicating if there is a path between two vertices,
  given the edges in the graph.
-/

inductive path {V : Type u } (is_edge : V -> V -> Prop) (a : V) : V → Type (u + 1)
| nil  : path a
| cons : Π {b c : V}, path b → (is_edge b c) → path c

def no_augumenting_path {V : Type*} [inst' : fintype V]
  (rsn : residual_network V) : Prop :=
  ∀ t : V, ∀ p : path rsn.is_edge rsn.afn.network.source t, ¬ (t = rsn.afn.network.sink)

def path.in {V : Type u }
  {is_edge : V -> V -> Prop}
  (u v : V)
  {s : V} : ∀ {t : V}, path is_edge s t -> Prop
  | t (@path.nil  _ is_edge' a)  := u = v
  | t (@path.cons _ _ _ t' _ p _)  := (u = t' ∧ v = t) ∨ (@path.in t' p)

lemma residual_capacity_non_neg {V : Type*} [inst' : fintype V]
  (rsn : residual_network V) : ∀ u v : V,  0 ≤ rsn.f' u v :=
begin
  intros u v,
  cases rsn,
  simp only,
  rw rsn_f_def,
  unfold mk_rsf,
  have tmp := classical.em (rsn_afn.network.to_capacity.to_strange_digraph.is_edge u v),
  cases tmp,
  {
    simp only [tmp, if_true, sub_nonneg, rsn_afn.no_overflow],
  },
  {
    simp only [tmp, if_false], clear tmp,
    have tmp := classical.em (rsn_afn.network.to_capacity.to_strange_digraph.is_edge v u),
    cases tmp,
    {
      have h := rsn_afn.non_neg_flow v u,
      simp only [tmp, h, if_true],
      linarith,
    },
    {
      simp only [tmp, if_false],
    },
  },
end

/-!
  Here is our second big lemma, if the active flow is maximum,
  then no augmenting path exists in the residual network.
-/

lemma no_augm_path {V : Type*} [inst' : fintype V]
  (rsn : residual_network V) : (is_max_flow_network rsn.afn) -> no_augumenting_path rsn :=
begin
  intros max_flow v exists_path,
  by_contradiction is_sink,
  set s := rsn.afn.network.source,
  set t := rsn.afn.network.sink,
  set vertices := {s} ∪ { x | (∃ y: V, exists_path.in x y) }, --all vertices in the augmenting path
  set d := 0,
  -- set flows := { rsn.f' x y | exists_path.in x y }, -- set of reals, why it doesn't work?
  -- set d := flows.min, -- the minimum flow in the augmenting path
  have pos: 0 < d := by sorry, -- by definition of is_edge in the residual network
  set better_flow: active_flow_network V :=
  ⟨rsn.afn.network,
  (λ u v : V, if exists_path.in u v then rsn.afn.f u v + d
              else if exists_path.in v u then rsn.afn.f u v - d else rsn.afn.f u v),
  begin -- source ≠ sink
    exact rsn.afn.sourceNotSink,
  end,
  begin -- non_neg_flow
    intros u v,
    by_cases h: exists_path.in u v,
    {
      have h1: rsn.afn.f u v ≥ 0 := rsn.afn.non_neg_flow u v,
      have h2: d ≥ 0 := -- needs to be changed, we can use the definition of rsn and split into cases
      begin
        by_contradiction h',
        have h3: d < 0 := lt_of_not_ge h',
        have h4: ¬ d < 0 := not_lt_of_gt pos,
        exact absurd h3 h4,
      end,
      linarith,
    },
    {
      by_cases h': exists_path.in v u,
        {
          have h1: rsn.f' v u = rsn.afn.f u v :=
          begin
            rw rsn.f_def,
            have edge: rsn.afn.network.is_edge v u := by sorry,-- use h' and definition of path.in
            unfold mk_rsf,
            sorry, -- just use edge to get the wanted result
          end,
          have h2: rsn.f' v u ≥ d := by sorry, -- minimality of d
          have h3: rsn.afn.f u v ≥ d := by {rw ←h1, exact h2},
          linarith,
        },
        {
          -- exact rsn.afn.non_neg_flow u v, -- should be correct, why is not working?
          linarith,
        },
    },
  end,
  begin -- no_overflow
    intros u v,
    by_cases h: exists_path.in u v,
    {
      have h1: rsn.afn.f u v + d ≤ rsn.afn.network.to_capacity.c u v := by sorry,
      -- begin
      --   have h2: rsn.afn.f u v + rsn.f' u v ≤ rsn.afn.network.to_capacity.c u v := by def of rsn
      --   have h3: d ≤ rsn.f' u v := by minimality of d
      --   have h4: rsn.afn.f u v + d ≤ rsn.afn.f u v + rsn.f' u v := by {linarith},
      --   exact le_trans h4 h2
      -- end,
      linarith,
    },
    {
      by_cases h': exists_path.in v u,
        {
          have h1: rsn.afn.f u v ≤ rsn.afn.network.to_capacity.c u v := rsn.afn.no_overflow u v,
          linarith, -- maybe pos will have to be used when d is properly defined
        },
        {
          have h1: rsn.afn.f u v ≤ rsn.afn.network.to_capacity.c u v := rsn.afn.no_overflow u v,
          linarith,
        },
    },
  end,
  begin --noEdgesInSource
    exact rsn.afn.noEdgesInSource,
  end,
  begin --noEdgesOutSink
    exact rsn.afn.noEdgesOutSink,
  end,
  begin -- conservation
    intros v vNotSinkSource,
    by_cases h: v ∈ vertices,
    {
      -- Issues: How are we proving the cardinality of predecessor and ancestor is 1?
      -- How exactly do we use that within the code to prove h2 and h3?
      set predecessor := {u | exists_path.in u v},
      set ancestor := {w | exists_path.in v w},
      have h1: mk_out rsn.afn.f {v} = mk_in rsn.afn.f {v} := rsn.afn.conservation v vNotSinkSource,
      -- have h2: mk_in f {v} = rsn.afn.mk_in {v} + d := by sorry, -- use the predecessor
      -- have h3: mk_out f {v} = rsn.afn.mk_out {v} + d := by sorry, -- use the ancestor
      -- rw [h2,h3,h1],
      -- rfl,
      sorry,
    },
    {
      sorry,
      -- have h1: ∀ u : V, ¬exists_path.in u v :=
      -- begin
      --   by_contradiction h',
      --   have ancestor: ∃w: exists_path.in v w := by v ≠ t,
      --   have contr: v ∈ vertives := by def of vertices and ancestor,
      --   contradiction -- with ¬v ∈ vertices,
      -- end,
      -- have h2: ∀ w : V, ¬exists_path.in u w :=
      -- begin
      --   by_contradiction h',
      --   have contr: v ∈ vertives := by def of vertices,
      --   contradiction -- with ¬v ∈ vertices
      -- end,
      -- have h3: ∀ u : V, better_flow.f u v = rsn.afn.f u v := by h1 and h2
      -- have h4: ∀ w : V, better_flow.f v w = rsn.afn.f v w := by h1 and h2
      -- rw [h3,h4],
      -- exact rsn.afn.conservation v vNotSinkSource,
    },
  end
  ⟩,
  have flow_value: F_value better_flow = F_value rsn.afn + d :=
  begin
    unfold F_value,
    have h1: mk_out better_flow.f {better_flow.network.source} =
    mk_out rsn.afn.f {rsn.afn.network.source} + d :=
    by sorry,
    -- take the edge with the added flow
    -- Issue: How do we prove that there is exactly one edge? How do we use it to prove h1?
    have h2: mk_in better_flow.f {better_flow.network.source} =
    mk_in rsn.afn.f {rsn.afn.network.source} := by {linarith},
    rw [h1,h2],
    linarith
  end,
  have le: F_value rsn.afn ≥ F_value better_flow :=
  begin
    have same_net: better_flow.network = rsn.afn.network := by {simp},
    unfold is_max_flow_network at max_flow,
    exact max_flow better_flow same_net,
  end,
  have lt: F_value rsn.afn < F_value better_flow :=
  begin
    rw flow_value,
    have h1: F_value rsn.afn - F_value rsn.afn < d :=
    begin
      have eq: F_value rsn.afn - F_value rsn.afn = 0 := by ring,
      rw eq,
      linarith
    end,
    have h2: F_value rsn.afn < F_value rsn.afn + d := lt_add_of_sub_left_lt h1,
    exact gt_iff_lt.2 h2,
  end,
  have nlt: ¬F_value rsn.afn < F_value better_flow := not_lt_of_ge le,
  exact absurd lt nlt,
end

/-!
  Now, we will prove that there exists a cut with value equal to the max flow in the same network.
  We will use a constructive proof, so we will construct our minimum cut.
-/

noncomputable
def mk_cut_set {V : Type u} [inst' : fintype V] -- The source set for the minimum cut
  (rsn : residual_network V) : finset V :=
  {x | (∃ p : path rsn.is_edge rsn.afn.network.source x, true)}.to_finset

noncomputable
def mk_cut_from_S {V : Type*} [inst' : fintype V]
  (rsn : residual_network V)
  (hno_augumenting_path : no_augumenting_path rsn)
  (S : finset V) (hS : S = mk_cut_set rsn) : cut V :=
⟨rsn.afn.network, S, V' \ S,
  begin
    rw hS,
    unfold mk_cut_set,
    simp only [set.mem_to_finset, set.mem_set_of_eq],
    exact exists.intro path.nil trivial,
  end,
  begin
    rw hS,
    unfold mk_cut_set,
    simp only [mem_sdiff, mem_univ, set.mem_to_finset, set.mem_set_of_eq, true_and],
    intro p,
    unfold no_augumenting_path at hno_augumenting_path,
    specialize hno_augumenting_path rsn.afn.network.sink ,
    simp only [eq_self_iff_true, not_true] at hno_augumenting_path,
    apply exists.elim p,
    intros p h,
    specialize hno_augumenting_path p,
    exact hno_augumenting_path,
  end,
rfl⟩

lemma s_t_not_connected {V : Type*} [inst' : fintype V]
  (rsn : residual_network V)
  (S : finset V) (hS : S = mk_cut_set rsn) :
  ∀ u ∈ S, ∀ v ∈ (V' \ S), ¬ rsn.is_edge u v :=
begin
  intros u h_u_in_S v h_v_in_T is_edge_u_v,
  rw hS at *,
  unfold mk_cut_set at *,
  simp only [set.mem_to_finset, set.mem_set_of_eq, mem_sdiff, mem_univ, true_and] at *,
  apply exists.elim h_u_in_S,
  intros p _,
  have tmp := path.cons p is_edge_u_v,
  apply h_v_in_T,
  exact exists.intro tmp trivial,
end

lemma residual_capacity_zero {V : Type*} [inst' : fintype V]
  (rsn : residual_network V)
  (ct : cut V)
  (h_eq_network : rsn.afn.network = ct.network)
  (h: ∀ u ∈ ct.S, ∀ v ∈ ct.T, ¬ rsn.is_edge u v) :
  ∀ u ∈ ct.S, ∀ v ∈ ct.T, rsn.f' u v = 0 :=
begin
  intros u h_u_in_S v h_v_in_T,
  specialize h u h_u_in_S v h_v_in_T,
  rw rsn.is_edge_def at h,
  simp only [not_lt] at h,
  have hge := residual_capacity_non_neg rsn u v,
  exact ge_antisymm hge h,
end

lemma min_max_cap_flow {V : Type*} [inst' : fintype V]
  (rsn : residual_network V)
  (ct : cut V)
  (h_eq_network : rsn.afn.network = ct.network)
  (h: ∀ u ∈ ct.S, ∀ v ∈ ct.T, rsn.f' u v = 0 ) :
  (∀ u ∈ ct.S, ∀ v ∈ ct.T, rsn.afn.f u v = rsn.afn.network.c u v) ∧
  (∀ u ∈ ct.T, ∀ v ∈ ct.S, rsn.afn.f u v = 0) :=
begin
  split,
  {
    intros u h_u_in_S v h_v_in_T,
    specialize h u h_u_in_S v h_v_in_T,
    rw rsn.f_def at h,
    unfold mk_rsf at h,
    have tmp := classical.em (rsn.afn.network.to_capacity.to_strange_digraph.is_edge u v),
    cases tmp,
    {
      simp only [tmp, if_true] at h,
      linarith,
    },
    {
      simp only [tmp, if_false, ite_eq_right_iff] at h,
      have foo := rsn.afn.network.vanishes u v tmp,
      rw foo,
      clear tmp h,
      have foo := rsn.afn.non_neg_flow u v,
      have bar := rsn.afn.no_overflow u v,
      linarith,
    }
  },
  {
    intros v h_v_in_T u h_u_in_S,
    specialize h u h_u_in_S v h_v_in_T,
    rw rsn.f_def at h,
    unfold mk_rsf at h,
    have tmp := classical.em (rsn.afn.network.to_capacity.to_strange_digraph.is_edge u v),
    cases tmp,
    {
      have foo := rsn.afn.network.hnonsymmetric u v,
      simp only [not_and] at foo,
      specialize foo tmp,
      have bar := rsn.afn.non_neg_flow v u,
      have baz := rsn.afn.no_overflow v u,
      have blurg := rsn.afn.network.vanishes v u foo,
      linarith,
    },
    {
      simp only [tmp, if_false, ite_eq_right_iff] at h,
      clear tmp,
      have tmp := classical.em (rsn.afn.network.to_capacity.to_strange_digraph.is_edge v u),
      cases tmp,
      {
        exact h tmp,
      },
      {
        have foo := rsn.afn.non_neg_flow v u,
        have bar := rsn.afn.no_overflow v u,
        have baz := rsn.afn.network.vanishes v u tmp,
        linarith,
      },
    },
  }
end

lemma f_value_eq_out {V : Type*} [inst' : fintype V]
    (ct : cut V)
    (afn : active_flow_network V)
    (h_eq_network : afn.network = ct.network)
    (h : (∀ u ∈ ct.T, ∀ v ∈ ct.S, afn.f u v = 0)) :
    F_value afn = mk_out afn.f ct.S :=
begin
  dsimp [F_value],
  rw flow_value_global_ver afn ct h_eq_network,
  dsimp [mk_in],
  simp_rw [← ct.Tcomp],
  simp only [sub_eq_self],
  have sum_eq_sum_zero : ∑ (x : V) in ct.T, ∑ y in ct.S, (afn.f x y) =
  ∑ x in ct.T, ∑ y in ct.S, 0 :=
  begin
    apply finset.sum_congr rfl,
    intros x x_in_T,
    apply finset.sum_congr rfl,
    intros y y_in_S,
    exact h x x_in_T y y_in_S,
  end,
  rw sum_eq_sum_zero,
  simp only [sum_const_zero],
end

lemma cut_cap_eq_out {V : Type*} [inst' : fintype V]
  (ct : cut V)
  (afn : active_flow_network V)
  (h_eq_network : afn.network = ct.network)
  (h : (∀ u ∈ ct.S, ∀ v ∈ V' \ ct.S, afn.f u v = afn.network.c u v) ∧
       (∀ u ∈ V' \ ct.S, ∀ v ∈ ct.S, afn.f u v = 0)) :
      mk_out afn.f ct.S = cut_cap ct :=
begin
  cases h with h_flow_eq_cap h_flow_zero,
  dsimp [cut_cap, mk_out],
  apply finset.sum_congr rfl,
  intros x x_in_S,
  rw ← ct.Tcomp at *,
  apply finset.sum_congr rfl,
  intros y y_in_T,
  simp [h_eq_network, h_flow_eq_cap x x_in_S y y_in_T],
end

lemma eq_on_res_then_on_sum {V : Type*} [inst' : fintype V]
  (A : finset V) (B : finset V) (f : V → V → ℝ) (g : V → V → ℝ)
  (eq_on_res : ∀ u ∈ A, ∀ v ∈ B, f u v = g u v) :
  ∑ (u : V) in A, ∑ (v : V) in B, f u v = ∑ (u : V) in A, ∑ (v : V) in B, g u v :=
begin
  apply finset.sum_congr rfl,
  intros a a_in_A,
  apply finset.sum_congr rfl,
  intros b b_in_B,
  exact eq_on_res a a_in_A b b_in_B,
end

/-!
  Here is our last big lemma, if there is no augmenting path in the resiual network,
  then there exists a cut with a capacity equal to the value of the active flow in the same network.
-/

lemma existence_of_a_cut {V : Type*} [inst' : fintype V]
  (rsn : residual_network V)
  (hno_augumenting_path : no_augumenting_path rsn) :
  (∃c : cut V, rsn.afn.network = c.network ∧ cut_cap c = F_value rsn.afn) :=
begin
  let S : finset V := mk_cut_set rsn,
  let T := V' \ S,
  have h1: S = mk_cut_set rsn := by refl,
  let min_cut := mk_cut_from_S (rsn) (hno_augumenting_path) (S) (h1),
  have eq_net : rsn.afn.network = min_cut.network := by refl,
  have subtract: ∀ x y : ℝ, (x=y) ↔ y-x=0 :=
  by {intros x y, split, intro heq, linarith, intro heq, linarith},
  have cf_vanishes_on_pipes: ∀u ∈ min_cut.S, ∀ v ∈ V' \ min_cut.S, rsn.f' u v = 0 :=
  begin
    intros u uInS v vInNS,
    by_contradiction h,
    have edge: rsn.is_edge u v :=
    begin
      by_contradiction h',
      have contr: rsn.f' u v = 0 :=
      begin
        rw rsn.is_edge_def at h',
        simp only [not_lt] at h',
        have hge := residual_capacity_non_neg rsn u v,
        exact ge_antisymm hge h',
      end,
      contradiction
    end,
    have notEdge: ¬ rsn.is_edge u v := by {exact s_t_not_connected rsn S h1 u uInS v vInNS},
    contradiction
  end,
  have cf_vanishes_on_pipes_spec: ∀ u ∈ min_cut.S, ∀ v ∈ V' \ min_cut.S,
    (rsn.afn.network.is_edge u v) → (rsn.afn.network.c u v - rsn.afn.f u v = 0) :=
  begin
    intros u u_in_S v v_in_T is_edge,
    have t: mk_rsf rsn.afn u v = rsn.afn.network.c u v - rsn.afn.f u v :=
    by {unfold mk_rsf, simp only [is_edge, if_true]},
    rw ← t,
    have r: mk_rsf rsn.afn u v = rsn.f' u v := by {rw rsn.f_def},
    rw r,
    exact cf_vanishes_on_pipes u u_in_S v v_in_T,
  end,
  have eq_on_pipes: ∀ u ∈ min_cut.S, ∀ v ∈ V' \ min_cut.S, rsn.afn.f u v = rsn.afn.network.c u v :=
  begin
    intros u u_in_S v v_in_T,
    cases classical.em (rsn.afn.network.is_edge u v),
    {
      rw subtract (rsn.afn.f u v) (rsn.afn.network.to_capacity.c u v),
      have mk_cf_spec: (rsn.f' u v = rsn.afn.network.c u v - rsn.afn.f u v) :=
      begin
        rw rsn.f_def,
        unfold mk_rsf,
        simp only [h, if_true],
      end,
      rw ← mk_cf_spec,
      exact cf_vanishes_on_pipes u u_in_S v v_in_T,
    },
    {
      rw rsn.afn.network.vanishes u v h,
      exact f_vanishes_outside_edge (rsn.afn) (u) (v) (h),
    },
  end,
  have no_backflow: ∀ u ∈ V' \ min_cut.S, ∀ v ∈ min_cut.S, rsn.afn.f u v = 0 :=
  begin
    intros u uInNS v vInS,
    exact (min_max_cap_flow rsn min_cut eq_net cf_vanishes_on_pipes).2 u uInNS v vInS,
  end,
  have func0 : ∀ u ∈ V' \ min_cut.S, ∀ v ∈ min_cut.S, (λ u v, 0) u v = 0 := by {simp},
  have no_backflow_func: ∀ u ∈ V' \ min_cut.S, ∀ v ∈ min_cut.S, rsn.afn.f u v = (λ u v, 0) u v :=
  begin
    intros u uInNS v vInS,
    rw no_backflow u uInNS v vInS,
    rw func0 u uInNS v vInS,
    simp
  end,
  have cut_eq_flow: cut_cap min_cut = F_value rsn.afn :=
  begin
    rw F_value,
    simp only,
    rw flow_value_global_ver rsn.afn min_cut eq_net,
    have no_input : mk_in rsn.afn.f min_cut.S = 0 :=
    begin
      rw mk_in,
      rw eq_on_res_then_on_sum (V' \ min_cut.S) (min_cut.S) (rsn.afn.f) (λ u v, 0) (no_backflow_func), -- type mismatch because of ↑, why is this arrow arriving?
      simp only [sum_const_zero],
    end,
    rw no_input,
    simp only [sub_zero],
    have flow_eq_cap_on_cut : mk_out rsn.afn.f min_cut.S = mk_out rsn.afn.network.c min_cut.S :=
    begin
      unfold mk_out,
      rw eq_on_res_then_on_sum (min_cut.S) (V' \ min_cut.S) (rsn.afn.f) (rsn.afn.network.to_capacity.c) (eq_on_pipes),
    end,
    rw flow_eq_cap_on_cut,
    refl,
  end,
  use min_cut,
  split,
  {exact eq_net},
  exact cut_eq_flow
end

/-!
  Finally, our biggest result, the max flow min cut theorem!
  If a maximum flow exists, its value is equal to the capacity of the min cut in the same network.
-/

theorem max_flow_min_cut {V : Type*} [inst' : fintype V]
  (rsn : residual_network V) (c: cut V) (same_network: rsn.afn.network = c.network) :
  (is_max_flow_network rsn.afn ∧ is_min_cut c) → (F_value rsn.afn = cut_cap c) :=
begin
  rintros ⟨max_flow, min_cut⟩ ,
  have noAugPath: no_augumenting_path rsn := by {exact no_augm_path rsn max_flow},
  have existsCut: ∃cut:cut V, rsn.afn.network = cut.network ∧ 
  cut_cap cut = F_value rsn.afn := existence_of_a_cut rsn noAugPath,
  have max_flow_min_cut: ∀ cut:cut V,
  (rsn.afn.network = cut.network ∧ cut_cap cut = F_value rsn.afn) → (F_value rsn.afn = cut_cap c) :=
  begin
    rintros cut ⟨same_net, eq⟩ ,
    have h1: is_min_cut cut := min_cut_criterion rsn.afn cut same_net eq,
    have h2: is_min_cut c := min_cut,
    have same_net1: cut.network = c.network := by {rw ← same_network, rw ← same_net},
    have same_net2: c.network = cut.network := by rw ← same_net1,
    have same_val: cut_cap cut = cut_cap c :=
    begin
      have le1: cut_cap cut ≤ cut_cap c :=
      begin
        unfold is_min_cut at h1,
        exact h1 c same_net1,
      end,
      have le2: cut_cap c ≤ cut_cap cut :=
      begin
        unfold is_min_cut at h2,
        exact h2 cut same_net2,
      end,
      exact le_antisymm le1 le2,
    end,
    rw ← eq,
    exact same_val,
  end,
  exact exists.elim existsCut max_flow_min_cut,
  end