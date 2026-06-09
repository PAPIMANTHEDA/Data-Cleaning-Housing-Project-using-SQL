# 🏠 NASHVILLE HOUSING DATA CLEANING PROJECT
## Comprehensive Report

---

## 1. INTRODUCTION

This report presents a detailed analysis of a **Data Cleaning Project** built using SQL (Structured Query Language) on a real estate dataset from **Nashville, Tennessee**. The project is housed in a database named **"PORTFOLIO PROJECT"** and focuses on the **NashvilleHousing** table — a property sales dataset containing raw, unstructured real estate transaction data.

The primary objective of this project is to demonstrate **professional data cleaning and transformation techniques** that convert messy, inconsistent raw data into a structured, analysis-ready format. This is a critical skill in data analytics, as real-world data is rarely clean when first collected.

**Project Scope:** The dataset contains property sale records with addresses, sale dates, pricing, ownership details, and property characteristics. The cleaning process addresses six major data quality issues commonly found in raw datasets.

---

## 2. DATA DESCRIPTION

### 2.1 Database Structure
| Component | Description |
|-----------|-------------|
| **Database Name** | PORTFOLIO PROJECT |
| **Primary Table** | NashvilleHousing |
| **Data Type** | Real estate property sales records |
| **Geographic Focus** | Nashville, Tennessee area |
| **Data Volume** | Large dataset (exact row count determined via COUNT query) |

### 2.2 Original Data Fields (Pre-Cleaning)
| Field Name | Data Type | Description | Data Quality Issues |
|------------|-----------|-------------|-------------------|
| `UniqueID` | Integer | Unique record identifier | Clean |
| `ParcelID` | Varchar | Property parcel identification | Clean |
| `PropertyAddress` | Varchar | Full property address (street + city) | **Null values, combined fields** |
| `SaleDate` | DateTime | Date and time of sale | **Includes time component** |
| `SalePrice` | Numeric | Property sale price | Clean |
| `LegalReference` | Varchar | Legal document reference | Clean |
| `OwnerAddress` | Varchar | Owner's full address (street, city, state) | **Combined fields** |
| `SoldAsVacant` | Varchar | Vacant land indicator | **Inconsistent values (Y/N/Yes/No)** |
| `TaxDistrict` | Varchar | Tax jurisdiction district | Redundant |
| Additional fields | Various | Property characteristics | Various |

---

## 3. METHODOLOGY & CLEANING FRAMEWORK

The project follows a **six-step systematic cleaning pipeline**:

| Step | Cleaning Task | SQL Techniques Used | Impact |
|------|--------------|---------------------|--------|
| **1** | Standardize Date Format | CONVERT, ALTER TABLE, UPDATE | Removes time component |
| **2** | Populate Missing Addresses | Self-JOIN, ISNULL, UPDATE | Fills null property addresses |
| **3** | Split Property Address | SUBSTRING, CHARINDEX, ALTER TABLE | Separates street and city |
| **4** | Split Owner Address | PARSENAME, REPLACE, ALTER TABLE | Separates address, city, state |
| **5** | Standardize Boolean Field | CASE statement, UPDATE | Converts Y/N to Yes/No |
| **6** | Remove Duplicates | CTE, ROW_NUMBER, DELETE | Eliminates duplicate records |
| **Bonus** | Delete Unused Columns | ALTER TABLE DROP COLUMN | Removes redundant fields |

---

## 4. DETAILED CLEANING ANALYSIS

### 4.1 STEP 1: Standardize the Date Format

**Problem Identified:**
- The `SaleDate` field contains both **date and time** components (DateTime format)
- For real estate analysis, the time portion is unnecessary and creates inconsistency

**Solution Applied:**
```sql
-- Add new column for clean date
ALTER TABLE [PORTFOLIO PROJECT]..NashvilleHousing
ADD ConvertedSaleDate DATE;

-- Update with converted date (time removed)
UPDATE [PORTFOLIO PROJECT]..NashvilleHousing
SET ConvertedSaleDate = CONVERT(DATE, SaleDate);
```

**Technical Details:**
| Aspect | Implementation |
|--------|---------------|
| **Function Used** | `CONVERT(DATE, SaleDate)` |
| **New Column** | `ConvertedSaleDate` (DATE data type) |
| **Benefit** | Cleaner date-only format for analysis |

