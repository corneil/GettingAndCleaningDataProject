Getting and Cleaning Data Project
=================================

*by Corneil du Plessis*

This repository contains the files that is my submission for the project.

### Files

File | Description
-----|------------
[run_analysis.R](run_analysis.R) | The R script that performs the analysis
[CodeBook.md](CodeBook.md) | The code book describing the tidy dataset.

### Packages
The analytis script uses the following packages from CRAN data.table, dplyr, tidyr and descr.

### Analysis
The script assumes the dataset zip was expanded in the current working directory and that all the files are in a sub-directory named 'UCI HAR Dataset'
The dataset files has no column names and I chose names and assigned during read or after transformation.

The analysis initially loads features.txt, activities.txt, y_test.txt, y_train.txt, subject_train.txt and subject_test.txt

features.txt is loaded, the 2 columns are named findex and fname.
The features are filtered retaining only features with mean()- or std()- in fname.  
This results in a set of 48 features.  
The name are then expanded to more descriptive names similar to the activity names.
```r
features <- fread('UCI HAR Dataset/features.txt', header = FALSE) %>% 
    setnames(c("findex", "fname")) %>%
    setkey('findex')

features_desc <- features %>% 
    filter(grepl("mean\\(\\)\\-", fname) | grepl("std\\(\\)\\-", fname))  %>% 
    mutate(fname = sub("mean\\(\\)\\-", "MEAN_", fname)) %>%
    mutate(fname = sub("std\\(\\)\\-", "STDDEV_", fname)) %>%
    mutate(fname = sub("^f", "FREQUENCY_DOMAIN_", fname)) %>%
    mutate(fname = sub("^t", "TIME_DOMAIN_", fname)) %>%
    mutate(fname = sub("Body", "BODY_", fname)) %>%
    mutate(fname = sub("AccJerk\\-", "ACCELEROMETER_JERK_", fname)) %>%
    mutate(fname = sub("Acc\\-", "ACCELEROMETER_", fname)) %>%
    mutate(fname = sub("GyroJerk\\-", "GYROSCOPE_JERK_", fname)) %>%
    mutate(fname = sub("Gyro\\-", "GYROSCOPE_", fname))
```
activity_labels.txt has 2 columns named them aindex and aname.  
y_test.txt and y_train.txt has 1 column named index.
subject_test.txt and subject_train.txt has 1 solumn named subject.

```r
activities <- fread('UCI HAR Dataset/activity_labels.txt', header=FALSE) %>% 
    setnames(c("aindex", "aname")) %>% 
    setkey('aindex')
y_test <- fread('UCI HAR Dataset/test/y_test.txt', header = FALSE) %>% 
    setnames(c("index")) %>% 
    setkey('index')
y_train <- fread('UCI HAR Dataset/train/y_train.txt', header = FALSE) %>% 
    setnames(c("index")) %>%
    setkey('index')
subject_test <- fread('UCI HAR Dataset/test/subject_test.txt', header = FALSE) %>%
    setnames(c("subject"))
subject_train <- fread('UCI HAR Dataset/train/subject_train.txt', header = FALSE) %>%
    setnames(c("subject")
```

The input files initially seemed confusing until I realised the X_test.txt and X_train.txt was fixed column files with a variable every 16 characters.
The load time using read.fwf slow taking minutes. The 2 large files are converted from fixed format to csv using fwf2csv resulting in a much decreased load time using fread over read.fwf
```r
tab <- data.table(row=c(1:561)) %>% mutate(start = 1 + ((row - 1) * 16), end = (row) * 16, name = paste0("V",as.character(row)))
fwf2csv('UCI HAR Dataset/test/X_test.txt', 'X_test.csv', tab[,name], tab[,start], tab[,end])
fwf2csv('UCI HAR Dataset/train/X_train.txt', 'X_train.csv',  tab[,name], tab[,start], tab[,end])
```
X_test and X_train is loaded and activity-index and subject added.
```r
X_test <- data.table(fread('X_test.csv')) %>% 
    mutate(activity_index = y_test[,index], subject = subject_test[,subject])
X_train <- data.table(fread('X_train.csv')) %>% 
    mutate(activity_index = y_train[,index], subject = subject_train[,subject])
```

The test and train datasets are combined, the descriptive activity assigned and the filtered features selected and column names assigned
```r
X_mean_std <- rbindlist(list(X_train, X_test)) %>% 
    mutate(activity = factor(activities[aindex == activity_index, aname])) %>%
    select(activity, subject, num_range("V", as.vector(features_desc[,findex]))) %>%
    setnames(c("Activity", "Subject", as.character(features_desc[,fname])))
```
The combined dataset is then gathered into a set of variables by subject and activity.
```r
x_gather <- X_mean_std %>% gather(Activity, Subject) %>%
    setnames(c("Activity", "Subject", "Variable", "Value"))
```
The means are determined for each variable by subject and activity.
```r
x_final <- x_gather %>% 
    group_by(Subject, Activity, Variable) %>% 
    summarise(Average = mean(Value)) %>% 
    arrange(Subject, Activity, Variable)
head(x_final)
```
```
##   Subject Activity                                Variable     Average
## 1       1  WALKING   TIME_DOMAIN_BODY_ACCELEROMETER_MEAN_X  0.26569692
## 2       1  WALKING   TIME_DOMAIN_BODY_ACCELEROMETER_MEAN_Y -0.01829817
## 3       1  WALKING   TIME_DOMAIN_BODY_ACCELEROMETER_MEAN_Z -0.10784573
## 4       1  WALKING TIME_DOMAIN_BODY_ACCELEROMETER_STDDEV_X -0.54579533
## 5       1  WALKING TIME_DOMAIN_BODY_ACCELEROMETER_STDDEV_Y -0.36771622
## 6       1  WALKING TIME_DOMAIN_BODY_ACCELEROMETER_STDDEV_Z -0.50264575
```
Write the final dataset of **1920** rows to a file
```r
write.table(x = x_final, file = "tidy-dataset.txt", row.names=FALSE)
```
The final dataset contains average values for each variable by subject and activity.  

The original 561 features was filtered to the 48 mean and std dev for X,Y,Z measurements.  


Output from running the script:
```
[1] "features_desc class: data.table data.frame 48 2"
[1] "y_test class: data.table data.frame 2947 1"
[1] "y_train class: data.table data.frame 7352 1"
[1] "subject_test class: data.table data.frame 2947 1"
[1] "subject_train class: data.table data.frame 7352 1"
[1] "Converting test to csv"
[1] "Converting train to csv"
[1] "Loading X_test"
[1] "X_test class: data.table data.frame 2947 563"
[1] "Loading X_train"
[1] "X_train class: data.table data.frame 7352 563"
[1] "Combining and Limiting"
[1] "X_mean_std class: data.table data.frame 10299 50"
[1] "Gather into rows"
[1] "x_gather class: data.table data.frame 494352 4"
[1] "Producing summary"
[1] "x_final class: grouped_dt tbl_dt tbl tbl_dt tbl data.table data.frame 1920 4"
[1] "Writing data"
   user  system elapsed 
  1.958   0.102   2.360 
```