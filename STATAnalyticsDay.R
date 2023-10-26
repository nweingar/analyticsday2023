library(tidyverse)
library(dplyr)

summary(pulse2023_puf_60$DOWN)
#Down Frequency Before
down_table <- table(pulse2023_puf_60$DOWN)
down_table
barplot(down_table, xlab = "Frequency of Feeling Depressed (1-4)",
                    main = "Figure 1: Bar Chart of the Down Variable")

#Down Frequency After
#if(pulse2023_puf_60$DOWN > 0){
  down_table2 <- table(pulse2023_puf_60[which(pulse2023_puf_60$DOWN >0),]$DOWN)
down_table2
barplot(down_table2, xlab = "Frequency of Feeling Depressed (1-4)",
        main = "Figure 2: Bar Chart of the Down Variable with Coded Values Excluded")

summary(pulse2023_puf_60$DOWN)
# Before
anxiety_table <- table(pulse2023_puf_60$ANXIOUS)
anxiety_table
barplot(down_table, xlab = "Frequency of Feeling Anxiety (1-4)",
        main = "Figure 3: Bar Chart of the Anxious Variable")
#461+8778+25743+19870+6164+7814
#637+8778+34465+16305+4251+4394

#Down Frequency After
#if(pulse2023_puf_60$DOWN > 0){
anxiety_table2 <- table(pulse2023_puf_60[which(pulse2023_puf_60$ANXIOUS >0),]$ANXIOUS)
anxiety_table2
barplot(down_table2, xlab = "Frequency of Feeling Anxiety (1-4)",
        main = "Figure 4: Bar Chart of the Anxious Variable with Coded Values Excluded")

eeduc_table <- table(pulse2023_puf_60$EEDUC)
eeduc_table
barplot(eeduc_table, xlab = "Educational Attainment",
        main = "Figure 5: Bar Chart of the EEDUC Variable")

genderbirth_table <- table(pulse2023_puf_60$EGENID_BIRTH)
genderbirth_table
barplot(genderbirth_table, xlab = "Gender at Birth",
        main = "Figure 6: Bar Chart of the EGENID_BIRTH Variable")

psych::describe(pulse2023_puf_60$THHLD_NUMPER)
hist(pulse2023_puf_60$THHLD_NUMPER, xlab = "Total Number of People in a Household",
     main = "Figure 7: Histogram of the THHLD_NUMPER Variable", xlim=range(1,10))

subset52 = subset(pulse2022_puf_52, select = c("SCRAM", "WEEK", "DOWN", "ANXIOUS"))
subset54 = subset(pulse2023_puf_54, select = c("SCRAM", "WEEK", "DOWN", "ANXIOUS"))
subset56 = subset(pulse2023_puf_56, select = c("SCRAM", "WEEK", "DOWN", "ANXIOUS"))
subset58 = subset(pulse2023_puf_58, select = c("SCRAM", "WEEK", "DOWN", "ANXIOUS"))
subset60 = subset(pulse2023_puf_60, select = c("SCRAM", "WEEK", "DOWN", "ANXIOUS"))

subsets <- dplyr::bind_rows(subset52, subset54, subset56, subset58, subset60, id=NULL)
subsets <- filter(subsets, DOWN > 0)
subsets <- filter(subsets, ANXIOUS > 0)

subsets$DOWN <- factor(subsets$DOWN)
ggplot(data=subsets, aes(fill=DOWN, x=WEEK)) +
  geom_bar(position="fill", stat="count") +
  scale_x_continuous(breaks=seq(52,60,by=2))

subsets$ANXIOUS <- factor(subsets$ANXIOUS)
ggplot(data=subsets, aes(fill=ANXIOUS, x=WEEK)) +
  geom_bar(position="fill", stat="count") +
  scale_x_continuous(breaks=seq(52,60,by=2))

freq_table_down <- table(subsets$WEEK, subsets$DOWN)
freq_table_anx <- table(subsets$WEEK, subsets$ANXIOUS)

freq_table_down
freq_table_anx 

prop_test_down <- prop.test(x=c(17904+4742+4989, 16295+4248+4387), n=c(33936+17904+4742+4989, 34427+16295+4248+4387))
prop_test_down

prop_test_anx <- prop.test(x=c(21364+6718+8521, 19800+6149+7795), n=c(24968+21364+6718+8521, 25613+19800+6149+7795))
prop_test_anx











