#4/19/2024:
#This file was made while recreating figures in the final revision stage
#of the thesis after defense.

#clear memory
rm(list = ls())

#set working directory to r-code in the GitHub repo
setwd("C:/Users/T470s/Documents/GitHub/ma_thesis_23-24/r-code")

#(pos-summary; name of the data spreadsheet and the xquery file)
#nu-table was a naming convention used during the analysis stage
nu.table <- read.csv("./../Data-output/var-info/pos-summary-3.15.24.csv", stringsAsFactors = TRUE, comment.char = "#", quote = "")

#using ggplot2 library for correlation
library(ggplot2)

#store the divisions of the text into variables. Each string in the vectors is a short title used in the WORK column of nu.table. colloquial.nosat is an artifact of the removal of the satires.
colloquial.nosat <- c("Pere", "Petr Speech", "Att", "Fab")
poetry <-  c("Elegie", "Elegia", "Sati", "Aen", "Met", "Carm", "Amor")
prose.noncoll <- c("(In Cat|Again)", "Hist", "Res", "Aug", "Ann", "Cael", "Gall", "off", "Vul", "agri")
prose <- c("Pere", "(In Cat|Again)", "Hist", "Res", "Aug", "Ann", "Cael", "Gall", "Att", "off", "Vul", "agri")

#FILE EXPORT SETTINGS
width <- 580;
height <- 460;

#EDITORIAL DECISIONS AFFECTING ALL GRAPHS:
#-sentence length (y axis) is clipped at 100

#PARTICIPLES (fig 3-1)

#THIS FIRST GRAPH IS COLLOQUIAL + PARTCIPLES (NO EGERIA) each of the following graphs proceeds this way:
# 1) gets the relevant work codes (the short names in the left column of nu.table) in $cortests
# 2) gets spearman's rho results in the variable $spearman; the type (PREPOSITION, PRONOUN, PARTICIPLE) must be specified here, as well as in the next step
# 3) creates the plot from the nu.table data, adds Spearman's rho to the graph label. The field (PREPOSITION etc.) must be specified in the aes function on the x-axis
# 4) save the graph to a file

#SOME OTHER EDITORIAL DECISIONS:
#-participles capped at 60 to eliminate outliers, BOTH in colloquial and non-colloquial

#colloquial participles fig 3-1 1

png(filename = "C:/Users/T470s/Documents/2024-Spring/Thesis/Ch. 3 edits/Correlation edits/fig 3-1 1.png")
cortests <- c("Petr Speech", "Fab", "Att"); set.seed(sum(utf8ToInt("stuffandthings")));spearman <- cor.test(x=jitter(nu.table$PARTICIPLE[nu.table$WORK %in% cortests]), y=jitter(nu.table$SENTLEN[nu.table$WORK %in% cortests]), method="spearman"); ggplot(nu.table[nu.table$WORK %in% cortests,], aes(x=jitter(PARTICIPLE, factor = 2), y=jitter(SENTLEN))) + geom_point() + xlim(c(0, 60)) + ylim(c(0,100)) + labs(title=paste("Participles in colloquial (no Egeria) texts \nvs. sentence lengths. Spearman:", as.character(round(spearman$estimate, 2)))) + geom_smooth(method="lm") + xlab("Count of participles") + ylab("Sentence length") + theme(text = element_text(size = 18)); 
dev.off()


#participial phrases in non-colloquial texts \nvs. sentence lengths fig 3-1 2
png(filename = "C:/Users/T470s/Documents/2024-Spring/Thesis/Ch. 3 edits/Correlation edits/fig 3-1 2.png")
cortests <- c(prose.noncoll, poetry); set.seed(sum(utf8ToInt("stuffandthings"))); spearman <- cor.test(x=jitter(nu.table$PARTICIPLE[nu.table$WORK %in% cortests]), y=jitter(nu.table$SENTLEN[nu.table$WORK %in% cortests]), method="spearman"); ggplot(nu.table[nu.table$WORK %in% cortests,], aes(x=jitter(PARTICIPLE, factor = 2), y=jitter(SENTLEN))) + geom_point() + xlim(c(0, 60)) + ylim(c(0,100)) + labs(title=paste("Participial phrases in non-colloquial texts \nvs. sentence lengths. Spearman:", as.character(round(spearman$estimate, 2)))) + geom_smooth(method="lm") + xlab("Count of participles") + ylab("Sentence length") + theme(text = element_text(size = 18));
dev.off()

#PREPOSITIONS (fig 3-2)

#editorial decisions:
#prepositional phrases (x axis) clipped to 30, although for poetry I clipped it to 10

#prepositions in prose (colloquial and non-colloquial) \nvs. sentence lengths fig 3-2 1
png(filename = "C:/Users/T470s/Documents/2024-Spring/Thesis/Ch. 3 edits/Correlation edits/fig 3-2 1.png")
cortests <- c(prose.noncoll); set.seed(sum(utf8ToInt("stuffandthings"))); spearman <- cor.test(x=jitter(nu.table$PREPOSITION[nu.table$WORK %in% cortests]), y=jitter(nu.table$SENTLEN[nu.table$WORK %in% cortests]), method="spearman"); ggplot(nu.table[nu.table$WORK %in% cortests,], aes(x=jitter(PREPOSITION, factor = 2), y=jitter(SENTLEN))) + geom_point() + xlim(c(0, 30)) + ylim(c(0,100)) + labs(title=paste("Prepositional phrases in prose \nvs. sentence lengths. Spearman:", as.character(round(spearman$estimate, 2)))) + geom_smooth(method="lm") + xlab("Count of prepositional phrases") + ylab("Sentence length") + theme(text = element_text(size = 18));
dev.off()

