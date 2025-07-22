<#
=== Pediatric Dosage Calculator for Liquid Medications ===

Version 2025.07.21
Author: Echo-Mirage

Description:
Calculates weight-based doses in mL for common over-the-counter liquid oral medications (Acetaminophen, Ibuprofen, and Diphenhydramine).
Supports custom medication entry for on-the-fly calculation
Can also generate a dosing table for a custom medication entry (weight-based in 0.5kg increments)
Optionally export calculations to a text file for later reference

Notes:
Requires PowerShell 5.1

Disclaimer: 
For personal use only, not to be used in a clinical setting.
None of this is to be construed as medical advice.
No guarantee is made as to the accuracy of the calculations. You need to check them yourself.

The calculation is done by first entering the mg/kg dose 
  Example: 10kg weight at 15mg/kg -> 10x15 = 150mg desired dose) 
Then using the concentration to determine the amount in mL needed to deliver the desired dose 
  Example: Acetaminophen 160mg/5mL = 32mg/mL, so the desired dose of 150mg / 32mg = 4.69mL to deliver 150mg dose)

#>



# Medication Presets
$script:medications = @(
    @{ Name = "Acetaminophen 160mg/5mL    (Dose 15mg/kg)"; Mg = 160; Volume = 5; DefaultDosage = 15 },
    @{ Name = "Ibuprofen 100mg/5mL        (Dose 10mg/kg)";     Mg = 100; Volume = 5; DefaultDosage = 10 },
    @{ Name = "Diphenhydramine 12.5mg/5mL (Dose  1mg/kg)"; Mg = 12.5; Volume = 5; DefaultDosage = 1 }
)



# Variables
$script:weightKg = 0
$script:doseHistory = @()
$script:statusMessage = ""
$script:statusColor = "DarkGreen"



# Functions
function ShowTitle {
    Write-Host "`n======================================================" -ForegroundColor DarkGray
    Write-Host "  Pediatric Dosage Calculator for Liquid Medications " -ForegroundColor DarkCyan
    Write-Host "======================================================`n" -ForegroundColor DarkGray
}

function GetNumericInput {
    param ([string]$prompt)
    do {
        $input = Read-Host $prompt
        if (-not ($input -match '^[0-9]+(\.[0-9]+)?$')) {
            $script:statusMessage = "Error: Enter numeric value"
			$script:statusColor = "DarkRed"
			Write-Host $script:statusMessage -ForegroundColor $script:statusColor
            continue
        }

        $number = [double]$input
        if ($number -eq 0) {
            $script:statusMessage = "Error: Number cannot be zero"
			$script:statusColor = "DarkRed"
			Write-Host $script:statusMessage -ForegroundColor $script:statusColor
            continue
        }
        $script:statusMessage = ""
        return $number
    } while ($true)
}

function GetWeightInput {
    param ([string]$prompt)
    do {
        $input = Read-Host $prompt
        if (-not ($input -match '^[0-9]+(\.[0-9]+)?$')) {
            $script:statusMessage = "Error: Enter numeric value"
            $script:statusColor = "DarkRed"
            Write-Host $script:statusMessage -ForegroundColor $script:statusColor
            continue
        }
        $number = [double]$input
        if ($number -eq 0) {
            $script:statusMessage = "Error: Weight cannot be zero"
            $script:statusColor = "DarkRed"
            Write-Host $script:statusMessage -ForegroundColor $script:statusColor
            continue
        }
        if ($number -lt 5) {
            $script:statusMessage = "Caution: Weight is lower than expected range (5 kg - 99 kg)"
            $script:statusColor = "DarkRed"
            Write-Host $script:statusMessage -ForegroundColor $script:statusColor
        }
        if ($number -gt 99) {
            $script:statusMessage = "Caution: Weight is higher than expected range (5 kg - 99 kg)"
            $script:statusColor = "DarkRed"
            Write-Host $script:statusMessage -ForegroundColor $script:statusColor
        }
#        $script:statusMessage = ""
        return $number
    } while ($true)
}

