##Load Libraries---------------------
library(readxl) #read_excel
library(dplyr) #mutate, summarize
#library(purrr) #map
library(tidyr) #spread, gather
library(lubridate) #year(as.Date)
library(plotly) #plot_ly
library(bizdays) #is.bizdays

##Import data---------------------
CallData <- read_excel("CallData.xlsx", col_types = c("date", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "text", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "text", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric", 
                                                      "numeric", "numeric", "numeric", "numeric"))

##Clean-----------------
#Format the date column
CallData$Date <- as.Date(CallData$Date)
year(CallData$Date) <- 2019 #Year needs to be 2019 (current year), listed as 2016 in excel

#Fix the names to represent the people
dataset <- CallData
names(dataset) <- c(names(dataset)[1], 
                    paste(c("Blank", "Hours", "Calls", "Transfers", "Dial per Transfer", "Revenue", "Margin", "Margin%"),
                          sort(rep(1:(length(names(dataset)[-1])/8), 8)))
                    )

#Grab the columns of interest
dataset <- dataset[grepl('Date|Calls|Transfers|Revenue|Margin [0-9]*$|Hours', names(dataset))]

#Remove rows where date is not in 2019 or date is NA
dataset <- dataset[!(is.na(dataset$Date)|dataset$Date<=as.Date("2019-01-01")),]

#Remove rows made entirely of NAs
dataset <- dataset[rowSums(is.na(dataset)) != ncol(dataset) - 1,]

#Get the most recent data-date for later
date_updated <- max(dataset$Date)

#Create calendar for is.bizday later
cal <- create.calendar("Brazil/ANBIMA", holidaysANBIMA, weekdays=c("saturday", "sunday"))

#Gather columns into Type and Value---------------
#Create statistics of interest
df <- dataset %>% 
  gather(key = Type, value = Value, -Date) %>% 
  separate(Type, c('Type', 'Person'), " ") %>%
  mutate(Person = if_else(is.na(Person), as.numeric(0), as.numeric(Person))) %>%
  spread(key = Type, value = Value, fill = 0) %>% 
  filter(Calls > 0 & Hours > 0) %>% 
  group_by(Date, Person) %>% 
  mutate(CallsPerTransfer = as.numeric(Calls)/as.numeric(Transfers),
         RevPerTransfer = as.numeric(Revenue)/as.numeric(Transfers),
         RevPerCall = as.numeric(Revenue)/as.numeric(Calls),
         PercentMargin = as.numeric(Margin)/as.numeric(Revenue)*100) %>%
  ungroup()

df_overall <- df %>% 
  mutate(Margin = as.numeric(Margin),
         Revenue = as.numeric(Revenue)) %>% 
  group_by(Date) %>% 
  summarize(MinMargin = min(Margin/Revenue)*100,
            MaxMargin = max(Margin/Revenue)*100,
            # WesMargin = Margin[Person == 9]/Revenue[Person == 9],
            Transfers = sum(as.numeric(Transfers), na.rm = T),
            Calls = sum(as.numeric(Calls), na.rm = T),
            Revenue = sum(Revenue, na.rm = T),
            Margin = sum(Margin, na.rm = T)) %>% 
  ungroup() %>% 
  mutate(CallsPerTransfer = Calls/Transfers,
         RevPerTransfer = Revenue/Transfers,
         RevPerCall = Revenue/Calls,
         PercentMargin = Margin/Revenue*100) 

df_medians <- df %>% 
  # filter(Date >= Sys.Date() - 60) %>% 
  group_by(Date) %>% 
  summarize(CallsPerTransfer = median(CallsPerTransfer), 
            RevPerTransfer = median(RevPerTransfer),
            RevPerCall = median(RevPerCall),
            PercentMargin = median(PercentMargin))

