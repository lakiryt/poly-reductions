\<^marker>\<open>creator Florian Keßler\<close>

section "Binary Operations in IMP--"

theory Binary_Operations imports IMP_Minus_To_IMP_Minus_Minus_State_Translations
begin 

type_synonym IMP_Minus_com = Com.com
type_synonym IMP_Minus_Minus_com = com

unbundle Com.no_com_syntax

fun com_list_to_seq:: "IMP_Minus_Minus_com list \<Rightarrow> IMP_Minus_Minus_com" where
"com_list_to_seq [] = SKIP" | 
"com_list_to_seq (c # cs) = c ;; (com_list_to_seq cs)"

lemma t_small_step_fun_com_list_to_seq_terminates: "t1 + t2 < t
  \<Longrightarrow> t_small_step_fun t1 (com_list_to_seq as, s1) = (SKIP, s3)
  \<Longrightarrow> t_small_step_fun t2 (com_list_to_seq bs, s3) = (SKIP, s2)
  \<Longrightarrow> t_small_step_fun t (com_list_to_seq (as @ bs), s1) = (SKIP, s2)"
proof(induction as arbitrary: s1 t1 t)
  case Nil
  then show ?case using t_small_step_fun_increase_time 
    by (metis Pair_inject append_self_conv2 com_list_to_seq.simps le_add2 
        less_imp_le_nat t_small_step_fun_SKIP)
next
  case (Cons a as)
  then obtain ta sa where ta_def: "ta < t1 \<and> t_small_step_fun ta (a, s1) = (SKIP, sa) 
    \<and> t_small_step_fun (t1 - (ta + 1)) (com_list_to_seq as, sa) = (SKIP, s3)"
    by (auto simp: seq_terminates_iff)
  hence "t_small_step_fun (t - (ta + 1)) (com_list_to_seq (as @ bs), sa) = (SKIP, s2)"  
    apply -
    apply(rule Cons(1))
    using Cons by(auto)
  thus ?case using ta_def Cons seq_terminates_iff by fastforce
qed

fun binary_assign_constant:: "nat \<Rightarrow> vname \<Rightarrow> nat \<Rightarrow> IMP_Minus_Minus_com" where 
"binary_assign_constant 0 v x = SKIP" |
"binary_assign_constant (Suc n) v x = (var_bit_to_var (v, n)) ::= A (N (nth_bit x n)) ;;
  binary_assign_constant n v x" 

lemma result_of_binary_assign_constant: "t_small_step_fun (3 * n) 
  (binary_assign_constant n v x, s) 
  = (SKIP, \<lambda>w. (case var_to_var_bit w of
      Some (w', m) \<Rightarrow> (if w' = v \<and> m < n then nth_bit x m else s w) |
      _ \<Rightarrow> s w))"
proof(induction n arbitrary: s)
  case (Suc n)
  thus ?case 
    apply auto
    apply(rule seq_terminates_when[where ?t1.0=1 and ?t2.0="3*n" and 
          ?s3.0="s(var_bit_to_var (v, n) := nth_bit x n)"])
    by(auto simp: fun_eq_iff var_to_var_bit_eq_Some_iff var_bit_to_var_eq_iff split: option.splits)
qed (auto simp: fun_eq_iff split: option.splits)

fun nth_carry:: "nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> nat" where
"nth_carry 0 a b = (if (nth_bit a 0 = 1 \<and> nth_bit b 0 = 1) then 1 else 0)" | 
"nth_carry (Suc n) a b = (if (nth_bit a (Suc n) = 1 \<and> nth_bit b (Suc n) = 1) 
  \<or> ((nth_bit a (Suc n) = 1 \<or> nth_bit b (Suc n) = 1) \<and> nth_carry n a b = 1) then 1 else 0)"

lemma zero_le_nth_carry_then[simp]: "0 < nth_carry n a b \<longleftrightarrow> nth_carry n a b = 1" 
  apply(cases n)
  by(auto split: if_splits)

lemma first_bit_of_add: "nth_bit (a + b) 0 = (if nth_bit a 0 + nth_bit b 0 = 1 then 1 else 0)" 
  apply(induction a)
   apply(auto split: if_splits)
  by presburger+

lemma nth_bit_of_add: "nth_bit (a + b) (Suc n) = (let s = nth_bit a (Suc n) + nth_bit b (Suc n) 
  + nth_carry n a b in (if s = 1 \<or> s = 3 then 1 else 0))" 
  sorry

lemma no_overflow_condition: "a + b < 2^n \<Longrightarrow> nth_carry (n - 1) a b = 0" 
  sorry

