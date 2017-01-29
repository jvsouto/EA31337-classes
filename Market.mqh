//+------------------------------------------------------------------+
//|                 EA31337 - multi-strategy advanced trading robot. |
//|                       Copyright 2016-2017, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
   This file is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Properties.
#property strict

// Forward declaration.
class Market;
class SymbolInfo;

// Includes.
#include "SymbolInfo.mqh"

/**
 * Class to provide market information.
 */
class Market : public SymbolInfo {

protected:

  // Structs.
  // Struct for making a snapshot of market values.
  struct MarketSnapshot {
    datetime dtime;
    double ask;
    double bid;
    double volume_session;
  };

  // Struct variables.
  MarketSnapshot snapshots[];

public:

  /**
   * Implements class constructor with a parameter.
   */
  Market(string _symbol = NULL, Log *_log = NULL) :
    SymbolInfo(_symbol, _log)
  {
  }

  ~Market() {
  }

  /* Getters */

  /**
   * Get pip precision.
   */
  static uint GetPipDigits(string _symbol) {
    return GetDigits(_symbol) < 4 ? 2 : 4;
  }
  uint GetPipDigits() {
    return GetPipDigits(symbol);
  }

  /**
   * Get pip value.
   */
  double GetPipValue() {
    return 10 >> GetPipDigits();
  }

  /**
   * Get current spread in points.
   *
   * @param
   *   symbol string (optional)
   *   Currency pair symbol.
   *
   * @return
   *   Return symbol trade spread level in points.
   */
  static uint GetSpreadInPts(string _symbol) {
    return GetSpread(_symbol);
  }
  uint GetSpreadInPts() {
    return GetSpread();
  }

  /**
   * Get current spread in float.
   */
  double GetSpreadInPips() {
    return (GetAsk() - GetBid()) * pow(10, GetPipDigits());
  }

  /**
   * Get current spread in percent.
   */
  double GetSpreadInPct() {
    return 100.0 * (GetAsk() - GetBid()) / GetAsk();
  }

  /**
   * Get number of points per pip.
   *
   * To be used to replace Point for trade parameters calculations.
   * See: http://forum.mql4.com/30672
   */
  int GetPointsPerPip() {
    return (int) pow(10, GetDigits() - GetPipDigits());
  }

  /**
   * Get a market distance in points.
   *
   * Minimal permissible distance value in points for StopLoss/TakeProfit.
   *
   * This is due that at placing of a pending order, the open price cannot be too close to the market.
   * The minimal distance of the pending price from the current market one in points can be obtained
   * using the MarketInfo() function with the MODE_STOPLEVEL parameter.
   * Related error messages:
   *   Error 130 (ERR_INVALID_STOPS) happens In case of false open price of a pending order.
   *   Error 145 (ERR_TRADE_MODIFY_DENIED) happens when modification of order was too close to market.
   *
   * @see: https://book.mql4.com/appendix/limits
   */
  long GetTradeDistanceInPts() {
    return fmax(GetTradeStopsLevel(), GetFreezeLevel());
  }

  /**
   * Get a market distance in pips.
   *
   * Minimal permissible distance value in pips for StopLoss/TakeProfit.
   *
   * @see: https://book.mql4.com/appendix/limits
   */
  double GetTradeDistanceInPips() {
    // @fixme
    return (double) (GetTradeDistanceInPts() / GetPointsPerPip());
  }

  /**
   * Get a market gap in value.
   *
   * Minimal permissible distance value in value for StopLoss/TakeProfit.
   *
   * @see: https://book.mql4.com/appendix/limits
   */
  double GetTradeDistanceInValue() {
    return GetTradeDistanceInPts() * GetPointSize();
  }

  /**
   * Get a lot step.
   */
  double GetLotStepInPips() {
    // @todo: Correct bit shifting.
    return fmax(GetLotStepInPts(), GetPipValue());
  }

  /**
   * Get a volume precision.
   */
  int GetVolumeDigits() {
    return (int)
      -log10(
          fmin(
            GetLotStepInPts(),
            GetMinLot()
          )
      );
  }

  /**
   * Free margin required to open 1 lot for buying.
   */
  static double GetMarginRequired(string _symbol) {
    #ifdef __MQL4__
    return MarketInfo(_symbol, MODE_MARGINREQUIRED);
    #else
    // @todo
    // @see: https://www.mql5.com/en/articles/81
    // OrderCalcMargin()?
    return (0);
    #endif
  }
  double GetMarginRequired() {
    return GetMarginRequired(symbol);
  }

  /**
   * Get current open price depending on the operation type.
   *
   * @param:
   *   op_type int Order operation type of the order.
   * @return
   *   Current open price.
   */
  double GetOpenPrice(ENUM_ORDER_TYPE _cmd = NULL) {
    if (_cmd == NULL) _cmd = (ENUM_ORDER_TYPE) OrderGetInteger(ORDER_TYPE); // Same as: OrderType();
    return _cmd == ORDER_TYPE_BUY ? GetAsk() : GetBid();
  }

  /**
   * Returns open price of a bar.
   */
  double GetOpen(uint _bar = 0) {
    #ifdef __MQL4__
    return Open[0];
    #else // __MQL5__
    double _open[];
    ArraySetAsSeries(_open, true);
    CopyOpen(symbol,_Period, 0, _bar, _open);
    return _open[_bar];
    #endif
  }

  /**
   * Returns close price of a bar.
   */
  double GetClose(uint _bar = 0) {
    #ifdef __MQL4__
    return Close[0];
    #else // __MQL5__
    double _close[];
    ArraySetAsSeries(_close, true);
    CopyOpen(symbol,_Period, 0, _bar, _close);
    return _close[_bar];
    #endif
  }

  /**
   * Returns low price of a bar.
   */
  double GetLow(uint _bar = 0) {
    #ifdef __MQL4__
    return Low[0];
    #else // __MQL5__
    double _low[];
    ArraySetAsSeries(_low, true);
    CopyOpen(symbol,_Period, 0, _bar, _low);
    return _low[_bar];
    #endif
  }

  /**
   * Returns high price of a bar.
   */
  double GetHigh(uint _bar = 0) {
    #ifdef __MQL4__
    return High[0];
    #else // __MQL5__
    double _high[];
    ArraySetAsSeries(_high, true);
    CopyOpen(symbol,_Period, 0, _bar, _high);
    return _high[_bar];
    #endif
  }

  /* Functional methods */

  /**
   * Refresh data in pre-defined variables and series arrays.
   *
   * @see http://docs.mql4.com/series/refreshrates
   */
  static bool RefreshRates() {
    // In MQL5 returns true for backward compability.
    return #ifdef __MQL4__ ::RefreshRates(); #else true; #endif
    // #ifdef __MQL5__ #define RefreshRates() Market::RefreshRates() #endif // @fixme
  }

  /**
   * Returns market data about securities.
   */
  static double MarketInfo(string _symbol, int _type) {
    switch(_type) {
      case MODE_LOW:               return SymbolInfoDouble(_symbol, SYMBOL_LASTLOW);
      case MODE_HIGH:              return SymbolInfoDouble(_symbol, SYMBOL_LASTHIGH);
      case MODE_TIME:              return (double) SymbolInfoInteger(_symbol, SYMBOL_TIME); // Time of the last quote.
      case MODE_BID:               return GetBid(_symbol);
      case MODE_ASK:               return GetAsk(_symbol);
      case MODE_POINT:             return GetPointSize(_symbol);
      case MODE_DIGITS:            return GetDigits(_symbol);
      case MODE_SPREAD:            return GetSpreadInPts(_symbol);
      case MODE_STOPLEVEL:         return (double) GetTradeStopsLevel(_symbol);
      case MODE_LOTSIZE:           return GetTradeContractSize(_symbol);
      case MODE_TICKVALUE:         return GetTickValue(_symbol);
      case MODE_TICKSIZE:          return GetTickSize(_symbol);
      case MODE_SWAPLONG:          return SymbolInfoDouble(_symbol, SYMBOL_SWAP_LONG);
      case MODE_SWAPSHORT:         return SymbolInfoDouble(_symbol, SYMBOL_SWAP_SHORT);
      case MODE_LOTSTEP:           return GetLotStepInPts(_symbol);
      case MODE_MINLOT:            return GetMinLot(_symbol);
      case MODE_MAXLOT:            return GetMaxLot(_symbol);
      case MODE_SWAPTYPE:          return (double) SymbolInfoInteger(_symbol, SYMBOL_SWAP_MODE);
      case MODE_PROFITCALCMODE:    return (double) SymbolInfoInteger(_symbol, SYMBOL_TRADE_CALC_MODE);
      case MODE_STARTING:          return (0); // @todo
      case MODE_EXPIRATION:        return (0); // @todo
      case MODE_TRADEALLOWED:      return Terminal::IsTradeAllowed();
      case MODE_MARGINCALCMODE:    return (0); // @todo
      case MODE_MARGININIT:        return (0); // @todo
      case MODE_MARGINMAINTENANCE: return (0); // @todo
      case MODE_MARGINHEDGED:      return (0); // @todo
      case MODE_MARGINREQUIRED:    return GetMarginRequired(_symbol);
      case MODE_FREEZELEVEL:       return GetFreezeLevel(_symbol);
    }
    return (-1);
  }
  double MarketInfo(int _type) {
    return MarketInfo(symbol, _type);
  }

  /**
   * Get current close price depending on the operation type.
   *
   * @param:
   *   op_type int Order operation type of the order.
   * @return
   * Current close price.
   */
  double GetClosePrice(ENUM_ORDER_TYPE _cmd = NULL) {
    if (_cmd == NULL) _cmd = (ENUM_ORDER_TYPE) OrderGetInteger(ORDER_TYPE); // Same as: OrderType();
    return _cmd == ORDER_TYPE_BUY ? GetBid() : GetAsk();
  }

  /**
   * Get delta value per lot in account currency of a point of symbol.
   *
   * @see
   * - https://forum.mql4.com/33975
   * - https://forum.mql4.com/43064#515262
   * - https://forum.mql4.com/41259/page3#512466
   * - https://www.mql5.com/en/forum/127584
   * - https://www.mql5.com/en/forum/135345
   * - https://www.mql5.com/en/forum/133792/page3#512466
   */
  double GetDeltaValue() {
    // Return tick value in the deposit currency divided by tick size in points.
    return GetTickValue() / GetTickSize();
  }

  /**
   * Returns the last price change in pips.
   *
   * Note: The change is calculated since the last call to GetAsk()/GetBid().
   */
  double GetLastPriceChangeInPips() {
    return fmax(fabs(GetLastAsk() - GetAsk()), fabs(GetLastBid() - GetBid())) * pow(10, GetPipDigits());
  }

  /* END: Getters */

  /* Normalization methods */

  /**
   * Normalize price value.
   *
   * Make sure that the price is a multiple of ticksize.
   */
  double NormalizePrice(double p) {
    // See: http://forum.mql4.com/47988
    // http://forum.mql4.com/43064#515262 zzuegg reports for non-currency DE30:
    // - MarketInfo(chart.symbol,MODE_TICKSIZE) returns 0.5
    // - MarketInfo(chart.symbol,MODE_DIGITS) return 1
    // - Point = 0.1
    // Rare fix when a change in tick size leads to a change in tick value.
    return round(p / GetPointSize()) * GetTickSize();
  }

  /**
   * Normalize lot size.
   */
  double NormalizeLots(double lots, bool ceiling = false) {
    // Related: http://forum.mql4.com/47988
    double precision = GetLotStepInPts() > 0.0 ? 1 / GetLotStepInPts() : 1 / GetMinLot();
    double lot_size = ceiling ? MathCeil(lots * precision) / precision : MathFloor(lots * precision) / precision;
    lot_size = fmin(fmax(lot_size, GetMinLot()), GetMaxLot());
    return NormalizeDouble(lot_size, GetVolumeDigits());
  }

  /* Trend methods */

  /**
   * Calculates the current market trend.
   *
   * @param
   *   method (int)
   *    Bitwise trend method to use.
   *   tf (ENUM_TIMEFRAMES)
   *     Frequency based on the given timeframe. Use NULL for the current.
   *   symbol (string)
   *     Symbol pair to check against it.
   *   simple (bool)
   *     If true, use simple trend calculation.
   *
   * @return
   *   Returns positive value for bullish, negative for bearish, zero for neutral market trend.
   *
   * @todo: Improve number of increases for bull/bear variables.
   */
  double GetTrend(int method, ENUM_TIMEFRAMES _tf = NULL, bool simple = false) {
    static datetime _last_trend_check = 0;
    static double _last_trend = 0;
    if (_last_trend_check == iTime(symbol, _tf, 0)) {
      return _last_trend;
    }
    double bull = 0, bear = 0;
    int _counter = 0;

    if (simple) {
      if ((method &   1) != 0)  {
        if (iOpen(NULL, PERIOD_MN1, 0) > iClose(NULL, PERIOD_MN1, 1)) bull++;
        if (iOpen(NULL, PERIOD_MN1, 0) < iClose(NULL, PERIOD_MN1, 1)) bear++;
      }
      if ((method &   2) != 0)  {
        if (iOpen(NULL, PERIOD_W1, 0) > iClose(NULL, PERIOD_W1, 1)) bull++;
        if (iOpen(NULL, PERIOD_W1, 0) < iClose(NULL, PERIOD_W1, 1)) bear++;
      }
      if ((method &   4) != 0)  {
        if (iOpen(NULL, PERIOD_D1, 0) > iClose(NULL, PERIOD_D1, 1)) bull++;
        if (iOpen(NULL, PERIOD_D1, 0) < iClose(NULL, PERIOD_D1, 1)) bear++;
      }
      if ((method &   8) != 0)  {
        if (iOpen(NULL, PERIOD_H4, 0) > iClose(NULL, PERIOD_H4, 1)) bull++;
        if (iOpen(NULL, PERIOD_H4, 0) < iClose(NULL, PERIOD_H4, 1)) bear++;
      }
      if ((method &   16) != 0)  {
        if (iOpen(NULL, PERIOD_H1, 0) > iClose(NULL, PERIOD_H1, 1)) bull++;
        if (iOpen(NULL, PERIOD_H1, 0) < iClose(NULL, PERIOD_H1, 1)) bear++;
      }
      if ((method &   32) != 0)  {
        if (iOpen(NULL, PERIOD_M30, 0) > iClose(NULL, PERIOD_M30, 1)) bull++;
        if (iOpen(NULL, PERIOD_M30, 0) < iClose(NULL, PERIOD_M30, 1)) bear++;
      }
      if ((method &   64) != 0)  {
        if (iOpen(NULL, PERIOD_M15, 0) > iClose(NULL, PERIOD_M15, 1)) bull++;
        if (iOpen(NULL, PERIOD_M15, 0) < iClose(NULL, PERIOD_M15, 1)) bear++;
      }
      if ((method &  128) != 0)  {
        if (iOpen(NULL, PERIOD_M5, 0) > iClose(NULL, PERIOD_M5, 1)) bull++;
        if (iOpen(NULL, PERIOD_M5, 0) < iClose(NULL, PERIOD_M5, 1)) bear++;
      }
      //if (iOpen(NULL, PERIOD_H12, 0) > iClose(NULL, PERIOD_H12, 1)) bull++;
      //if (iOpen(NULL, PERIOD_H12, 0) < iClose(NULL, PERIOD_H12, 1)) bear++;
      //if (iOpen(NULL, PERIOD_H8, 0) > iClose(NULL, PERIOD_H8, 1)) bull++;
      //if (iOpen(NULL, PERIOD_H8, 0) < iClose(NULL, PERIOD_H8, 1)) bear++;
      //if (iOpen(NULL, PERIOD_H6, 0) > iClose(NULL, PERIOD_H6, 1)) bull++;
      //if (iOpen(NULL, PERIOD_H6, 0) < iClose(NULL, PERIOD_H6, 1)) bear++;
      //if (iOpen(NULL, PERIOD_H2, 0) > iClose(NULL, PERIOD_H2, 1)) bull++;
      //if (iOpen(NULL, PERIOD_H2, 0) < iClose(NULL, PERIOD_H2, 1)) bear++;
    } else {
      if ((method &   1) != 0)  {
        for (_counter = 0; _counter < 3; _counter++) {
          if (iOpen(NULL, PERIOD_MN1, _counter) > iClose(NULL, PERIOD_MN1, _counter + 1)) bull += 30;
          else if (iOpen(NULL, PERIOD_MN1, _counter) < iClose(NULL, PERIOD_MN1, _counter + 1)) bear += 30;
        }
      }
      if ((method &   2) != 0)  {
        for (_counter = 0; _counter < 8; _counter++) {
          if (iOpen(NULL, PERIOD_W1, _counter) > iClose(NULL, PERIOD_W1, _counter + 1)) bull += 7;
          else if (iOpen(NULL, PERIOD_W1, _counter) < iClose(NULL, PERIOD_W1, _counter + 1)) bear += 7;
        }
      }
      if ((method &   4) != 0)  {
        for (_counter = 0; _counter < 7; _counter++) {
          if (iOpen(NULL, PERIOD_D1, _counter) > iClose(NULL, PERIOD_D1, _counter + 1)) bull += 1440/1440;
          else if (iOpen(NULL, PERIOD_D1, _counter) < iClose(NULL, PERIOD_D1, _counter + 1)) bear += 1440/1440;
        }
      }
      if ((method &   8) != 0)  {
        for (_counter = 0; _counter < 24; _counter++) {
          if (iOpen(NULL, PERIOD_H4, _counter) > iClose(NULL, PERIOD_H4, _counter + 1)) bull += 240/1440;
          else if (iOpen(NULL, PERIOD_H4, _counter) < iClose(NULL, PERIOD_H4, _counter + 1)) bear += 240/1440;
        }
      }
      if ((method &   16) != 0)  {
        for (_counter = 0; _counter < 24; _counter++) {
          if (iOpen(NULL, PERIOD_H1, _counter) > iClose(NULL, PERIOD_H1, _counter + 1)) bull += 60/1440;
          else if (iOpen(NULL, PERIOD_H1, _counter) < iClose(NULL, PERIOD_H1, _counter + 1)) bear += 60/1440;
        }
      }
      if ((method &   32) != 0)  {
        for (_counter = 0; _counter < 48; _counter++) {
          if (iOpen(NULL, PERIOD_M30, _counter) > iClose(NULL, PERIOD_M30, _counter + 1)) bull += 30/1440;
          else if (iOpen(NULL, PERIOD_M30, _counter) < iClose(NULL, PERIOD_M30, _counter + 1)) bear += 30/1440;
        }
      }
      if ((method &   64) != 0)  {
        for (_counter = 0; _counter < 96; _counter++) {
          if (iOpen(NULL, PERIOD_M15, _counter) > iClose(NULL, PERIOD_M15, _counter + 1)) bull += 15/1440;
          else if (iOpen(NULL, PERIOD_M15, _counter) < iClose(NULL, PERIOD_M15, _counter + 1)) bear += 15/1440;
        }
      }
      if ((method &  128) != 0)  {
        for (_counter = 0; _counter < 288; _counter++) {
          if (iOpen(NULL, PERIOD_M5, _counter) > iClose(NULL, PERIOD_M5, _counter + 1)) bull += 5/1440;
          else if (iOpen(NULL, PERIOD_M5, _counter) < iClose(NULL, PERIOD_M5, _counter + 1)) bear += 5/1440;
        }
      }
    }
    _last_trend = (bull - bear);
    _last_trend_check = iTime(symbol, _tf, 0);
    #ifdef __trace__ PrintFormat("%s: %g", __FUNCTION__, _last_trend); #endif
    return _last_trend;
  }

