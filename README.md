# Coastal Harbor Seal Survey Counting

This repository stores code necessary for counting harbor seals using DIVE. Instructions for the counting process can be found on Google Drive {add link}.

The data management processing code is as follows:
* **CoastalPv_Counting_01_GenerateImageList.R** - code to generate a list of images for import in DIVE that have been identified to have harbor seals that will be counted
* **CoastalPv_Counting_02_ImportAnnotations.R** - code to import annotations (after counting is complete) into the pep PostgreSQL database