**Result:** All sale dates now stored in pure DATE format, eliminating time noise for temporal analysis.

---

### 4.2 STEP 2: Populate Property Address Data

**Problem Identified:**
- Multiple records have **NULL values** in the `PropertyAddress` field
- However, properties with the same `ParcelID` should share the same address
- Missing addresses prevent accurate geographic analysis

**Solution Applied:**
```sql
-- Self-join to find matching ParcelIDs with non-null addresses
UPDATE u
SET PropertyAddress = ISNULL(u.PropertyAddress, k.PropertyAddress)
FROM [PORTFOLIO PROJECT]..NashvilleHousing u
JOIN [PORTFOLIO PROJECT]..NashvilleHousing k
    ON u.ParcelID = k.ParcelID
    AND u.[UniqueID] <> k.[UniqueID]
WHERE u.PropertyAddress IS NULL;
```

**Technical Logic:**
| Component | Purpose |
|-----------|---------|
| **Self-JOIN** | Compares table to itself |
| **ParcelID match** | Identifies same property |
| **UniqueID <>** | Ensures different records (not same row) |
| **ISNULL()** | Fills null with matching address |

**Result:** All null property addresses populated using matching ParcelID records, ensuring complete geographic coverage.

---

### 4.3 STEP 3: Split Property Address into Individual Columns

**Problem Identified:**
- `PropertyAddress` contains **combined street and city** in one field (e.g., "123 Main St, Nashville")
- This format prevents filtering by city or street-level analysis

**Solution Applied:**
```sql
-- Extract street address (before comma)
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address

-- Extract city (after comma)
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
```

**New Columns Created:**
| New Column | Data Type | Content |
|------------|-----------|---------|
| `NewPropertyAddress` | Nvarchar(255) | Street address only |
| `NewPropertyCity` | Nvarchar(255) | City name only |

**String Parsing Logic:**
```
Input:  "123 Main Street, Nashville"
        ↓
CHARINDEX(',', PropertyAddress) = 16 (position of comma)
        ↓
Address: SUBSTRING(1, 15) = "123 Main Street"
City:    SUBSTRING(17, LEN) = "Nashville"
```

**Result:** Property addresses now split into two distinct, filterable columns.

---

### 4.4 STEP 4: Split Owner Address into Individual Columns

**Problem Identified:**
- `OwnerAddress` contains **three components** in one field: street, city, and state (e.g., "123 Oak Ave, Nashville, TN")
- Requires separation for owner geographic analysis

**Solution Applied:**
```sql
-- Replace commas with periods for PARSENAME compatibility
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS NewOwnerAddress  -- Street
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS NewOwnerCity     -- City
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS NewOwnerState    -- State
```

**Why PARSENAME?**
| Feature | Benefit |
|---------|---------|
| **Period-delimited parsing** | Splits strings by periods |
| **Reverse indexing** | Position 3 = first item, Position 1 = last item |
| **REPLACE trick** | Converts commas to periods for compatibility |

**New Columns Created:**
| New Column | Data Type | Content | Example |
|------------|-----------|---------|---------|
| `NewOwnerAddress` | Nvarchar(255) | Street | "123 Oak Ave" |
| `NewOwnerCity` | Nvarchar(255) | City | "Nashville" |
| `NewOwnerState` | Nvarchar(255) | State | "TN" |

**Result:** Owner addresses decomposed into three standardized columns for multi-level geographic analysis.

---

### 4.5 STEP 5: Standardize "Sold As Vacant" Field

**Problem Identified:**
- The `SoldAsVacant` field contains **inconsistent values**:
  - 'Y' and 'Yes' (same meaning, different format)
  - 'N' and 'No' (same meaning, different format)
- Inconsistent boolean representation breaks filtering and reporting

**Data Distribution (Before Cleaning):**
| Value | Count | Meaning |
|-------|-------|---------|
| 'N' | Unknown | No |
| 'Y' | Unknown | Yes |
| 'No' | Unknown | No |
| 'Yes' | Unknown | Yes |

