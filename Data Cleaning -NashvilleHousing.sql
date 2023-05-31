
/*

Cleaning Data in SQL Queries

*/

-- Moving the tables from the dbo schema to my portfolio schema
Alter schema portfolio transfer dbo.NashvilleHousing;


/* DATA CLEANING */

Select *
From portfolio.NashvilleHousing

-- 1) Changing the format of SaleDate from datetime to date

ALTER TABLE portfolio.NashvilleHousing
ALTER COLUMN SaleDate date;


-- 2) Populating the NULL values in PropertyAddress

Select *
From portfolio.NashvilleHousing
Where PropertyAddress IS NULL

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From portfolio.NashvilleHousing a
JOIN portfolio.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null


Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From portfolio.NashvilleHousing a
JOIN portfolio.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null


-- 3) Breaking out Address into Individual Columns (Address, City, State)

--Property Address

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as Address
From portfolio.NashvilleHousing

ALTER TABLE portfolio.NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

ALTER TABLE portfolio.NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update portfolio.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

Update portfolio.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))


-- Owner Address

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3) Address
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2) City
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1) State
From portfolio.NashvilleHousing

ALTER TABLE portfolio.NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

ALTER TABLE portfolio.NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

ALTER TABLE portfolio.NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update portfolio.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)

Update portfolio.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)

Update portfolio.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)


-- 4) Change Y and N to Yes and No in "Sold as Vacant" field

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From portfolio.NashvilleHousing
Group by SoldAsVacant
order by 2

Select SoldAsVacant,
CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END AS S
From portfolio.NashvilleHousing

Update portfolio.NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END


-- 5) Removing Duplicates

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID) row_num
From portfolio.NashvilleHousing
)
Delete
From RowNumCTE
Where row_num > 1


-- 6) Delete Unused Columns

ALTER TABLE portfolio.NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress


