# Two Button Verilog Simon

This repository was made for an Honors Contract for a class. These verilog files (\*.v) can be compiled together and will result in a simon game that uses two buttons.

# TwoToFour.diff

This diff file was added to show how the file would be changed to implement 4 buttons rather than two. This diff file shows how to generally change the two button implementation to 2^n buttons by simply changing the differences from four bytes to 2^n bytes.
To go to more than four bytes requires more changes on the main file but the diff file outlines the general process to expand the functionality.

# The reason for two buttons

Originally I had implementations for 4 and 8 buttons but since I have not been able to figure out how to properly wire additional buttons to my board that only has 2 buttons, I have made a 2 button edition so that I would be able to utilize the buttons.


A useful resource that I referenced while making this simon game was https://github.com/cemulate/simple-simon.
