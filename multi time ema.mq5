//+------------------------------------------------------------------+
//|                                               multi time ema.mq5 |
//|                                                     yin zhanpeng |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "yin zhanpeng"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>

int handle_trend_ma_fast;
int handle_trend_ma_slow;

int handle_ma_fast;
int handle_ma_medium;
int handle_ma_slow;

CTrade trade;
input int magic_num = 1;   // magic number
input double lot = 0.05;

int OnInit()
  {
  
  
   trade.SetExpertMagicNumber(magic_num);
   
      
   handle_trend_ma_fast = iMA(_Symbol,PERIOD_H1,8, 0, MODE_EMA, PRICE_CLOSE);
   handle_trend_ma_slow = iMA(_Symbol,PERIOD_H1,20, 0, MODE_EMA, PRICE_CLOSE);
   
   handle_ma_fast = iMA(_Symbol, PERIOD_M5, 8, 0, MODE_EMA, PRICE_CLOSE);
   handle_ma_medium = iMA(_Symbol, PERIOD_M5, 13, 0, MODE_EMA, PRICE_CLOSE);
   handle_ma_slow = iMA(_Symbol, PERIOD_M5, 21, 0, MODE_EMA, PRICE_CLOSE);
   
   
   
   return(INIT_SUCCEEDED);
   
  }

void OnDeinit(const int reason)
  {

   
  }

void OnTick()
  {

   double ma_trendfast[],ma_trendslow[];
   CopyBuffer(handle_trend_ma_fast, 0, 0, 1, ma_trendfast);
   CopyBuffer(handle_trend_ma_slow, 0, 0, 1, ma_trendslow);
   
   double mafast[], mamedium[], maslow[];
   CopyBuffer(handle_ma_fast,0,0,1,mafast);
   CopyBuffer(handle_ma_medium,0,0,1,mamedium);
   CopyBuffer(handle_ma_slow,0,0,1,maslow);
   
   
   
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   int trend_direction = 0;
   
   if (ma_trendfast[0] > ma_trendslow[0] && bid > ma_trendfast[0])
   {
      trend_direction = 1; 
   }
   else if (ma_trendfast[0] < ma_trendslow[0] && bid < ma_trendfast[0])
   {
      trend_direction = -1;
   }
   
   int positions = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong posticket = PositionGetTicket(i);
      if(PositionSelectByTicket(posticket))
        {
           if(PositionGetDouble(POSITION_VOLUME) >= lot){
              if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == magic_num)
                {
                    positions++;
                    
                    if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                      {
                        double tp = PositionGetDouble(POSITION_PRICE_OPEN) + (PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_SL));
                        
                        if(bid >= tp)
                          {
                              if(trade.PositionClosePartial(posticket, NormalizeDouble(PositionGetDouble(POSITION_VOLUME)/2,2)))
                                {
                                    double sl = PositionGetDouble(POSITION_PRICE_OPEN);
                                    sl = NormalizeDouble(sl, _Digits);
                                    if(trade.PositionModify(posticket,sl,0))
                                      {
                                       
                                      }
                                }
                          }
                       
                      } 
                      else
                     {
                        int lowest = iLowest(_Symbol, PERIOD_M5, MODE_LOW, 3, 1);
                        double sl = iLow(_Symbol, PERIOD_M5, lowest);
                        sl = NormalizeDouble(sl, _Digits);
                        
                           if(sl > PositionGetDouble(POSITION_SL)){
                              if(trade.PositionModify(posticket, sl, 0))
                                {
                                 
                                }
                        
                        }
                        
                     }
                   }
                  
                 else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
                   {
                        if(PositionGetDouble(POSITION_VOLUME) >= lot){
                   
                               double tp = PositionGetDouble(POSITION_PRICE_OPEN) - (PositionGetDouble(POSITION_SL) - PositionGetDouble(POSITION_PRICE_OPEN));
                              
                                 if(bid <= tp)
                                   {
                                       if(trade.PositionClosePartial(posticket, NormalizeDouble(PositionGetDouble(POSITION_VOLUME)/2,2)))
                                         {
                                             double sl = PositionGetDouble(POSITION_PRICE_OPEN);
                                             sl = NormalizeDouble(sl, _Digits);
                                             if(trade.PositionModify(posticket,sl,0))
                                               {
                                                
                                               }
                                         }
                                   }
                               
                   }
                    else
                     {
                        int highest = iHighest(_Symbol, PERIOD_M5, MODE_HIGH, 3, 1);
                        double sl = iHigh(_Symbol, PERIOD_M5, highest);
                        sl = NormalizeDouble(sl, _Digits);
                        
                           if(sl > PositionGetDouble(POSITION_SL)){
                              if(trade.PositionModify(posticket, sl, 0))
                                {
                                 
                                }
                        
                        }
                        
                     }
             }
        }
   }
   }
   int order = 0;
   for(int i = OrdersTotal()-1; i >= 0; i--)
   {
      ulong orderticket = OrderGetTicket(i);
      if(OrderSelect(orderticket))
        {
           if(OrderGetString(ORDER_SYMBOL) == _Symbol && OrderGetInteger(ORDER_MAGIC) == magic_num)
             {
                 if(OrderGetInteger(ORDER_TIME_SETUP) < TimeCurrent() - 30* PeriodSeconds(PERIOD_M1))
                   {
                    trade.OrderDelete(orderticket);
                   }
                 order++;
             }
        }
   }
   
   
   if(trend_direction == 1)
   {
      if(mafast[0] > mamedium[0] && mamedium[0] > maslow[0])
      {
         if(bid <= mafast[0])
           {
            printf("buy signal");
            if(positions + order <=0)
            {
               int indexHighest = iHighest(_Symbol,PERIOD_M5, MODE_HIGH,5,1);
               double highprice = iHigh(_Symbol,PERIOD_M5,indexHighest);
               highprice = NormalizeDouble(highprice, _Digits);
               
               double sl = iLow(_Symbol,PERIOD_M5,0) - 30 * _Point;
               sl = NormalizeDouble(sl, _Digits);
               
               
               trade.BuyStop(lot, highprice, _Symbol,sl);
               
            }
            
           }
      
      }
   }
   else if( trend_direction == -1)
   {
   
      if(mafast[0] < mamedium[0] && mamedium[0] < maslow[0])
      {
      
         if(bid >= mafast[0])
              {
               printf("sell signal");
               if(positions + order <=0)
               {
                  int indexlowest = iLowest(_Symbol,PERIOD_M5, MODE_LOW,5,1);
                  double lowprice = iLow(_Symbol,PERIOD_M5,indexlowest);
                  lowprice = NormalizeDouble(lowprice, _Digits);
                  

                  double sl = iHigh(_Symbol,PERIOD_M5,0) + 30 * _Point;
                  sl = NormalizeDouble(sl, _Digits);
                  

                  
                  trade.SellStop(lot, lowprice, _Symbol, sl);
                  
               }
              }
      
      }
   
   }
   
   
   Comment("\nFast Trend MA: ", DoubleToString(ma_trendfast[0],_Digits),
           "\nSlow Trend MA: ", DoubleToString(ma_trendslow[0],_Digits),
           "\nTrend Direction: ",trend_direction,
           "\n",
           "\nFast MA: ", DoubleToString(mafast[0],_Digits),
           "\nMedium MA: ", DoubleToString(mamedium[0],_Digits),
           "\nSlow MA: ", DoubleToString(maslow[0],_Digits),
           "\n",
           "\nPositions: ", positions,
           "\nOrders:", order
           );
  }