  /**
   * Get the current market trend.
   *
   * @param
   *   method (int)
   *    Bitwise trend method to use.
   *   tf (ENUM_TIMEFRAMES)
   *     Frequency based on the given timeframe. Use NULL for the current.
   *   symbol (string)
   *     Symbol pair to check against it.
   *   simple (bool)
   *     If true, use simple trend calculation.
   *
   * @return
   *   Returns Buy operation for bullish, Sell for bearish, otherwise NULL for neutral market trend.
   */
  ENUM_ORDER_TYPE GetTrendOp(int method, ENUM_TIMEFRAMES _tf = NULL, bool simple = false) {
    double _curr_trend = GetTrend(method, _tf, simple);
    return _curr_trend == 0 ? (ENUM_ORDER_TYPE) (ORDER_TYPE_BUY + ORDER_TYPE_SELL) : (_curr_trend > 0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
  }

  /* Market state checking */

  /**
   * Check whether given symbol exists.
   */
  static bool SymbolExists(string _symbol = NULL) {
    ResetLastError();
    GetAsk(_symbol);
    return GetLastError() != ERR_MARKET_UNKNOWN_SYMBOL;
  }

  /**
   * Check whether we're trading within market peak hours.
   */
  bool IsPeakHour() {
      return DateTime::Hour() >= 8 && DateTime::Hour() <= 16;
  }

  /**
   * Returns textual representation of the Market class.
   */
  string ToString() {
    return StringFormat(
      "Pip digits: %d, Spread: %d pts (%g pips; %g%%), Pts/pip: %d, " +
      "Trade distance: %d pts (%.4f pips), Lot step: %g pips, Volume digits: %d, " +
      "Margin required: %g/lot, Delta: %g",
      // GetOpen(), GetClose(), GetLow(), GetHigh(),
      GetPipDigits(), GetSpreadInPts(), GetSpreadInPips(), GetSpreadInPct(), GetPointsPerPip(),
      GetTradeDistanceInPts(), GetTradeDistanceInPips(), GetLotStepInPips(), GetVolumeDigits(),
      GetMarginRequired(), GetDeltaValue()
      );
  }

  /* Snapshots */

  /**
   * Create a market snapshot.
   */
  bool MakeSnapshot() {
    uint _size = ArraySize(snapshots);
    if (ArrayResize(snapshots, _size + 1, 100)) {
      snapshots[_size].dtime = TimeCurrent();
      snapshots[_size].ask = GetAsk();
      snapshots[_size].bid = GetBid();
      snapshots[_size].volume_session = GetSessionVolume();
      return true;
    } else {
      return false;
    }
  }

  /* Other methods */

  /**
   * Validate whether trade operation is permitted.
   *
   * @param int cmd
   *   Trade command.
   * @param int sl
   *   Stop loss price value.
   * @param int tp
   *   Take profit price value.
   * @param string symbol
   *   Currency symbol.
   * @return
   *   Returns true when trade operation is allowed.
   *
   * @see: https://book.mql4.com/appendix/limits
   * @see: https://www.mql5.com/en/articles/2555#invalid_SL_TP_for_position
   */
  double TradeOpAllowed(ENUM_ORDER_TYPE _cmd, double sl, double tp) {
    double ask = GetAsk();
    double bid = GetBid();
    double openprice = GetOpenPrice(_cmd);
    double closeprice = GetClosePrice(_cmd);
    // The minimum distance of SYMBOL_TRADE_STOPS_LEVEL taken into account.
    double distance = GetTradeDistanceInValue();
    // bool result;
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        // Buying is done at the Ask price.
        // Requirements for Minimum Distance Limitation:
        // - Bid - StopLoss >= StopLevel  && TakeProfit - Bid >= StopLevel
        // - Bid - StopLoss > FreezeLevel && TakeProfit - Bid > FreezeLevel
        /*
        result = sl > 0 && tp > 0 && bid - sl >= distance && tp - bid >= distance;
        PrintFormat("1. Buy: (%g - %g) = %g >= %g; %s", Bid, sl, (bid - sl), distance, result ? "true" : "false");
        PrintFormat("2. Buy: (%g - %g) = %g >= %g; %s", tp, Bid, (tp - Bid), distance, result ? "true" : "false");
        */
        // The TakeProfit and StopLoss levels must be at the distance of at least SYMBOL_TRADE_STOPS_LEVEL points from the Bid price.
        return sl > 0 && tp > 0 &&
          bid - sl >= distance &&
          tp - bid >= distance;
      case ORDER_TYPE_SELL:
        // Selling is done at the Bid price.
        // Requirements for Minimum Distance Limitation:
        // - StopLoss - Ask >= StopLevel  && Ask - TakeProfit >= StopLevel
        // - StopLoss - Ask > FreezeLevel && Ask - TakeProfit > FreezeLevel
        /*
        result = sl > 0 && tp > 0 && sl - ask > distance && ask - tp > distance;
        PrintFormat("1. Sell: (%g - %g) = %g >= %g; %s",
          sl, Ask, (sl - Ask), distance, result ? "true" : "false");
        PrintFormat("2. Sell: (%g - %g) = %g >= %g; %s",
          Ask, tp, (ask - tp), distance, result ? "true" : "false");
        */
        // The TakeProfit and StopLoss levels must be at the distance of at least SYMBOL_TRADE_STOPS_LEVEL points from the Ask price.
        return sl > 0 && tp > 0 &&
          sl - ask > distance &&
          ask - tp > distance;
      case ORDER_TYPE_BUY_LIMIT:
        // Requirements when performing trade operations:
        // - Ask-OpenPrice >= StopLevel && OpenPrice-SL >= StopLevel && TP-OpenPrice >= StopLevel
        // - Open Price of a Pending Order is Below the current Ask price.
        // - Ask price reaches open price.
        return
          ask - openprice >= distance &&
          openprice - sl >= distance &&
          tp - openprice >= distance;
      case ORDER_TYPE_SELL_LIMIT:
        // Requirements when performing trade operations:
        // - OpenPrice-Bid >= StopLevel && SL-OpenPrice >= StopLevel && OpenPrice-TP >= StopLevel
        // - Open Price of a Pending Order is Above the current Bid price.
        // - Bid price reaches open price.
        return
          openprice - bid >= distance &&
          sl - openprice >= distance &&
          openprice - tp >= distance;
      case ORDER_TYPE_BUY_STOP:
        // Requirements when performing trade operations:
        // - OpenPrice-Ask >= StopLevel && OpenPrice-SL >= StopLevel && TP-OpenPrice >= StopLevel
        // - Open Price of a Pending Order is Above the current Ask price.
        // - Ask price reaches open price.
        return
          openprice - ask >= distance &&
          openprice - sl >= distance &&
          tp - openprice >= distance;
      case ORDER_TYPE_SELL_STOP:
        // Requirements when performing trade operations:
        // - Bid-OpenPrice >= StopLevel && SL-OpenPrice >= StopLevel && OpenPrice-TP >= StopLevel
        // - Open Price of a Pending Order is Below the current Bid price.
        // - Bid price reaches open price.
        return
          bid - openprice >= distance &&
          sl - openprice >= distance &&
          openprice - tp >= distance;
      default:
        return (true);
    }
  }

