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

int totalPosition = 0;



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
   
        if(isNoPosition(Symbol())){
          double pipDistance = getDistance(SymbolInfoDouble(Symbol(),SYMBOL_ASK),ema55Values[1]);
          double tpPrice = getTpPrice("long",SymbolInfoDouble(Symbol(),SYMBOL_ASK),pipDistance);
          placeInstantOrder("long",ema55Values[1],tpPrice);
        }
      }
      if( trendNow == "Bearish" && bid >= NormalizeDouble(ema21Values[1],5)){
         if(isNoPosition(Symbol())){
          double pipDistance = getDistance(SymbolInfoDouble(Symbol(),SYMBOL_ASK),ema55Values[1]);
          double tpPrice = getTpPrice("short",SymbolInfoDouble(Symbol(),SYMBOL_ASK),pipDistance);
          placeInstantOrder("short",ema55Values[1],tpPrice);
        }
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

double getDistance(double openPrice, double ema55Val){
  double point_size = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
  double pip_diff = (openPrice - ema55Val) / point_size;

  return MathAbs(pip_diff); // Return the absolute pip difference
}

double getTpPrice(string position, double open_price, int pip_distance){
   // Mendapatkan nilai 1 pip dari simbol
   double point_size = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int pip_multiplier = (int)(1 / point_size / 10); // Menentukan faktor pengali pip

   // Menghitung jarak TP dalam nilai harga
   double tp_distance = pip_distance * point_size * pip_multiplier;

   // Menentukan harga TP berdasarkan jenis posisi
   double tp_price;
   if (position == "long")
   {
      tp_price = open_price + tp_distance;
   }
   else
   {
      tp_price = open_price - tp_distance;
   }

   return tp_price;
}

bool placeInstantOrder(string posisi,double slPrice, double tpPrice) {
  MqlTradeRequest request={};
  MqlTradeResult  result={};

  if(posisi == "long"){
    request.type     =ORDER_TYPE_BUY;                       
    request.price    =SymbolInfoDouble(Symbol(),SYMBOL_ASK);
  }else{
    request.type     =ORDER_TYPE_SELL;                       
    request.price    =SymbolInfoDouble(Symbol(),SYMBOL_BID);
  }
  request.action   =TRADE_ACTION_DEAL;                     // type of trade operation
  request.symbol   =Symbol();                              // symbol
  request.volume   =0.1;                                   // volume of 0.1 lot
  request.sl       =slPrice;
  request.tp       =tpPrice;
  request.deviation=5;                                     // allowed deviation from the price
  request.magic    =EXPERT_MAGIC;                          // MagicNumber of the order

  if(!OrderSend(request,result)){

      PrintFormat("OrderSend error %d",GetLastError()); 
       PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
      return false;
  }
  return true;
}

bool isNoPosition(string pair){
   int total=PositionsTotal(); 
   for(int i=0; i<total; i++) 
     { 
      //--- get position symbol by i loop index 
      ResetLastError(); 
      string symbol=PositionGetSymbol(i); 
       
      //--- if the position symbol is successfully received, then the position at the i index becomes selected automatically 
      //--- and we can obtain its properties using PositionGetDouble, PositionGetInteger and PositionGetString 
      if(symbol == pair ) 
        { 
          return false;
        //  ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE); 
        //  PrintFormat("Position symbol at index %d: %s, position type: %s", i, symbol, StringSubstr(EnumToString(type), 14)); 

        }
       
  
  }
   return true;
}


