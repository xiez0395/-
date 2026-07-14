-- ============================================================
-- 西安居民剩菜盲盒调查数据库 — Schema设计
-- 项目: 惜食减损，"剩"者为王
-- 引擎: SQLite 3
-- 设计者: 西北大学 正大杯项目组
-- ============================================================

-- 清理旧表（如需重建）
DROP TABLE IF EXISTS decision_factors;
DROP TABLE IF EXISTS intention_scores;
DROP TABLE IF EXISTS attitude_scores;
DROP TABLE IF EXISTS purchase_willingness;
DROP TABLE IF EXISTS cognition;
DROP TABLE IF EXISTS respondents;

-- ============================================================
-- 表1: respondents — 受访者基础信息
-- ============================================================
CREATE TABLE respondents (
    respondent_id   INTEGER PRIMARY KEY,           -- 受访者编号（序号）
    gender          INTEGER NOT NULL CHECK(gender IN (1, 2)),    -- 1=男, 2=女
    age_group       INTEGER NOT NULL CHECK(age_group BETWEEN 1 AND 6),
        /* 1=18岁以下, 2=18-25岁, 3=26-35岁, 4=36-45岁, 5=46-55岁, 6=55岁以上 */
    education       INTEGER NOT NULL CHECK(education BETWEEN 1 AND 5),
        /* 1=初中及以下, 2=高中/中专, 3=大专, 4=本科, 5=硕士及以上 */
    occupation      INTEGER NOT NULL CHECK(occupation BETWEEN 1 AND 9),
        /* 1=学生, 2=企业职员, 3=公务员/事业单位, 4=自由职业, 5=个体经营,
           6=教育/科研, 7=医疗, 8=其他, 9=退休 */
    monthly_income  INTEGER NOT NULL CHECK(monthly_income BETWEEN 1 AND 5),
        /* 1=3000以下, 2=3000-5000, 3=5000-8000, 4=8000-15000, 5=15000以上 */
    monthly_spend   INTEGER NOT NULL CHECK(monthly_spend BETWEEN 1 AND 5),
        /* 1=2000以下, 2=2000-4000, 3=4000-6000, 4=6000-10000, 5=10000以上 */
    total_score     INTEGER,                        -- 问卷总分
    survey_duration INTEGER,                        -- 作答耗时(秒)
    created_at      TEXT                            -- 提交时间
);

-- 复合索引：支持按人口统计特征快速筛选
CREATE INDEX idx_resp_gender ON respondents(gender);
CREATE INDEX idx_resp_age ON respondents(age_group);
CREATE INDEX idx_resp_edu ON respondents(education);
CREATE INDEX idx_resp_occupation ON respondents(occupation);
CREATE INDEX idx_resp_income_spend ON respondents(monthly_income, monthly_spend);

-- ============================================================
-- 表2: cognition — 认知评估
-- ============================================================
CREATE TABLE cognition (
    cognition_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    respondent_id   INTEGER NOT NULL UNIQUE,
    awareness_level INTEGER NOT NULL CHECK(awareness_level BETWEEN 1 AND 4),
        /* 1=完全不了解, 2=不太了解, 3=一般了解, 4=非常了解 */
    new_thing_attitude INTEGER CHECK(new_thing_attitude IS NULL OR new_thing_attitude BETWEEN 1 AND 4),
        /* 对新事物态度: 1=非常积极, 2=比较积极, 3=一般, 4=保守, NULL=未作答 */
    association     INTEGER CHECK(association IS NULL OR association BETWEEN 1 AND 5),
        /* 首先联想到: 1=环保节约, 2=新颖消费, 3=食品安全隐患, 4=临期打折, 5=其他 */
    source_social   INTEGER DEFAULT 0,              -- 社交媒体 (0/1)
    source_friend   INTEGER DEFAULT 0,              -- 朋友推荐 (0/1)
    source_news     INTEGER DEFAULT 0,              -- 新闻媒体 (0/1)
    source_ad       INTEGER DEFAULT 0,              -- 商家广告 (0/1)
    source_other    INTEGER DEFAULT 0,              -- 其他 (0/1)
    FOREIGN KEY (respondent_id) REFERENCES respondents(respondent_id)
);

CREATE INDEX idx_cog_awareness ON cognition(awareness_level);