  /**
   * Validate whether trade operation is permitted.
   *
   * @param int cmd
   *   Trade command.
   * @param int price
   *   Take profit or stop loss price value.
   * @return
   *   Returns true when trade operation is allowed.
   *
   * @see: https://book.mql4.com/appendix/limits
   */
  double TradeOpAllowed(ENUM_ORDER_TYPE _cmd, double price) {
    double ask = GetAsk();
    double bid = GetBid();
    double distance = GetTradeDistanceInPips() + GetPipSize();
    // bool result;
    switch (_cmd) {
      case ORDER_TYPE_BUY_STOP:
        // OpenPrice-Ask >= StopLevel && OpenPrice-SL >= StopLevel && TP-OpenPrice >= StopLevel
      case ORDER_TYPE_BUY_LIMIT:
        // Ask-OpenPrice >= StopLevel && OpenPrice-SL >= StopLevel && TP-OpenPrice >= StopLevel
      case ORDER_TYPE_BUY:
        // Bid-OpenPrice >= StopLevel && SL-OpenPrice >= StopLevel && OpenPrice-TP >= StopLevel
      case ORDER_TYPE_SELL_LIMIT:
        // OpenPrice-Bid >= StopLevel && SL-OpenPrice >= StopLevel && OpenPrice-TP >= StopLevel
      case ORDER_TYPE_SELL_STOP:
        // Bid-OpenPrice >= StopLevel && SL-OpenPrice >= StopLevel && OpenPrice-TP >= StopLevel
      case ORDER_TYPE_SELL:
        /*
        result = price > 0 && ask - price > distance && price - ask > distance;
        PrintFormat("%s: 1: %g - %g = %g > %g; %s",
            __FUNCTION__, bid, price, bid - price, distance, result ? "true" : "false");
        PrintFormat("%s: 2: %g - %g = %g > %g; %s",
            __FUNCTION__, ask, price, ask - price, distance, result ? "true" : "false");
         */
        // return price > 0 && fabs(bid - price) > distance && fabs(ask - price) > distance;
        return price > 0 &&
          fabs(bid - price) > distance &&
          fabs(ask - price) > distance;
      default:
        return (true);
    }
  }

  /**
   * Returns Terminal log handler.
   */
  Log *Log() {
    return logger;
  }

  /**
   * Returns class handler.
   */
  /*
  Market *Market() {
    return GetPointer(this);
  }
  */

};
