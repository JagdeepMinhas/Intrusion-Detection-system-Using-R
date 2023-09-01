df <- read.table("Term_Project_Dataset.txt", sep =',', header = TRUE)
df

library(ggplot2)

# Remove NA values
df <- df[complete.cases(df),]
df[is.na(df)] <- 0

# Scale the train data
train_features <- c("Global_active_power", "Global_reactive_power", "Voltage", "Global_intensity", "Sub_metering_1", "Sub_metering_2", "Sub_metering_3")
df_scaled <- scale(df[, train_features])

pca <- prcomp(df_scaled)
pca.var <- pca$sdev^2
pca.var.per <- round(pca.var/sum(pca.var)*100, 1)
pca.var.per
barplot(pca.var.per, main="PC Variation Plot", xlab="Principal Component", ylab="Percent Variation", col = "steelblue")

summary(pca)

loadings <- (pca$rotation)
pca_graph <- round(pca/sum(pca)*100, 1)

#####PART2##########

df_train <- df[1:1089510, ]
df_test <- df[1089511:1556444, ]
# Global_active_power, Global_intensity
# Day chosen: 1/1/2007
# Time window: 6:00 ~ 10:00

df_train$DateTime <- as.POSIXct(paste(df_train$Date, df_train$Time), format = "%d/%m/%Y %H:%M:%S")
df_train$DaysOfWeek <- weekdays(df_train$DateTime)

#for the test data
df_test$DateTime <- as.POSIXct(paste(df_test$Date, df_test$Time), format = "%d/%m/%Y %H:%M:%S")
df_test$DaysOfWeek <- weekdays(df_test$DateTime)

library(dplyr)
df_train_mondays <- df_train %>% filter(df_train$DaysOfWeek == "Monday")
df_train_mondays_time <- df_train_mondays %>% filter((Time >= "06:00:00") & (Time <= "10:00:00"))
df_train_mondays_time <- na.omit(df_train_mondays_time)

#for the test data
df_test_mondays <- df_test %>% filter(df_test$DaysOfWeek == "Monday")
df_test_mondays_time <- df_test_mondays %>% filter((Time >= "06:00:00") & (Time <= "10:00:00"))
df_test_mondays_time <- na.omit(df_test_mondays_time)

nan_rows <- apply(df_train_mondays_time, 1, function(x) any(is.nan(x)))
inf_rows <- apply(df_train_mondays_time, 1, function(x) any(is.infinite(x)))

#nan_rows_test <- apply(df_test_mondays_time, 1, function(x) any(is.nan(x)))
#inf_rows_test <- apply(df_test_mondays_time, 1, function(x) any(is.infinite(x)))

df_train_mondays_time <- df_train_mondays_time[complete.cases(df_train_mondays_time),]

df_test_mondays_time <- df_test_mondays_time[complete.cases(df_test_mondays_time),]

library(depmixS4)

#scale the data
train_features <- c("Global_active_power",  "Global_intensity")
df_train_scaled <- scale(df_train_mondays_time[, train_features])
df_test_scaled <- scale(df_test_mondays_time[, train_features])
df_train_scaled <- data.frame(df_train_scaled)
df_test_scaled <- data.frame(df_test_scaled)
response <- list(
  df_train_scaled$Global_active_power ~ 1,
  df_train_scaled$Global_intensity ~ 1
)
#sub_metering_3 was one of the candidates for the variables chosen from PCA however caused an error

family <- list(
  gaussian(),
  gaussian()
)

#for the test data
response_test <- list(
  df_test_scaled$Global_active_power ~ 1,
  df_test_scaled$Global_intensity ~ 1
)
family_test <- list(
  gaussian(),
  gaussian()
)

