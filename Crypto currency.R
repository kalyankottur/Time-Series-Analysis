install.packages("tseries")
install.packages("TSA")
install.packages("forecast")
library("ggplot2")
library(tseries)
library(TSA)
library(forecast)
data_btc <- read.csv("C:/Users/kalya/Desktop/Masters/MA 5781Time series Analysis/bitcoin_price.csv"
                     ,sep=",",header=TRUE,stringsAsFactors = FALSE)
data_btcash <- read.csv("C:/Users/kalya/Desktop/Masters/MA 5781Time series Analysis/bitcoin_cash_price.csv"
                        ,sep=",",header=TRUE,stringsAsFactors = FALSE)
data_eth <- read.csv("C:/Users/kalya/Desktop/Masters/MA 5781Time series Analysis/ethereum_price.csv"
                     ,sep=",",header=TRUE,stringsAsFactors = FALSE)
data_ltc <- read.csv("C:/Users/kalya/Desktop/Masters/MA 5781Time series Analysis/litecoin_price.csv"
                     ,sep=",",header=TRUE,stringsAsFactors = FALSE)
data_xrp <- read.csv("C:/Users/kalya/Desktop/Masters/MA 5781Time series Analysis/ripple_price.csv"
                     ,sep=",",header=TRUE,stringsAsFactors = FALSE)
data_dash <- read.csv("C:/Users/kalya/Desktop/Masters/MA 5781Time series Analysis/dash_price.csv"
                      ,sep=",",header=TRUE,stringsAsFactors = FALSE)
#plot(data_eth$Date,data_eth$Close,type="h")
#install.packages("anytime")
#library("anytime")
data_btc$Date <- as.Date(data_btc$Date,format="%b%d,%Y")
data_btcash$Date <- as.Date(data_btcash$Date,format="%b%d,%Y")
data_eth$Date <- as.Date(data_eth$Date,format="%b%d,%Y")
data_ltc$Date <- as.Date(data_ltc$Date,format="%b%d,%Y")
data_xrp$Date <- as.Date(data_xrp$Date,format="%b%d,%Y")
data_dash$Date <- as.Date(data_dash$Date,format="%b%d,%Y")
str(data_btc)
#plot(data_eth$Date,data_eth$Close,type="l",col="red")
data <- rbind(data_btc,data_btcash,data_eth,data_ltc,data_xrp,data_dash)
data$coin <- c(rep("BTC",nrow(data_btc)),rep("BCH",nrow(data_btcash)),rep("ETH",nrow(data_eth)),rep("LTC",nrow(data_ltc)),rep("XRP",nrow(data_xrp)),rep("DASH",nrow(data_dash)))
vol <- gsub(",","",data_btc$Volume)
data_btc$Volume <- as.numeric(vol)
market <- gsub(",","",data$Market.Cap)
data$Market.Cap <- as.numeric(market)
data_na <- apply(data,1,function(x){any(is.na(x))})
new_data <- data[!data_na,]
ggplot(data=data_btc, aes(x=Date, y=Close)) + geom_line()
ggplot(data=new_data, aes(x=Date, y=Close, col=coin)) + geom_line()
#write.csv(data,"C:/Users/admin/Documents/ma5781/cryptodata.csv")
###### with linear time trend #########
model <- lm(data_btc$Close~time(data_btc$Close))
summary(model)
plot(data_btc$Close,type="l",col="red")
abline(model)
close.ts <- ts(data_btc[1760:1,5],frequency=365.25,start=c(2013.326,4,28))
#close.ts <- ts(data_btc[1517:1,5],frequency=365.25,start=c(2013,12,27))
#plot(close.ts)
dec <- decompose(close.ts)
plot(dec)
adf.test(close.ts)
pp.test(close.ts)
plot(diff(close.ts,lag=1),main="Difference of close price of Bitcoin")
diff_close.ts <- diff(close.ts,lag=1)
acf(diff_close.ts)
pacf(diff_close.ts)
eacf(diff_close.ts,ar.max=13,ma.max=13)
adf.test(diff(close.ts))
pp.test(diff(close.ts))
plot(armasubsets(y=diff_close.ts,nar=20,nma=20,y.name='test',ar.method='ols'),scale="AIC")
plot(armasubsets(y=diff_close.ts,nar=20,nma=20,y.name='test',ar.method='ols'),scale="BIC")
auto.arima(close.ts)
percent <- diff(close.ts)/lag(close.ts)
plot(percent,main="Relative change of closing price of Bitcoin")
adf.test(percent)
acf(percent)
pacf(percent)
log <- log(close.ts) ####not stationary
plot(log,main="Logarithm of closing price of Bitcoin")
adf.test(log)
diff_log <- diff(log)*100
plot(diff_log,main="Difference in logs of closing price of Bitcoin") ##Compound returns
adf.test(diff_log)
pp.test(diff_log)
acf(diff_log)
pacf(diff_log)
eacf(diff_log)
plot(armasubsets(y=diff_log,nar=13,nma=13,y.name='test',ar.method='ols'),scale="AIC")
plot(armasubsets(y=diff_log,nar=13,nma=13,y.name='test',ar.method='ols'),scale="BIC")
m1 <- Arima(log,method="ML",c(5,1,13))
m2 <- Arima(log,method="ML",c(11,1,13))
m3 <- Arima(log,method="ML",c(6,1,0))
m4 <- Arima(log,method="ML",c(0,1,1))
##Random walk with drift
Arima(log,c(0,1,0),xreg=(1:length(log)))
##Least square estimates on log transformed and difference of log transformed data
lm(log~time(log))
lm(diff_log~time(diff_log))
#####Model diagnostics
plot(residuals(m1),type='h',ylab='Standardized Residuals')
qqnorm(residuals(m1)); qqline(residuals(m1))
hist(diff_log)
shapiro.test(residuals(m1))
####gBox(m1)
Box.test((residuals(m1))^2, lag = 20, type = "Ljung-Box")
ar.yw(diff_log,order.max=6,demean=T,intercept=F)
##To forecast the log transformed data for the next two months
predx=predict(m2,n.ahead=60)
pr=predx$pred
uci=pr+2*predx$se
lci=pr-2*predx$se
ymin=min(c(as.vector(lci),log))-.1
ymax=max(c(as.vector(uci),log))+.1
plot(log,ylim=c(ymin,ymax),main="Log of Bitcoin closing prices",type='l')
lines(pr,col=2)
lines(uci,col=3)
lines(lci,col=3)
## In the original scale..
plot(exp(log),ylab="Closing price",xlab="Time",main="Forecast of Closing price of Bitcoin using ARIMA(11,1,13)",ylim=c(exp(ymin),exp(ymax)))
lines(exp(pr),col=2)
lines(exp(uci),col=3)
lines(exp(lci),col=3)