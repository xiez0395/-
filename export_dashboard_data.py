# -*- coding: utf-8 -*-
import sqlite3, json

conn = sqlite3.connect('E:/workbuddy/2026-07-14-11-06-39/portfolio/data/survey.db')
conn.row_factory = sqlite3.Row
data = {}

data['gender'] = [dict(r) for r in conn.execute("SELECT CASE gender WHEN 1 THEN '男' WHEN 2 THEN '女' END as label, COUNT(*) as value FROM respondents GROUP BY gender").fetchall()]
data['age'] = [dict(r) for r in conn.execute("SELECT CASE age_group WHEN 1 THEN '18岁以下' WHEN 2 THEN '18-25' WHEN 3 THEN '26-35' WHEN 4 THEN '36-45' WHEN 5 THEN '46-55' WHEN 6 THEN '55+' END as label, COUNT(*) as value FROM respondents GROUP BY age_group ORDER BY age_group").fetchall()]
data['education'] = [dict(r) for r in conn.execute("SELECT CASE education WHEN 1 THEN '初中及以下' WHEN 2 THEN '高中/中专' WHEN 3 THEN '大专' WHEN 4 THEN '本科' WHEN 5 THEN '硕士及以上' END as label, COUNT(*) as value FROM respondents GROUP BY education ORDER BY education").fetchall()]
data['income'] = [dict(r) for r in conn.execute("SELECT CASE monthly_income WHEN 1 THEN '<3000' WHEN 2 THEN '3000-5000' WHEN 3 THEN '5000-8000' WHEN 4 THEN '8000-15000' WHEN 5 THEN '>15000' END as label, COUNT(*) as value FROM respondents GROUP BY monthly_income ORDER BY monthly_income").fetchall()]
data['awareness'] = [dict(r) for r in conn.execute("SELECT CASE awareness_level WHEN 1 THEN '完全不了解' WHEN 2 THEN '不太了解' WHEN 3 THEN '一般了解' WHEN 4 THEN '非常了解' END as label, COUNT(*) as value FROM cognition GROUP BY awareness_level ORDER BY awareness_level").fetchall()]

# Edu x willingness
data['edu_willing'] = []
for r in conn.execute("""SELECT CASE r.education WHEN 1 THEN '初中及以下' WHEN 2 THEN '高中/中专' WHEN 3 THEN '大专' WHEN 4 THEN '本科' WHEN 5 THEN '硕士及以上' END as label, ROUND(100.0*SUM(CASE WHEN pw.willing_to_try=1 THEN 1 ELSE 0 END)/COUNT(*),1) as willing, ROUND(100.0*SUM(CASE WHEN pw.has_purchased=1 THEN 1 ELSE 0 END)/COUNT(*),1) as purchased FROM respondents r JOIN purchase_willingness pw ON r.respondent_id=pw.respondent_id GROUP BY r.education ORDER BY r.education"""):
    data['edu_willing'].append(dict(r))

# Motivations
data['motivations'] = [
    {'label': '价格实惠', 'value': conn.execute("SELECT SUM(reason_price) FROM purchase_willingness WHERE willing_to_try=1").fetchone()[0]},
    {'label': '环保意识', 'value': conn.execute("SELECT SUM(reason_eco) FROM purchase_willingness WHERE willing_to_try=1").fetchone()[0]},
    {'label': '盲盒惊喜感', 'value': conn.execute("SELECT SUM(reason_surprise) FROM purchase_willingness WHERE willing_to_try=1").fetchone()[0]},
    {'label': '食品安全保障', 'value': conn.execute("SELECT SUM(reason_safety) FROM purchase_willingness WHERE willing_to_try=1").fetchone()[0]},
    {'label': '商家信誉', 'value': conn.execute("SELECT SUM(reason_reputation) FROM purchase_willingness WHERE willing_to_try=1").fetchone()[0]},
    {'label': '购买便利性', 'value': conn.execute("SELECT SUM(reason_convenience) FROM purchase_willingness WHERE willing_to_try=1").fetchone()[0]},
]

data['barriers'] = [
    {'label': '质量安全疑虑', 'value': conn.execute("SELECT SUM(barrier_quality) FROM purchase_willingness WHERE willing_to_try=2").fetchone()[0]},
    {'label': '倾向新鲜食品', 'value': conn.execute("SELECT SUM(barrier_fresh) FROM purchase_willingness WHERE willing_to_try=2").fetchone()[0]},
    {'label': '更喜欢自选', 'value': conn.execute("SELECT SUM(barrier_choice) FROM purchase_willingness WHERE willing_to_try=2").fetchone()[0]},
    {'label': '价格太高', 'value': conn.execute("SELECT SUM(barrier_price) FROM purchase_willingness WHERE willing_to_try=2").fetchone()[0]},
]

