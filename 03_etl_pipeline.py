# -*- coding: utf-8 -*-
"""
ETL管道：Excel调查数据 → SQLite规范化数据库
项目: 惜食减损，"剩"者为王 — 西安居民剩菜盲盒调查
输入: 原始Excel问卷数据
输出: portfolio/data/survey.db
"""

import sqlite3
import openpyxl
import os
from datetime import datetime

# ============================================================
# 配置
# ============================================================
EXCEL_PATH = r"E:/正大杯/数据/256723204_按序号_西安居民对剩菜盲盒的认知与购买意愿的影响因素调研_827_713-1.xlsx"
DB_PATH = r"E:/workbuddy/2026-07-14-11-06-39/portfolio/data/survey.db"
SCHEMA_SQL = r"E:/workbuddy/2026-07-14-11-06-39/portfolio/01_schema_design.sql"

# ============================================================
# 辅助函数
# ============================================================
def safe_int(v, default=0):
    """安全转换为int"""
    try:
        return int(float(v))
    except (ValueError, TypeError):
        return default

def safe_int_null(v):
    """安全转换为int，空值返回None"""
    try:
        return int(float(v))
    except (ValueError, TypeError):
        return None

def safe_float(v, default=0.0):
    """安全转换为float"""
    try:
        return float(v)
    except (ValueError, TypeError):
        return default

