# MT5 for Beginners

> New to MetaTrader 5? This is the 5-minute mental model you need before the code makes sense.

---

## What MT5 is

**MetaTrader 5 (MT5)** is a trading platform. Your **account** lives on a broker's **server** (e.g. `MetaQuotes-Demo`). Through it you trade **symbols** (instruments like `EURUSD` or `XAUUSD`).

This SDK talks to your MT5 terminal over the network (gRPC to `mt5.mrpc.pro:443`) so you can automate everything from Ruby.

> Always learn on a **demo** account. It trades with fake money on real prices — no risk.

---

## Getting a demo account & API key

**Registration and your API key are free.** Sign up at [mrpc.pro/signup](https://mrpc.pro/signup) and your key is provisioned automatically — nothing to generate; in the web Explorer it's even attached to every call for you. What costs money is **paid usage of the service** (for example the instant $1 demo below).

To run the SDK you also need an **MT5 demo account** (login / password / server). You can get one two ways:

### ⚡ Fastest — one click on mrpc.pro ($1)

Our **[MT5 Client API Explorer](https://mrpc.pro/explorer/mt5-client)** (a live API playground) spins up a demo account instantly — no terminal install:

1. Open the **[MT5 Client API Explorer](https://mrpc.pro/explorer/mt5-client)** (sign in first). Your **API key** is already shown at the top (*Active* · **Copy key**).
2. The demo **server is fixed to `MetaQuotes-Demo`**. Click **Open demo account ($1)**. The **$1 is charged to your MetaRPC balance** (the account that holds your API key) — *not* to a broker.
3. The demo is created **instantly** with a ready **login / password / server** — you can even run real API calls right on that page (the key is attached automatically).

![MT5 Client API Explorer — one-click demo account](../Guide_Images/mrpc-explorer-mt5.png)

Copy the demo **login / password / server**, then jump to [Getting Started](./GETTING_STARTED.md) to connect from Ruby.

### 🖥️ Free — create a demo in the MetaTrader 5 terminal

The no-cost route: create a MetaQuotes demo account directly in the MT5 terminal (free), and connect with your free API key — or with the literal value `"TRIAL"` for a quick first look.

**1 · Download & install MT5.** Get the terminal from **[metatrader5.com/download](https://www.metatrader5.com/en/download)** and install it.

**2 · Find the Navigator panel.** It's on the left, below *Market Watch*. Its **Accounts** section is where you add accounts.

![Navigator panel](../Guide_Images/1.%20NAV.png)

**3 · Open a new account.** Right-click **Accounts → Open an account** to bring up the broker-server search.

**4 · Pick the MetaQuotes demo server.** Find **MetaQuotes-Demo** (search if needed) and click **Next**.

![MetaQuotes server selection](../Guide_Images/2.%20META.png)

**5 · Choose "Open a new demo account"** and click **Next**.

![Open a new demo account](../Guide_Images/3.%20OPEN.png)

**6 · Fill in the form** (name, email; virtual deposit e.g. `$10,000`, leverage `1:100`, currency `USD`), accept the terms, **Next**.

![Account creation form](../Guide_Images/4.%20creator.png)

**7 · Save your credentials.** MT5 shows your **login**, **password** (master) and **server** (`MetaQuotes-Demo`). **Copy them now** — the SDK needs exactly these three values.

![Account credentials](../Guide_Images/5.%20OKK.png)

> Two passwords are shown: the **master** password trades; the **investor** password is read-only. Use the master password with the SDK.

---

## The money words

| Term | In one line |
| ---- | ----------- |
| **Balance** | Your settled money (no open trades counted). |
| **Equity** | Balance **plus** the profit/loss of trades you have open right now. |
| **Margin** | Money "reserved" while a trade is open. |
| **Free margin** | What's left to open new trades. |

When you open a trade, equity moves tick by tick. When you close it, the result folds into balance.

---

## Buying and selling

* **Buy** (go long) — you profit if the price **rises**.
* **Sell** (go short) — you profit if the price **falls**.

You trade in **lots** (volume). `0.01` is a micro lot — the smallest typical size, perfect for learning.

Two ways to enter:

* **Market order** — fill **now** at the current price.
* **Pending order** — wait for a price. A **LIMIT** waits for a better price; a **STOP** waits for a breakout.

---

## Protecting a trade

* **Stop-Loss (SL)** — auto-close if the price goes against you by so much. Caps the loss.
* **Take-Profit (TP)** — auto-close once you've made your target.

Set them as prices — compute the distances from **pips** (`pip = point × 10` on a 5-digit symbol):

```ruby
pip    = mt5.symbol_point("EURUSD") * 10
digits = mt5.symbol_digits("EURUSD")
q      = mt5.price("EURUSD")

# 20-pip stop, 40-pip target
mt5.buy_market_with_sl_tp("EURUSD", 0.01,
  sl: (q.bid - 20 * pip).round(digits),
  tp: (q.ask + 40 * pip).round(digits))
```

See [Risk Management](../MT5Sugar/11.%20Risk_Management.md) for sizing a trade to a fixed risk.

---

## MT5's model: orders, positions, deals

This trips up newcomers, so remember:

* An **order** is the *instruction*.
* A **position** is the resulting *open trade*.
* A **deal** is each *execution* (fill) that builds a position.

On MT5 these are **separate** things (unlike MT4). A filled market BUY gives you a **position**, identified by a **ticket**.

---

## Your first 10 lines

```ruby
require "metarpc_mt5"

mt5 = MetaRPC::MT5::MT5Sugar.create("mt5.mrpc.pro", 443, api_key: ENV["MRPC_API_KEY"])
mt5.quick_connect(login, "password", "MetaQuotes-Demo")

puts "balance #{mt5.balance.round(2)}"
r = mt5.buy_market("EURUSD", 0.01)          # tiny demo trade
mt5.close_position(r.order)                  # r.order is the position ticket
```

---

## Next steps

* [Getting Started](./GETTING_STARTED.md) — install and connect properly.
* [Your First Project](./Your_First_Project.md) — build something small.
* [Glossary](./GLOSSARY.md) — every term, defined.
* [MT5Sugar](../MT5Sugar/MT5Sugar.API_Overview.md) — the friendliest API.