#log-likeli - higher the better
#BIC - lower the better
logs <- vector()
#ntimes_vec <- rep(c(241),each= 107)
ntimes_vec <- rep(c(241),each= 108)
logsTrain <- vector()
selectedStatesTrain <- c(4,6,8,10,16,20)
BICTrain <- vector()
#models for the test data
#creating a table for the test data to view the BIC, and the loglikhood for the train data
for(j in selectedStatesTrain ){
  model_train <- depmix(response = response, data = df_train_scaled, nstates = j, ntimes = ntimes_vec, family = family)
  fit_train <- fit(model_train)
  print("Current number of states :")
  print(j)
  summary(fit_train)
  print(fit_train)
  logsTrain <- append(logsTrain, logLik(fit_train))
  BICTrain <- append(BICTrain, BIC(fit_train))
}
table1 <- data.frame(selectedStatesTrain, BICTrain, logsTrain)
View(table1)
library(ggplot2)

ggplot()+
  geom_line(aes(x = selectedStatesTrain, y = BICTrain,color = "darkred"))+
  geom_line(aes(x = selectedStatesTrain, y = logsTrain,color = "steelblue")) +
  scale_colour_manual (labels = c("BIC","Log likelihood"),values = c("darkred","steelblue"))+
  labs(title = "BIC and log likelihood", y = "Unit values")

111#based on the training models, we have chosen states 16 and 20

logsTest <- vector()
#models for the test data
ntimes_test <- c(241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,240)
#ntimes_test <- c(241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,241,242)

#based on the loglik and BIC are selcted to be the ideal states for HMM
selectedStates <- c(16, 20)
BICTest <- vector()
#models for the test data
#creating a table for the test data to view the BIC, and the loglikhood for the test data
for(j in selectedStates ){
  model_test <- depmix(response = response_test, data = df_test_scaled, nstates = j, ntimes = ntimes_test, family = family_test)
  fit_test <- fit(model_test)
  print("Current number of states :")
  print(j)
  summary(fit_test)
  print(fit_test)
  logsTest <- append(logsTest, logLik(fit_test))
  BICTest <- append(BICTest, BIC(fit_test))
}
table2 <- data.frame(selectedStates, BICTest, logsTest)
View(table2)

#normalizing training log-likeihood and test log-likeihood to get 
#the best model out of states 16 and 20

#chooses last 2 elements of vector, i.e., states 16 and 20
logsTrain_chosen <- logsTrain[(length(logsTrain)-1):length(logsTrain)]

logsTrain_chosen <- logsTrain_chosen/nrow(df_train_scaled)
logsTest <- logsTest/nrow(df_test_scaled)
normalisedLogs <- data.frame(selectedStates,logsTrain_chosen, logsTest)

#based on the normalised log likelihood values, state = 20 is much closer than state = 16
#therefore state = 20 is a better model than 16.
#########################################################

##Log-likelihood of normal data (for the complete data)

df_normal <- read.table("Term_Project_Dataset.txt", sep =',', header = TRUE)
df_normal

df_normal <- df_normal[complete.cases(df_normal),]

df_normal$DateTime <- as.POSIXct(paste(df_normal$Date, df_normal$Time), format = "%d/%m/%Y %H:%M:%S")
df_normal$DaysOfWeek <- weekdays(df_normal$DateTime)

df_normal_mondays <- df_normal %>% filter(df_normal$DaysOfWeek == "Monday")
df_normal_mondays_time <- df_normal_mondays %>% filter((Time >= "06:00:00") & (Time <= "10:00:00"))
df_normal_mondays_time <- na.omit(df_normal_mondays_time)


nan_rows_normal <- apply(df_normal_mondays_time, 1, function(x) any(is.nan(x)))
inf_rows_normal <- apply(df_normal_mondays_time, 1, function(x) any(is.infinite(x)))

df_normal_mondays_time <- df_normal_mondays_time[complete.cases(df_normal_mondays_time),]

features0 <- c("Global_active_power", "Global_intensity")
df_normal_scaled <- scale(df_normal_mondays_time[, features0])
df_normal_scaled <- scale(df_normal_mondays_time[, features0])
df_normal_scaled <- data.frame(df_normal_scaled)
View(df_normal_scaled)

response_normal <- list(
  df_normal_scaled$Global_active_power ~ 1,
  df_normal_scaled$Global_intensity ~ 1
)
family_normal <- list(
  gaussian(),
  gaussian()
)

