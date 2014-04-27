ReadActData<-function(SearchTerms="mean;std",ActDir="~/Documents/CQA/gettingCleanData/UCI HAR Dataset"){
  
  ActWD<-setwd(ActDir)
  dateDownloaded <- format(Sys.time(), "%Y%b%d") #for now, we assume the files are already downloaded
  
  featureLabelFile<-paste0(ActWD,"/features.txt")
  activityLabelFile<-paste0(ActWD,"/activity_labels.txt")  
  #check these key files exist - else no point in doing anything ! 
  if(file.exists(featureLabelFile) && 
              file.exists(activityLabelFile)){
    #once the files exist, read them in - note there are assumptions about the structure of each file ! 
    #simple tests only on each file
    featureLabels<-read.table(featureLabelFile)
    #this next section relabels the features, by adding the first col - the ordinal position.
    #simple scheme guarantees no duplicates at the expense of storing trouble for later. 
    featureLabels.orig<-featureLabels[,2]
    colnumbers    <- featureLabels[,1]
    coldash<-c(rep("-",length(featureLabels[,2]))) 
    featureLabels<-paste0(colnumbers,coldash,featureLabels.orig)
    nfeatureLabels<-length(unique(featureLabels)) 
       
    if(nfeatureLabels < 1){stop("no Features found")} #if the list is empty then obviously no point in continuing
    
    #the second file is the activity labels
    ActLabels<-read.table(activityLabelFile)
    NAct<-length(ActLabels[,1])
    if(length(ActLabels[1,]) != 2){stop("Activity labels not 2 column table")}
    names(ActLabels)<-c("Activity","ActLabel") #these names will allow for the merge later
  }else{stop("correct files not found in base directory. Check your input")}
  
  #this next section examines the names of all files in the current directory, 
  #all which are sub-directories are kept as possible DataSets in the list DSName
  fls<-dir(ActWD,recursive=FALSE)
  nDSPossible<-0
  DSName<-vector(length=1)
  DSName[1]<-c(" ")
  for(f in fls){
    DSName[nDSPossible+1]<-f
    f<-file.path(ActWD,f)
    if(file.info(f)$isdir){
      nDSPossible<-nDSPossible+1
    }
  }
  
 #now we examine each subdirectory in turn and see if it contains 3 files 
 # named according to the convention and containing the 'correct' dimensions of data.
 # all that contain the data are 'merged' into DS and we also track the total lines of data
  
  nDS<-0
  nLines<-0
  tempDS<-data.frame(c(replicate(nfeatureLabels+2,numeric())))
  DS<-data.frame(c(replicate(nfeatureLabels+2,numeric())))
  
  for (possDS in DSName){
    
    featureFile<-paste0(ActWD,"/",possDS,"/X_",possDS,".txt")
    subjectFile<-paste0(ActWD,"/",possDS,"/subject_",possDS,".txt")
    activityFile<-paste0(ActWD,"/",possDS,"/y_",possDS,".txt")
        #if these files don't exist - skip this possibleDS ! 
    if(file.exists(featureFile) && 
         file.exists(subjectFile) &&
         file.exists(activityFile)){ #if yes, read in each file successively and 'test' 
     
          subjectLines<-readLines(subjectFile)
          nSubject<-length(subjectLines)
          activityLines<-readLines(activityFile)
          nActivity<-length(activityLines)
          featureLines<-read.table(featureFile,sep="")
          nFeature<-length(featureLines[1,])
          nFeatureLines<-length(featureLines[,1])
     
     if((nSubject == nActivity)&&
          (nActivity==nFeatureLines)&&
          (nFeature == nfeatureLabels)){
         
               nDS<-nDS+1
               DSName[nDS]<-possDS
               nLines<-nLines+nSubject
               tempDS<-data.frame(featureLines,subjectLines,activityLines,stringsAsFactors=FALSE)
               DS<-rbind(DS,tempDS) #this is the key line - append valid rows found onto our master list DS
               #need do a 'vlookup to translate these into names later
                                           }
                          } 
    #otherwise we just skip onto the next file ! 
  }
  
  #tell user how we are getting on : 
  
  infoLine1<-paste0("There are ", nDS," valid data sets, containing ",nFeature,
                    " columns and ",nLines," rows")
  print(infoLine1 )
  
  #next we extract the distinct search terms - note that we are appending () so the 
  # user just needs to specify the function like mean, std etc so a string like 
  #"mean;std" will result in mean() and std() being search for "min;max" in min() and max() etc
  #default values are mean;std - i.e. running the function without other argument results in mean() and std() values being extracted
 
    SearchTerms<-strsplit(SearchTerms,split=";",fixed=TRUE) # make a list using ; as the splitting point
    SearchTerms<-unlist(SearchTerms) #unlist to make a vector of terms 
    print(SearchTerms) #remind user what we are looking for ! 
 
  #in the following, we could probably greatly simplify by replacing the ;with a | 
  # and therefore avoid all the complications of unlisting and so on.
  targetCols<-vector(length=0)
  nSearchTerms<-length(SearchTerms)
  for(term in SearchTerms){
    term<-paste0(term,"()")
    targetCols<-union(targetCols,grep(term,featureLabels,fixed=TRUE)) #note fixed=TRUE means the () are searched for literally
    #could also have escaped them as \\(\\)
  }

  infoLine2<-paste0("There are ", length(targetCols)," variable matching your selection ")
  print(infoLine2)
   
  if (length(targetCols) < 1){
    stop("goodbyeee !")
  }
  #if we got this far it must be OK !
 
  
    tidyData<-DS[,c(targetCols,nfeatureLabels+1,nfeatureLabels+2)]
    names(tidyData)<-c(featureLabels[targetCols],"Subject","Activity")
  

#do a "vlookup" to change the Activity numbers into Activity labels
ActNames<-merge(ActLabels,tidyData,by="Activity")[,2] #another hack ! the merge will produce all the cols otherwise
tidyData[,length(targetCols)+2]<-ActNames #this hack overwrites the Activity numbers 

  #lastly - write a table - this is an interim result - in this large file will be stored ALL the records from Tidy and Test data
  tidyDataFile<-paste0(ActWD,"/tidyData.txt")
  write.table(tidyData,file=tidyDataFile,row.names=FALSE,quote=FALSE,col.names=names(tidyData))
  

  
  
}

