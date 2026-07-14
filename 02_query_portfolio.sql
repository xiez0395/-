-- ============================================================
-- SQL 能力展示作品集
-- 项目: 西安居民剩菜盲盒认知与购买意愿调查分析
-- 数据: survey.db (SQLite, 624条/6表)
-- 难度: L1(基础) → L5(分析)
-- ============================================================

-- ============================================================
-- 难度 L1: 基础查询 (SELECT/WHERE/LIKE/IN/BETWEEN/ORDER BY/LIMIT/DISTINCT)
-- ============================================================

-- Q1: 查询所有男性、年龄26-35岁、本科及以上学历的受访者（多条件筛选）
SELECT respondent_id, gender, age_group, education, monthly_income
FROM respondents
WHERE gender = 1
  AND age_group = 3
  AND education >= 4
ORDER BY monthly_income DESC;

-- Q2: 使用BETWEEN查询收入在3000-8000区间的受访者
SELECT respondent_id, monthly_income, monthly_spend,
       CASE monthly_income
           WHEN 1 THEN '3000以下'
           WHEN 2 THEN '3000-5000'
           WHEN 3 THEN '5000-8000'
           WHEN 4 THEN '8000-15000'
           WHEN 5 THEN '15000以上'
       END AS income_label
FROM respondents
WHERE monthly_income BETWEEN 2 AND 3
LIMIT 20;

-- Q3: 使用LIKE模糊匹配 — 查找建议中含"安全"关键字的受访者
SELECT respondent_id, suggestions
FROM purchase_willingness
WHERE suggestions IS NOT NULL
  AND suggestions LIKE '%安全%'
ORDER BY respondent_id
LIMIT 15;

-- Q4: 使用DISTINCT查询所有职业类型分布
SELECT occupation, COUNT(*) AS cnt
FROM respondents
GROUP BY occupation
ORDER BY cnt DESC;

-- Q5: 使用IN查询特定年龄段（18-25, 26-35, 36-45）
SELECT gender,
       COUNT(*) AS count,
       ROUND(AVG(total_score), 1) AS avg_score
FROM respondents
WHERE age_group IN (2, 3, 4)
GROUP BY gender
ORDER BY gender;

-- ============================================================
-- 难度 L2: 聚合查询 (GROUP BY/HAVING/聚合函数/CASE WHEN)
-- ============================================================

