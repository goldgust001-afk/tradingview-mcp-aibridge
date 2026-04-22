/**
 * Korean-market-specific MCP tools (AI BRIDGE additions).
 */
import { z } from 'zod';
import { jsonResult } from './_format.js';
import * as core from '../core/korean.js';

export function registerKoreanTools(server) {
  server.tool(
    'kimchi_premium',
    'Calculate the Korean premium (김치 프리미엄) for a crypto asset: compares the KRW price on a Korean exchange (default Upbit) against the USD price on a global exchange (default Binance), normalized by the current USD/KRW FX rate from TradingView. Momentarily switches the active chart across three symbols to read prices, then restores the original symbol. Returns premium percent and interpretation.',
    {
      base: z
        .string()
        .optional()
        .describe('Base asset ticker (default "BTC"). Examples: "BTC", "ETH", "SOL", "XRP".'),
      kr_exchange: z
        .string()
        .optional()
        .describe('Korean exchange prefix (default "UPBIT"). Alternatives: "BITHUMB".'),
      global_exchange: z
        .string()
        .optional()
        .describe('Global exchange prefix (default "BINANCE"). Alternatives: "COINBASE", "BYBIT".'),
      fx_symbol: z
        .string()
        .optional()
        .describe('TradingView FX symbol for USD/KRW (default "TRADINGVIEW:USDKRW").'),
    },
    async ({ base, kr_exchange, global_exchange, fx_symbol }) => {
      try {
        return jsonResult(
          await core.kimchiPremium({ base, kr_exchange, global_exchange, fx_symbol }),
        );
      } catch (err) {
        return jsonResult(
          {
            success: false,
            error: err.message,
            hint: 'Ensure TradingView Desktop is running with CDP enabled and both the KR and global symbols exist on TradingView.',
          },
          true,
        );
      }
    },
  );
}