ntimes_normal <- nrow(df_normal_scaled)
model_normal <- depmix(response = response_normal, data = df_normal_scaled, nstates = 20, ntimes = ntimes_normal, family = family_normal)

logs_vec <- vector()
BIC_vec <- vector()
fit_normal <- fit(model_normal)
summary(fit_normal)
print(fit_normal)
logs_vec <- append(logs_vec, logLik(fit_normal))
BIC_vec <- append(BIC_vec, BIC(fit_normal))


#Anomly detection
#Anomly1 detection
df_anomaly1 <- read.table("Dataset_with_Anomalies_1.txt", sep =',', header = TRUE)
df_anomaly1

df_anomaly1 <- df_anomaly1[complete.cases(df_anomaly1),]

df_anomaly1$DateTime <- as.POSIXct(paste(df_anomaly1$Date, df_anomaly1$Time), format = "%d/%m/%Y %H:%M:%S")
df_anomaly1$DaysOfWeek <- weekdays(df_anomaly1$DateTime)

df_anomaly1_mondays <- df_anomaly1 %>% filter(df_anomaly1$DaysOfWeek == "Monday")
df_anomaly1_mondays_time <- df_anomaly1_mondays %>% filter((Time >= "06:00:00") & (Time <= "10:00:00"))
df_anomaly1_mondays_time <- na.omit(df_anomaly1_mondays_time)


nan_rows_anomaly1 <- apply(df_anomaly1_mondays_time, 1, function(x) any(is.nan(x)))
inf_rows_anomaly1 <- apply(df_anomaly1_mondays_time, 1, function(x) any(is.infinite(x)))

df_anomaly1_mondays_time <- df_anomaly1_mondays_time[complete.cases(df_anomaly1_mondays_time),]

features1 <- c("Global_active_power", "Global_intensity")
df_anomaly1_scaled <- scale(df_anomaly1_mondays_time[, features1])
df_anomaly1_scaled <- scale(df_anomaly1_mondays_time[, features1])
df_anomaly1_scaled <- data.frame(df_anomaly1_scaled)
View(df_anomaly1_scaled)

response_anomaly1 <- list(
  df_anomaly1_scaled$Global_active_power ~ 1,
  df_anomaly1_scaled$Global_intensity ~ 1
)
family_anomaly1 <- list(
  gaussian(),
  gaussian()
)

ntimes_anomaly1 <- rep(c(241),each= 50)
model_anomaly1 <- depmix(response = response_anomaly1, data = df_anomaly1_scaled, nstates = 20, ntimes = ntimes_anomaly1, family = family_anomaly1)

BIC_anomaly <- vector()
logs_anomaly <- vector()
fit_anomaly1 <- fit(model_anomaly1)
summary(fit_anomaly1)
print(fit_anomaly1)
logs_vec <- append(logs_vec, logLik(fit_anomaly1))
BIC_vec <- append(BIC_vec, BIC(fit_anomaly1))


#Anomly2 detection
df_anomaly2 <- read.table("Dataset_with_Anomalies_2.txt", sep =',', header = TRUE)
df_anomaly2

df_anomaly2 <- df_anomaly2[complete.cases(df_anomaly2),]

df_anomaly2$DateTime <- as.POSIXct(paste(df_anomaly2$Date, df_anomaly2$Time), format = "%d/%m/%Y %H:%M:%S")
df_anomaly2$DaysOfWeek <- weekdays(df_anomaly2$DateTime)

df_anomaly2_mondays <- df_anomaly2 %>% filter(df_anomaly2$DaysOfWeek == "Monday")
df_anomaly2_mondays_time <- df_anomaly2_mondays %>% filter((Time >= "06:00:00") & (Time <= "10:00:00"))
df_anomaly2_mondays_time <- na.omit(df_anomaly2_mondays_time)


nan_rows_anomaly2 <- apply(df_anomaly2_mondays_time, 1, function(x) any(is.nan(x)))
inf_rows_anomaly2 <- apply(df_anomaly2_mondays_time, 1, function(x) any(is.infinite(x)))