-- Q6: 按学历分组，统计购买意愿和购买行为分布（CASE WHEN分段）
SELECT
    CASE education
        WHEN 1 THEN '初中及以下' WHEN 2 THEN '高中/中专'
        WHEN 3 THEN '大专' WHEN 4 THEN '本科'
        WHEN 5 THEN '硕士及以上'
    END AS edu_label,
    COUNT(*) AS total,
    SUM(CASE WHEN pw.willing_to_try = 1 THEN 1 ELSE 0 END) AS willing,
    SUM(CASE WHEN pw.has_purchased = 1 THEN 1 ELSE 0 END) AS purchased,
    ROUND(100.0 * SUM(CASE WHEN pw.willing_to_try = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS willing_rate,
    ROUND(100.0 * SUM(CASE WHEN pw.has_purchased = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS purchase_rate
FROM respondents r
JOIN purchase_willingness pw ON r.respondent_id = pw.respondent_id
GROUP BY r.education
ORDER BY r.education;

-- Q7: 使用HAVING筛选 — 找出态度均分>4.0且至少10人的职业群体
SELECT r.occupation,
       COUNT(*) AS cnt,
       ROUND(AVG(a.att_avg_score), 2) AS avg_attitude
FROM respondents r
JOIN attitude_scores a ON r.respondent_id = a.respondent_id
GROUP BY r.occupation
HAVING AVG(a.att_avg_score) > 4.0 AND COUNT(*) >= 10
ORDER BY avg_attitude DESC;

-- Q8: 多维度聚合 — 按性别×年龄分组，统计购买意愿率
SELECT
    CASE r.gender WHEN 1 THEN '男' WHEN 2 THEN '女' END AS gender_label,
    CASE r.age_group
        WHEN 1 THEN '18岁以下' WHEN 2 THEN '18-25' WHEN 3 THEN '26-35'
        WHEN 4 THEN '36-45' WHEN 5 THEN '46-55' WHEN 6 THEN '55+'
    END AS age_label,
    COUNT(*) AS total,
    SUM(CASE WHEN pw.willing_to_try = 1 THEN 1 ELSE 0 END) AS willing_count,
    ROUND(100.0 * AVG(CASE WHEN pw.willing_to_try = 1 THEN 1.0 ELSE 0.0 END), 1) AS willing_pct,
    ROUND(AVG(i.int_avg_score), 2) AS avg_intention_score
FROM respondents r
JOIN purchase_willingness pw ON r.respondent_id = pw.respondent_id
JOIN intention_scores i ON r.respondent_id = i.respondent_id
GROUP BY r.gender, r.age_group
ORDER BY r.gender, r.age_group;

-- Q9: 购买动机排序 — 统计各动机被选中的次数和占比
SELECT '环保意识' AS motive, SUM(reason_eco) AS count,
       ROUND(100.0 * SUM(reason_eco) / COUNT(*), 1) AS pct
FROM purchase_willingness WHERE willing_to_try = 1
UNION ALL
SELECT '价格实惠', SUM(reason_price), ROUND(100.0*SUM(reason_price)/COUNT(*),1)
FROM purchase_willingness WHERE willing_to_try = 1
UNION ALL
SELECT '盲盒惊喜感', SUM(reason_surprise), ROUND(100.0*SUM(reason_surprise)/COUNT(*),1)
FROM purchase_willingness WHERE willing_to_try = 1
UNION ALL
SELECT '食品安全保障', SUM(reason_safety), ROUND(100.0*SUM(reason_safety)/COUNT(*),1)
FROM purchase_willingness WHERE willing_to_try = 1
UNION ALL
SELECT '商家信誉', SUM(reason_reputation), ROUND(100.0*SUM(reason_reputation)/COUNT(*),1)
FROM purchase_willingness WHERE willing_to_try = 1
UNION ALL
SELECT '购买便利性', SUM(reason_convenience), ROUND(100.0*SUM(reason_convenience)/COUNT(*),1)
FROM purchase_willingness WHERE willing_to_try = 1
ORDER BY count DESC;

-- Q10: 购买障碍排序（针对不愿意购买者）
SELECT '食品质量安全疑虑' AS barrier, SUM(barrier_quality) AS count,
       ROUND(100.0 * SUM(barrier_quality) / COUNT(*), 1) AS pct
FROM purchase_willingness WHERE willing_to_try = 2
UNION ALL
SELECT '倾向新鲜食品', SUM(barrier_fresh),
       ROUND(100.0*SUM(barrier_fresh)/COUNT(*),1)
FROM purchase_willingness WHERE willing_to_try = 2
UNION ALL
SELECT '更喜欢自选', SUM(barrier_choice),
       ROUND(100.0*SUM(barrier_choice)/COUNT(*),1)
FROM purchase_willingness WHERE willing_to_try = 2
UNION ALL
SELECT '价格太高', SUM(barrier_price),
       ROUND(100.0*SUM(barrier_price)/COUNT(*),1)
FROM purchase_willingness WHERE willing_to_try = 2
ORDER BY count DESC;

-- ============================================================
-- 难度 L3: 连接查询 (INNER JOIN/LEFT JOIN/多表联查/UNION/自连接)
-- ============================================================

-- Q11: 四表JOIN — 受访者完整画像（基本信息+认知+意愿+决策因素）
SELECT
    r.respondent_id,
    CASE r.gender WHEN 1 THEN '男' WHEN 2 THEN '女' END AS gender,
    CASE r.age_group WHEN 2 THEN '18-25' WHEN 3 THEN '26-35'
                     WHEN 4 THEN '36-45' WHEN 5 THEN '46-55' END AS age,
    c.awareness_level,
    CASE pw.willing_to_try WHEN 1 THEN '愿意' WHEN 2 THEN '不愿意' END AS willing,
    ROUND(a.att_avg_score, 1) AS att_score,
    ROUND(i.int_avg_score, 1) AS int_score,
    d.f_quality, d.f_price, d.f_eco
FROM respondents r
INNER JOIN cognition c ON r.respondent_id = c.respondent_id
INNER JOIN purchase_willingness pw ON r.respondent_id = pw.respondent_id
INNER JOIN attitude_scores a ON r.respondent_id = a.respondent_id
INNER JOIN intention_scores i ON r.respondent_id = i.respondent_id
INNER JOIN decision_factors d ON r.respondent_id = d.respondent_id
WHERE i.int_avg_score >= 4.0
ORDER BY i.int_avg_score DESC
LIMIT 20;

-- Q12: LEFT JOIN全貌 — 包含所有受访者（即使某些表没有记录）
SELECT
    r.respondent_id, r.gender, r.age_group,
    COALESCE(c.awareness_level, 0) AS awareness,
    COALESCE(pw.willing_to_try, 0) AS willing,
    COALESCE(ROUND(a.att_avg_score, 1), 0) AS attitude_avg
FROM respondents r
LEFT JOIN cognition c ON r.respondent_id = c.respondent_id
LEFT JOIN purchase_willingness pw ON r.respondent_id = pw.respondent_id
LEFT JOIN attitude_scores a ON r.respondent_id = a.respondent_id
ORDER BY r.respondent_id
LIMIT 20;

-- Q13: 自连接 — 找出与指定受访者（ID=1）决策因素最相似的人
SELECT d2.respondent_id,
       ABS(d1.f_price - d2.f_price) +
       ABS(d1.f_quality - d2.f_quality) +
       ABS(d1.f_eco - d2.f_eco) AS diff_sum,
       d2.f_price, d2.f_quality, d2.f_eco
FROM decision_factors d1
JOIN decision_factors d2 ON d1.respondent_id != d2.respondent_id
WHERE d1.respondent_id = 1
ORDER BY diff_sum ASC
LIMIT 10;

-- Q14: 购买决策因素9项综合排名（行转列）
SELECT '价格' AS factor, ROUND(AVG(f_price), 2) AS avg_score,
       RANK() OVER (ORDER BY AVG(f_price) DESC) AS rank_no
FROM decision_factors
UNION ALL
SELECT '质量', ROUND(AVG(f_quality), 2),
       RANK() OVER (ORDER BY AVG(f_quality) DESC)
FROM decision_factors
UNION ALL
SELECT '环保性', ROUND(AVG(f_eco), 2),
       RANK() OVER (ORDER BY AVG(f_eco) DESC)
FROM decision_factors
UNION ALL
SELECT '品牌知名度', ROUND(AVG(f_brand), 2),
       RANK() OVER (ORDER BY AVG(f_brand) DESC)
FROM decision_factors
UNION ALL
SELECT '社会认同感', ROUND(AVG(f_social_accept), 2),
       RANK() OVER (ORDER BY AVG(f_social_accept) DESC)
FROM decision_factors
UNION ALL
SELECT '食物种类口味', ROUND(AVG(f_variety_taste), 2),
       RANK() OVER (ORDER BY AVG(f_variety_taste) DESC)
FROM decision_factors
UNION ALL
SELECT '包装设计', ROUND(AVG(f_packaging), 2),
       RANK() OVER (ORDER BY AVG(f_packaging) DESC)
FROM decision_factors
UNION ALL
SELECT '购买便捷性', ROUND(AVG(f_convenience), 2),
       RANK() OVER (ORDER BY AVG(f_convenience) DESC)
FROM decision_factors
UNION ALL
SELECT '商家信誉服务', ROUND(AVG(f_service), 2),
       RANK() OVER (ORDER BY AVG(f_service) DESC)
FROM decision_factors
ORDER BY avg_score DESC;

-- ============================================================
-- 难度 L4: 高级查询 (窗口函数/CTE/相关子查询/EXISTS)
-- ============================================================

-- Q15: 窗口函数 ROW_NUMBER — 按收入分组，每个收入层级内按总分排名
SELECT
    monthly_income,
    respondent_id,
    total_score,
    ROW_NUMBER() OVER (PARTITION BY monthly_income ORDER BY total_score DESC) AS rank_in_group
FROM respondents
WHERE total_score > 0
ORDER BY monthly_income, rank_in_group
LIMIT 30;

-- Q16: 窗口函数 RANK vs DENSE_RANK — 意向评分排名（含并列）
SELECT
    respondent_id,
    int_avg_score,
    RANK() OVER (ORDER BY int_avg_score DESC) AS rank_no,
    DENSE_RANK() OVER (ORDER BY int_avg_score DESC) AS dense_rank_no,
    ROW_NUMBER() OVER (ORDER BY int_avg_score DESC) AS row_num
FROM intention_scores
ORDER BY int_avg_score DESC
LIMIT 15;

-- Q17: LAG/LEAD窗口函数 — 计算相邻受访者的意图评分变化
SELECT
    respondent_id,
    int_avg_score,
    LAG(int_avg_score, 1) OVER (ORDER BY respondent_id) AS prev_score,
    LEAD(int_avg_score, 1) OVER (ORDER BY respondent_id) AS next_score,
    ROUND(int_avg_score - LAG(int_avg_score, 1) OVER (ORDER BY respondent_id), 2) AS diff_from_prev
FROM intention_scores
WHERE respondent_id BETWEEN 1 AND 20
ORDER BY respondent_id;

-- Q18: CTE (WITH) — 使用公共表表达式计算各年龄段的购买意愿转化率
WITH age_stats AS (
    SELECT
        r.age_group,
        COUNT(*) AS total,
        SUM(CASE WHEN pw.willing_to_try = 1 THEN 1 ELSE 0 END) AS willing,
        SUM(CASE WHEN pw.has_purchased = 1 THEN 1 ELSE 0 END) AS purchased
    FROM respondents r
    JOIN purchase_willingness pw ON r.respondent_id = pw.respondent_id
    GROUP BY r.age_group
)
SELECT
    age_group,
    total,
    willing,
    purchased,
    ROUND(100.0 * willing / total, 1) AS willingness_rate,
    ROUND(100.0 * purchased / total, 1) AS purchase_rate,
    ROUND(100.0 * purchased / NULLIF(willing, 0), 1) AS conversion_rate
FROM age_stats
ORDER BY age_group;

-- Q19: CTE嵌套 — 高价值用户识别（购买过+高分+高意向）
WITH purchased_users AS (
    SELECT respondent_id FROM purchase_willingness WHERE has_purchased = 1
),
high_score_users AS (
    SELECT respondent_id FROM respondents WHERE total_score > 150
),
high_intent_users AS (
    SELECT respondent_id FROM intention_scores WHERE int_avg_score >= 4.5
)
SELECT
    r.respondent_id,
    r.gender, r.age_group, r.education,
    i.int_avg_score, r.total_score
FROM respondents r
JOIN intention_scores i ON r.respondent_id = i.respondent_id
WHERE r.respondent_id IN (SELECT respondent_id FROM purchased_users)
  AND r.respondent_id IN (SELECT respondent_id FROM high_score_users)
  AND r.respondent_id IN (SELECT respondent_id FROM high_intent_users)
ORDER BY r.total_score DESC
LIMIT 20;

-- Q20: 相关子查询 — 找出态度评分高于其同职业群体均分的受访者
SELECT
    r.respondent_id, r.occupation,
    ROUND(a.att_avg_score, 2) AS my_attitude,
    ROUND((SELECT AVG(a2.att_avg_score)
           FROM attitude_scores a2
           JOIN respondents r2 ON a2.respondent_id = r2.respondent_id
           WHERE r2.occupation = r.occupation), 2) AS occ_avg_attitude
FROM respondents r
JOIN attitude_scores a ON r.respondent_id = a.respondent_id
WHERE a.att_avg_score > (
    SELECT AVG(a2.att_avg_score)
    FROM attitude_scores a2
    JOIN respondents r2 ON a2.respondent_id = r2.respondent_id
    WHERE r2.occupation = r.occupation
)
ORDER BY r.occupation, my_attitude DESC
LIMIT 20;

-- Q21: EXISTS — 查找有实质建议的受访者
SELECT r.respondent_id, r.age_group, r.education,
       pw.suggestions
FROM respondents r
JOIN purchase_willingness pw ON r.respondent_id = pw.respondent_id
WHERE EXISTS (
    SELECT 1 FROM purchase_willingness pw2
    WHERE pw2.respondent_id = r.respondent_id
      AND pw2.suggestions IS NOT NULL
      AND LENGTH(pw2.suggestions) > 5
)
ORDER BY LENGTH(pw.suggestions) DESC
LIMIT 15;

-- Q22: NOT EXISTS — 找出未填写任何认知来源的受访者
SELECT r.respondent_id, r.age_group, r.education,
       c.awareness_level
FROM respondents r
JOIN cognition c ON r.respondent_id = c.respondent_id
WHERE NOT EXISTS (
    SELECT 1
    FROM cognition c2
    WHERE c2.respondent_id = r.respondent_id
      AND (c2.source_social + c2.source_friend + c2.source_news
           + c2.source_ad + c2.source_other) > 0
)
LIMIT 15;

-- Q23: 累计和/移动平均 — 按受访者ID计算态度评分的滚动均值
SELECT
    respondent_id,
    att_avg_score,
    ROUND(AVG(att_avg_score) OVER (ORDER BY respondent_id ROWS BETWEEN 4 PRECEDING AND CURRENT ROW), 2) AS moving_avg_5,
    SUM(att_avg_score) OVER (ORDER BY respondent_id) AS cumulative_sum
FROM attitude_scores
WHERE respondent_id <= 30
ORDER BY respondent_id;

-- Q24: NTILE分位数 — 将受访者按意向评分分为4个层级
SELECT
    respondent_id,
    int_avg_score,
    NTILE(4) OVER (ORDER BY int_avg_score) AS quartile,
    CASE NTILE(4) OVER (ORDER BY int_avg_score)
        WHEN 1 THEN '低意向'
        WHEN 2 THEN '中低意向'
        WHEN 3 THEN '中高意向'
        WHEN 4 THEN '高意向'
    END AS intention_level
FROM intention_scores
ORDER BY int_avg_score DESC
LIMIT 20;

-- ============================================================
-- 难度 L5: 分析型查询 (RFM分段/漏斗分析/群体画像/假设检验)
-- ============================================================

-- Q25: 转化漏斗分析 — 从认知到购买的各阶段转化
SELECT
    '认知(了解程度≥3)' AS stage, COUNT(*) AS count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM cognition), 1) AS pct
FROM cognition WHERE awareness_level >= 3
UNION ALL
SELECT '愿意尝试', COUNT(*),
       ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM purchase_willingness),1)
