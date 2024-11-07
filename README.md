### Lotto Number Generator

The Lotto Number Generator is an assembly program written for the Commodore 64 (C64) which generates a row of 6 unique random numbers from 1 to 40. 

## Generating Random Number
The program runs in O(n) by avoiding duplicate numbers being selected in the number geneator. Instead, the number generator selects the location in the array, prepopulated with 1..40, to assign to the current column to populate e.g. when generating the first number, the value in array(1) is swapped with the value in array(random number). Since the numbers are always swapped, a duplicate never exists.   

## IDE
This  program was written using CMB.PRG Studio https://www.ajordison.co.uk/

## Screenshot

![image](https://github.com/user-attachments/assets/c0192168-2203-41d4-ab30-64ba16ff09fb)
