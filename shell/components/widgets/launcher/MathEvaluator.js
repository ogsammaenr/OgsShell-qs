.pragma library

// ============================================================================
// MathEvaluator.js - Safe and Robust Mathematical Expression Evaluator
// ============================================================================

/**
 * Checks if input is a valid mathematical expression and calculates the result.
 * Returns an object { display, rawValue, expression, value } or null if invalid.
 */
function evaluate(input) {
  if (!input || typeof input !== "string") return null;

  let raw = input.trim();
  if (raw.length === 0) return null;

  // Hesap makinesi sadece '=' ile başlayan sorgularda tetiklenir (örn: = 5+5)
  if (!raw.startsWith("=")) {
    return null;
  }

  raw = raw.substring(1).trim();
  if (raw.length === 0) return null;

  // Words that are permitted in math queries
  const ALLOWED_WORDS = [
    "sqrt", "cbrt", "sin", "cos", "tan", "pow", "abs",
    "log", "ln", "round", "floor", "ceil", "pi", "e",
    "deg", "rad", "of"
  ];

  // Check for forbidden alphabet words (e.g., app names like "firefox", "gimp")
  let words = raw.match(/[a-zA-Z_]+/g) || [];
  for (let i = 0; i < words.length; i++) {
    let w = words[i].toLowerCase();
    if (ALLOWED_WORDS.indexOf(w) === -1) {
      return null;
    }
  }

  // Must contain at least one digit or constant
  let hasNumberOrConst = /[0-9]|pi\b|\be\b/i.test(raw);
  if (!hasNumberOrConst) return null;

  try {
    let cleanExpr = preprocess(raw);
    let tokens = tokenize(cleanExpr);
    if (!tokens || tokens.length === 0) return null;

    let parser = new Parser(tokens);
    let val = parser.parse();

    if (val === null || val === undefined || !isFinite(val)) {
      return null;
    }

    // Format output
    let rawStr = formatRaw(val);
    let displayStr = "= " + formatDisplay(val);

    return {
      display: displayStr,
      rawValue: rawStr,
      expression: raw,
      value: val
    };
  } catch (err) {
    // Incomplete or invalid syntax while user is typing
    return null;
  }
}

/**
 * Preprocesses natural language syntax (e.g. "15% of 200", "100 + 10%", "5 x 10")
 */
function preprocess(str) {
  let s = str;

  // Convert localized decimal comma between digits: "2,5" -> "2.5" (when not followed by space)
  s = s.replace(/(\d+),(\d+)/g, "$1.$2");

  // "x% of y" -> "(x / 100) * y"
  s = s.replace(/(\d+(?:\.\d+)?)\s*%\s*of\s*(\d+(?:\.\d+)?)/gi, "(($1 / 100) * $2)");

  // "a + b%" -> "a * (1 + (b / 100))"
  s = s.replace(/(\d+(?:\.\d+)?)\s*\+\s*(\d+(?:\.\d+)?)\s*%/g, "($1 * (1 + ($2 / 100)))");

  // "a - b%" -> "a * (1 - (b / 100))"
  s = s.replace(/(\d+(?:\.\d+)?)\s*\-\s*(\d+(?:\.\d+)?)\s*%/g, "($1 * (1 - ($2 / 100)))");

  // Standalone percentage "50%" -> "(50 / 100)"
  s = s.replace(/(\d+(?:\.\d+)?)\s*%/g, "($1 / 100)");

  // Degree support inside trigonometry: "90 deg" or "90deg" -> "(90 * 0.017453292519943295)"
  s = s.replace(/(\d+(?:\.\d+)?)\s*deg\b/gi, "($1 * 0.017453292519943295)");
  s = s.replace(/(\d+(?:\.\d+)?)\s*rad\b/gi, "$1");

  // Multiplication glyphs
  s = s.replace(/×/g, "*");
  s = s.replace(/÷/g, "/");

  // "5 x 10" or "5x10" when x is surrounded by digits or space
  s = s.replace(/(\d)\s*[xX]\s*(\d)/g, "$1 * $2");

  return s;
}

/**
 * Tokenizer
 */
function tokenize(str) {
  let tokens = [];
  let i = 0;
  let len = str.length;

  while (i < len) {
    let ch = str[i];

    if (/\s/.test(ch)) {
      i++;
      continue;
    }

    if (/[0-9]/.test(ch) || (ch === "." && i + 1 < len && /[0-9]/.test(str[i + 1]))) {
      let numStr = "";
      while (i < len && (/[0-9.]/.test(str[i]))) {
        numStr += str[i];
        i++;
      }
      tokens.push({ type: "NUM", value: parseFloat(numStr) });
      continue;
    }

    if (/[a-zA-Z_]/.test(ch)) {
      let word = "";
      while (i < len && /[a-zA-Z0-9_]/.test(str[i])) {
        word += str[i];
        i++;
      }
      let lower = word.toLowerCase();
      if (lower === "pi") {
        tokens.push({ type: "NUM", value: Math.PI });
      } else if (lower === "e") {
        tokens.push({ type: "NUM", value: Math.E });
      } else {
        tokens.push({ type: "FUNC", value: lower });
      }
      continue;
    }

    if ("+-*/%^(),".indexOf(ch) !== -1) {
      tokens.push({ type: "OP", value: ch });
      i++;
      continue;
    }

    // Unknown char
    return null;
  }

  return tokens;
}