lemma all_bits_in_sum_zero_then: "(\<forall>i \<le> k. nth_bit (a + b) i = 0) 
  \<Longrightarrow> (a + b \<ge> 2^(k + 1) \<or> (a = 0 \<and> b = 0))"
  sorry

lemma has_bit_one_then_greater_zero: "nth_bit a j = Suc 0 \<Longrightarrow> 0 < a" 
  sorry

fun nth_carry_sub:: "nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> nat" where
"nth_carry_sub 0 a b = (if (nth_bit a 0 = 0 \<and> nth_bit b 0 = 1) then 1 else 0)" | 
"nth_carry_sub (Suc n) a b = (if nth_bit a (Suc n) < nth_bit b (Suc n) + nth_carry_sub n a b then 1
  else 0)"

lemma nth_carry_sub_leq_one: "nth_carry_sub n a b = x \<Longrightarrow> (x = 0 \<or> x = 1)"
  by (metis nth_carry_sub.elims)

lemma nth_carry_sub__neq_one_iff[simp]: "nth_carry_sub n a b \<noteq> Suc 0 \<longleftrightarrow> nth_carry_sub n a b = 0" 
  using nth_carry_sub_leq_one by auto

lemma nth_bit_of_sub_n_no_underflow: "a \<ge> b \<Longrightarrow> 
  nth_bit (a - b) (Suc n) = (let an = nth_bit a (Suc n); bn = nth_bit b (Suc n);
  c = nth_carry_sub n a b in (if  bn + c = 0 \<or> bn + c = 2 then an 
    else (if bn + c = 1 \<and> an = 0 then 1 else 0)))" 
  sorry

lemma nth_bit_of_sub_n_underflow: "a < b \<Longrightarrow> 
  nth_bit (a - b) (Suc n) = 0" 
  by simp

fun operand_bit_to_var:: "(char * nat) \<Rightarrow> vname" where 
"operand_bit_to_var (c, 0) = [c]" |
"operand_bit_to_var (c, (Suc n)) = c # operand_bit_to_var (c, n)"

definition var_to_operand_bit:: "vname \<Rightarrow> (char * nat) option" where
"var_to_operand_bit v = (if v \<noteq> [] \<and> v = (operand_bit_to_var (hd v, length v - 1)) 
  then Some (hd v, length v - 1) else None)" 

lemma hd_of_operand_bit_to_var[simp]: 
  "hd (operand_bit_to_var (op, n)) = op" by (induction n) auto

lemma length_of_operand_bit_to_var[simp]:
  "length (operand_bit_to_var (op, n)) = n + 1" by (induction n) auto  

lemma var_to_operand_bit_of_operand_bit_to_var[simp]: 
  "var_to_operand_bit (operand_bit_to_var (op, n)) = Some (op, n)"
  apply(induction n)
  by(auto simp: var_to_operand_bit_def)

lemma var_to_operand_bit_eq_Some_iff: "var_to_operand_bit x = Some (op, i) 
  \<longleftrightarrow> x = operand_bit_to_var (op, i)" 
  apply(auto simp: var_to_operand_bit_def)
  apply(cases i)
  by auto

lemma var_to_operand_bit_of_carry[simp]: "var_to_operand_bit ''carry'' = None" 
  by(simp add: var_to_operand_bit_def)

lemma set_of_operand_bit_to_var[simp]: "set (operand_bit_to_var (op, b)) = { op }" 
  by (induction b) auto

lemma var_to_operand_bit_var_bit_to_var[simp]: "var_to_operand_bit (var_bit_to_var (a, b)) = None" 
  apply(simp add: var_to_operand_bit_def var_bit_to_var_def)
  apply(rule ccontr)
  apply simp
  apply(drule arg_cong[where ?f=set])
  by simp

lemma var_to_var_bit_operand_bit_to_var[simp]: "var_to_var_bit (operand_bit_to_var (c, k)) = None" 
  by (simp add: var_to_var_bit_def)

lemma var_to_operand_bit_non_zero_indicator[simp]: 
  "var_to_operand_bit (CHR ''?'' # CHR ''$'' # v) = None"
  apply(auto simp: var_to_operand_bit_def)
  apply(rule ccontr)
  apply simp
  apply(drule arg_cong[where ?f=set])
  by simp

lemma operand_bit_to_var_ne_non_zero_indicator[simp]: 
  "operand_bit_to_var (c, k) \<noteq> CHR ''?'' # CHR ''$'' # v" 
  apply(induction k)
   apply auto
proof -
  fix ka :: nat
  assume "operand_bit_to_var (CHR ''?'', ka) = CHR ''$'' # v"
  then have "CHR ''?'' = CHR ''$''" by (metis hd_of_operand_bit_to_var list.sel(1))
  then show False by force
qed

lemma operand_bit_to_var_non_empty: "operand_bit_to_var (op, n) \<noteq> []"
  by (induction n) auto