#Holidays, Weekdays
a <- seq(as.Date(paste0(year(dataset$Date[1]), '-01-01')), max(dataset$Date), 1)
holidays <- as.Date(c('2019-01-01', '2019-01-21', '2019-05-27', '2019-07-04', '2019-09-02'))
df_days <- data_frame(Date = a) %>% 
  group_by(Date) %>% 
  summarize(Weekday = weekdays(Date),
            AroundAHoliday = if_else(sum(seq(Date - 5, Date + 5, 1) %in% holidays)>0,
                                     'Around A Holiday',
                                     'Normal'))

#Dataframe for analysis of Calls Per Transfer
df_analysis <- df_overall %>% 
  select(Date, Calls, Transfers) %>% 
  mutate(CallsPerTransfer = Calls/Transfers) %>% 
  left_join(df_days, by = c("Date" = "Date")) %>% 
  select(-Date, -Calls, -Transfers)
choices = names(df_analysis)[!names(df_analysis) %in% c("CallsPerTransfer")]

#Simple Linear Modeling For CallsPerTransfer
#Holidays
lm_holiday = lm(df_analysis$CallsPerTransfer ~ df_analysis$AroundAHoliday)
temp = gsub('df\\_analysis\\$|Weekday|AroundAHoliday', '', row.names(summary(lm_holiday)$coefficients))
df_holiday = data.frame(summary(lm_holiday)$coefficients,
                        row.names = temp)
colnames(df_holiday) = c("Estimate", 'Std. Error', 'tValue', 'Pr(>|t|)')
#Weekdays
lm_weekday = lm(df_analysis$CallsPerTransfer ~ df_analysis$Weekday)
temp = gsub('df\\_analysis\\$|Weekday|AroundAHoliday', '', row.names(summary(lm_weekday)$coefficients))
df_weekday = data.frame(summary(lm_weekday)$coefficients,
                     row.names = temp)
colnames(df_weekday) = c("Estimate", 'Std. Error', 'tValue', 'Pr(>|t|)')

#Multiple regression model for CallsPerTransfer
lm_both = lm(CallsPerTransfer ~ AroundAHoliday + Weekday, data = df_analysis)
temp = gsub('df\\_analysis\\$|Weekday|AroundAHoliday', '', row.names(summary(lm_both)$coefficients))
df_both = data.frame(summary(lm_both)$coefficients,
                     row.names = temp)
colnames(df_both) = c("Estimate", 'Std. Error', 'tValue', 'Pr(>|t|)')

#Plot 
# p <- ggplot(df_analysis, aes(x=`Transfers`)) +
#   geom_density(aes(group=`Past5`, fill=`Past5`), alpha = 0.2, position = 'identity')
# ggplotly(p)
# 
# plot_ly(data = df_analysis,
#         x = ~Transfers,
#         type = 'histogram',
#         name = ~Ind)

