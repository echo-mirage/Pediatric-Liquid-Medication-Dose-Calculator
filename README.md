# Pediatric-Liquid-Medication-Dose-Calculator

![dosecalc](https://github.com/user-attachments/assets/f5d51360-e9e4-4c3a-af6d-1c623ea11395)



=== Pediatric Dosage Calculator for Liquid Medications ===

Version 2025.07.21

Author: Echo-Mirage


Description:

Calculates weight-based doses in mL for common over-the-counter liquid oral medications (Acetaminophen, Ibuprofen, and Diphenhydramine)

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

  Example: 10kg weight at 15mg/kg = 150mg desired dose
  
Then using the concentration to determine the amount in mL needed to deliver the desired dose 

  Example: Acetaminophen 160mg/5mL = 32mg/mL, so the desired 150mg dose / 32mg = 4.69mL to deliver 150mg dose

Changelog: 
2025.07.21 - Added Dosing Charts for preset medications.