df_anomaly2_mondays_time <- df_anomaly2_mondays_time[complete.cases(df_anomaly2_mondays_time),]

features2 <- c("Global_active_power", "Global_intensity")
df_anomaly2_scaled <- scale(df_anomaly2_mondays_time[, features2])
df_anomaly2_scaled <- scale(df_anomaly2_mondays_time[, features2])
df_anomaly2_scaled <- data.frame(df_anomaly2_scaled)
View(df_anomaly2_scaled)

response_anomaly2 <- list(
  df_anomaly2_scaled$Global_active_power ~ 1,
  df_anomaly2_scaled$Global_intensity ~ 1
)
family_anomaly2 <- list(
  gaussian(),
  gaussian()
)

ntimes_anomaly2 <- rep(c(241),each= 50)
model_anomaly2 <- depmix(response = response_anomaly2, data = df_anomaly2_scaled, nstates = 20, ntimes = ntimes_anomaly2, family = family_anomaly2)

logs_anomaly2 <- vector()
fit_anomaly2 <- fit(model_anomaly2)
summary(fit_anomaly2)
print(fit_anomaly2)
logs_vec <- append(logs_vec, logLik(fit_anomaly2))
BIC_vec <- append(BIC_vec, BIC(fit_anomaly2))


#Anomly3 detection
df_anomaly3 <- read.table("Dataset_with_Anomalies_3.txt", sep =',', header = TRUE)
df_anomaly3

df_anomaly3 <- df_anomaly3[complete.cases(df_anomaly3),]

df_anomaly3$DateTime <- as.POSIXct(paste(df_anomaly3$Date, df_anomaly3$Time), format = "%d/%m/%Y %H:%M:%S")
df_anomaly3$DaysOfWeek <- weekdays(df_anomaly3$DateTime)

df_anomaly3_mondays <- df_anomaly3 %>% filter(df_anomaly3$DaysOfWeek == "Monday")
df_anomaly3_mondays_time <- df_anomaly3_mondays %>% filter((Time >= "06:00:00") & (Time <= "10:00:00"))
df_anomaly3_mondays_time <- na.omit(df_anomaly3_mondays_time)


nan_rows_anomaly3 <- apply(df_anomaly3_mondays_time, 1, function(x) any(is.nan(x)))
inf_rows_anomaly3 <- apply(df_anomaly3_mondays_time, 1, function(x) any(is.infinite(x)))

df_anomaly3_mondays_time <- df_anomaly3_mondays_time[complete.cases(df_anomaly3_mondays_time),]

feature3 <- c("Global_active_power", "Global_intensity")
df_anomaly3_scaled <- scale(df_anomaly3_mondays_time[, feature3])
df_anomaly3_scaled <- scale(df_anomaly3_mondays_time[, feature3])
df_anomaly3_scaled <- data.frame(df_anomaly3_scaled)
View(df_anomaly3_scaled)

response_anomaly3 <- list(
  df_anomaly3_scaled$Global_active_power ~ 1,
  df_anomaly3_scaled$Global_intensity ~ 1
)
family_anomaly3 <- list(
  gaussian(),
  gaussian()
)

ntimes_anomaly3 <- rep(c(241),each= 50)
model_anomaly3 <- depmix(response = response_anomaly3, data = df_anomaly3_scaled, nstates = 20, ntimes = ntimes_anomaly3, family = family_anomaly3)

logs_anomaly3 <- vector()
fit_anomaly3 <- fit(model_anomaly3)
summary(fit_anomaly3)
print(fit_anomaly3)
logs_vec <- append(logs_vec, logLik(fit_anomaly3))
BIC_vec <- append(BIC_vec, BIC(fit_anomaly3))


#logs_vec <- data.frame(logs_vec)

BIC_anomaly <- data.frame(BIC_anomaly)
name_of_data <- c("original data","anomaly 1", "anomaly 2", "anomaly 3")

table3 <- data.frame(name_of_data, logs_vec, BIC_vec)