# ###REVENUE PER TRANSFER----------------
# rev_per_transfer <- plot_ly(data = df, #Seeing a SHARP decrease in Revenue per transfer, need to know that
#         x = ~Date, #Transfers per day has increased enough to make up for it
#         y = ~RevPerTransfer,
#         type = 'scatter',
#         mode = 'line',
#         name = 'Everyday Truth') %>% 
#   add_trace(y = mean(df$RevPerTransfer),
#             name = 'YTDAverage')
# 
# ###TRANSFERS PER DAY---------------
# transfers_per_day <- plot_ly(data = df,
#         x = ~Date,
#         y = ~Transfers,
#         type = 'scatter',
#         mode = 'lines',
#         name = 'Everyday Truth') %>% 
#   add_trace(y = mean(df$Transfers),
#             name = 'YTDMean')
# 
# ###TRANSFER RATE PER DAY-------------
# transferrate_per_day <- plot_ly(data = df,
#         x = ~Date,
#         y = ~CallsPerTransfer,
#         type = 'scatter',
#         mode = 'lines',
#         name = 'Everyday Truth') %>% 
#   add_trace(y = mean(df$CallsPerTransfer),
#             name = 'YTDMean')
# 
# ##HOUSE MARGIN ON ANY GIVEN DAY--------------
# margin_per_day <- df %>% 
#   group_by(Date) %>% 
#   summarize(`HouseMargin%` = Margin/Revenue*100) %>% 
#   plot_ly(x = ~Date,
#           y = ~`HouseMargin%`,
#           type = 'scatter',
#           mode = 'lines')
# 
# ###PROPORTION OF CALLERS AT OR ABOVE 30% MARGIN PER DAY--------------------
# df_other <- dataset %>% 
#   gather(key = Type, value = Value, -Date) %>% 
#   separate(Type, c('Type', 'Person'), "__") %>%
#   mutate(Person = if_else(is.na(Person), as.numeric(0), as.numeric(Person))) %>%
#   spread(key = Type, value = Value, fill = 0) %>% 
#   mutate(`Margin%` = as.numeric(Margin)/as.numeric(Revenue)) %>% 
#   filter(Calls > 0 & Hours > 0 & !is.na(`Margin%`) & !`Margin%` %in% c(Inf, NaN)) %>% 
#   mutate(AtLeast30 = if_else(`Margin%` >= .30, 1, 0)) %>% 
#   group_by(Date) %>% 
#   summarize(PropAt30 = sum(AtLeast30)/n())
# plot_ly(data = df_other,
#         x = ~Date,
#         y = ~PropAt30,
#         type = 'scatter',
#         mode = 'lines')
# 
# #Wes's Margins--------------
# df_wes <- dataset %>% 
#   gather(key = Type, value = Value, -Date) %>% 
#   separate(Type, c('Type', 'Person'), "__") %>%
#   mutate(Person = if_else(is.na(Person), as.numeric(0), as.numeric(Person))) %>%
#   spread(key = Type, value = Value, fill = 0) %>% 
#   filter(Date >= as.Date('2019-08-30') & Person == 9) %>% #9 = Wes past August 30th
#   mutate(`Margin%` = as.numeric(Margin)/as.numeric(Revenue)*100) 
# # plot_ly(data = df_wes,
# #         x = ~Date,
# #         y = ~`Margin%`,
# #         type = 'scatter',
# #         mode = 'lines')
# # 

  