FROM purchase_willingness WHERE willing_to_try = 1
UNION ALL
SELECT '曾经购买', COUNT(*),
       ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM purchase_willingness),1)
FROM purchase_willingness WHERE has_purchased = 1
UNION ALL
SELECT '满意体验(≥4)', COUNT(*),
       ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM purchase_willingness WHERE purchase_exp IS NOT NULL),1)
FROM purchase_willingness WHERE purchase_exp >= 4;

-- Q26: 用户RFM式分段（基于调研数据改造版）
-- R=是否近期有购买意愿, F=购买频次, M=意向评分
SELECT
    CASE
        WHEN pw.has_purchased = 1 AND pw.purchase_freq >= 3 AND i.int_avg_score >= 4.5 THEN '核心用户'
        WHEN pw.has_purchased = 1 AND i.int_avg_score >= 4.0 THEN '活跃用户'
        WHEN pw.willing_to_try = 1 AND i.int_avg_score >= 3.5 THEN '潜力用户'
        WHEN pw.willing_to_try = 1 THEN '观望用户'
        ELSE '流失用户'
    END AS user_segment,
    COUNT(*) AS count,
    ROUND(AVG(i.int_avg_score), 2) AS avg_intention,
    ROUND(AVG(r.total_score), 1) AS avg_total_score,
    ROUND(AVG(COALESCE(pw.purchase_exp, 0)), 1) AS avg_experience
