--CLEANING DATA IN SQL

--select * 
--from [PORTFOLIO PROJECT]..NashvilleHousing
--where PropertyAddress is null;

--Select top 1000 *
--from [PORTFOLIO PROJECT].. NashvilleHousing;

---------------------------------------------------------------------------------------------

--1. STANDARDIZE THE DATE FORMAT

--Select COUNT(*) as TotalRows
--from [PORTFOLIO PROJECT].. NashvilleHousing;

--Select SaleDate,
--CONVERT(Date, SaleDate) as ConvertedSaleDate
--from [PORTFOLIO PROJECT].. NashvilleHousing;

--Alter Table [PORTFOLIO PROJECT].. NashvilleHousing
--Add ConvertedSaleDate Date;

--update [PORTFOLIO PROJECT].. NashvilleHousing
--set ConvertedSaleDate = CONVERT(Date, SaleDate);

------------------------------------------------------------------------------------------------

--2. POPULATE PROPERTY ADDRESS DATA

--Select *
--from [PORTFOLIO PROJECT].. NashvilleHousing
--Where PropertyAddress is not null
--Order by ParcelID;

--Select *
----from [PORTFOLIO PROJECT].. NashvilleHousing u
----join [PORTFOLIO PROJECT].. NashvilleHousing k
----	on u.ParcelID = k.ParcelID
----	and u.[UniqueID ] <> k.[UniqueID ]
----	where u.PropertyAddress is null;

--Select u.ParcelID,u.PropertyAddress,k.ParcelID,k.PropertyAddress
--from [PORTFOLIO PROJECT].. NashvilleHousing u
--join [PORTFOLIO PROJECT].. NashvilleHousing k
--	on u.ParcelID = k.ParcelID
--	and u.[UniqueID ] <> k.[UniqueID ]
--	where u.PropertyAddress is null;


--Update u
--Set PropertyAddress = ISNULL (u.PropertyAddress, k.PropertyAddress)
--from [PORTFOLIO PROJECT].. NashvilleHousing u
--join [PORTFOLIO PROJECT].. NashvilleHousing k
--	on u.ParcelID = k.ParcelID
--	and u.[UniqueID ] <> k.[UniqueID ]
--	where u.PropertyAddress is null;

-------------------------------------------------------------------------------------------------

--3. SPLIT PROPERTY ADDRESS INTO COLUMNS
--Select 
--SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) -1) As Address,
--SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress)) As City
--from [PORTFOLIO PROJECT].. NashvilleHousing


--Alter Table [PORTFOLIO PROJECT].. NashvilleHousing
--Add NewPropertyAddress Nvarchar(255);

--update [PORTFOLIO PROJECT].. NashvilleHousing
--set NewPropertyAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) -1);

--Alter Table [PORTFOLIO PROJECT].. NashvilleHousing
--Add NewPropertyCity Nvarchar(255);

--update [PORTFOLIO PROJECT].. NashvilleHousing
--set NewPropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress));

----------------------------------------------------------------------------------------------------

--4. SPLIT OWNERS ADDRESS INTO INDIVIDUAL COLUMNS (ADDRESS, CITY, STATE)

--Select 
--PARSENAME(Replace(OwnerAddress, ',', '.'), 3) as NewOwnerAddress,
--PARSENAME(Replace(OwnerAddress, ',', '.'), 2) as NewOwnerCity,
--PARSENAME(Replace(OwnerAddress, ',', '.'), 1) as NewOwnerState
--from [PORTFOLIO PROJECT].. NashvilleHousing
--where OwnerAddress is not null;


--Alter Table [PORTFOLIO PROJECT].. NashvilleHousing
--Add NewOwnerAddress Nvarchar(255);

--update [PORTFOLIO PROJECT].. NashvilleHousing
--set NewOwnerAddress = PARSENAME(Replace(OwnerAddress, ',', '.'), 3);


--Alter Table [PORTFOLIO PROJECT].. NashvilleHousing
--Add NewOwnerCity Nvarchar(255);

--update [PORTFOLIO PROJECT].. NashvilleHousing
--set NewOwnerCity = PARSENAME(Replace(OwnerAddress, ',', '.'), 2);


--Alter Table [PORTFOLIO PROJECT].. NashvilleHousing
--Add NewOwnerState Nvarchar(255);

--update [PORTFOLIO PROJECT].. NashvilleHousing
--set NewOwnerState = PARSENAME(Replace(OwnerAddress, ',', '.'), 1);


--CHANGE Y&N TO YES OR NO IN THE "SOLD AS VACANT" FIELD

--Select distinct(SoldAsVacant), COUNT(SoldAsVacant) as SoldVacant
--from [PORTFOLIO PROJECT].. NashvilleHousing
--group by SoldAsVacant
--order by 2;

--Select SoldAsVacant,
--CASE 
--	when SoldAsVacant = 'Y' then 'Yes'
--	when SoldAsVacant = 'N' then 'No'
--	else SoldAsVacant
--	end
--from [PORTFOLIO PROJECT].. NashvilleHousing

--Update [PORTFOLIO PROJECT].. NashvilleHousing
--set SoldAsVacant = CASE 
--	when SoldAsVacant = 'Y' then 'Yes'
--	when SoldAsVacant = 'N' then 'No'
--	else SoldAsVacant
--	end

----------------------------------------------------------------------------------------------

--5. REMOVE DUPLICATES

--Select *,
--	ROW_NUMBER() OVEr (
--	PARTITION by ParcelID,
--				PropertyAddress,
--				SalePrice,
--				SaleDate,
--				LegalReference
--				Order by 
--					UniqueID
--					) row_num
--from [PORTFOLIO PROJECT].. NashvilleHousing


--With RowNumCTE as (
--Select *,
--	ROW_NUMBER() OVEr (
--	PARTITION by ParcelID,
--				PropertyAddress,
--				SalePrice,
--				SaleDate,
--				LegalReference
--				Order by 
--					UniqueID
--					) row_num
--from [PORTFOLIO PROJECT].. NashvilleHousing
--)
--Select * 
--from RowNumCTE
--Where row_num > 1
--Order by PropertyAddress;



--With RowNumCTE as (
--Select *,
--	ROW_NUMBER() OVEr (
--	PARTITION by ParcelID,
--				PropertyAddress,
--				SalePrice,
--				SaleDate,
--				LegalReference
--				Order by 
--					UniqueID
--					) row_num
--from [PORTFOLIO PROJECT].. NashvilleHousing
--)
--Delete
--from RowNumCTE
--Where row_num > 1
----Order by PropertyAddress;

-------------------------------------------------------------------------------------------------

--6. DELETE UNUSED COLUMNS

--Select *
--from [PORTFOLIO PROJECT].. NashvilleHousing
--Where NewPropertyAddress is not null;

--Alter Table [PORTFOLIO PROJECT].. NashvilleHousing
--Drop Column PropertyAddress, SaleDate, OwnerAddress, TaxDistrict