# ###CORRELATIONS---------
# cor(dataset$Transfers, dataset$YesterdaysTransfers, use = "complete.obs")
# cor(dataset$Transfers, dataset$TwoDaysAgoTransfers, use = "complete.obs")
# 
#   filter(Date >= as.Date('2019-08-30') & Calls > 0) %>% 
#   mutate(Group = #if_else(as.numeric(Person) <= 5, 'InHouse', 
#                          if_else(as.numeric(Person) == 9, 'Wes', 'Everyone Else'))#)
# 
# #Calculate Margin Percentages By Person
# df_byperson <- dataset %>% 
#   group_by(Date, Group) %>% 
#   summarize(CallsPerTransfer = sum(as.numeric(Calls))/sum(as.numeric(Transfers))) %>% 
#   ungroup()
# plot_ly(data = df_byperson,
#         x = ~Date,
#         y = ~CallsPerTransfer,
#         name = ~Group,
#         type = 'scatter',
#         mode = 'lines')
# 
# #%>% #,
#          #`Margin%` = as.numeric(Margin)/as.numeric(Revenue)*100,
#          #MarginPerCall = as.numeric(Margin)/as.numeric(Calls)) %>%
#   filter(#!`Margin%` %in% c(Inf, -Inf, NaN) & !is.na(`Margin%`),
#          !`CallsPerTransfer` %in% c(Inf, -Inf, NaN) & !is.na(`CallsPerTransfer`)) %>% #These shouldn't exist at this point, if they do, there's an error 
#   group_by(Date, Group) %>% 
#   summarize(MedianMargin = median(`Margin%`),
#             MedianCPT = median(CallsPerTransfer),
#             MedianMPC = median(MarginPerCall)) %>% 
#   ungroup()
# 
# plot_ly(data = df_byperson,
#         x = ~Date,
#         y = ~MedianMargin,
#         type='scatter',
#         mode='lines',
#         name = ~Group)
# plot_ly(data = df_byperson,
#         x = ~Date,
#         y = ~MedianCPT,
#         type='scatter',
#         mode='lines',
#         name = ~Group)
# plot_ly(data = df_byperson,
#         x = ~Date,
#         y = ~MedianMPC,
#         type='scatter',
#         mode='lines',
#         name = ~Group)
# 
#   
# 
# summarize(ChanceOfGoal = sum(if_else(`Margin%`>=.3, 1, 0))/n(),
#             High = max(`Margin%`),
#             Low = min(`Margin%`),
#             Median = median(`Margin%`))
# 
# wes <- dataset %>% 
#   gather(key = Type, value = Value, -Date) %>% 
#   separate(Type, c('Type', 'Person'), "__") %>%
#   mutate(Person = if_else(is.na(Person), as.numeric(0), as.numeric(Person))) %>%
#   spread(key = Type, value = Value, fill = 0) %>% 
#   filter(Date >= as.Date('2019-08-30') & Calls > 0 & Person == 9) %>% 
#   mutate(Group = if_else(as.numeric(Person) <= 5, 'InHouse', 'Upwork'),
#          CallsPerTransfer = as.numeric(Calls)/as.numeric(Transfers),
#          `Margin%` = as.numeric(Margin)/as.numeric(Revenue)) %>%
#   filter(!`Margin%` %in% c(Inf, -Inf, NaN) & !is.na(`Margin%`)) 
# plot_ly(data=df_byperson,
#         x=~Date,
#         y=~Median,
#         type='scatter',
#         mode='lines',
#         name="Median") %>% 
#   add_trace(x=~Date,
#             y=~Low,
#             name='Low') %>% 
#   add_trace(x=~Date,
#             y=~High,
#             name="High") %>% 
#   add_trace(x=~Date,
#             y=.3,
#             name='Goal') %>% 
#   add_trace(data=wes,
#             x=~Date,
#             y=~`Margin%`,
#             name='Wes')
# 
# 
#   # group_by(Date, Person) %>% 
#   # mutate(`Margin%` = as.numeric(Margin)/as.numeric(Revenue)*100) %>% 
#   # ungroup() %>% 
#   # filter(!`Margin%` %in% c(-Inf, Inf, NaN) & !is.na(`Margin%`))
#   
# plot_ly(data=df_byperson,
#         x=~`Margin%`,
#         y=~CallsPerTransfer,
#         type='scatter',
#         name=~Group)
# 
# p <- ggplot(df_byperson, aes(x=`Margin%`)) +
#   geom_density(aes(group=Group, fill=Group), alpha = 0.2, position = 'identity')
# 
#       geom_histogram(aes(y = ..density..), position = 'identity', binwidth=density(df_byperson$`Margin%`)) +
#       geom_density(fill="red", alpha = 0.2)
# ggplotly(p)
# 
# 
#   group_by(Date) %>% 
#   mutate(`TotalMargin%` = sum(as.numeric(Margin), na.rm = T)/sum(as.numeric(Revenue), na.rm = T)*100,
#          `WesMargin%` = sum(as.numeric(Margin)[Person==9]/as.numeric(Revenue)[Person==9])*100) %>% 
#   group_by(Date, Person) %>% 
#   mutate(`PerPersonMargin%` = as.numeric(Margin)/as.numeric(Revenue)*100) %>% 
#   ungroup() %>% 
#   filter(!`PerPersonMargin%` %in% c(-Inf, Inf, NaN) & !is.na(`PerPersonMargin%`)) %>% 
#   group_by(Date) %>% 
#   mutate(`MedianPerPersonM%` = median(`PerPersonMargin%`))
# 
# ##Total Call Center Margin % By Day--------------
# test = df_byperson %>% 
#   ungroup() %>% 
#   select(Date, `TotalMargin%`, `MedianPerPersonM%`, `WesMargin%`, Revenue, Margin, Person) %>% 
#   unique() %>% 
#   filter(Date >= as.Date('2019-08-30') & Person == 9) %>% #I'm person 9
#   mutate(`WesTotalMargin%` = sum(as.numeric(Margin))/sum(as.numeric(Revenue))*100) %>% 
#   plot_ly(x = ~Date,
#           y = ~`TotalMargin%`,
#           type = 'scatter',
#           mode = 'lines',
#           name = 'Total As A Team') %>% 
#   add_trace(x = ~Date,
#             y = ~`MedianPerPersonM%`,
#             type = 'scatter',
#             mode = 'lines',
#             name = 'Median Per Person') %>% 
#   add_trace(x = ~Date,
#             y = ~`WesMargin%`,
#             type = 'scatter',
#             mode = 'lines',
#             name = 'Wes') %>% 
#   add_trace(x = ~Date,
#             y = 30,
#             type = 'scatter',
#             mode = 'lines',
#             name = '30% Margin Line') %>% 
#   add_trace(x = ~Date,
#             y = ~`WesTotalMargin%`,
#             type = 'scatter',
#             mode = 'lines',
#             name = "Wes's Total Margin %")
#   
# 
# ##Create By Day Total Transfer Rates Dataframe----------------------
# df_byday <- df_byperson %>% 
#   group_by(Date) %>% 
#   summarize(Calls = sum(Calls),
#             Transfers = sum(Transfers)) %>% 
#   ungroup() %>% 
#   mutate(CallsPerTransfer = round(Calls/Transfers, 2))
# 
# #Add weekdays column
# df_byday$Weekdays <- weekdays(df_byday$Date)
# 
# #Add indicator for holidays
# #Produces 100% FALSE currently
# # transfers <- transfers %>%
# #   group_by(Date) %>% 
# #   mutate(LeavingHolidayWeek = sum(!is.bizday(seq(Date-7, Date, 1))) > 0,
# #          EnteringHolidayWeek = sum(!is.bizday(seq(Date, Date+7, 1))) > 0)
# 
# ##A Look At Total Transfer Numbers Over Each Weekday--------------
# plot_ly(data = df_byday,
#         x = ~Transfers,
#         type = "histogram",
#         name = ~Weekdays,
#         alpha = .6) %>% 
#   layout(barmode = "overlay")
# 
# ##Simple Linear Modeling, Are There Differences Between Weekdays?---------
# ###NEED TO ADD HOLIDAY INDICATOR STILL###
# lm_callspertransfer = lm(df_byday$CallsPerTransfer ~ df_byday$Weekdays)
# lm_transfers = lm(df_byday$Transfers ~ df_byday$Weekdays)
# summary(lm_transfers)
# summary(lm_callspertransfer)
# 
# ##A Look At Transfer Rates This Year--------
# #A look by day
# df_byday %>% 
#   ungroup() %>% 
#   mutate(TransfersPerCall = Transfers/Calls) %>% 
#   plot_ly(x = ~Date,
#           y = ~TransfersPerCall,
#           type = 'scatter',
#           mode = 'lines',
#           text = ~paste0('Calls: ', Calls,
#                         '\nTransfers: ', Transfers))
# #A look by month
# df_byday %>% 
#   group_by(month(Date)) %>% 
#   summarize(CallsPerTransfer = round(sum(Transfers)/sum(Calls), 2)) %>% 
#   plot_ly(x = ~`month(Date)`,
#           y = ~CallsPerTransfer,
#           type = 'scatter',
#           mode = 'lines')
# 
# # #A look by day, by "person"
# # plot_ly(data = df_byperson,
# #         x = ~Date,
# #         y = ~CallsPerTransfer,
# #         name = ~Person,
# #         type = 'scatter',
# #         mode = 'lines',
# #         text = ~paste0('Calls: ', Calls,
# #                        '\nTransfers: ', Transfers))






