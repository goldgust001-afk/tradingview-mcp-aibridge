/**
 * Korean-market-specific helpers (AI BRIDGE additions).
 *
 * kimchiPremium: compare the price of an asset on a Korean KRW exchange
 *   (default Upbit) vs a global USD exchange (default Binance), using a
 *   TradingView USD/KRW quote to normalize currencies, and return the
 *   premium as a percentage.
 */
import * as chartCore from './chart.js';
import * as dataCore from './data.js';

const DEFAULT_KR_EXCHANGE = 'UPBIT';
const DEFAULT_GLOBAL_EXCHANGE = 'BINANCE';
const DEFAULT_FX_SYMBOL = 'TRADINGVIEW:USDKRW';

function buildKrwSymbol(base, exchange) {
  return `${exchange}:${base.toUpperCase()}KRW`;
}

function buildUsdSymbol(base, exchange) {
  // Binance uses USDT, Coinbase uses USD. Default Binance+USDT.
  const suffix = exchange === 'COINBASE' ? 'USD' : 'USDT';
  return `${exchange}:${base.toUpperCase()}${suffix}`;
}

async function readClose(symbol) {
  await chartCore.setSymbol({ symbol });
  // Small settle delay on top of waitForChartReady, because quote reads last-bar value.
  await new Promise((r) => setTimeout(r, 400));
  const q = await dataCore.getQuote({ symbol });
  const price = q.close ?? q.last;
  if (!price || Number.isNaN(Number(price))) {
    throw new Error(`Could not read price for ${symbol}`);
  }
  return Number(price);
}

export async function kimchiPremium({
  base = 'BTC',
  kr_exchange,
  global_exchange,
  fx_symbol,
} = {}) {
  const krEx = (kr_exchange || DEFAULT_KR_EXCHANGE).toUpperCase();
  const glEx = (global_exchange || DEFAULT_GLOBAL_EXCHANGE).toUpperCase();
  const fxSym = fx_symbol || DEFAULT_FX_SYMBOL;

  const krSymbol = buildKrwSymbol(base, krEx);
  const usdSymbol = buildUsdSymbol(base, glEx);

  // Remember the original symbol so we can restore it when done.
  let originalSymbol = null;
  try {
    const state = await chartCore.getState();
    originalSymbol = state.symbol;
  } catch {
    /* non-fatal */
  }

  const errors = [];
  let krPriceKrw = null;
  let usdPrice = null;
  let fxRate = null;

  try {
    krPriceKrw = await readClose(krSymbol);
  } catch (e) {
    errors.push(`KR leg (${krSymbol}): ${e.message}`);
  }

  try {
    usdPrice = await readClose(usdSymbol);
  } catch (e) {
    errors.push(`Global leg (${usdSymbol}): ${e.message}`);
  }

  try {
    fxRate = await readClose(fxSym);
  } catch (e) {
    errors.push(`FX leg (${fxSym}): ${e.message}`);
  }

  // Always try to restore original chart symbol, even if partially failed.
  if (originalSymbol) {
    try {
      await chartCore.setSymbol({ symbol: originalSymbol });
    } catch {
      /* non-fatal */
    }
  }

  if (krPriceKrw == null || usdPrice == null || fxRate == null) {
    return {
      success: false,
      error: 'Failed to fetch one or more price legs',
      details: errors,
      partial: { kr_price_krw: krPriceKrw, usd_price: usdPrice, fx_rate: fxRate },
    };
  }

  const usdPriceInKrw = usdPrice * fxRate;
  const premiumRatio = krPriceKrw / usdPriceInKrw - 1;
  const premiumPct = premiumRatio * 100;

  return {
    success: true,
    base: base.toUpperCase(),
    kr_exchange: krEx,
    global_exchange: glEx,
    kr_symbol: krSymbol,
    global_symbol: usdSymbol,
    fx_symbol: fxSym,
    kr_price_krw: krPriceKrw,
    global_price_usd: usdPrice,
    usd_krw_fx_rate: fxRate,
    global_price_in_krw: Math.round(usdPriceInKrw),
    premium_percent: Number(premiumPct.toFixed(3)),
    premium_krw_per_unit: Math.round(krPriceKrw - usdPriceInKrw),
    interpretation:
      premiumPct > 3
        ? '한국 프리미엄 높음 — 해외가 상대적으로 저렴'
        : premiumPct < -1
        ? '역프리미엄 — 국내가 상대적으로 저렴'
        : '프리미엄 정상 범위',
    restored_symbol: originalSymbol,
  };
}