function BuildDoseEntry {
    param (
        [string]$Name,
        [double]$Mg,
        [double]$Ml,
        [double]$DosePerKg,
        [double]$Weight
    )

    $doseMg = $DosePerKg * $Weight
    $volume = ($doseMg * $Ml) / $Mg
    $volumeRounded = [math]::Round($volume, 2)
	$displayString = "$Name >> Weight: ${Weight}kg >> Dose = ${volumeRounded} mL"

    return [PSCustomObject]@{
        Name          = $Name
        MgPerVolume   = "$Mg mg / $Ml mL"
        DosePerKg     = "$DosePerKg mg/kg"
        Weight        = $Weight
        TotalDoseMg   = $doseMg
        VolumeMl      = $volumeRounded
        DisplayString = $displayString
        StatusColor   = "DarkCyan"
    }
}

function IsDuplicateEntry {
    param (
        [object]$entry,
        [array]$history
    )

    $tolerance = 0.01

    foreach ($existing in $history) {
		if (
			$existing.Name -eq $entry.Name -and
			[math]::Abs($existing.Weight - $entry.Weight) -lt $tolerance
		) {
			return $true
		}
    }
    return $false
}

function ShowDoseHistory {
    Write-Host "----- Dose Calculations -------------------------------------------------------" -ForegroundColor DarkGreen
    foreach ($entry in $script:doseHistory) {
        $color = if ($entry.StatusColor) { $entry.StatusColor } else { "White" }
        Write-Host $entry.DisplayString -ForegroundColor $color
    }
    Write-Host "-------------------------------------------------------------------------------" -ForegroundColor DarkGreen
}

function ShowStatus {
	    if ($script:weightKg -gt 0) {
        Write-Host "`nCurrent weight: $($script:weightKg) kg" -ForegroundColor DarkCyan
    }

    if ($script:statusMessage) {
        Write-Host $script:statusMessage -ForegroundColor $script:statusColor
        Write-Host ""
        $script:statusMessage = ""
    }
}


# Display Initial Title Screen
ShowTitle

$script:statusMessage = ""
$script:doseHistory = @()
$script:weightKg = GetWeightInput "Enter weight in kilograms"



