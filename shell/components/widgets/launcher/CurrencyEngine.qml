import QtQuick
import Quickshell
import Quickshell.Io
import "../../.."
import "../../../backend"

Item {
  id: root
  visible: false

  property var ipc: null

  // Canonical path: $XDG_CONFIG_HOME/ogsShell/currency_rates.json
  readonly property string cacheDir: {
    let d = Quickshell.env("XDG_CONFIG_HOME")
    if (!d || d.length === 0) {
      d = (Quickshell.env("HOME") || "/home/excalibur") + "/.config"
    }
    return d + "/ogsShell"
  }
  readonly property string cachePath: cacheDir + "/currency_rates.json"

  // Rates relative to USD (base: USD = 1.0; crypto: USD price)
  property var rates: ({
    "USD": 1.0,
    "TRY": 48.59,
    "EUR": 0.86,
    "GBP": 0.74,
    "CHF": 0.81,
    "JPY": 154.0,
    "CAD": 1.38,
    "AUD": 1.39,
    "RUB": 90.0,
    "CNY": 6.70,
    "SAR": 3.75,
    "AED": 3.67,
    "BTC": 78000.0,
    "ETH": 2500.0,
    "SOL": 140.0
  })

  property int timestamp: 0
  property string lastUpdated: ""

  readonly property var aliases: ({
    "$": "USD", "usd": "USD", "dollar": "USD", "dolar": "USD", "doları": "USD",
    "€": "EUR", "eur": "EUR", "euro": "EUR", "avro": "EUR",
    "₺": "TRY", "try": "TRY", "tl": "TRY", "lira": "TRY", "turk lirasi": "TRY", "türk lirası": "TRY",
    "£": "GBP", "gbp": "GBP", "pound": "GBP", "sterlin": "GBP",
    "¥": "JPY", "jpy": "JPY", "yen": "JPY",
    "₽": "RUB", "rub": "RUB", "ruble": "RUB",
    "chf": "CHF", "frank": "CHF", "franc": "CHF",
    "cad": "CAD", "aud": "AUD", "cny": "CNY", "yuan": "CNY",
    "sar": "SAR", "riyal": "SAR", "aed": "AED", "dirhem": "AED",
    "₿": "BTC", "btc": "BTC", "bitcoin": "BTC",
    "eth": "ETH", "ethereum": "ETH",
    "sol": "SOL", "solana": "SOL"
  })

  readonly property var symbols: ({
    "TRY": "₺", "USD": "$", "EUR": "€", "GBP": "£", "JPY": "¥",
    "RUB": "₽", "CHF": "CHF", "BTC": "₿", "ETH": "Ξ", "CAD": "C$", "AUD": "A$"
  })

  function normalizeCurr(str) {
    if (!str) return null
    let s = str.trim().toLowerCase()
    if (aliases[s]) return aliases[s]
    let up = s.toUpperCase()
    return rates[up] !== undefined ? up : null
  }

  // =========================================================================
  // Currency Query Evaluator
  // =========================================================================
  function evaluate(query) {
    if (!Config.currencyEnabled) return null
    if (!query || typeof query !== "string") return null
    let q = query.trim().toLowerCase()
    if (q.length === 0) return null

    let amount = null
    let fromCurr = null
    let toCurr = null

    // Pattern 1: Symbol prefix e.g. "$100", "€ 50", "₺1000"
    let m1 = q.match(/^([$€₺£¥₽₿])\s*(\d+(?:[.,]\d+)?)$/)
    if (m1) {
      fromCurr = normalizeCurr(m1[1])
      amount = parseFloat(m1[2].replace(",", "."))
    }

    // Pattern 2: Symbol suffix e.g. "100$", "50 €", "1000₺"
    let m2 = q.match(/^(\d+(?:[.,]\d+)?)\s*([$€₺£¥₽₿])$/)
    if (!m1 && m2) {
      amount = parseFloat(m2[1].replace(",", "."))
      fromCurr = normalizeCurr(m2[2])
    }

    // Pattern 3: Explicit separator e.g. "50 eur to try", "100 usd in eur", "25 gbp = usd", "1000 try -> eur"
    let m3 = q.match(/^(\d+(?:[.,]\d+)?)\s*([a-z$€₺£¥₽₿]+)\s*(?:to|in|veya|->|=|\/)\s*([a-z$€₺£¥₽₿]+)$/)
    if (!m1 && !m2 && m3) {
      amount = parseFloat(m3[1].replace(",", "."))
      fromCurr = normalizeCurr(m3[2])
      toCurr = normalizeCurr(m3[3])
    }

    // Pattern 4: Two currencies side by side e.g. "50 eur try", "100 usd eur", "25 gbp try"
    let m4 = q.match(/^(\d+(?:[.,]\d+)?)\s*([a-z$€₺£¥₽₿]+)\s+([a-z$€₺£¥₽₿]+)$/)
    if (!m1 && !m2 && !m3 && m4) {
      let c1 = normalizeCurr(m4[2])
      let c2 = normalizeCurr(m4[3])
      if (c1 && c2) {
        amount = parseFloat(m4[1].replace(",", "."))
        fromCurr = c1
        toCurr = c2
      }
    }

    // Pattern 5: Single currency with amount e.g. "100 usd", "25 gbp", "0.5 btc", "100 dolar", "1000 tl"
    let m5 = q.match(/^(\d+(?:[.,]\d+)?)\s*([a-z$€₺£¥₽₿]+)$/)
    if (!m1 && !m2 && !m3 && !m4 && m5) {
      let c1 = normalizeCurr(m5[2])
      if (c1) {
        amount = parseFloat(m5[1].replace(",", "."))
        fromCurr = c1
      }
    }

    if (amount === null || isNaN(amount) || amount <= 0 || !fromCurr) {
      return null
    }

    // Default target currency from config.json (reactive to Config.currencyDefaultTarget)
    if (!toCurr) {
      let configuredTarget = (Config.currencyDefaultTarget || "TRY").toUpperCase()
      toCurr = (fromCurr === configuredTarget) ? (configuredTarget === "TRY" ? "USD" : "TRY") : configuredTarget
    }

    if (fromCurr === toCurr) return null

    const cryptoCurrencies = ["BTC", "ETH", "SOL"]
    let isFromCrypto = cryptoCurrencies.indexOf(fromCurr) !== -1
    let isToCrypto = cryptoCurrencies.indexOf(toCurr) !== -1

    // Convert fromCurr to USD
    let amountUSD = 0
    if (isFromCrypto) {
      amountUSD = amount * (rates[fromCurr] || 0)
    } else {
      amountUSD = amount / (rates[fromCurr] || 1)
    }

    // Convert USD to toCurr
    let result = 0
    if (isToCrypto) {
      result = amountUSD / (rates[toCurr] || 1)
    } else {
      result = amountUSD * (rates[toCurr] || 1)
    }

    // Unit Parity calculation (1 fromCurr = X toCurr)
    let unitUSD = isFromCrypto ? rates[fromCurr] : (1 / (rates[fromCurr] || 1))
    let parity = isToCrypto ? (unitUSD / (rates[toCurr] || 1)) : (unitUSD * (rates[toCurr] || 1))

    let toSym = symbols[toCurr] || toCurr
    let formattedResult = formatCurrencyAmount(result, isToCrypto)
    let formattedParity = formatCurrencyAmount(parity, isToCrypto)
    let updateTimeLabel = root.lastUpdated.length > 0 ? root.lastUpdated.split(" ").pop() : "Bugün"

    return {
      isCurrency: true,
      display: "= " + formattedResult + " " + toSym,
      subtitle: "1 " + fromCurr + " = " + formattedParity + " " + toSym + " • Son güncelleme: " + updateTimeLabel,
      rawValue: result.toFixed(isToCrypto ? 6 : 2),
      fromCurrency: fromCurr,
      toCurrency: toCurr,
      amount: amount,
      result: result
    }
  }

  function formatCurrencyAmount(val, isCrypto) {
    if (val === undefined || val === null || isNaN(val)) return "0.00"
    if (val >= 1000) {
      return val.toLocaleString(Qt.locale("tr_TR"), "f", 2)
    }
    if (isCrypto) {
      return val.toFixed(6)
    }
    return val.toLocaleString(Qt.locale("tr_TR"), "f", 2)
  }

  // =========================================================================
  // Zero-Process Reactive Cache Observer & IPC Listener
  // =========================================================================
  property var ratesFileView: FileView {
    path: root.cachePath
    preload: true
    printErrors: false
    onTextChanged: {
      root.loadCacheString(text())
    }
  }

  function loadCacheString(content) {
    if (!content || content.trim().length === 0) return
    try {
      let data = JSON.parse(content)
      if (data.rates) {
        root.rates = Object.assign({}, root.rates, data.rates)
      }
      if (data.timestamp) root.timestamp = data.timestamp
      if (data.last_updated) root.lastUpdated = data.last_updated
    } catch (e) {
      console.warn("[CurrencyEngine] JSON parse error in currency_rates.json:", e)
    }
  }

  Connections {
    target: root.ipc
    function onCurrencyRatesUpdated(payload) {
      if (!payload) return
      if (payload.rates) {
        root.rates = Object.assign({}, root.rates, payload.rates)
      }
      if (payload.timestamp) root.timestamp = payload.timestamp
      if (payload.last_updated) root.lastUpdated = payload.last_updated
    }
  }

  function refreshRates() {
    if (root.ipc) {
      root.ipc.requestCurrencyRates()
    } else if (ratesFileView && ratesFileView.text().length > 0) {
      loadCacheString(ratesFileView.text())
    }
  }

  Component.onCompleted: {
    if (ratesFileView && ratesFileView.text().length > 0) {
      loadCacheString(ratesFileView.text())
    }
    refreshRates()
  }
}