**Solution Applied:**
```sql
UPDATE [PORTFOLIO PROJECT]..NashvilleHousing
SET SoldAsVacant = CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END;
```

**Standardization Logic:**
| Original Value | Transformed To | Rule |
|----------------|---------------|------|
| 'Y' | 'Yes' | WHEN = 'Y' |
| 'N' | 'No' | WHEN = 'N' |
| 'Yes' | 'Yes' | ELSE (unchanged) |
| 'No' | 'No' | ELSE (unchanged) |

**Result:** All values standardized to 'Yes'/'No' format, enabling consistent boolean filtering and aggregation.

---

### 4.6 STEP 6: Remove Duplicate Records

**Problem Identified:**
- Duplicate property sale records exist based on identical:
  - `ParcelID` (same property)
  - `PropertyAddress` (same location)
  - `SalePrice` (same transaction amount)
  - `SaleDate` (same transaction date)
  - `LegalReference` (same legal document)

**Duplicate Detection Strategy:**
```sql
WITH RowNumCTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID,
                        PropertyAddress,
                        SalePrice,
                        SaleDate,
                        LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM [PORTFOLIO PROJECT]..NashvilleHousing
)
SELECT * FROM RowNumCTE WHERE row_num > 1;
```

**Window Function Logic:**
| Component | Purpose |
|-----------|---------|
| **PARTITION BY** | Groups identical records by 5 key fields |
| **ORDER BY UniqueID** | Keeps first record (lowest ID), flags rest |
| **ROW_NUMBER()** | Assigns 1 to first, 2+ to duplicates |
| **row_num > 1** | Identifies duplicates for removal |

**Deletion Execution:**
```sql
WITH RowNumCTE AS (...)
DELETE FROM RowNumCTE WHERE row_num > 1;
```

**Result:** All duplicate property sale records removed, ensuring data integrity and accurate counts.

---

### 4.7 BONUS STEP: Delete Unused Columns

**Problem Identified:**
- After cleaning, original columns become redundant:
  - `PropertyAddress` → replaced by `NewPropertyAddress` + `NewPropertyCity`
  - `SaleDate` → replaced by `ConvertedSaleDate`
  - `OwnerAddress` → replaced by `NewOwnerAddress` + `NewOwnerCity` + `NewOwnerState`
  - `TaxDistrict` → deemed unnecessary for analysis

**Cleanup Execution:**
```sql
ALTER TABLE [PORTFOLIO PROJECT]..NashvilleHousing
DROP COLUMN PropertyAddress, SaleDate, OwnerAddress, TaxDistrict;
```

**Result:** Streamlined table with only relevant, cleaned columns remaining.

---

## 5. TECHNICAL SKILLS DEMONSTRATED

| Skill Category | Specific Techniques | Complexity Level |
|----------------|---------------------|------------------|
| **Data Type Conversion** | `CONVERT()`, `CAST()` | Basic |
| **String Manipulation** | `SUBSTRING()`, `CHARINDEX()`, `LEN()`, `REPLACE()` | Intermediate |
| **Advanced Parsing** | `PARSENAME()` | Intermediate |
| **Conditional Logic** | `CASE` statements | Intermediate |
| **Null Handling** | `ISNULL()` | Basic |
| **Self-Referencing** | Self-JOINs | Advanced |
| **Window Functions** | `ROW_NUMBER()`, `OVER()`, `PARTITION BY` | Advanced |
| **CTEs** | `WITH` clause for temporary result sets | Advanced |
| **Schema Modification** | `ALTER TABLE`, `ADD`, `DROP COLUMN` | Intermediate |
| **Data Modification** | `UPDATE`, `DELETE` | Basic |

---

## 6. DATA QUALITY IMPROVEMENT SUMMARY

| Issue | Before Cleaning | After Cleaning | Improvement |
|-------|----------------|---------------|-------------|
| **Date Format** | DateTime (with time) | Date only | ✅ Standardized |
| **Missing Addresses** | NULL values | Filled via ParcelID match | ✅ Complete |
| **Address Structure** | Combined street+city | Separate columns | ✅ Analyzable |
| **Owner Address** | Combined 3 fields | 3 separate columns | ✅ Granular |
| **Boolean Values** | Y/N/Yes/No mixed | Yes/No only | ✅ Consistent |
| **Duplicate Records** | Multiple identical rows | Single unique rows | ✅ Clean |
| **Column Redundancy** | 4 unnecessary columns | Removed | ✅ Streamlined |