#prepositional phrases in poetry \nvs. sentence lengths fig 3-2 2
png(filename = "C:/Users/T470s/Documents/2024-Spring/Thesis/Ch. 3 edits/Correlation edits/fig 3-2 2.png")
cortests <- c(poetry); set.seed(sum(utf8ToInt("stuffandthings"))); spearman <- cor.test(x=jitter(nu.table$PREPOSITION[nu.table$WORK %in% cortests]), y=jitter(nu.table$SENTLEN[nu.table$WORK %in% cortests]), method="spearman"); ggplot(nu.table[nu.table$WORK %in% cortests,], aes(x=jitter(PREPOSITION, factor = 2), y=jitter(SENTLEN))) + geom_point() + xlim(c(0, 10)) + ylim(c(0,100)) + labs(title=paste("Prepositional phrases in poetry \nvs. sentence lengths. Spearman:", as.character(round(spearman$estimate, 2)))) + geom_smooth(method="lm") + xlab("Count of prepositional phrases") + ylab("Sentence length") + theme(text = element_text(size = 18)); 
dev.off()

#prepositional phrases in colloquial texts \nvs. sentence lengths fig 3-2 3
png(filename = "C:/Users/T470s/Documents/2024-Spring/Thesis/Ch. 3 edits/Correlation edits/fig 3-2 3.png")
cortests <- c(colloquial.nosat); set.seed(sum(utf8ToInt("stuffandthings"))); spearman <- cor.test(x=jitter(nu.table$PREPOSITION[nu.table$WORK %in% cortests]), y=jitter(nu.table$SENTLEN[nu.table$WORK %in% cortests]), method="spearman"); ggplot(nu.table[nu.table$WORK %in% cortests,], aes(x=jitter(PREPOSITION, factor = 2), y=jitter(SENTLEN))) + geom_point() + xlim(c(0, 10)) + ylim(c(0,100)) + labs(title=paste("Prepositional phrases in colloquial texts \nvs. sentence lengths. Spearman:", as.character(round(spearman$estimate, 2)))) + geom_smooth(method="lm") + xlab("Count of prepositional phrases") + ylab("Sentence length") + theme(text = element_text(size = 18)); 

dev.off()

#PRONOUNS (fig 3-3)
#editorial decisions:
#-pronouns capped at 15, there aren't really any outliers though

#Pronouns in colloquial texts \nvs. sentence lengths fig 3-3 1

png(filename = "C:/Users/T470s/Documents/2024-Spring/Thesis/Ch. 3 edits/Correlation edits/fig 3-3 1.png")
cortests <- c(colloquial.nosat); set.seed(sum(utf8ToInt("stuffandthings"))); spearman <- cor.test(x=jitter(nu.table$PRONOUN[nu.table$WORK %in% cortests]), y=jitter(nu.table$SENTLEN[nu.table$WORK %in% cortests]), method="spearman"); ggplot(nu.table[nu.table$WORK %in% cortests,], aes(x=jitter(PRONOUN, factor = 2), y=jitter(SENTLEN))) + geom_point() + xlim(c(0, 15)) + ylim(c(0,100)) + labs(title=paste("Pronouns in colloquial texts \nvs. sentence lengths. Spearman:", as.character(round(spearman$estimate, 2)))) + geom_smooth(method="lm") + xlab("Count of pronouns") + ylab("Sentence length") + theme(text = element_text(size = 18));
dev.off()

#Pronouns in poetry \nvs. sentence lengths

png(filename = "C:/Users/T470s/Documents/2024-Spring/Thesis/Ch. 3 edits/Correlation edits/fig 3-3 2.png")
cortests <- c(poetry); set.seed(sum(utf8ToInt("stuffandthings"))); spearman <- cor.test(x=jitter(nu.table$PRONOUN[nu.table$WORK %in% cortests]), y=jitter(nu.table$SENTLEN[nu.table$WORK %in% cortests]), method="spearman"); ggplot(nu.table[nu.table$WORK %in% cortests,], aes(x=jitter(PRONOUN, factor = 2), y=jitter(SENTLEN))) + geom_point() + xlim(c(0, 15)) + ylim(c(0,100)) + labs(title=paste("Pronouns in poetry \nvs. sentence lengths. Spearman:", as.character(round(spearman$estimate, 2)))) + geom_smooth(method="lm") + xlab("Count of pronouns") + ylab("Sentence length") + theme(text = element_text(size = 18));
dev.off()

#pronouns in prose \nvs. sentence lengths

png(filename = "C:/Users/T470s/Documents/2024-Spring/Thesis/Ch. 3 edits/Correlation edits/fig 3-3 3.png")
cortests <- c(prose.noncoll); set.seed(sum(utf8ToInt("stuffandthings"))); spearman <- cor.test(x=jitter(nu.table$PRONOUN[nu.table$WORK %in% cortests]), y=jitter(nu.table$SENTLEN[nu.table$WORK %in% cortests]), method="spearman"); ggplot(nu.table[nu.table$WORK %in% cortests,], aes(x=jitter(PRONOUN, factor = 2), y=jitter(SENTLEN))) + geom_point() + xlim(c(0, 15)) + ylim(c(0,100)) + labs(title=paste("Pronouns in prose \nvs. sentence lengths. Spearman:", as.character(round(spearman$estimate, 2)))) + geom_smooth(method="lm") + xlab("Count of pronouns") + ylab("Sentence length") + theme(text = element_text(size = 18)); 
dev.off()
