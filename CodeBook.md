CodeBook
========

*by Corneil du Plessis*

**2015-01-15**

## Initial dataset.

### features.txt

Name | Type | Description
-----|------|------------
findex | int | Index for each feature.
fname | character | Label of the feature. 

### activity_labels.txt

Name | Type | Description
-----|------|------------
aindex | int | Index for each activity.
aname | character | Label for the activity. 

### y_test.txt and y_train.txt

Name | Type | Description
-----|------|------------
index | int | Index of activity for the corresponding row in X_ set

### subject_test.txt and subject_train.txt

Name | Type | Description
-----|------|------------
index | int | Index of subject for the corresponding row in X_ set

### X_test.txt and X_train.txt

- Fixed width file, with 561 columns of 16 characters each.  
- Every column matches the features from features.txt  
- Every row representing a processed collection of the features for an activity and subject.

## Final dataset columns.

Name | Type | Description
----|----|-----------
Subject | Integer | The index of the subject obtains from subject-test and subject-train
Activity | Character | The descriptive activity obtained from activities.txt
Variable | Character | The descriprive variable obtained by expanding features.txt
Value | Number | The mean of variable values for each subject and activity