#This next function assumes the previous one has run successfully.
#Simply reads in the big file with all the records
#converts the data frame into a data-table, runs the average function by [subject, activity] combination
# and writes back out the table

ReadProcActData<-function(TargetFile="tidyData.txt",ActDir="~/Documents/CQA/gettingCleanData/UCI HAR Dataset"){
  tidyDataFile<-paste0(ActDir,"/tidyData.txt")
  tidyDataIn<-read.table(file=tidyDataFile,sep=" ",header=TRUE,quote=" ",check.names=FALSE,stringsAsFactors=FALSE)
  
  nFeatures<-length(names(tidyDataIn))-2 #assume nFeature cols and then 2 for Activity and Subject
  td1<-data.table(tidyDataIn) #make into data-frame
  #the following code was from : http://stackoverflow.com/questions/14937165/using-dynamic-column-names-in-data-table?lq=1
  td2<-td1[,lapply(.SD,mean),by=list(Subject,Activity),.SDcols=1:nFeatures]
  
  tidyMeanDataFile<-paste0(ActDir,"/tidyMeanData.txt")
  write.table(td2,file=tidyMeanDataFile,row.names=FALSE,quote=FALSE,col.names=names(td2))
  tidyMeanDataCodebook<-paste0(ActDir,"/tidyMeanDataCodebook.txt")
  
  writeLines(names(td2),tidyMeanDataCodebook,sep="\n")
  
  return(head(td2))
}

#The following function makes the codebook by using reg exp to parse the original column names
#This assumes there is already a file called 'tidyMeanDataCodebook.txt' in the active directory

makeCodeBook<-function(ActDir="~/Documents/CQA/gettingCleanData/UCI HAR Dataset"){
  
  ActWD<-setwd(ActDir)
  
  tidyMeanDataCodebook<-paste0(ActDir,"/tidyMeanDataCodebook.txt")
  
  
  ColHeadings<-readLines(tidyMeanDataCodebook)
  
  featureLabels<-ColHeadings[-c(1,2)]
  
  head(featureLabels)
  
  
  Ordinal<-regexpr("^[0-9]{1,3}",featureLabels)
  Ordinal<-regmatches(featureLabels,Ordinal)
  
  Axis<-regexpr("[XYZ]|.$",featureLabels)
  Axis<-regmatches(featureLabels,Axis)
  Axis<-gsub('[^XYZ]',"non-axial measurement",Axis)
  Axis<-gsub("([XYZ])", "\\1 Axis",Axis)
  #NB --- Note the () around the [XYZ] which allow the use of backcapture !
  
  TimeFreq<-regexpr("[0-9]-([tf])",featureLabels)
  TimeFreq<-regmatches(featureLabels,TimeFreq)
  TimeFreq<-sub("([0-9]){1,5}-","",TimeFreq)
  TimeFreq<-sub("([tf])","\\1 domain",TimeFreq)
  
  AccGyro<-regexpr("(Acc)|(Gyro)",featureLabels)
  AccGyro<-regmatches(featureLabels,AccGyro)
  AccGyro<-sub("Acc","Accelerometer",AccGyro)
  AccGyro<-sub("Gyro","Gyroscope",AccGyro)
  
  BodyGravity<-regexpr("(Body)|(Gravity)",featureLabels)
  BodyGravity<-regmatches(featureLabels,BodyGravity)
  
  
  Jerk<-grep("Jerk",featureLabels)
  NotJerk<-grep("Jerk",featureLabels,invert=TRUE)
  JerkNotJerk<-featureLabels
  JerkNotJerk[Jerk]<-"derivative of linear acceleration or angular velocity"
  JerkNotJerk[NotJerk]<-""
  
  Mag<-grep("Mag",featureLabels)
  NotMag<-grep("Mag",featureLabels,invert=TRUE)
  MagNotMag<-featureLabels
  MagNotMag[Mag]<-"magnitude of 3-dimensional signals according to Euclidean norm"
  MagNotMag[NotMag]<-""
  
  Statistic<-regexpr("-+([a-z]+)\\(\\)",featureLabels) #-std()
  Statistic<-regmatches(featureLabels,Statistic)
  Statistic<-sub("-([[a-z]+)\\(\\)","\\1",Statistic)
  
  Description<-featureLabels
  
  for (index in 1:length(featureLabels)){
    Description[index]<-paste0("The scaled value of the ",Statistic[index]," statistic ",
                               "of the ",TimeFreq[index]," signal, from the ",
                               JerkNotJerk[index],MagNotMag[index],
                               BodyGravity[index]," component of the ",
                               AccGyro[index], " measurement on the ",
                               Axis[index],". This was originally column number ",
                               Ordinal[index])
  }
  
  Codebook<-cbind(ColHeadings,c("","",Description))
  
  tidyMeanDataCodebook2<-paste0(ActDir,"/tidyMeanDataCodebook2.txt")
  write.table(Codebook,file=tidyMeanDataCodebook2,row.names=FALSE,quote=FALSE,col.names=FALSE)
}