FROM respondents r
JOIN purchase_willingness pw ON r.respondent_id = pw.respondent_id
JOIN intention_scores i ON r.respondent_id = i.respondent_id
GROUP BY user_segment
ORDER BY avg_intention DESC;

-- Q27: 决策因素影响力 — 购买者 vs 未购买者对比（价值感知差异分析）
SELECT
    CASE WHEN pw.has_purchased = 1 THEN '已购买' ELSE '未购买' END AS purchase_status,
    COUNT(*) AS count,
    ROUND(AVG(d.f_price), 2) AS avg_price_importance,
    ROUND(AVG(d.f_quality), 2) AS avg_quality_importance,
    ROUND(AVG(d.f_eco), 2) AS avg_eco_importance,
    ROUND(AVG(d.f_convenience), 2) AS avg_convenience_importance,
    ROUND(AVG(d.f_service), 2) AS avg_service_importance
FROM respondents r
JOIN purchase_willingness pw ON r.respondent_id = pw.respondent_id
JOIN decision_factors d ON r.respondent_id = d.respondent_id
GROUP BY pw.has_purchased
ORDER BY pw.has_purchased;

-- Q28: 认知来源交叉分析 — 社交媒体+朋友推荐的双渠道影响
SELECT
    CASE
        WHEN c.source_social = 1 AND c.source_friend = 1 THEN '双渠道(社交+朋友)'
        WHEN c.source_social = 1 THEN '仅社交媒体'
        WHEN c.source_friend = 1 THEN '仅朋友推荐'
        ELSE '其他渠道'
    END AS channel_group,
    COUNT(*) AS count,
    ROUND(AVG(a.att_avg_score), 2) AS avg_attitude,
    ROUND(100.0 * SUM(CASE WHEN pw.willing_to_try = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS willing_rate,
    ROUND(100.0 * SUM(CASE WHEN pw.has_purchased = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS purchase_rate
FROM cognition c
JOIN purchase_willingness pw ON c.respondent_id = pw.respondent_id
JOIN attitude_scores a ON c.respondent_id = a.respondent_id
GROUP BY channel_group
ORDER BY willing_rate DESC;

-- Q29: 百分比排名 — 每个受访者的意向得分在全体中的百分位
SELECT
    respondent_id,
    int_avg_score,
    ROUND(PERCENT_RANK() OVER (ORDER BY int_avg_score) * 100, 1) AS percentile,
    CUME_DIST() OVER (ORDER BY int_avg_score) AS cumulative_dist
FROM intention_scores
ORDER BY int_avg_score DESC
LIMIT 20;

-- Q30: 群体画像 — 各年龄段的完整profile（综合分析）
WITH age_profile AS (
    SELECT
        r.age_group,
        COUNT(*) AS cnt,
        ROUND(AVG(a.att_avg_score), 2) AS avg_attitude,
        ROUND(AVG(i.int_avg_score), 2) AS avg_intention,
        ROUND(AVG(d.f_quality), 2) AS avg_quality_need,
        ROUND(AVG(d.f_price), 2) AS avg_price_sensitivity,
        ROUND(100.0 * SUM(CASE WHEN pw.has_purchased = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS purchase_rate
    FROM respondents r
    JOIN attitude_scores a ON r.respondent_id = a.respondent_id
    JOIN intention_scores i ON r.respondent_id = i.respondent_id
    JOIN decision_factors d ON r.respondent_id = d.respondent_id
    JOIN purchase_willingness pw ON r.respondent_id = pw.respondent_id
    GROUP BY r.age_group
)
SELECT
    CASE age_group
        WHEN 1 THEN '18岁以下' WHEN 2 THEN '18-25' WHEN 3 THEN '26-35'
        WHEN 4 THEN '36-45' WHEN 5 THEN '46-55' WHEN 6 THEN '55+'
    END AS age_label,
    cnt, avg_attitude, avg_intention, avg_quality_need,
    avg_price_sensitivity, purchase_rate,
    RANK() OVER (ORDER BY avg_intention DESC) AS intention_rank
FROM age_profile
ORDER BY age_group;

-- Q31: 综合子查询 — 找出"高环保意识但低购买率"的矛盾群体特征
SELECT
    r.respondent_id, r.age_group, r.gender,
    d.f_eco AS eco_importance,
    i.int_avg_score,
    pw.has_purchased
FROM respondents r
JOIN decision_factors d ON r.respondent_id = d.respondent_id
JOIN intention_scores i ON r.respondent_id = i.respondent_id
JOIN purchase_willingness pw ON r.respondent_id = pw.respondent_id
WHERE d.f_eco >= 7                    -- 认为环保极其重要
  AND i.int_avg_score >= 4.0          -- 购买意向高
  AND pw.has_purchased = 2            -- 但实际未购买
  AND pw.barrier_quality = 1          -- 障碍是质量安全疑虑
ORDER BY i.int_avg_score DESC
LIMIT 15;

-- Q32: FIRST_VALUE/LAST_VALUE — 各年龄组内评分最高和最低的受访者
SELECT DISTINCT
    r.age_group,
    FIRST_VALUE(r.respondent_id) OVER (PARTITION BY r.age_group ORDER BY i.int_avg_score DESC) AS top_respondent,
    FIRST_VALUE(i.int_avg_score) OVER (PARTITION BY r.age_group ORDER BY i.int_avg_score DESC) AS top_intention,
    FIRST_VALUE(r.respondent_id) OVER (PARTITION BY r.age_group ORDER BY i.int_avg_score ASC) AS bottom_respondent,
    FIRST_VALUE(i.int_avg_score) OVER (PARTITION BY r.age_group ORDER BY i.int_avg_score ASC) AS bottom_intention
FROM respondents r
JOIN intention_scores i ON r.respondent_id = i.respondent_id
ORDER BY r.age_group;

-- ============================================================
-- 查询数量统计
-- ============================================================
-- 难度L1: 5条 (Q1-Q5)
-- 难度L2: 5条 (Q6-Q10)
-- 难度L3: 4条 (Q11-Q14)
-- 难度L4: 10条 (Q15-Q24)
-- 难度L5: 8条 (Q25-Q32)
-- 总计: 32条SQL查询
-- 覆盖: SELECT, WHERE, LIKE, IN, BETWEEN, DISTINCT,
--        GROUP BY, HAVING, 聚合函数, CASE WHEN, UNION,
--        INNER JOIN, LEFT JOIN, 自连接, 子查询, 相关子查询,
--        EXISTS/NOT EXISTS, CTE(WITH), ROW_NUMBER, RANK, DENSE_RANK,
--        NTILE, LAG, LEAD, FIRST_VALUE, PERCENT_RANK, CUME_DIST,
--        窗口聚合, 漏斗分析, RFM分段, 群体画像