# Display Menu and Dose Calculation History
while ($true) {
    Clear-Host
	ShowTitle
	ShowDoseHistory
	ShowStatus

	Write-Host "`nSelect an option:`n" -ForegroundColor DarkGray
    for ($i = 0; $i -lt $script:medications.Count; $i++) {
        Write-Host " $($i+1). $($script:medications[$i].Name)"
		}
    Write-Host " 4. Calculate All Preset Medications 1-3"
    Write-Host " 5. Other Medication (Manual Entry)"
	Write-Host " 6. Dosing Chart: Acetaminophen"
	Write-Host " 7. Dosing Chart: Ibuprofen"
	Write-Host " 8. Dosing Chart: Diphenhydramine"
    Write-Host " 9. Dosing Chart: Other Medication (Manual Entry)"
    Write-Host "10. New Weight in Kilograms"
    Write-Host "11. New Weight in Pounds"
    Write-Host "12. Clear Dose History"
    Write-Host "13. Export Calculations"
    Write-Host "14. Exit"

    $choice = Read-Host "`nEnter choice"
	if ($choice -notmatch '^(1[0-4]|[1-9])$') {
			$script:statusMessage = "Error: Invalid selection"
			$script:statusColor = "DarkRed"
			Write-Host $script:statusMessage -ForegroundColor $script:statusColor
			continue
		}
    $index = [int]$choice

# Menu Logic
    switch ($index) { 
# 1-3. Medication Presets
        { $_ -ge 1 -and $_ -le 3 } {
            $med = $script:medications[$index - 1]
            $entry = BuildDoseEntry -Name $script:med.Name -Mg $script:med.Mg -Ml $script:med.Volume -DosePerKg $script:med.DefaultDosage -Weight $script:weightKg
            if (-not (IsDuplicateEntry -entry $entry -history $script:doseHistory)) {
				$script:statusMessage = ""
                $script:doseHistory += $entry
            } else {
                $script:statusMessage = "Duplicate entries skipped"
                $script:statusColor = "DarkRed"
            }
        }		
# 4. Calculate All Preset Medications 1-3
        4 { 
            foreach ($med in $script:medications) {
                $entry = BuildDoseEntry -Name $med.Name -Mg $med.Mg -Ml $med.Volume -DosePerKg $med.DefaultDosage -Weight $script:weightKg
                if (-not (IsDuplicateEntry -entry $entry -history $script:doseHistory)) {
					$script:statusMessage = ""
                    $script:doseHistory += $entry
                } else {
                    $script:statusMessage = "Duplicate entries skipped"
                    $script:statusColor = "DarkRed"
                }
            }
        }
# 5. Other Medication (Manual Entry)
        5 { 
            $name  = Read-Host "Enter medication name"
            $mg    = GetNumericInput "Enter strength of drug (mg)"
            $ml    = GetNumericInput "Enter liquid volume (mL)"
            $dose  = GetNumericInput "Enter dose (mg/kg)"
            $entry = BuildDoseEntry -Name $name -Mg $mg -Ml $ml -DosePerKg $dose -Weight $script:weightKg
            if (-not (IsDuplicateEntry -entry $entry -history $script:doseHistory)) {
				$script:statusMessage = ""
                $script:doseHistory += $entry
            } else {
                $script:statusMessage = "Duplicate entries skipped"
                $script:statusColor = "DarkRed"
            }
        }
# 6. Dosing Chart: Acetaminophen		
		6 {
			$name = "Acetaminophen"
			$mg = 160
			$ml = 5
			$dose = 15
			$conc = $mg / $ml
			$startWeight = GetNumericInput "Enter first weight to calculate (kg)"
			$endWeight = GetNumericInput "Enter last weight to calculate (kg)"
			$increment = GetNumericInput "Enter weight increment (e.g. 0.5)"

			if ($startWeight -gt $endWeight) {
				$script:statusMessage = "Error: Starting weight ($startWeight kg) cannot be greater than ending weight ($endWeight kg)"
				$script:statusColor = "DarkRed"
			}
			elseif ($increment -le 0) {
				$script:statusMessage = "Error: Weight increment must be greater than zero"
				$script:statusColor = "DarkRed"
			}
			else {
				for ($w = $startWeight; $w -le $endWeight; $w += $increment) {
					$doseMg = $dose * $w
					$vol = ($doseMg * $ml) / $mg
					$roundedVol = [math]::Round($vol, 2)
					$entry = [PSCustomObject]@{
						Name          = $name
						Weight        = [math]::Round($w, 2)
						TotalDoseMg   = $doseMg
						Volume        = $vol
						DisplayString = "$name ${mg}mg/${ml}mL (Dose ${dose}mg/kg)  >> Weight: ${w}kg >> Dose = ${roundedVol} mL"
						StatusColor   = "DarkCyan"
					}
					if (-not (IsDuplicateEntry -entry $entry -history $script:doseHistory)) {
						$script:doseHistory += $entry
					}
				}

				$script:statusMessage = "Generated dosing chart for Acetaminophen (Dose: 15mg/kg)"
				$script:statusColor = "Green"
			}
		}
# 7. Dosing Chart: Ibuprofen
		7 {
			$name = "Ibuprofen"
			$mg = 100
			$ml = 5
			$dose = 10
			$conc = $mg / $ml
			$startWeight = GetNumericInput "Enter first weight to calculate (kg)"
			$endWeight = GetNumericInput "Enter last weight to calculate (kg)"
			$increment = GetNumericInput "Enter weight increment (e.g. 0.5)"

			if ($startWeight -gt $endWeight) {
				$script:statusMessage = "Error: Starting weight ($startWeight kg) cannot be greater than ending weight ($endWeight kg)"
				$script:statusColor = "DarkRed"
			}
			elseif ($increment -le 0) {
				$script:statusMessage = "Error: Weight increment must be greater than zero"
				$script:statusColor = "DarkRed"
			}
			else {
				for ($w = $startWeight; $w -le $endWeight; $w += $increment) {
					$doseMg = $dose * $w
					$vol = ($doseMg * $ml) / $mg
					$roundedVol = [math]::Round($vol, 2)
					$entry = [PSCustomObject]@{
						Name          = $name
						Weight        = [math]::Round($w, 2)
						TotalDoseMg   = $doseMg
						Volume        = $vol
						DisplayString = "$name ${mg}mg/${ml}mL (Dose ${dose}mg/kg)  >> Weight: ${w}kg >> Dose = ${roundedVol} mL"
						StatusColor   = "DarkCyan"
					}
					if (-not (IsDuplicateEntry -entry $entry -history $script:doseHistory)) {
						$script:doseHistory += $entry
					}
				}
				$script:statusMessage = "Generated dosing chart for Ibuprofen (Dose: 10mg/kg)"
				$script:statusColor = "Green"
			}
		}
# 8. Dosing Chart: Diphenhydramine		
		8 {
			$name = "Diphenhydramine"
			$mg = 12.5
			$ml = 5
			$dose = 1
			$conc = $mg / $ml
			$startWeight = GetNumericInput "Enter first weight to calculate (kg)"
			$endWeight = GetNumericInput "Enter last weight to calculate (kg)"
			$increment = GetNumericInput "Enter weight increment (e.g. 0.5)"

			if ($startWeight -gt $endWeight) {
				$script:statusMessage = "Error: Starting weight ($startWeight kg) cannot be greater than ending weight ($endWeight kg)"
				$script:statusColor = "DarkRed"
			}
			elseif ($increment -le 0) {
				$script:statusMessage = "Error: Weight increment must be greater than zero"
				$script:statusColor = "DarkRed"
			}
			else {
				for ($w = $startWeight; $w -le $endWeight; $w += $increment) {
					$doseMg = $dose * $w
					$vol = ($doseMg * $ml) / $mg
					$roundedVol = [math]::Round($vol, 2)
					$entry = [PSCustomObject]@{
						Name          = $name
						Weight        = [math]::Round($w, 2)
						TotalDoseMg   = $doseMg
						Volume        = $vol
						DisplayString = "$name ${mg}mg/${ml}mL (Dose ${dose}mg/kg)  >> Weight: ${w}kg >> Dose = ${roundedVol} mL"
						StatusColor   = "DarkCyan"
					}
					if (-not (IsDuplicateEntry -entry $entry -history $script:doseHistory)) {
						$script:doseHistory += $entry
					}
				}
				$script:statusMessage = "Generated dosing chart for Diphenhydramine (Dose: 1mg/kg)" 
				$script:statusColor = "Green"
			}
		}
# 9. Dosing Chart: Other Medication (Manual Entry)		
		9 {
			$name = Read-Host "Enter medication name"
			$mg = GetNumericInput "Enter strength of drug (mg)"
			$ml = GetNumericInput "Enter liquid volume (mL)"
			$dose = GetNumericInput "Enter dose (mg/kg)"
			$conc = $mg / $ml
			$startWeight = GetNumericInput "Enter first weight to calculate (kg)"
			$endWeight = GetNumericInput "Enter last weight to calculate (kg)"
			$increment = GetNumericInput "Enter weight increment (e.g. 0.5)"

			if ($startWeight -gt $endWeight) {
				$script:statusMessage = "Error: Starting weight ($startWeight kg) cannot be greater than ending weight ($endWeight kg)"
				$script:statusColor = "DarkRed"
			}
			elseif ($increment -le 0) {
				$script:statusMessage = "Error: Weight increment must be greater than zero"
				$script:statusColor = "DarkRed"
			}
			else {
				for ($w = $startWeight; $w -le $endWeight; $w += $increment) {
					$doseMg = $dose * $w
					$vol = ($doseMg * $ml) / $mg
					$roundedVol = [math]::Round($vol, 2)
					$entry = [PSCustomObject]@{
						Name          = $name
						Weight        = [math]::Round($w, 2)
						TotalDoseMg   = $doseMg
						Volume        = $vol
						DisplayString = "$name ${mg}mg/${ml}mL (Dose ${dose}mg/kg)  >> Weight: ${w}kg >> Dose = ${roundedVol} mL"
						StatusColor   = "DarkCyan"
					}
					if (-not (IsDuplicateEntry -entry $entry -history $script:doseHistory)) {
						$script:doseHistory += $entry
					}
				}

				$script:statusMessage = "Generated dosing chart for $name ${mg}mg/${ml}mL (Dose ${dose}mg/kg)"
				$script:statusColor = "Green"
			}
		}
# 10. New Weight in Kilograms
        10 { 
            $script:weightKg = GetWeightInput "Enter new weight in kilograms"
			if ($script:weightKg -lt 5) {
				$script:statusMessage = "Caution: Weight is lower than expected range (5 kg - 99 kg)"
				$script:statusColor = "DarkRed"
				Write-Host $script:statusMessage -ForegroundColor $script:statusColor
			}	
			elseif ($script:weightKg -gt 99) {
				$script:statusMessage = "Caution: Weight is higher than expected range (5 kg - 99 kg)"
				$script:statusColor = "DarkRed"
				Write-Host $script:statusMessage -ForegroundColor $script:statusColor
			}			
			else {		
				$script:statusMessage = "Updated weight: $($script:weightKg) kg"
				$script:statusColor = "Green"
				}
		}
# 11. New Weight in Pounds
        11 { 
            $lbs = GetWeightInput "Enter new weight in pounds (auto-converts to kg)"
            $script:weightKg = [math]::Round($lbs / 2.2, 2)
			if ($script:weightKg -lt 5) {
				$script:statusMessage = "Caution: Weight $lbs lbs = $($script:weightKg) kg is less than expected range (5 kg - 99 kg)"
				$script:statusColor = "DarkRed"
				Write-Host $script:statusMessage -ForegroundColor $script:statusColor
			}	
			elseif ($script:weightKg -gt 99) {
				$script:statusMessage = "Caution: Weight $lbs lbs = $($script:weightKg) kg is higher than expected range (5 kg - 99 kg)"
				$script:statusColor = "DarkRed"
				Write-Host $script:statusMessage -ForegroundColor $script:statusColor
			}			
			else {
				$script:statusMessage = "Updated weight: $lbs lbs = $($script:weightKg) kg"
				$script:statusColor = "Green"
			}
        }
# 12. Clear Dose History
        12 { 
            $script:doseHistory = @()
            $script:statusMessage = "Dose history cleared"
            $script:statusColor = "DarkGreen"
        }
# 13. Export Calculations
        13 { 
            if ($script:doseHistory.Count -eq 0) {
                $script:statusMessage = "Error: No calculations to export"
                $script:statusColor = "DarkRed"
            } else {
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $filename = "Pediatric Dosage Summary $timestamp.txt"
                $script:doseHistory | ForEach-Object { $_.DisplayString } | Set-Content -Path $filename -Encoding UTF8
                $script:statusMessage = "Calculation history saved to $filename"
                $script:statusColor = "Green"
            }
        }
# 14. Exit
        14 { 
            exit
        }
    }
}