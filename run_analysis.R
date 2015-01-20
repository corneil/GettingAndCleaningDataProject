tabinfo <- function(name, df) {	
	paste(name, "class:", paste(class(df), collapse=" "), paste(as.character(dim(df)), collapse=" "), collapse=" ")
}
# Install required packages that are not available
if(!require(data.table)) {
    install.packages("data.table")
    library(data.table)
}
if(!require(dplyr)) {
    install.packages("dplyr")
    library(dplyr)
}
if(!require(tidyr)) {
    install.packages("tidyr")
    library(tidyr)
}
if(!require(descr)) {
    install.packages("descr")
    library(descr)
}
st <- proc.time()
# Load the features 
features <- fread('UCI HAR Dataset/features.txt', header = FALSE) %>% 
    setnames(c("findex", "fname")) %>%
    setkey('findex')
# Filter only features that contain mean()- or std()- and expand the features to descriptive names
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
print(tabinfo("features_desc", features_desc))
# Load the descriptive activities
activities <- fread('UCI HAR Dataset/activity_labels.txt', header=FALSE) %>% 
    setnames(c("aindex", "aname")) %>% 
    setkey('aindex')
# Load the activities for the test and training data
y_test <- fread('UCI HAR Dataset/test/y_test.txt', header = FALSE) %>% 
    setnames(c("index")) %>% 
    setkey('index')
print(tabinfo("y_test", y_test))
y_train <- fread('UCI HAR Dataset/train/y_train.txt', header = FALSE) %>% 
    setnames(c("index")) %>%
    setkey('index')
print(tabinfo("y_train", y_train))

# Load the subjects for the test and training data
subject_test <- fread('UCI HAR Dataset/test/subject_test.txt', header = FALSE) %>%
    setnames(c("subject"))
print(tabinfo("subject_test", subject_test))
subject_train <- fread('UCI HAR Dataset/train/subject_train.txt', header = FALSE) %>%
    setnames(c("subject"))
print(tabinfo("subject_train", subject_train))
# Set the column widths for the conversion of fixed width data to csv
tab <- data.table(row=c(1:561)) %>% mutate(start = 1 + ((row - 1) * 16), end = (row) * 16, name = paste0("V",as.character(row)))
print('Converting test to csv')
fwf2csv('UCI HAR Dataset/test/X_test.txt', 'X_test.csv', tab[,name], tab[,start], tab[,end])
print('Converting train to csv')
fwf2csv('UCI HAR Dataset/train/X_train.txt', 'X_train.csv',  tab[,name], tab[,start], tab[,end])
print('Loading X_test')
# Load the test data and add activity and subject information
X_test <- data.table(fread('X_test.csv')) %>% mutate(activity_index = y_test[,index], subject = subject_test[,subject])
print(tabinfo("X_test", X_test))
print('Loading X_train')
# Load the training  data and add activity and subject information
X_train <- data.table(fread('X_train.csv')) %>% mutate(activity_index = y_train[,index], subject = subject_train[,subject])
print(tabinfo("X_train", X_train))

# Combine the datasets and add the descriptive activity and limits columns to the filtered features
print('Combining and Limiting')
X_mean_std <- rbindlist(list(X_train, X_test)) %>% mutate(activity = factor(activities[aindex == activity_index, aname])) %>%
    select(activity, subject, num_range("V", as.vector(features_desc[,findex]))) %>%
    setnames(c("Activity", "Subject", features_desc[,fname]))
print(tabinfo("X_mean_std", X_mean_std))
print('Gather into rows')
# Gather the data so that variable end in one column and assign proper column names
x_gather <- X_mean_std %>% gather(Activity, Subject) %>%
    setnames(c("Activity", "Subject", "Variable", "Value"))
print(tabinfo("x_gather", x_gather))
print('Producing summary')
# Calculate mean for variables by subject and activity
x_final <- x_gather %>% 
    group_by(Subject, Activity, Variable) %>% 
    summarise(Average = mean(Value)) %>% 
    arrange(Subject, Activity, Variable)
print(tabinfo("x_final", x_final))
# Write the data
print('Writing data')
write.table(x = x_final, file = "tidy-dataset.txt", row.names=FALSE)
et <- proc.time()
print(et-st)