-- ============================================================
-- 表3: purchase_willingness — 购买意愿与行为
-- ============================================================
CREATE TABLE purchase_willingness (
    pw_id           INTEGER PRIMARY KEY AUTOINCREMENT,
    respondent_id   INTEGER NOT NULL UNIQUE,
    willing_to_try  INTEGER NOT NULL CHECK(willing_to_try IN (1, 2)),
        /* 1=愿意, 2=不愿意 */
    -- 购买动机（多选，0/1标记）
    reason_eco      INTEGER DEFAULT 0,              -- 环保意识
    reason_price    INTEGER DEFAULT 0,              -- 价格实惠
    reason_surprise INTEGER DEFAULT 0,              -- 惊喜感
    reason_safety   INTEGER DEFAULT 0,              -- 食品安全保障
    reason_reputation INTEGER DEFAULT 0,            -- 商家信誉
    reason_convenience INTEGER DEFAULT 0,           -- 便利性
    reason_other    INTEGER DEFAULT 0,              -- 其他
    -- 购买障碍（多选，0/1标记）
    barrier_price   INTEGER DEFAULT 0,              -- 价格太高
    barrier_quality INTEGER DEFAULT 0,              -- 质量安全疑虑
    barrier_choice  INTEGER DEFAULT 0,              -- 更喜欢自选
    barrier_fresh   INTEGER DEFAULT 0,              -- 倾向新鲜食品
    barrier_conv    INTEGER DEFAULT 0,              -- 取货不便利
    barrier_trust   INTEGER DEFAULT 0,              -- 商家信誉差
    barrier_other   INTEGER DEFAULT 0,              -- 其他
    -- 实际购买行为
    has_purchased   INTEGER NOT NULL CHECK(has_purchased IN (1, 2)),
        /* 1=是, 2=否 */
    purchase_exp    INTEGER CHECK(purchase_exp IS NULL OR purchase_exp BETWEEN 1 AND 5),
        /* 购买体验: 1=非常不满意...5=非常满意, NULL=未购买 */
    purchase_freq   INTEGER CHECK(purchase_freq IS NULL OR purchase_freq BETWEEN 1 AND 4),
        /* 1=从不, 2=偶尔, 3=经常, 4=每次都买 */
    suggestions     TEXT,                           -- 开放式建议
    FOREIGN KEY (respondent_id) REFERENCES respondents(respondent_id)
);

CREATE INDEX idx_pw_willing ON purchase_willingness(willing_to_try);
CREATE INDEX idx_pw_purchased ON purchase_willingness(has_purchased);

-- ============================================================
-- 表4: attitude_scores — 态度评分（Q11, Likert 1-5量表）
-- ============================================================
CREATE TABLE attitude_scores (
    attitude_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    respondent_id   INTEGER NOT NULL UNIQUE,
    q11_concept     INTEGER NOT NULL CHECK(q11_concept BETWEEN 1 AND 5),
        -- 对剩菜盲盒概念的理解程度
    q11_reduce_waste INTEGER NOT NULL CHECK(q11_reduce_waste BETWEEN 1 AND 5),
        -- 减少食物浪费的有效手段
    q11_eco_innov   INTEGER NOT NULL CHECK(q11_eco_innov BETWEEN 1 AND 5),
        -- 环保且创新的售卖方式
    q11_novel_exp   INTEGER NOT NULL CHECK(q11_novel_exp BETWEEN 1 AND 5),
        -- 新颖的消费体验
    q11_food_safety INTEGER NOT NULL CHECK(q11_food_safety BETWEEN 1 AND 5),
        -- 食品安全应严格把关
    q11_fair_price  INTEGER NOT NULL CHECK(q11_fair_price BETWEEN 1 AND 5),
        -- 定价应合理反映价值
    q11_self_pickup INTEGER NOT NULL CHECK(q11_self_pickup BETWEEN 1 AND 5),
        -- 自提能减少第三方污染
    att_avg_score   REAL,                           -- 态度平均分（计算列）
    FOREIGN KEY (respondent_id) REFERENCES respondents(respondent_id)
);

-- ============================================================
-- 表5: intention_scores — 购买意向评分（Q16, Likert 1-5量表）
-- ============================================================
CREATE TABLE intention_scores (
    intention_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    respondent_id   INTEGER NOT NULL UNIQUE,
    q16_learn       INTEGER NOT NULL CHECK(q16_learn BETWEEN 1 AND 5),
        -- 会主动了解
    q16_eco_support INTEGER NOT NULL CHECK(q16_eco_support BETWEEN 1 AND 5),
        -- 环保可持续消费，愿意支持
    q16_novel_fun   INTEGER NOT NULL CHECK(q16_novel_fun BETWEEN 1 AND 5),
        -- 新颖有趣的体验，愿意尝试
    q16_satisfy     INTEGER NOT NULL CHECK(q16_satisfy BETWEEN 1 AND 5),
        -- 满足新奇体验和节约需求
    q16_future_buy  INTEGER NOT NULL CHECK(q16_future_buy BETWEEN 1 AND 5),
        -- 未来会购买
    q16_follow_info INTEGER NOT NULL CHECK(q16_follow_info BETWEEN 1 AND 5),
        -- 会关注商家信息和优惠
    q16_recommend   INTEGER NOT NULL CHECK(q16_recommend BETWEEN 1 AND 5),
        -- 会推荐身边人
    q16_share_social INTEGER NOT NULL CHECK(q16_share_social BETWEEN 1 AND 5),
        -- 会在社交平台分享
    int_avg_score   REAL,                           -- 意向平均分
    FOREIGN KEY (respondent_id) REFERENCES respondents(respondent_id)
);

