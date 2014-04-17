TidyData
========
Motivation
-------------------------
This script and associated files is to answer my interpretation of the Getting and Cleaning Data project assignment. 

I assumed : 
 
  - that the source data is 'as extracted' from the zip with same construct for file-name, directory and file-content
  - that the user is interested in extracting only the mathematical transformations of the original signals - i.e. 
    - 'mean' should match only mean() and not blahmeanblah and likewise 'std' --> std()
    - the script should return mean() and std() as default, but other functions (not limited to 2) should also be possible to extract. for instance call with SearchTerms="min;max" etc
  - that the merging should be generic i.e. as well as 'train' and 'test' I wanted to leave open the possibility the name will change or new data-sets will be provided. So, once they fit the structure the script has been written with this in mind. 

How to run
-------------------------

with a valid data set in a given directory (MyDir) and sub-directories (e.g. MyDir/test and MyDir/train), issue the following commands at the R console

>source(<github address url>run_analysis.R) # I'm not sure how to do this ! It might be an idea to download the script or even just 'copy and paste' !
>ReadActData(ActDir=MyDir) #first function - must run this first ! 
...where MyDir is a text string pointing to a directory on your computer 
...you must have Read/Write privileges to MyDir
...MyDir must contain activity_labels.txt and features.txt files with data formatted as per original source.
.... optionally pass a variable SearchTerms - a string containing one or more statistical terms from the list 
.... provided in the original documentation, with ; as separator. Note that () is appended to the string terms
.... meaning 'mean()' is matched but meanFreq() and similar terms are not.

... after running check in MyDir for a correctly formmatted working file. 
..then type  : 
>ReadProcActData(ActDir=MyDir) #second function - make sure the first one outputted a file ! 

.... and then check for a text file called TidyMeanData.txt in MyDir.

The CodeBook found in this repository applies and includes the R command used to load the result file back into R for further processing. 

More Details 
=============
The file run_Analysis.R contains 3 functions, 2 of which are used to create 'tidy data' according to the specification of the Coursera assignment 'Getting and Cleaning Data Project'.

Function 1) : 
-------------------------

ReadActData<-function(SearchTerms="mean;std",ActDir="~/Documents/CQA/gettingCleanData/UCI HAR Dataset")

* Test 1 :  ActDir contains files called activity_labels.txt and features.txt

* Test 2 : The files can be read into R and pass some simple tests 

* Test 3 : There are 1 or more sub-directories of ActDir which 
  * Contain 3 files with names matching a simple convention 
  * where each file can be read into an R data-structure and pass some comparison criteria

then the data in each valid subdirectory is read into a data-frame for further processing.


* Test 4 : the string SearchTerms is split into individual strings using ; and a '()' is appended so the default gives mean() and std() for instance. These 'features' are searched for in features.txt stored structure and the test is passed if at least one column matches all supplied terms. 

  * then : the data-frame is subsetted according to the pattern matched in Test 4

-and : the file "tidydata.txt" is written to the directory supplied (MyDir) in a text format. This can be considered an interim or 'bonus' file which can be independently analysed.

Function 2):
-------------------------
ReadProcActData<-function(TargetFile="tidyData.txt",ActDir="~/Documents/CQA/gettingCleanData/UCI HAR Dataset")

Reads in a file from the supplied directory, the default is the same 'hardcoded' output from the previous stage, but this can be changed. However the format is fixed according to the output of the previous stage. 

* converts the data-frame to a data-table
* performs a transformation to make a new data-table containing mean values grouped by Activity, Subject. 
* Writes the new dataframe to a new file (hardcoded name : TidyMeanData.txt) in the same directory. 
* Writes the column headers to a new file which can be the genesis of a CodeBook file. 

* Returns the header of the result data-frame to give a quick view of whether it is working as expected or not.