df = conn.execute("SELECT ROUND(AVG(f_price),2) as price, ROUND(AVG(f_quality),2) as quality, ROUND(AVG(f_eco),2) as eco, ROUND(AVG(f_brand),2) as brand, ROUND(AVG(f_social_accept),2) as social, ROUND(AVG(f_variety_taste),2) as variety, ROUND(AVG(f_packaging),2) as packaging, ROUND(AVG(f_convenience),2) as convenience, ROUND(AVG(f_service),2) as service FROM decision_factors").fetchone()
data['decision_factors'] = dict(df)

data['segments'] = [dict(r) for r in conn.execute("""SELECT CASE WHEN pw.has_purchased=1 AND pw.purchase_freq>=3 AND i.int_avg_score>=4.5 THEN '核心用户' WHEN pw.has_purchased=1 AND i.int_avg_score>=4.0 THEN '活跃用户' WHEN pw.willing_to_try=1 AND i.int_avg_score>=3.5 THEN '潜力用户' WHEN pw.willing_to_try=1 THEN '观望用户' ELSE '流失用户' END as label, COUNT(*) as value FROM respondents r JOIN purchase_willingness pw ON r.respondent_id=pw.respondent_id JOIN intention_scores i ON r.respondent_id=i.respondent_id GROUP BY label ORDER BY COUNT(*) DESC""").fetchall()]

data['funnel'] = [
    {'stage': '总受访者', 'count': 624, 'pct': 100.0},
    {'stage': '了解(>=一般)', 'count': conn.execute("SELECT COUNT(*) FROM cognition WHERE awareness_level>=3").fetchone()[0], 'pct': round(100.0*conn.execute("SELECT COUNT(*) FROM cognition WHERE awareness_level>=3").fetchone()[0]/624,1)},
    {'stage': '愿意尝试', 'count': conn.execute("SELECT COUNT(*) FROM purchase_willingness WHERE willing_to_try=1").fetchone()[0], 'pct': round(100.0*conn.execute("SELECT COUNT(*) FROM purchase_willingness WHERE willing_to_try=1").fetchone()[0]/624,1)},
    {'stage': '曾经购买', 'count': conn.execute("SELECT COUNT(*) FROM purchase_willingness WHERE has_purchased=1").fetchone()[0], 'pct': round(100.0*conn.execute("SELECT COUNT(*) FROM purchase_willingness WHERE has_purchased=1").fetchone()[0]/624,1)},
]

data['intention_dims'] = [
    {'label': '主动了解', 'score': conn.execute("SELECT ROUND(AVG(q16_learn),2) FROM intention_scores").fetchone()[0]},
    {'label': '环保支持', 'score': conn.execute("SELECT ROUND(AVG(q16_eco_support),2) FROM intention_scores").fetchone()[0]},
    {'label': '新颖有趣', 'score': conn.execute("SELECT ROUND(AVG(q16_novel_fun),2) FROM intention_scores").fetchone()[0]},
    {'label': '满足需求', 'score': conn.execute("SELECT ROUND(AVG(q16_satisfy),2) FROM intention_scores").fetchone()[0]},
    {'label': '未来购买', 'score': conn.execute("SELECT ROUND(AVG(q16_future_buy),2) FROM intention_scores").fetchone()[0]},
    {'label': '关注信息', 'score': conn.execute("SELECT ROUND(AVG(q16_follow_info),2) FROM intention_scores").fetchone()[0]},
    {'label': '推荐他人', 'score': conn.execute("SELECT ROUND(AVG(q16_recommend),2) FROM intention_scores").fetchone()[0]},
    {'label': '社交分享', 'score': conn.execute("SELECT ROUND(AVG(q16_share_social),2) FROM intention_scores").fetchone()[0]},
]

row = conn.execute("""SELECT COUNT(*), ROUND(100.0*SUM(CASE WHEN gender=2 THEN 1 ELSE 0 END)/COUNT(*),1), ROUND(100.0*SUM(CASE WHEN education>=4 THEN 1 ELSE 0 END)/COUNT(*),1), ROUND(AVG(a.att_avg_score),2), ROUND(AVG(i.int_avg_score),2), ROUND(100.0*SUM(CASE WHEN pw.willing_to_try=1 THEN 1 ELSE 0 END)/COUNT(*),1), ROUND(100.0*SUM(CASE WHEN pw.has_purchased=1 THEN 1 ELSE 0 END)/COUNT(*),1) FROM respondents r JOIN attitude_scores a ON r.respondent_id=a.respondent_id JOIN intention_scores i ON r.respondent_id=i.respondent_id JOIN purchase_willingness pw ON r.respondent_id=pw.respondent_id""").fetchone()
data['summary'] = {'total': row[0], 'female_pct': row[1], 'bachelor_pct': row[2], 'attitude_avg': row[3], 'intention_avg': row[4], 'willing_pct': row[5], 'purchased_pct': row[6]}

with open('E:/workbuddy/2026-07-14-11-06-39/portfolio/data/dashboard_data.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

conn.close()
print('Dashboard data exported!')
