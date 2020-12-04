\<^marker>\<open>creator Bilel Ghorbel, Florian Kessler\<close>

section "Inductive definition of relation power"
theory Rel_Pow imports Main begin

paragraph "Summary"
text\<open>We provide an inductive definition for applying a relation n times.\<close>

inductive rel_pow:: "('a \<Rightarrow> 'a \<Rightarrow> bool) \<Rightarrow> nat \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> bool" for r where
refl: "rel_pow r 0 x x"|
step:"r x y \<Longrightarrow> rel_pow r n y z \<Longrightarrow> rel_pow r (Suc n) x z"
hide_fact (open) refl step

lemma rel_pow_rhs: "rel_pow r n x y \<Longrightarrow> r y z \<Longrightarrow> rel_pow r (Suc n) x z"
  by (induction rule:rel_pow.induct)  (auto simp add: rel_pow.refl rel_pow.step)

lemma rel_pow_sum: "rel_pow r n1 x y \<Longrightarrow> rel_pow r n2 y z \<Longrightarrow> rel_pow r (n1+n2) x z"
  apply (induction rule:rel_pow.induct)
   apply (auto simp add: rel_pow.refl rel_pow.step)
  done

lemmas rel_pow_induct =
  rel_pow.induct[of "r:: 'a*'b \<Rightarrow> 'a*'b \<Rightarrow> bool", split_format(complete)]
lemmas rel_pow_intros =
  rel_pow.intros[of "r:: 'a*'b \<Rightarrow> 'a*'b \<Rightarrow> bool",split_format(complete)]
declare rel_pow.intros[simp,intro]

lemma rel_pow_step1[simp, intro]: "r x y \<Longrightarrow> rel_pow r 1 x y"
  using rel_pow.simps by fastforce

inductive_cases  reflE[elim!]: "rel_pow r 0 x y"
inductive_cases  stepE[elim!]: "rel_pow r (Suc n) x y"

code_pred rel_pow .
  
  
end