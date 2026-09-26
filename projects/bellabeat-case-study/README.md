# Bellabeat Case Study: Sleep & Activity Analysis

📊 [View the full presentation deck](./Bellabeat-presentation-pdf.pdf)

A marketing analytics case study for Bellabeat, a wellness technology company, analyzing FitBit fitness tracker data to uncover the relationship between sleep and physical activity.

## Introduction

Bellabeat is a high-tech wellness company that manufactures health-focused smart products for women, founded by Urška Sršen and Sando Mur in 2013. The marketing analytics team was asked to analyze smart device usage data (FitBit Fitness Tracker Data) to uncover trends applicable to Bellabeat's product line, with the goal of informing marketing strategy. This analysis focused specifically on the relationship between sleep duration and physical activity, to evaluate whether a sleep/recovery-focused marketing angle would be data-supported.

## Data Source

FitBit Fitness Tracker Data (Kaggle, CC0: Public Domain, made available through Mobius) — personal fitness tracker data from 30 consenting Fitbit users. Files used: `dailyActivity_merged`, `sleepDay_merged`.

**Limitations:** small sample (34 unique users), self-selected sample, data collected in 2016, inconsistent daily logging by users.

## Problems

The core question: does a user's sleep duration relate to their physical activity levels, in a way that could inform Bellabeat's marketing strategy? Initial day-to-day analysis (correlating sleep duration with next-day step count) showed a weak relationship (CORREL ≈ -0.14), suggesting no strong short-term predictive effect.

## Solutions

Segmenting users by overall activity level (using CDC-style step thresholds: Sedentary, Low Active, Somewhat Active, Active) revealed a clearer pattern that the day-to-day correlation missed: users in the "Active" segment averaged notably less sleep (~4.7 hours) than users in every other segment (6.3–7.3 hours). This indicates the sleep-activity relationship is more visible as a stable, person-level trait than as a short-term daily effect.

## Conclusion

While no meaningful day-to-day correlation exists between sleep and next-day activity, highly active users consistently sleep less than their less-active counterparts when compared as groups. This is a real, if modest-sample, pattern worth acting on.

## Recommendations

1. Introduce targeted sleep-recovery content or reminders for Bellabeat's most active users specifically, rather than generic sleep messaging for all users.
2. Position relevant Bellabeat products (e.g. the Time watch or Leaf tracker's sleep tracking features) as tools for balancing high activity with adequate recovery.
3. Validate this finding with a larger sample and Bellabeat's own first-party device data before committing significant marketing budget to this angle.

## Tools Used

Google Sheets — pivot tables, charts, INDEX/MATCH, IFS segmentation, CORREL()
