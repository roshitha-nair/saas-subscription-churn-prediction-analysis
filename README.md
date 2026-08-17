# SaaS / Subscription Churn Prediction & Analysis

## Business Problem

Subscription businesses depend on recurring revenue and customer retention. When customers churn, the business loses future recurring revenue and may need to spend additional resources on customer acquisition and retention.

This project analyzes customer subscription behavior to identify customers who are at risk of churning and quantify the recurring revenue potentially at risk.

The analysis is designed from a business-facing Data Analyst perspective, with an emphasis on clear reasoning, interpretable modeling, and actionable business recommendations.

---

## Business Objective

The primary objective is to:

> Identify customers at risk of churn and quantify the recurring revenue potentially at risk so that the business can prioritize retention efforts.

The project will combine SQL, Python/Pandas, interpretable predictive modeling, and Power BI to move from raw customer data to a business-focused retention analysis.

---

## Business Questions

The analysis will answer the following questions:

1. What proportion of customers have churned?
2. Which customer and subscription characteristics are associated with churn?
3. Which customer segments show higher churn risk?
4. Which customers represent the greatest potential revenue risk?
5. How much recurring revenue is associated with customers at risk of churn?
6. How can the business prioritize customers for retention efforts?

---

## Analytical Approach

The project follows a full-stack analytics workflow:

```text
Raw Customer / Subscription Data
            ↓
           SQL
  Extraction & Aggregation
            ↓
       Python / Pandas
  Cleaning & Feature Engineering
            ↓
    Logistic Regression
     Churn Risk Prediction
            ↓
        Power BI
 At-Risk Revenue & Segmentation
            ↓
      Business Case
 Recommendations for Retention
```

### 1. SQL Layer

SQL will be used to simulate a warehouse-style extraction and aggregation layer involving customer, subscription, and relevant usage or service information.

The goal is to create a feature-ready analytical dataset before the Python stage.

### 2. Python / Pandas Layer

Python and Pandas will be used for:

* Data cleaning
* Missing-value handling
* Data type standardization
* Exploratory analysis
* Simple, explainable feature engineering

Features will be deliberately limited to those with clear business interpretations.

### 3. Predictive Modeling

A Logistic Regression model will be used to estimate customer churn risk.

The model is intentionally simple and interpretable. The project prioritizes business understanding and coefficient interpretation over model complexity.

### 4. Power BI Layer

Power BI will be used to build a business-facing dashboard showing:

* Customer churn
* Customer risk segments
* At-risk customers
* At-risk recurring revenue
* Relevant customer/subscription segments

### 5. Business Case

The final output will include a one-page business case written for non-technical stakeholders, translating the analysis into retention priorities and business recommendations.

---

## Technology Stack

| Layer                     | Tools          |
| ------------------------- | -------------- |
| Data extraction           | SQL            |
| Data cleaning & analysis  | Python, Pandas |
| Predictive modeling       | Scikit-learn   |
| Visualization & BI        | Power BI       |
| Version control           | Git, GitHub    |
| Documentation             | Markdown       |

---

## Dataset

**Dataset:** Telco / SaaS Customer Churn Dataset

**Source:** To be added after dataset selection and validation.

**Raw file:** To be added to `data/raw/`

The raw dataset will be preserved separately from the cleaned analytical data.

---

## Data Dictionary

The final data dictionary will be completed after inspecting the actual dataset. No column definitions will be assumed before the raw data is validated.

| Column | Description | Data Type | Business Meaning |
| ------ | ----------- | --------- | ----------------- |
| TBD    | TBD         | TBD       | TBD                |

---

## Key Findings

*To be completed after exploratory analysis and modeling.*

---

## Business Recommendations

*To be completed after the analytical findings are validated.*

---

## Project Structure

```text
saas-subscription-churn-prediction-analysis/
│
├── data/
│   └── raw/
│
├── sql/
│
├── notebooks/
│
├── powerbi/
│
├── business_case/
│
└── README.md
```

---

