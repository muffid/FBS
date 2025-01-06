#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#define EXPERT_MAGIC 123456 

int EMA_20;
int EMA_50;
int EMA_100;
int EMA_200;
int EMA_21;
int EMA_55;
string symbol;
double bid;
double ask;
double ema20Values[];
double ema50Values[];
double ema100Values[];
double ema200Values[];
double ema21Values[];
double ema55Values[];
double higherHigh;
double lowerLow;
double openPrice,highPrice,lowPrice,closePrice;
double arrEmaTrends[4];
bool initTicking = true;
string trendNow = "";
bool pipValidity;
int counter = 0;


int OnInit(){
  return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){
}

void OnTick(){
  openPrice  = iOpen(symbol, PERIOD_CURRENT, 0);
  highPrice  = iHigh(symbol, PERIOD_CURRENT, 0);
  lowPrice   = iLow(symbol, PERIOD_CURRENT, 0);
  closePrice = iClose(symbol, PERIOD_CURRENT, 0);
  EMA_20 = iMA(Symbol(), PERIOD_CURRENT,20, 0, MODE_EMA, PRICE_CLOSE);
  EMA_50 = iMA(Symbol(), PERIOD_CURRENT, 50, 0, MODE_EMA, PRICE_CLOSE);
  EMA_100 = iMA(Symbol(), PERIOD_CURRENT,100, 0, MODE_EMA, PRICE_CLOSE);
  EMA_200 = iMA(Symbol(), PERIOD_CURRENT, 200, 0, MODE_EMA, PRICE_CLOSE);
  EMA_21 = iMA(Symbol(), PERIOD_CURRENT,22, 0, MODE_EMA, PRICE_CLOSE);
  EMA_55 = iMA(Symbol(), PERIOD_CURRENT, 55, 0, MODE_EMA, PRICE_CLOSE);
  CopyBuffer(EMA_20,0,0,2,ema20Values);
  CopyBuffer(EMA_50,0,0,2,ema50Values);
  CopyBuffer(EMA_100,0,0,2,ema100Values);
  CopyBuffer(EMA_200,0,0,2,ema200Values);
  CopyBuffer(EMA_21,0,0,2,ema21Values);
  CopyBuffer(EMA_55,0,0,2,ema55Values);
  arrEmaTrends[0] = ema20Values[1];   
  arrEmaTrends[1] = ema50Values[1];
  arrEmaTrends[2] = ema100Values[1];
  arrEmaTrends[3] = ema200Values[1];
  bid = SymbolInfoDouble(symbol, SYMBOL_BID);
  ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
  trendNow =  whatTrends(arrEmaTrends);
  pipValidity = isPipGood(ema21Values[1],ema55Values[1]);
  if(
      trendNow != "Unconfirm" 
      && isOhlcNotCrossingEma(openPrice,highPrice,lowPrice,ema21Values[1],trendNow)
      &&  pipValidity == true 
     ){
      if( trendNow == "Bullish" && bid <= NormalizeDouble(ema21Values[1],5)){

         Print("Valid ",trendNow);
         BuyInstant("EURUSD", 0.1, bid);  
      }
      if( trendNow == "Bearish" && bid >= NormalizeDouble(ema21Values[1],5)){
    
         Print("Valid ",trendNow);
      }
  }else{ 
    // Print("Inv");
   
  }
}

string whatTrends(double &arrData[]){
  if(arrData[0]<arrData[1] && arrData[1]<arrData[2] && arrData[2]<arrData[3]){
    return "Bearish";
  }
  if(arrData[0]>arrData[1] && arrData[1]>arrData[2] && arrData[2]>arrData[3]){
    return "Bullish";
  }
  return "Unconfirm";
}

bool isPipGood(double ema21, double ema55){
  if(ema21 < ema55){
    if((MathAbs(ema55 - ema21) / 0.0001)>=10){
      return true;
    }
  }
  if(ema21 > ema55){
    if((MathAbs(ema21 - ema55) / 0.0001)>=10){
      return true;
    }
  }
  return false;
}

bool isPriceNotCross21(string trend, double ema21, double bidPrice, double askPrice){
  if(trend == "Bearish"){
    if(bidPrice < ema21){
      return true;
    }
  }

  if(trend == "Bullish"){
    if(askPrice > ema21){
      return true;
    }
  }
  return false;
}

bool isOhlcNotCrossingEma(double openP, double highP, double lowP, double ema21,string trend){
  if(
    (trend == "Bearish" && openP < ema21 && highP < ema21 && lowP < ema21 ) 
    ||
    (trend == "Bullish" && openP > ema21 && highP > ema21 && lowP > ema21 ) ){
    return true;
  }
  return false;
}

void makeTransaction(string trend){
  Print("Order Created ",trend);
}

// Function to place an instant execution buy order

void BuyInstant(string symbol, double volume, double price) {


  MqlTradeRequest request={};
  MqlTradeResult  result={};

   request.action   =TRADE_ACTION_DEAL;                     // type of trade operation
   request.symbol   =Symbol();                              // symbol
   request.volume   =0.1;                                   // volume of 0.1 lot
   request.type     =ORDER_TYPE_BUY;                        // order type
   request.price    =SymbolInfoDouble(Symbol(),SYMBOL_ASK); // price for opening
   request.deviation=5;                                     // allowed deviation from the price
   request.magic    =EXPERT_MAGIC;                          // MagicNumber of the order

   if(!OrderSend(request,result))
      PrintFormat("OrderSend error %d",GetLastError());     // if unable to send the request, output the error code

   PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);


}