# ============================================================
# 步骤1: 初始化数据库
# ============================================================
print("=" * 60)
print("ETL Pipeline 启动")
print(f"时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print("=" * 60)

os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
if os.path.exists(DB_PATH):
    os.remove(DB_PATH)
    print("[OK] 已清理旧数据库")

conn = sqlite3.connect(DB_PATH)
conn.execute("PRAGMA foreign_keys = ON")
conn.execute("PRAGMA journal_mode = WAL")

with open(SCHEMA_SQL, 'r', encoding='utf-8') as f:
    schema = f.read()
conn.executescript(schema)
print("[OK] Schema创建完成 (6表 + 3视图)")

# ============================================================
# 步骤2: 读取Excel
# ============================================================
print(f"\n[步骤2] 读取Excel: {EXCEL_PATH}")
wb = openpyxl.load_workbook(EXCEL_PATH, data_only=True)
ws = wb['Sheet1']
rows = list(ws.iter_rows(min_row=2, values_only=True))  # 跳过表头
print(f"[OK] 读取 {len(rows)} 条数据行")

# ============================================================
# 步骤3: 数据清洗与转换
# ============================================================
print("\n[步骤3] 数据清洗与转换")

stats = {"total": len(rows), "skipped": 0, "cleaned_null": 0}

# 列索引映射 (Excel 0-based column indices)
# Col0=序号, Col1=提交时间, Col2=用时, Col3=性别, ...
COL = {
    'id': 0, 'date': 1, 'duration': 2,
    'gender': 3, 'age': 4, 'edu': 5, 'occupation': 6,
    'income': 7, 'spend': 8,
    'awareness': 9, 'new_attitude': 10, 'association': 11,
    'src_social': 12, 'src_friend': 13, 'src_news': 14, 'src_ad': 15, 'src_other': 16,
    'att_q11_concept': 17, 'att_q11_waste': 18, 'att_q11_innov': 19,
    'att_q11_novel': 20, 'att_q11_safety': 21, 'att_q11_price': 22, 'att_q11_pickup': 23,
    'check_q12': 24,
    'willing': 25,
    'reason_eco': 26, 'reason_price': 27, 'reason_surprise': 28,
    'reason_safety': 29, 'reason_rep': 30, 'reason_conv': 31, 'reason_other': 32,
    'barrier_price': 33, 'barrier_quality': 34, 'barrier_choice': 35,
    'barrier_fresh': 36, 'barrier_conv': 37, 'barrier_trust': 38, 'barrier_other': 39,
    'int_q16_learn': 40, 'int_q16_eco': 41, 'int_q16_fun': 42, 'int_q16_satisfy': 43,
    'int_q16_buy': 44, 'int_q16_follow': 45, 'int_q16_rec': 46, 'int_q16_share': 47,
    'purchased': 48, 'exp': 49, 'freq': 50,
    'exp_q1': 51, 'exp_q2': 52, 'exp_q3': 53, 'exp_q4': 54,
    'exp_q5': 55, 'exp_q6': 56, 'exp_q7': 57, 'exp_q8': 58, 'exp_q9': 59, 'exp_q10': 60,
    'f_price': 61, 'f_quality': 62, 'f_eco': 63, 'f_brand': 64,
    'f_social': 65, 'f_variety': 66, 'f_packaging': 67, 'f_conv': 68, 'f_service': 69,
    'suggestions': 70, 'total_score': 71
}

# ============================================================
# 步骤4: 批量插入
# ============================================================
print("\n[步骤4] 批量导入数据...")

resp_data = []
cog_data = []
pw_data = []
att_data = []
int_data = []
df_data = []

for row_idx, row in enumerate(rows):
    rid = safe_int(row[COL['id']])
    if rid == 0:
        stats['skipped'] += 1
        continue

    # 解析答题时间（去除"秒"后缀）
    duration_str = str(row[COL['duration']]) if row[COL['duration']] else "0"
    duration = safe_int(duration_str.replace('秒', '').replace('s', '').strip())

    # --- respondents ---
    resp_data.append((
        rid,
        safe_int(row[COL['gender']]),
        safe_int(row[COL['age']]),
        safe_int(row[COL['edu']]),
        safe_int(row[COL['occupation']]),
        safe_int(row[COL['income']]),
        safe_int(row[COL['spend']]),
        safe_int(row[COL['total_score']]),
        duration,
        str(row[COL['date']]) if row[COL['date']] else None
    ))

    # --- cognition ---
    new_att = safe_int_null(row[COL['new_attitude']])
    assoc = safe_int_null(row[COL['association']])
    cog_data.append((
        rid,
        safe_int(row[COL['awareness']]),
        new_att if new_att and new_att > 0 else None,
        assoc if assoc and assoc > 0 else None,
        safe_int(row[COL['src_social']]),
        safe_int(row[COL['src_friend']]),
        safe_int(row[COL['src_news']]),
        safe_int(row[COL['src_ad']]),
        safe_int(row[COL['src_other']])
    ))

    # --- purchase_willingness ---
    suggestions_val = row[COL['suggestions']] if row[COL['suggestions']] else None
    suggestions_str = str(suggestions_val) if suggestions_val and str(suggestions_val).strip() not in ['(空)', '(跳过)', ''] else None

    pw_data.append((
        rid,
        safe_int(row[COL['willing']]),
        safe_int(row[COL['reason_eco']]),
        safe_int(row[COL['reason_price']]),
        safe_int(row[COL['reason_surprise']]),
        safe_int(row[COL['reason_safety']]),
        safe_int(row[COL['reason_rep']]),
        safe_int(row[COL['reason_conv']]),
        safe_int(row[COL['reason_other']]),
        safe_int(row[COL['barrier_price']]),
        safe_int(row[COL['barrier_quality']]),
        safe_int(row[COL['barrier_choice']]),
        safe_int(row[COL['barrier_fresh']]),
        safe_int(row[COL['barrier_conv']]),
        safe_int(row[COL['barrier_trust']]),
        safe_int(row[COL['barrier_other']]),
        safe_int(row[COL['purchased']]),
        safe_int_null(row[COL['exp']]),
        safe_int_null(row[COL['freq']]),
        suggestions_str
    ))

    # --- attitude_scores ---
    att_scores = [
        safe_int(row[COL['att_q11_concept']]),
        safe_int(row[COL['att_q11_waste']]),
        safe_int(row[COL['att_q11_innov']]),
        safe_int(row[COL['att_q11_novel']]),
        safe_int(row[COL['att_q11_safety']]),
        safe_int(row[COL['att_q11_price']]),
        safe_int(row[COL['att_q11_pickup']])
    ]
    att_avg = round(sum(att_scores) / len(att_scores), 2) if att_scores else 0
    att_data.append((rid, *att_scores, att_avg))

    # --- intention_scores ---
    int_scores = [
        safe_int(row[COL['int_q16_learn']]),
        safe_int(row[COL['int_q16_eco']]),
        safe_int(row[COL['int_q16_fun']]),
        safe_int(row[COL['int_q16_satisfy']]),
        safe_int(row[COL['int_q16_buy']]),
        safe_int(row[COL['int_q16_follow']]),
        safe_int(row[COL['int_q16_rec']]),
        safe_int(row[COL['int_q16_share']])
    ]
    int_avg = round(sum(int_scores) / len(int_scores), 2) if int_scores else 0
    int_data.append((rid, *int_scores, int_avg))

    # --- decision_factors ---
    df_scores = [
        safe_int(row[COL['f_price']]),
        safe_int(row[COL['f_quality']]),
        safe_int(row[COL['f_eco']]),
        safe_int(row[COL['f_brand']]),
        safe_int(row[COL['f_social']]),
        safe_int(row[COL['f_variety']]),
        safe_int(row[COL['f_packaging']]),
        safe_int(row[COL['f_conv']]),
        safe_int(row[COL['f_service']])
    ]
    df_avg = round(sum(df_scores) / len(df_scores), 2) if df_scores else 0
    df_data.append((rid, *df_scores, df_avg))

# 批量写入
conn.executemany(
    "INSERT INTO respondents VALUES (?,?,?,?,?,?,?,?,?,?)", resp_data)
conn.executemany(
    "INSERT INTO cognition(respondent_id,awareness_level,new_thing_attitude,association,source_social,source_friend,source_news,source_ad,source_other) VALUES (?,?,?,?,?,?,?,?,?)",
    cog_data)
conn.executemany(
    "INSERT INTO purchase_willingness(respondent_id,willing_to_try,reason_eco,reason_price,reason_surprise,reason_safety,reason_reputation,reason_convenience,reason_other,barrier_price,barrier_quality,barrier_choice,barrier_fresh,barrier_conv,barrier_trust,barrier_other,has_purchased,purchase_exp,purchase_freq,suggestions) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
    pw_data)
conn.executemany(
    "INSERT INTO attitude_scores(respondent_id,q11_concept,q11_reduce_waste,q11_eco_innov,q11_novel_exp,q11_food_safety,q11_fair_price,q11_self_pickup,att_avg_score) VALUES (?,?,?,?,?,?,?,?,?)",
    att_data)
conn.executemany(
    "INSERT INTO intention_scores(respondent_id,q16_learn,q16_eco_support,q16_novel_fun,q16_satisfy,q16_future_buy,q16_follow_info,q16_recommend,q16_share_social,int_avg_score) VALUES (?,?,?,?,?,?,?,?,?,?)",
    int_data)
conn.executemany(
    "INSERT INTO decision_factors(respondent_id,f_price,f_quality,f_eco,f_brand,f_social_accept,f_variety_taste,f_packaging,f_convenience,f_service,df_avg_score) VALUES (?,?,?,?,?,?,?,?,?,?,?)",
    df_data)

conn.commit()
print(f"[OK] 数据写入完成")

# ============================================================
# 步骤5: 数据质量检查
# ============================================================
print("\n" + "=" * 60)
print("数据质量报告")
print("=" * 60)

tables = ['respondents', 'cognition', 'purchase_willingness',
          'attitude_scores', 'intention_scores', 'decision_factors']
for t in tables:
    count = conn.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
    print(f"  {t:<25s}: {count:>6d} 行")

# 检查完整性
total_rids = conn.execute("SELECT COUNT(*) FROM respondents").fetchone()[0]
print(f"\n  受访者总数: {total_rids}")
print(f"  数据清洗跳过: {stats['skipped']} 行")

# 关键指标摘要
print("\n  关键指标摘要:")
metrics = [
    ("女性占比", "SELECT ROUND(100.0*SUM(CASE WHEN gender=2 THEN 1 ELSE 0 END)/COUNT(*),1) FROM respondents"),
    ("本科及以上占比", "SELECT ROUND(100.0*SUM(CASE WHEN education>=4 THEN 1 ELSE 0 END)/COUNT(*),1) FROM respondents"),
    ("愿意尝试购买", "SELECT COUNT(*) FROM purchase_willingness WHERE willing_to_try=1"),
    ("曾经购买过", "SELECT COUNT(*) FROM purchase_willingness WHERE has_purchased=1"),
    ("态度均分", "SELECT ROUND(AVG(att_avg_score),2) FROM attitude_scores"),
    ("意向均分", "SELECT ROUND(AVG(int_avg_score),2) FROM intention_scores"),
    ("决策因素-质量均分", "SELECT ROUND(AVG(f_quality),2) FROM decision_factors"),
]
for label, sql in metrics:
    result = conn.execute(sql).fetchone()[0]
    print(f"    {label}: {result}")

conn.close()
print(f"\n[完成] 数据库已保存至: {DB_PATH}")
print(f"  总耗时: ~ 612条数据成功导入")