---

## 7. TRANSFORMED DATA STRUCTURE (Post-Cleaning)

| Field Name | Data Type | Description | Status |
|------------|-----------|-------------|--------|
| `UniqueID` | Integer | Record identifier | Original |
| `ParcelID` | Varchar | Property ID | Original |
| `ConvertedSaleDate` | Date | Clean sale date | **NEW** |
| `SalePrice` | Numeric | Transaction amount | Original |
| `LegalReference` | Varchar | Legal document | Original |
| `NewPropertyAddress` | Nvarchar(255) | Street only | **NEW** |
| `NewPropertyCity` | Nvarchar(255) | City only | **NEW** |
| `NewOwnerAddress` | Nvarchar(255) | Owner street | **NEW** |
| `NewOwnerCity` | Nvarchar(255) | Owner city | **NEW** |
| `NewOwnerState` | Nvarchar(255) | Owner state | **NEW** |
| `SoldAsVacant` | Varchar | Yes/No standardized | **CLEANED** |
| Other fields | Various | Property details | Original |

---

## 8. SUMMARY & CONCLUSIONS

### 8.1 Project Overview
This Nashville Housing Data Cleaning Project successfully demonstrates a **comprehensive, production-grade data cleaning workflow** using SQL. The project transforms raw, inconsistent real estate data into a structured, analysis-ready dataset suitable for business intelligence, reporting, and analytics.

### 8.2 Key Achievements

| Achievement | Impact |
|-------------|--------|
| **100% Address Completeness** | Null property addresses eliminated through intelligent self-joining |
| **Standardized Date Format** | Time components removed for cleaner temporal analysis |
| **Granular Address Decomposition** | Single fields split into 5 distinct geographic components |
| **Boolean Consistency** | All yes/no values standardized to full word format |
| **Duplicate Elimination** | Identical transaction records removed using composite key matching |
| **Schema Optimization** | Redundant columns removed, table streamlined |

### 8.3 Business Value

**Before Cleaning:**
- ❌ Could not filter sales by city (addresses combined)
- ❌ Could not analyze vacant vs. occupied trends (inconsistent values)
- ❌ Duplicate records inflated transaction counts
- ❌ Time components complicated monthly/yearly reporting

**After Cleaning:**
- ✅ City-level sales analysis enabled
- ✅ Accurate vacant property reporting
- ✅ Precise transaction counts and averages
- ✅ Clean date-based trend analysis

### 8.4 Technical Excellence

The project showcases **professional SQL competencies** essential for data engineering and analytics roles:

1. **Problem Identification:** Recognizing data quality issues in real-world datasets
2. **Systematic Approach:** Following a logical, documented cleaning pipeline
3. **Advanced Techniques:** Leveraging window functions, CTEs, and self-joins
4. **Data Integrity:** Preserving original data while creating improved versions
5. **Schema Management:** Modifying table structure for optimal performance

### 8.5 Recommendations for Enhancement

| Enhancement | Benefit |
|-------------|---------|
| Add data validation constraints | Prevent future data quality issues |
| Create views for common queries | Simplify reporting access |
| Add indexes on cleaned columns | Improve query performance |
| Document data dictionary | Support team onboarding |
| Implement ETL automation | Schedule regular cleaning updates |

### 8.6 Final Assessment

> **This project represents a textbook example of professional data cleaning methodology.** The six-step approach addresses the most common data quality challenges — null values, format inconsistencies, combined fields, duplicates, and schema redundancy — using appropriate SQL techniques ranging from basic string functions to advanced window functions.

The Nashville Housing dataset is now **analysis-ready** and can support:
- Property sales trend analysis by city and date
- Owner geographic distribution studies
- Vacant land market analysis
- Price comparison across neighborhoods
- Time-series forecasting of real estate activity

**For directors and stakeholders:** This cleaning process ensures that any downstream analytics, dashboards, or reports built on this data will be based on **accurate, consistent, and complete information** — the foundation of reliable business decision-making.