/**
 * Recursive Descent Parser
 */
function Parser(tokens) {
  this.tokens = tokens;
  this.pos = 0;
}

Parser.prototype.peek = function() {
  return this.pos < this.tokens.length ? this.tokens[this.pos] : null;
};

Parser.prototype.consume = function(expectedVal) {
  let t = this.peek();
  if (!t) throw new Error("Unexpected end of input");
  if (expectedVal !== undefined && t.value !== expectedVal) {
    throw new Error("Expected " + expectedVal + " but got " + t.value);
  }
  this.pos++;
  return t;
};

Parser.prototype.parse = function() {
  let res = this.expr();
  if (this.pos < this.tokens.length) {
    throw new Error("Unconsumed tokens");
  }
  return res;
};

Parser.prototype.expr = function() {
  return this.add();
};

Parser.prototype.add = function() {
  let val = this.mul();
  while (true) {
    let t = this.peek();
    if (t && t.type === "OP" && (t.value === "+" || t.value === "-")) {
      this.consume();
      let right = this.mul();
      val = (t.value === "+") ? (val + right) : (val - right);
    } else {
      break;
    }
  }
  return val;
};

Parser.prototype.mul = function() {
  let val = this.power();
  while (true) {
    let t = this.peek();
    if (t && t.type === "OP" && (t.value === "*" || t.value === "/" || t.value === "%")) {
      this.consume();
      let right = this.power();
      if (t.value === "*") {
        val = val * right;
      } else if (t.value === "/") {
        if (right === 0) throw new Error("Division by zero");
        val = val / right;
      } else if (t.value === "%") {
        if (right === 0) throw new Error("Modulo by zero");
        val = val % right;
      }
    } else {
      break;
    }
  }
  return val;
};

Parser.prototype.power = function() {
  let val = this.unary();
  let t = this.peek();
  if (t && t.type === "OP" && t.value === "^") {
    this.consume();
    let right = this.power(); // right-associative
    val = Math.pow(val, right);
  }
  return val;
};

Parser.prototype.unary = function() {
  let t = this.peek();
  if (t && t.type === "OP" && (t.value === "+" || t.value === "-")) {
    this.consume();
    let operand = this.unary();
    return t.value === "-" ? -operand : operand;
  }
  return this.primary();
};

Parser.prototype.primary = function() {
  let t = this.peek();
  if (!t) throw new Error("Unexpected end of input");

  if (t.type === "NUM") {
    this.consume();
    return t.value;
  }

  if (t.type === "FUNC") {
    this.consume();
    let funcName = t.value;
    this.consume("(");
    let args = [];
    if (this.peek() && this.peek().value !== ")") {
      args.push(this.expr());
      while (this.peek() && this.peek().value === ",") {
        this.consume(",");
        args.push(this.expr());
      }
    }
    this.consume(")");

    switch (funcName) {
      case "sqrt": return Math.sqrt(args[0]);
      case "cbrt": return Math.cbrt(args[0]);
      case "sin": return Math.sin(args[0]);
      case "cos": return Math.cos(args[0]);
      case "tan": return Math.tan(args[0]);
      case "abs": return Math.abs(args[0]);
      case "log": return Math.log10 ? Math.log10(args[0]) : (Math.log(args[0]) / Math.LN10);
      case "ln": return Math.log(args[0]);
      case "pow": return Math.pow(args[0], args[1] !== undefined ? args[1] : 2);
      case "round": return Math.round(args[0]);
      case "floor": return Math.floor(args[0]);
      case "ceil": return Math.ceil(args[0]);
      default: throw new Error("Unknown function: " + funcName);
    }
  }

  if (t.type === "OP" && t.value === "(") {
    this.consume("(");
    let val = this.expr();
    this.consume(")");
    return val;
  }

  throw new Error("Unexpected token: " + t.value);
};

/**
 * Formats a number for rich UI presentation
 */
function formatDisplay(n) {
  if (Math.abs(n) >= 1e12 || (Math.abs(n) < 1e-6 && n !== 0)) {
    return n.toExponential(4);
  }
  if (Number.isInteger(n)) {
    return n.toLocaleString("en-US");
  }
  // Trim excessive trailing zeros
  let fixed = n.toFixed(4);
  let trimmed = parseFloat(fixed).toString();
  let parts = trimmed.split(".");
  let intPart = parseInt(parts[0]).toLocaleString("en-US");
  return parts.length > 1 ? (intPart + "." + parts[1]) : intPart;
}

/**
 * Formats a clean raw number for clipboard copying
 */
function formatRaw(n) {
  if (Number.isInteger(n)) return "" + n;
  if (Math.abs(n) >= 1e12 || (Math.abs(n) < 1e-6 && n !== 0)) {
    return "" + n;
  }
  return "" + parseFloat(n.toFixed(6));
}