lemma operand_bit_to_var_eq_operand_bit_to_var_iff[simp]: 
  "operand_bit_to_var (op, a) = operand_bit_to_var (op', b) 
  \<longleftrightarrow> (op = op' \<and> a = b)" 
proof 
  assume "operand_bit_to_var (op, a) = operand_bit_to_var (op', b)" 
  hence "length (operand_bit_to_var (op, a)) = length (operand_bit_to_var (op', b))
    \<and> set (operand_bit_to_var (op, a)) = set (operand_bit_to_var (op', b))" by simp
  thus "op = op' \<and> a = b" by auto
qed auto

lemma var_bit_to_var_neq_operand_bit_to_var[simp]: 
  "var_bit_to_var (v, a) \<noteq> operand_bit_to_var (op, b)"
proof(rule ccontr)
  assume "\<not> (var_bit_to_var (v, a) \<noteq> operand_bit_to_var (op, b))" 
  hence "set (var_bit_to_var (v, a)) = set (operand_bit_to_var (op, b))" by simp
  thus False using set_of_operand_bit_to_var by(auto simp: var_bit_to_var_def)
qed

fun copy_var_to_operand:: "nat \<Rightarrow> char \<Rightarrow> vname \<Rightarrow> IMP_Minus_Minus_com" where
"copy_var_to_operand 0 op v = SKIP" |
"copy_var_to_operand (Suc i) op v = 
   (operand_bit_to_var (op, i)) ::= A (V (var_bit_to_var (v, i))) ;;
    copy_var_to_operand i op v " 

lemma copy_var_to_operand_result:
  "t_small_step_fun (2 * n) (copy_var_to_operand n op v, s)
  = (SKIP, \<lambda>w. (case var_to_operand_bit w of
    Some (op', i) \<Rightarrow> (if op' = op \<and> i < n then s (var_bit_to_var (v, i)) else s w) |
    _ \<Rightarrow> s w))" 
  apply(induction n arbitrary: s)
   apply(auto simp: fun_eq_iff var_to_operand_bit_eq_Some_iff split!: option.splits if_splits)
  using less_antisym by blast

fun copy_const_to_operand:: "nat \<Rightarrow> char \<Rightarrow> nat \<Rightarrow> IMP_Minus_Minus_com" where
"copy_const_to_operand 0 op x = SKIP" |
"copy_const_to_operand (Suc i) op x = 
   (operand_bit_to_var (op, i)) ::= A (N (nth_bit x i)) ;;
    copy_const_to_operand i op x " 

lemma copy_const_to_operand_result:
  "t_small_step_fun (2 * n) (copy_const_to_operand n op x, s)
  = (SKIP, \<lambda>w. (case var_to_operand_bit w of
    Some (op', i) \<Rightarrow> (if op' = op \<and> i < n then nth_bit x i else s w) |
    _ \<Rightarrow> s w))" 
  apply(induction n arbitrary: s)
   apply(auto simp: fun_eq_iff var_to_operand_bit_eq_Some_iff split!: option.splits if_splits)
  using less_antisym by blast

definition assign_var_carry:: 
  "nat \<Rightarrow> vname \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> IMP_Minus_Minus_com" where
"assign_var_carry i v a b c = 
  (var_bit_to_var (v, i)) ::= A (N (if a + b + c = 1 \<or> a + b + c = 3 then 1 else 0)) ;; 
  ''carry'' ::= A (N (if a + b + c \<ge> 2 then 1 else 0))"

lemma result_of_assign_var_carry:  
  "t_small_step_fun 7 (assign_var_carry i v a b c, s)
    = (SKIP, s(var_bit_to_var (v, i) := (if a + b + c = 1 \<or> a + b + c = 3 then 1 else 0),
     ''carry'' :=  (if a + b + c \<ge> 2 then 1 else 0)))"
  by(auto simp: assign_var_carry_def t_small_step_fun_terminate_iff)

definition full_adder:: "nat \<Rightarrow> vname \<Rightarrow> IMP_Minus_Minus_com" where
"full_adder i v  = (let assign = assign_var_carry i v; op_a = operand_bit_to_var (CHR ''a'', i);
  op_b = operand_bit_to_var (CHR ''b'', i) in 
  IF op_a\<noteq>0 THEN 
    IF ''carry''\<noteq>0 THEN
      IF op_b\<noteq>0 THEN assign 1 1 1 
      ELSE assign 1 1 0
    ELSE 
      IF op_b\<noteq>0 THEN assign 1 0 1
      ELSE assign 1 0 0
  ELSE 
    IF ''carry''\<noteq>0 THEN
      IF op_b\<noteq>0 THEN assign 0 1 1
      ELSE assign 0 1 0
    ELSE 
      IF op_b\<noteq>0 THEN assign 0 0 1
      ELSE assign 0 0 0)"

lemma full_adder_correct: 
  assumes "i = 0 \<longrightarrow> s ''carry'' = 0" 
    "i > 0 \<longrightarrow> s ''carry'' = nth_carry (i - 1) a b"
    "s (operand_bit_to_var (CHR ''a'', i)) = nth_bit a i" 
    "s (operand_bit_to_var (CHR ''b'', i)) = nth_bit b i"
  shows "t_small_step_fun 10 (full_adder i v, s) = (SKIP, 
    s(var_bit_to_var (v, i) := nth_bit (a + b) i, ''carry'' := nth_carry i a b))" 
  using assms 
  apply(simp add: full_adder_def Let_def t_small_step_fun_terminate_iff result_of_assign_var_carry)
  apply(cases i)
  apply(simp_all add: fun_eq_iff nth_bit_of_add[simplified])
   apply(auto)
  by (meson dvd_imp_mod_0 even_add not_mod2_eq_Suc_0_eq_0)
  

lemma sequence_of_full_adders: 
  assumes 
    "s ''carry'' = 0" 
    "\<forall>j \<le> k. s (operand_bit_to_var (CHR ''a'', j)) = nth_bit a j" 
    "\<forall>j \<le> k. s (operand_bit_to_var (CHR ''b'', j)) = nth_bit b j"
  shows
   "t_small_step_fun (12 * (k + 1))
                       (com_list_to_seq (map (\<lambda>i. full_adder i v) [0..<(k + 1)]), s)
  = (SKIP, (\<lambda>w. (case var_to_var_bit w of
    Some (w', m) \<Rightarrow> (if w' = v \<and> m \<le> k then nth_bit (a + b) m else s w) |
    _ \<Rightarrow> (if w = ''carry'' then nth_carry k a b  
          else s w))))"   
  using assms
proof(induction k)
  case 0
  then show ?case 
      apply(auto simp: seq_terminates_iff)
    apply(simp_all only: numeral_eq_Suc exists_terminating_iff)
    apply auto
    apply(rule t_small_step_fun_increase_time[where ?t=10 and ?t'=11])
    apply auto
    apply (subst full_adder_correct[where ?a=a and ?b=b])
    by(auto simp: var_to_var_bit_eq_Some_iff numeral_eq_Suc split!: option.splits)
next
  case (Suc k)
  hence "t_small_step_fun (24 + 12 * k)
   (com_list_to_seq ((map (\<lambda>i. full_adder i v) [0..<(k + 1)]) @ [full_adder (k + 1) v]), s)
    = (SKIP, (\<lambda>w. (case var_to_var_bit w of
    Some (w', m) \<Rightarrow> (if w' = v \<and> m \<le> Suc k then nth_bit (a + b) m else s w) |
    _ \<Rightarrow> (if w = ''carry'' then nth_carry (Suc k) a b  
          else s w))))"
    apply -
    apply(rule t_small_step_fun_com_list_to_seq_terminates[where ?t1.0="12 * (k + 1)" and ?t2.0=11])
      apply(auto simp: seq_terminates_iff)
      apply(auto simp only: numeral_eq_Suc exists_terminating_iff fun_eq_iff)
     apply auto
    apply(subst full_adder_correct)
    apply(simp_all)
      apply(auto simp add: fun_eq_iff var_to_var_bit_eq_Some_iff var_bit_to_var_eq_iff split!: option.splits)
    by(auto simp: var_bit_to_var_def)
  thus ?case by auto
qed 

definition check_bit_non_zero:: "nat \<Rightarrow> vname \<Rightarrow> IMP_Minus_Minus_com" where
"check_bit_non_zero i v = (IF (var_bit_to_var (v, i))\<noteq>0 THEN (''?$'' @ v) ::= A (N 1) ELSE SKIP)" 

lemma result_of_check_bit_non_zero_sequence: 
  "t_small_step_fun (4 * k)
  (com_list_to_seq (map (\<lambda>i. check_bit_non_zero i v) [0..<k]), s)
    = (SKIP, if (\<exists>j < k. s (var_bit_to_var (v, j)) \<noteq> 0) then (s(''?$'' @ v := 1)) else s)" 
proof(induction k)
  case 0
  then show ?case by (auto simp: check_bit_non_zero_def t_small_step_fun_terminate_iff)
next
  case (Suc k)
  hence "t_small_step_fun (4 * (Suc k))
   (com_list_to_seq ((map (\<lambda>i. check_bit_non_zero i v) [0..<k]) 
    @ [check_bit_non_zero k v]), s)
    = (SKIP, if (\<exists>j < Suc k. s (var_bit_to_var (v, j)) \<noteq> 0) then (s(''?$'' @ v := 1)) else s)"
     apply -
    apply(rule t_small_step_fun_com_list_to_seq_terminates[where ?t1.0="4 * k" and ?t2.0=3])
      apply(auto simp: seq_terminates_iff)
      apply(auto simp only: numeral_eq_Suc exists_terminating_iff fun_eq_iff)
    by (auto simp: check_bit_non_zero_def t_small_step_fun_terminate_iff less_Suc_eq split: if_splits)
  thus ?case by simp
qed

definition binary_adder:: "nat \<Rightarrow> vname \<Rightarrow> vname \<Rightarrow> vname \<Rightarrow> IMP_Minus_Minus_com" where
"binary_adder n v a b = 
  copy_var_to_operand n (CHR ''a'') a ;;
  (copy_var_to_operand n (CHR ''b'') b ;;
  (com_list_to_seq (map (\<lambda>i. full_adder i v) [0..<n]) ;; 
  ((''?$'' @ v) ::= A (N 0) ;;
  (com_list_to_seq (map (\<lambda>i. check_bit_non_zero i v) [0..<n]) ;;
  (copy_const_to_operand n (CHR ''a'') 0 ;;
  copy_const_to_operand n (CHR ''b'') 0)))))"

lemma binary_adder_correct: 
  assumes "n > 0" "s ''carry'' = 0" 
    "\<forall>j < n. s (operand_bit_to_var (CHR ''a'', j)) = 0"
    "\<forall>j < n. s (operand_bit_to_var (CHR ''b'', j)) = 0"
    "\<forall>j < n. s (var_bit_to_var (va, j)) = nth_bit a j" 
    "\<forall>j < n. s (var_bit_to_var (vb, j)) = nth_bit b j"
    "a + b < 2 ^ n" 
  shows "t_small_step_fun (50 * (n + 1)) (binary_adder n v va vb, s) 
    = (SKIP, (\<lambda>w. (case var_to_var_bit w of
      Some (w', m) \<Rightarrow> (if w' = v \<and> m < n then nth_bit (a + b) m else s w) |
      _ \<Rightarrow> (if w = ''carry'' then 0  
            else if w = ''?$'' @ v then (if a + b \<noteq> 0 then 1 else 0) 
            else s w))))"
proof -
  obtain k where k_def: "Suc k = n" using assms(1) gr0_implies_Suc by blast
  hence "nth_carry k a b = 0" using assms no_overflow_condition by (metis diff_Suc_1)
  thus ?thesis apply(simp only: binary_adder_def) 
    apply(rule seq_terminates_when[where ?t1.0="2 * n" and ?t2.0="48 * n + 49"])
     apply(auto)[1]
     apply(auto simp: copy_var_to_operand_result)[1]
    apply(rule seq_terminates_when[where ?t1.0="2 * n" and ?t2.0="46 * n + 48"])
      apply auto[1]
     apply(auto simp: copy_var_to_operand_result)[1]
    apply(rule seq_terminates_when[where ?t1.0="12 * (k + 1)" and ?t2.0="34 * n + 47"])
    using k_def apply auto[1]
    using k_def[symmetric] apply simp
     apply(rule sequence_of_full_adders[simplified])
    using assms apply(simp split: option.splits)
    using assms apply(auto split: option.splits)[1]
    using assms apply(auto split: option.splits)[1]
    apply(rule seq_terminates_when[where ?t1.0="1" and ?t2.0="34 * n + 45"])
      apply auto[1]
     apply auto[1]
    apply(rule seq_terminates_when[where ?t1.0="4 * n" and ?t2.0="30 * n + 44"])
      apply auto[1]
     apply(auto simp: result_of_check_bit_non_zero_sequence)[1]
    apply(rule seq_terminates_when[where ?t1.0="2 * n" and ?t2.0="28 * n + 43"])
     apply(auto)[1]
     apply(auto simp: copy_const_to_operand_result)[1]
    apply(rule t_small_step_fun_increase_time[where ?t="2*n" and ?t' = "28 * n + 43"]) 
     apply auto[1]
    apply(simp only: copy_const_to_operand_result)
    apply(auto simp only: fun_eq_iff split!: option.splits)
       apply (simp_all add: var_to_var_bit_eq_Some_iff var_to_operand_bit_eq_Some_iff)
    using k_def assms(2) assms(3) assms(4) assms(7) apply auto
    by(frule all_bits_in_sum_zero_then, simp)+
qed

definition binary_adder_constant:: "nat \<Rightarrow> vname \<Rightarrow> vname \<Rightarrow> nat \<Rightarrow> IMP_Minus_Minus_com" where
"binary_adder_constant n v a b = 
  copy_var_to_operand n (CHR ''a'') a ;;
  (copy_const_to_operand n (CHR ''b'') b ;;
  (com_list_to_seq (map (\<lambda>i. full_adder i v) [0..<n]) ;; 
  ((''?$'' @ v) ::= A (N 0) ;;
  (com_list_to_seq (map (\<lambda>i. check_bit_non_zero i v) [0..<n]) ;;
  (copy_const_to_operand n (CHR ''a'') 0 ;;
  copy_const_to_operand n (CHR ''b'') 0)))))"

lemma binary_adder_constant_correct: 
  assumes "n > 0" "s ''carry'' = 0" 
    "\<forall>j < n. s (operand_bit_to_var (CHR ''a'', j)) = 0"
    "\<forall>j < n. s (operand_bit_to_var (CHR ''b'', j)) = 0"
    "\<forall>j < n. s (var_bit_to_var (va, j)) = nth_bit a j" 
    "a + b < 2 ^ n" 
  shows "t_small_step_fun (50 * (n + 1)) (binary_adder_constant n v va b, s) 
    = (SKIP, (\<lambda>w. (case var_to_var_bit w of
      Some (w', m) \<Rightarrow> (if w' = v \<and> m < n then nth_bit (a + b) m else s w) |
      _ \<Rightarrow> (if w = ''carry'' then 0  
            else if w = ''?$'' @ v then (if a + b \<noteq> 0 then 1 else 0) 
            else s w))))"
proof -
  obtain k where k_def: "Suc k = n" using assms(1) gr0_implies_Suc by blast
  hence "nth_carry k a b = 0" using assms no_overflow_condition by (metis diff_Suc_1)
  thus ?thesis apply(simp only: binary_adder_constant_def) 
    apply(rule seq_terminates_when[where ?t1.0="2 * n" and ?t2.0="48 * n + 49"])
     apply(auto)[1]
     apply(auto simp: copy_var_to_operand_result)[1]
    apply(rule seq_terminates_when[where ?t1.0="2 * n" and ?t2.0="46 * n + 48"])
      apply auto[1]
     apply(auto simp: copy_const_to_operand_result)[1]
    apply(rule seq_terminates_when[where ?t1.0="12 * (k + 1)" and ?t2.0="34 * n + 47"])
    using k_def apply auto[1]
    using k_def[symmetric] apply simp
     apply(rule sequence_of_full_adders[simplified])
    using assms apply(simp split: option.splits)
    using assms apply(auto split: option.splits)[1]
    using assms apply(auto split: option.splits)[1]
    apply(rule seq_terminates_when[where ?t1.0="1" and ?t2.0="34 * n + 45"])
      apply auto[1]
     apply auto[1]
    apply(rule seq_terminates_when[where ?t1.0="4 * n" and ?t2.0="30 * n + 44"])
      apply auto[1]
     apply(auto simp: result_of_check_bit_non_zero_sequence)[1]
    apply(rule seq_terminates_when[where ?t1.0="2 * n" and ?t2.0="28 * n + 43"])
     apply(auto)[1]
     apply(auto simp: copy_const_to_operand_result)[1]
    apply(rule t_small_step_fun_increase_time[where ?t="2*n" and ?t' = "28 * n + 43"]) 
     apply auto[1]
    apply(simp only: copy_const_to_operand_result)
    apply(auto simp only: fun_eq_iff split!: option.splits)
       apply (simp_all add: var_to_var_bit_eq_Some_iff var_to_operand_bit_eq_Some_iff)
    using k_def assms(2) assms(3) assms(4) assms(6) apply auto
    by(frule all_bits_in_sum_zero_then, simp)+
qed

definition assign_var_carry_sub:: 
  "nat \<Rightarrow> vname \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> IMP_Minus_Minus_com" where
"assign_var_carry_sub i v a b c = 
  (var_bit_to_var (v, i)) ::= A (N (if b + c = 0 \<or> b + c = 2 then a 
    else (if b + c = 1 \<and> a = 0 then 1 else 0))) ;; 
  ''carry'' ::= A (N (if a < b + c then 1 else 0))"

lemma result_of_assign_var_carry_sub:  
  "t_small_step_fun 7 (assign_var_carry_sub i v a b c, s)
    = (SKIP, s(var_bit_to_var (v, i) := (if b + c = 0 \<or> b + c = 2 then a 
    else (if b + c = 1 \<and> a = 0 then 1 else 0)),
     ''carry'' :=  (if a < b + c then 1 else 0)))"
  by(auto simp: assign_var_carry_sub_def t_small_step_fun_terminate_iff)

definition full_subtractor:: "nat \<Rightarrow> vname \<Rightarrow> IMP_Minus_Minus_com" where
"full_subtractor i v  = (let assign = assign_var_carry_sub i v; op_a = operand_bit_to_var (CHR ''a'', i);
  op_b = operand_bit_to_var (CHR ''b'', i) in 
  IF op_a\<noteq>0 THEN 
    IF ''carry''\<noteq>0 THEN
      IF op_b\<noteq>0 THEN assign 1 1 1 
      ELSE assign 1 1 0
    ELSE 
      IF op_b\<noteq>0 THEN assign 1 0 1
      ELSE assign 1 0 0
  ELSE 
    IF ''carry''\<noteq>0 THEN
      IF op_b\<noteq>0 THEN assign 0 1 1
      ELSE assign 0 1 0
    ELSE 
      IF op_b\<noteq>0 THEN assign 0 0 1
      ELSE assign 0 0 0)"

lemma full_subtractor_correct_no_underflow: 
  assumes "a \<ge> b"
    "i = 0 \<longrightarrow> s ''carry'' = 0" 
    "i > 0 \<longrightarrow> s ''carry'' = nth_carry_sub (i - 1) a b"
    "s (operand_bit_to_var (CHR ''a'', i)) = nth_bit a i" 
    "s (operand_bit_to_var (CHR ''b'', i)) = nth_bit b i"
  shows "t_small_step_fun 10 (full_subtractor i v, s) = (SKIP, 
    s(var_bit_to_var (v, i) := nth_bit (a - b) i, ''carry'' := nth_carry_sub i a b))" 
  using assms 
  apply(simp add: full_subtractor_def Let_def t_small_step_fun_terminate_iff result_of_assign_var_carry_sub)
  apply(cases i)
  apply(simp_all add: fun_eq_iff nth_bit_of_sub_n_no_underflow[simplified] Let_def)
   apply(auto simp: mod2_eq_if)
  by(frule nth_bit_eq_zero_or_one[where ?x="b div 2"], simp)+
  

lemma sequence_of_full_subtractors_no_underflow: 
  assumes "a \<ge> b"
    "s ''carry'' = 0" 
    "\<forall>j \<le> k. s (operand_bit_to_var (CHR ''a'', j)) = nth_bit a j" 
    "\<forall>j \<le> k. s (operand_bit_to_var (CHR ''b'', j)) = nth_bit b j"
  shows
   "t_small_step_fun (12 * (k + 1))
                       (com_list_to_seq (map (\<lambda>i. full_subtractor i v) [0..<(k + 1)]), s)
  = (SKIP, (\<lambda>w. (case var_to_var_bit w of
    Some (w', m) \<Rightarrow> (if w' = v \<and> m \<le> k then nth_bit (a - b) m else s w) |
    _ \<Rightarrow> (if w = ''carry'' then nth_carry_sub k a b  
          else s w))))"   
  sorry

lemma sequence_of_full_subtractors_with_underflow: 
  assumes "a < b"
    "a < 2^(k + 2)" "b < 2^(k+2)" 
    "s ''carry'' = 0" 
    "\<forall>j \<le> k. s (operand_bit_to_var (CHR ''a'', j)) = nth_bit a j" 
    "\<forall>j \<le> k. s (operand_bit_to_var (CHR ''b'', j)) = nth_bit b j"
  shows
   "t_small_step_fun (12 * (k + 1))
                       (com_list_to_seq (map (\<lambda>i. full_subtractor i v) [0..<(k + 1)]), s)
  = (SKIP, (\<lambda>w. (case var_to_var_bit w of
    Some (w', m) \<Rightarrow> (if w' = v \<and> m \<le> k then nth_bit (2^(k+2) + a - b) m else s w) |
    _ \<Rightarrow> (if w = ''carry'' then 1
          else s w))))"   
  sorry

definition underflow_handler:: "nat \<Rightarrow> vname \<Rightarrow> IMP_Minus_Minus_com" where
"underflow_handler n v = (IF ''carry''\<noteq>0 THEN (''carry'' ::= A (N 0) ;;
  binary_assign_constant n v 0)
  ELSE SKIP)" 

definition binary_subtractor:: "nat \<Rightarrow> vname \<Rightarrow> vname \<Rightarrow> vname \<Rightarrow> IMP_Minus_Minus_com" where
"binary_subtractor n v a b = 
  copy_var_to_operand n (CHR ''a'') a ;;
  (copy_var_to_operand n (CHR ''b'') b ;;
  (com_list_to_seq (map (\<lambda>i. full_subtractor i v) [0..<n]) ;; 
  underflow_handler n v ;;
  ((''?$'' @ v) ::= A (N 0) ;;
  (com_list_to_seq (map (\<lambda>i. check_bit_non_zero i v) [0..<n]) ;;
  (copy_const_to_operand n (CHR ''a'') 0 ;;
  copy_const_to_operand n (CHR ''b'') 0)))))"

lemma binary_subtractor_correct: 
  assumes "n > 0" "s ''carry'' = 0" 
    "\<forall>j < n. s (operand_bit_to_var (CHR ''a'', j)) = 0"
    "\<forall>j < n. s (operand_bit_to_var (CHR ''b'', j)) = 0"
    "\<forall>j < n. s (var_bit_to_var (va, j)) = nth_bit a j" 
    "\<forall>j < n. s (var_bit_to_var (vb, j)) = nth_bit b j"
    "a + b < 2 ^ n" 
  shows "t_small_step_fun (50 * (n + 1)) (binary_subtractor n v va vb, s) 
    = (SKIP, (\<lambda>w. (case var_to_var_bit w of
      Some (w', m) \<Rightarrow> (if w' = v \<and> m < n then nth_bit (a - b) m else s w) |
      _ \<Rightarrow> (if w = ''carry'' then 0  
            else if w = ''?$'' @ v then (if a - b \<noteq> 0 then 1 else 0) 
            else s w))))"
  sorry

definition binary_subtractor_constant:: "nat \<Rightarrow> vname \<Rightarrow> vname \<Rightarrow> nat \<Rightarrow> IMP_Minus_Minus_com" where
"binary_subtractor_constant n v a b = 
  copy_var_to_operand n (CHR ''a'') a ;;
  (copy_const_to_operand n (CHR ''b'') b ;;
  (com_list_to_seq (map (\<lambda>i. full_adder i v) [0..<n]) ;; 
  (underflow_handler n v ;;
  ((''?$'' @ v) ::= A (N 0) ;;
  (com_list_to_seq (map (\<lambda>i. check_bit_non_zero i v) [0..<n]) ;;
  (copy_const_to_operand n (CHR ''a'') 0 ;;
  copy_const_to_operand n (CHR ''b'') 0))))))"

lemma binary_subtractor_constant_correct: 
 assumes "n > 0" "s ''carry'' = 0" 
    "\<forall>j < n. s (operand_bit_to_var (CHR ''a'', j)) = 0"
    "\<forall>j < n. s (operand_bit_to_var (CHR ''b'', j)) = 0"
    "\<forall>j < n. s (var_bit_to_var (va, j)) = nth_bit a j" 
    "a + b < 2 ^ n" 
  shows "t_small_step_fun (50 * (n + 1)) (binary_subtractor_constant n v va b, s) 
    = (SKIP, (\<lambda>w. (case var_to_var_bit w of
      Some (w', m) \<Rightarrow> (if w' = v \<and> m < n then nth_bit (a - b) m else s w) |
      _ \<Rightarrow> (if w = ''carry'' then 0  
            else if w = ''?$'' @ v then (if a - b \<noteq> 0 then 1 else 0) 
            else s w))))"
  sorry

definition binary_subtractor_constant':: "nat \<Rightarrow> vname \<Rightarrow> nat \<Rightarrow> vname \<Rightarrow> IMP_Minus_Minus_com" where
"binary_subtractor_constant' n v a b = 
  copy_const_to_operand n (CHR ''a'') a ;;
  (copy_var_to_operand n (CHR ''b'') b ;;
  (com_list_to_seq (map (\<lambda>i. full_adder i v) [0..<n]) ;; 
  (underflow_handler n v ;;
  ((''?$'' @ v) ::= A (N 0) ;;
  (com_list_to_seq (map (\<lambda>i. check_bit_non_zero i v) [0..<n]) ;;
  (copy_const_to_operand n (CHR ''a'') 0 ;;
  copy_const_to_operand n (CHR ''b'') 0))))))"

lemma binary_subtractor_constant_correct': 
 assumes "n > 0" "s ''carry'' = 0" 
    "\<forall>j < n. s (operand_bit_to_var (CHR ''a'', j)) = 0"
    "\<forall>j < n. s (operand_bit_to_var (CHR ''b'', j)) = 0"
    "\<forall>j < n. s (var_bit_to_var (vb, j)) = nth_bit b j" 
    "a + b < 2 ^ n" 
  shows "t_small_step_fun (50 * (n + 1)) (binary_subtractor_constant' n v a vb, s) 
    = (SKIP, (\<lambda>w. (case var_to_var_bit w of
      Some (w', m) \<Rightarrow> (if w' = v \<and> m < n then nth_bit (a - b) m else s w) |
      _ \<Rightarrow> (if w = ''carry'' then 0  
            else if w = ''?$'' @ v then (if a - b \<noteq> 0 then 1 else 0) 
            else s w))))"
  sorry


end