-- ============================================================
-- 表6: decision_factors — 决策因素影响程度（Q21, Likert 1-7量表）
-- ============================================================
CREATE TABLE decision_factors (
    df_id           INTEGER PRIMARY KEY AUTOINCREMENT,
    respondent_id   INTEGER NOT NULL UNIQUE,
    f_price         INTEGER NOT NULL CHECK(f_price BETWEEN 1 AND 7),
        -- 价格
    f_quality       INTEGER NOT NULL CHECK(f_quality BETWEEN 1 AND 7),
        -- 质量
    f_eco           INTEGER NOT NULL CHECK(f_eco BETWEEN 1 AND 7),
        -- 环保性
    f_brand         INTEGER NOT NULL CHECK(f_brand BETWEEN 1 AND 7),
        -- 品牌知名度
    f_social_accept INTEGER NOT NULL CHECK(f_social_accept BETWEEN 1 AND 7),
        -- 社会认同感
    f_variety_taste INTEGER NOT NULL CHECK(f_variety_taste BETWEEN 1 AND 7),
        -- 食物种类和口味
    f_packaging     INTEGER NOT NULL CHECK(f_packaging BETWEEN 1 AND 7),
        -- 包装和设计
    f_convenience   INTEGER NOT NULL CHECK(f_convenience BETWEEN 1 AND 7),
        -- 购买取货便捷性
    f_service       INTEGER NOT NULL CHECK(f_service BETWEEN 1 AND 7),
        -- 商家信誉和服务
    df_avg_score    REAL,                           -- 决策因素平均分
    FOREIGN KEY (respondent_id) REFERENCES respondents(respondent_id)
);

-- ============================================================
-- 视图：受访者完整画像（JOIN全部6表）
-- ============================================================
CREATE VIEW v_respondent_full AS
SELECT
    r.respondent_id,
    r.gender, r.age_group, r.education, r.occupation,
    r.monthly_income, r.monthly_spend, r.total_score,
    c.awareness_level, c.new_thing_attitude,
    c.source_social, c.source_friend, c.source_news, c.source_ad,
    pw.willing_to_try, pw.has_purchased, pw.purchase_exp, pw.purchase_freq,
    pw.reason_eco, pw.reason_price, pw.reason_surprise,
    pw.barrier_quality, pw.barrier_fresh,
    a.q11_reduce_waste, a.q11_novel_exp, a.q11_food_safety, a.att_avg_score,
    i.q16_future_buy, i.q16_recommend, i.int_avg_score,
    d.f_price, d.f_quality, d.f_eco, d.f_convenience, d.f_service, d.df_avg_score
FROM respondents r
LEFT JOIN cognition c ON r.respondent_id = c.respondent_id
LEFT JOIN purchase_willingness pw ON r.respondent_id = pw.respondent_id
LEFT JOIN attitude_scores a ON r.respondent_id = a.respondent_id
LEFT JOIN intention_scores i ON r.respondent_id = i.respondent_id
LEFT JOIN decision_factors d ON r.respondent_id = d.respondent_id;

-- ============================================================
-- 视图：购买意愿转化漏斗
-- ============================================================
CREATE VIEW v_conversion_funnel AS
SELECT
    '总受访者' AS stage, COUNT(*) AS count FROM respondents
UNION ALL
SELECT
    '了解剩菜盲盒' AS stage,
    COUNT(*) FROM cognition WHERE awareness_level >= 3
UNION ALL
SELECT
    '愿意尝试' AS stage,
    COUNT(*) FROM purchase_willingness WHERE willing_to_try = 1
UNION ALL
SELECT
    '曾经购买' AS stage,
    COUNT(*) FROM purchase_willingness WHERE has_purchased = 1;

-- ============================================================
-- 视图：高意向用户（购买意向均分≥4）
-- ============================================================
CREATE VIEW v_high_intention_users AS
SELECT
    r.respondent_id, r.gender, r.age_group, r.education,
    r.monthly_income, i.int_avg_score, d.f_quality, d.f_price
FROM respondents r
JOIN intention_scores i ON r.respondent_id = i.respondent_id
JOIN decision_factors d ON r.respondent_id = d.respondent_id
WHERE i.int_avg_score >= 4.0
ORDER BY i.int_avg_score DESC;

-- === Schema设计完成 ===
-- 共6张表 + 3个视图已创建
-- 表: respondents, cognition, purchase_willingness, attitude_scores, intention_scores, decision_factors
-- 视图: v_respondent_full, v_conversion_funnel, v_high_intention_users
