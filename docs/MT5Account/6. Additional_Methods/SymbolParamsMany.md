# 📐 Full Spec of Every Symbol

> **Request:** the complete contract specification of **all** symbols in one call (`[SymbolParameters]`) — digits, point, lot limits, swaps, margins, currencies and more.

**API Information:**

* **Low-level API:** `MT5Account#symbol_params_many(sort:)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.AccountHelper`
* **Proto definition:** `SymbolParamsMany` (defined in `mt5-term-api-account-helper.proto`)

### RPC

* **Service:** `mt5_term_api.AccountHelper`
* **Method:** `SymbolParamsMany(SymbolParamsManyRequest) → SymbolParamsManyReply`
* **Low-level client (generated):** the SDK returns `data.symbol_infos` (an array of `SymbolParameters`).

---

## 💬 Just the essentials

* **What it is.** One (heavy) RPC returning the full spec of every symbol.
* **Why you need it.** Validate/round volumes, respect the min stop distance, compute pip size, pre-trade checks — all without per-symbol round-trips.
* **Sanity check.** `.find { |s| s.name == "EURUSD" }` returns a spec with non-zero `digits` / `point`.

---

## 🎯 Purpose

`symbol_params_many` is the **bulk spec** read — one round-trip for the whole catalog. Fetch it once at startup and **cache it** (index by `name`); every later "what's the min lot / point / stops level for X?" becomes a hash lookup instead of a network call.

> Need only a few fields of one symbol? The single-property reads ([`symbol_info_double`](../2.%20Symbol_Information/SymbolInfoDouble.md) / integer / string) are lighter.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  # Full spec of all symbols. Uses a longer internal deadline (big payload).
  def symbol_params_many(sort: nil) -> Array   # [Mt5TermApi::SymbolParameters]
end
```

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `sort` | `Symbol` *(keyword, optional)* | Optional ordering of the result. |

## 🧱 Sort enum — `AH_SYMBOL_PARAMS_MANY_SORT_TYPE` (all 4)

```protobuf
AH_PARAMS_MANY_SORT_TYPE_SYMBOL_NAME_ASC  = 0
AH_PARAMS_MANY_SORT_TYPE_SYMBOL_NAME_DESC = 1
AH_PARAMS_MANY_SORT_TYPE_MQL_INDEX_ASC    = 2
AH_PARAMS_MANY_SORT_TYPE_MQL_INDEX_DESC   = 3
```

## ⬆️ Output — `[SymbolParameters]` (key fields)

| Ruby accessor | Type | Description |
| ------------- | ---- | ----------- |
| `name` | `String` | Symbol. |
| `sym_description` | `String` | Long description. |
| `digits` | `Integer` | Price decimal places. |
| `point` | `Float` | Point size (pip = point × 10 on 3/5-digit symbols). |
| `trade_contract_size` | `Float` | Contract size (units per lot). |
| `volume_min` / `volume_max` / `volume_step` | `Float` | Lot limits and step. |
| `volume_limit` | `Float` | Max total volume per symbol. |
| `trade_stops_level` | `Integer` | Min SL/TP distance (points). |
| `trade_freeze_level` | `Integer` | Freeze distance (points). |
| `trade_tick_value` / `trade_tick_size` | `Float` | Tick value / size (sizing). |
| `swap_long` / `swap_short` | `Float` | Swap rates. |
| `margin_initial` / `margin_maintenance` | `Float` | Margins. |
| `currency_base` / `currency_profit` / `currency_margin` | `String` | Currencies. |
| `trade_mode` | `Symbol` | Trading mode enum. |
| `path` | `String` | Market Watch folder path. |

> `SymbolParameters` has **100+ fields** (session prices, Greeks, swap-per-weekday…). The table lists the ones you'll use most.

---

## 🧱 Enum values (outputs)

Each `SymbolParameters` row carries these enum-typed fields (as Ruby symbols). The big catalogues (`industry` = 152, `sector` = 14) are collapsed:

??? info "`sector` -> `BMT5_ENUM_SYMBOL_SECTOR` (14)"
    ```protobuf
    BMT5_SECTOR_UNDEFINED = 0
    BMT5_SECTOR_BASIC_MATERIALS = 1
    BMT5_SECTOR_COMMUNICATION_SERVICES = 2
    BMT5_SECTOR_CONSUMER_CYCLICAL = 3
    BMT5_SECTOR_CONSUMER_DEFENSIVE = 4
    BMT5_SECTOR_CURRENCY = 5
    BMT5_SECTOR_CURRENCY_CRYPTO = 6
    BMT5_SECTOR_ENERGY = 7
    BMT5_SECTOR_FINANCIAL = 8
    BMT5_SECTOR_HEALTHCARE = 9
    BMT5_SECTOR_INDUSTRIALS = 10
    BMT5_SECTOR_REAL_ESTATE = 11
    BMT5_SECTOR_TECHNOLOGY = 12
    BMT5_SECTOR_UTILITIES = 13
    ```

??? info "`industry` -> `BMT5_ENUM_SYMBOL_INDUSTRY` (152)"
    ```protobuf
    BMT5_INDUSTRY_UNDEFINED = 0
    BMT5_INDUSTRY_AGRICULTURAL_INPUTS = 1
    BMT5_INDUSTRY_ALUMINIUM = 2
    BMT5_INDUSTRY_BUILDING_MATERIALS = 3
    BMT5_INDUSTRY_CHEMICALS = 4
    BMT5_INDUSTRY_COKING_COAL = 5
    BMT5_INDUSTRY_COPPER = 6
    BMT5_INDUSTRY_GOLD = 7
    BMT5_INDUSTRY_LUMBER_WOOD = 8
    BMT5_INDUSTRY_INDUSTRIAL_METALS = 9
    BMT5_INDUSTRY_PRECIOUS_METALS = 10
    BMT5_INDUSTRY_PAPER = 11
    BMT5_INDUSTRY_SILVER = 12
    BMT5_INDUSTRY_SPECIALTY_CHEMICALS = 13
    BMT5_INDUSTRY_STEEL = 14
    BMT5_INDUSTRY_ADVERTISING = 15
    BMT5_INDUSTRY_BROADCASTING = 16
    BMT5_INDUSTRY_GAMING_MULTIMEDIA = 17
    BMT5_INDUSTRY_ENTERTAINMENT = 18
    BMT5_INDUSTRY_INTERNET_CONTENT = 19
    BMT5_INDUSTRY_PUBLISHING = 20
    BMT5_INDUSTRY_TELECOM = 21
    BMT5_INDUSTRY_APPAREL_MANUFACTURING = 22
    BMT5_INDUSTRY_APPAREL_RETAIL = 23
    BMT5_INDUSTRY_AUTO_MANUFACTURERS = 24
    BMT5_INDUSTRY_AUTO_PARTS = 25
    BMT5_INDUSTRY_AUTO_DEALERSHIP = 26
    BMT5_INDUSTRY_DEPARTMENT_STORES = 27
    BMT5_INDUSTRY_FOOTWEAR_ACCESSORIES = 28
    BMT5_INDUSTRY_FURNISHINGS = 29
    BMT5_INDUSTRY_GAMBLING = 30
    BMT5_INDUSTRY_HOME_IMPROV_RETAIL = 31
    BMT5_INDUSTRY_INTERNET_RETAIL = 32
    BMT5_INDUSTRY_LEISURE = 33
    BMT5_INDUSTRY_LODGING = 34
    BMT5_INDUSTRY_LUXURY_GOODS = 35
    BMT5_INDUSTRY_PACKAGING_CONTAINERS = 36
    BMT5_INDUSTRY_PERSONAL_SERVICES = 37
    BMT5_INDUSTRY_RECREATIONAL_VEHICLES = 38
    BMT5_INDUSTRY_RESIDENT_CONSTRUCTION = 39
    BMT5_INDUSTRY_RESORTS_CASINOS = 40
    BMT5_INDUSTRY_RESTAURANTS = 41
    BMT5_INDUSTRY_SPECIALTY_RETAIL = 42
    BMT5_INDUSTRY_TEXTILE_MANUFACTURING = 43
    BMT5_INDUSTRY_TRAVEL_SERVICES = 44
    BMT5_INDUSTRY_BEVERAGES_BREWERS = 45
    BMT5_INDUSTRY_BEVERAGES_NON_ALCO = 46
    BMT5_INDUSTRY_BEVERAGES_WINERIES = 47
    BMT5_INDUSTRY_CONFECTIONERS = 48
    BMT5_INDUSTRY_DISCOUNT_STORES = 49
    BMT5_INDUSTRY_EDUCATION_TRAINIG = 50
    BMT5_INDUSTRY_FARM_PRODUCTS = 51
    BMT5_INDUSTRY_FOOD_DISTRIBUTION = 52
    BMT5_INDUSTRY_GROCERY_STORES = 53
    BMT5_INDUSTRY_HOUSEHOLD_PRODUCTS = 54
    BMT5_INDUSTRY_PACKAGED_FOODS = 55
    BMT5_INDUSTRY_TOBACCO = 56
    BMT5_INDUSTRY_OIL_GAS_DRILLING = 57
    BMT5_INDUSTRY_OIL_GAS_EP = 58
    BMT5_INDUSTRY_OIL_GAS_EQUIPMENT = 59
    BMT5_INDUSTRY_OIL_GAS_INTEGRATED = 60
    BMT5_INDUSTRY_OIL_GAS_MIDSTREAM = 61
    BMT5_INDUSTRY_OIL_GAS_REFINING = 62
    BMT5_INDUSTRY_THERMAL_COAL = 63
    BMT5_INDUSTRY_URANIUM = 64
    BMT5_INDUSTRY_EXCHANGE_TRADED_FUND = 65
    BMT5_INDUSTRY_ASSETS_MANAGEMENT = 66
    BMT5_INDUSTRY_BANKS_DIVERSIFIED = 67
    BMT5_INDUSTRY_BANKS_REGIONAL = 68
    BMT5_INDUSTRY_CAPITAL_MARKETS = 69
    BMT5_INDUSTRY_CLOSE_END_FUND_DEBT = 70
    BMT5_INDUSTRY_CLOSE_END_FUND_EQUITY = 71
    BMT5_INDUSTRY_CLOSE_END_FUND_FOREIGN = 72
    BMT5_INDUSTRY_CREDIT_SERVICES = 73
    BMT5_INDUSTRY_FINANCIAL_CONGLOMERATE = 74
    BMT5_INDUSTRY_FINANCIAL_DATA_EXCHANGE = 75
    BMT5_INDUSTRY_INSURANCE_BROKERS = 76
    BMT5_INDUSTRY_INSURANCE_DIVERSIFIED = 77
    BMT5_INDUSTRY_INSURANCE_LIFE = 78
    BMT5_INDUSTRY_INSURANCE_PROPERTY = 79
    BMT5_INDUSTRY_INSURANCE_REINSURANCE = 80
    BMT5_INDUSTRY_INSURANCE_SPECIALTY = 81
    BMT5_INDUSTRY_MORTGAGE_FINANCE = 82
    BMT5_INDUSTRY_SHELL_COMPANIES = 83
    BMT5_INDUSTRY_BIOTECHNOLOGY = 84
    BMT5_INDUSTRY_DIAGNOSTICS_RESEARCH = 85
    BMT5_INDUSTRY_DRUGS_MANUFACTURERS = 86
    BMT5_INDUSTRY_DRUGS_MANUFACTURERS_SPEC = 87
    BMT5_INDUSTRY_HEALTHCARE_PLANS = 88
    BMT5_INDUSTRY_HEALTH_INFORMATION = 89
    BMT5_INDUSTRY_MEDICAL_FACILITIES = 90
    BMT5_INDUSTRY_MEDICAL_DEVICES = 91
    BMT5_INDUSTRY_MEDICAL_DISTRIBUTION = 92
    BMT5_INDUSTRY_MEDICAL_INSTRUMENTS = 93
    BMT5_INDUSTRY_PHARM_RETAILERS = 94
    BMT5_INDUSTRY_AEROSPACE_DEFENSE = 95
    BMT5_INDUSTRY_AIRLINES = 96
    BMT5_INDUSTRY_AIRPORTS_SERVICES = 97
    BMT5_INDUSTRY_BUILDING_PRODUCTS = 98
    BMT5_INDUSTRY_BUSINESS_EQUIPMENT = 99
    BMT5_INDUSTRY_CONGLOMERATES = 100
    BMT5_INDUSTRY_CONSULTING_SERVICES = 101
    BMT5_INDUSTRY_ELECTRICAL_EQUIPMENT = 102
    BMT5_INDUSTRY_ENGINEERING_CONSTRUCTION = 103
    BMT5_INDUSTRY_FARM_HEAVY_MACHINERY = 104
    BMT5_INDUSTRY_INDUSTRIAL_DISTRIBUTION = 105
    BMT5_INDUSTRY_INFRASTRUCTURE_OPERATIONS = 106
    BMT5_INDUSTRY_FREIGHT_LOGISTICS = 107
    BMT5_INDUSTRY_MARINE_SHIPPING = 108
    BMT5_INDUSTRY_METAL_FABRICATION = 109
    BMT5_INDUSTRY_POLLUTION_CONTROL = 110
    BMT5_INDUSTRY_RAILROADS = 111
    BMT5_INDUSTRY_RENTAL_LEASING = 112
    BMT5_INDUSTRY_SECURITY_PROTECTION = 113
    BMT5_INDUSTRY_SPEALITY_BUSINESS_SERVICES = 114
    BMT5_INDUSTRY_SPEALITY_MACHINERY = 115
    BMT5_INDUSTRY_STUFFING_EMPLOYMENT = 116
    BMT5_INDUSTRY_TOOLS_ACCESSORIES = 117
    BMT5_INDUSTRY_TRUCKING = 118
    BMT5_INDUSTRY_WASTE_MANAGEMENT = 119
    BMT5_INDUSTRY_REAL_ESTATE_DEVELOPMENT = 120
    BMT5_INDUSTRY_REAL_ESTATE_DIVERSIFIED = 121
    BMT5_INDUSTRY_REAL_ESTATE_SERVICES = 122
    BMT5_INDUSTRY_REIT_DIVERSIFIED = 123
    BMT5_INDUSTRY_REIT_HEALTCARE = 124
    BMT5_INDUSTRY_REIT_HOTEL_MOTEL = 125
    BMT5_INDUSTRY_REIT_INDUSTRIAL = 126
    BMT5_INDUSTRY_REIT_MORTAGE = 127
    BMT5_INDUSTRY_REIT_OFFICE = 128
    BMT5_INDUSTRY_REIT_RESIDENTAL = 129
    BMT5_INDUSTRY_REIT_RETAIL = 130
    BMT5_INDUSTRY_REIT_SPECIALITY = 131
    BMT5_INDUSTRY_COMMUNICATION_EQUIPMENT = 132
    BMT5_INDUSTRY_COMPUTER_HARDWARE = 133
    BMT5_INDUSTRY_CONSUMER_ELECTRONICS = 134
    BMT5_INDUSTRY_ELECTRONIC_COMPONENTS = 135
    BMT5_INDUSTRY_ELECTRONIC_DISTRIBUTION = 136
    BMT5_INDUSTRY_IT_SERVICES = 137
    BMT5_INDUSTRY_SCIENTIFIC_INSTRUMENTS = 138
    BMT5_INDUSTRY_SEMICONDUCTOR_EQUIPMENT = 139
    BMT5_INDUSTRY_SEMICONDUCTORS = 140
    BMT5_INDUSTRY_SOFTWARE_APPLICATION = 141
    BMT5_INDUSTRY_SOFTWARE_INFRASTRUCTURE = 142
    BMT5_INDUSTRY_SOLAR = 143
    BMT5_INDUSTRY_UTILITIES_DIVERSIFIED = 144
    BMT5_INDUSTRY_UTILITIES_POWERPRODUCERS = 145
    BMT5_INDUSTRY_UTILITIES_RENEWABLE = 146
    BMT5_INDUSTRY_UTILITIES_REGULATED_ELECTRIC = 147
    BMT5_INDUSTRY_UTILITIES_REGULATED_GAS = 148
    BMT5_INDUSTRY_UTILITIES_REGULATED_WATER = 149
    BMT5_INDUSTRY_UTILITIES_FIRST = 150
    BMT5_INDUSTRY_UTILITIES_LAST = 151
    ```

??? info "`chart_mode` -> `BMT5_ENUM_SYMBOL_CHART_MODE` (2)"
    ```protobuf
    BMT5_SYMBOL_CHART_MODE_BID = 0
    BMT5_SYMBOL_CHART_MODE_LAST = 1
    ```

??? info "`trade_calc_mode` -> `BMT5_ENUM_SYMBOL_CALC_MODE` (13)"
    ```protobuf
    BMT5_SYMBOL_CALC_MODE_FOREX = 0
    BMT5_SYMBOL_CALC_MODE_FOREX_NO_LEVERAGE = 1
    BMT5_SYMBOL_CALC_MODE_FUTURES = 2
    BMT5_SYMBOL_CALC_MODE_CFD = 3
    BMT5_SYMBOL_CALC_MODE_CFDINDEX = 4
    BMT5_SYMBOL_CALC_MODE_CFDLEVERAGE = 5
    BMT5_SYMBOL_CALC_MODE_EXCH_STOCKS = 6
    BMT5_SYMBOL_CALC_MODE_EXCH_FUTURES = 7
    BMT5_SYMBOL_CALC_MODE_EXCH_FUTURES_FORTS = 8
    BMT5_SYMBOL_CALC_MODE_EXCH_BONDS = 9
    BMT5_SYMBOL_CALC_MODE_EXCH_STOCKS_MOEX = 10
    BMT5_SYMBOL_CALC_MODE_EXCH_BONDS_MOEX = 11
    BMT5_SYMBOL_CALC_MODE_SERV_COLLATERAL = 12
    ```

??? info "`trade_mode` -> `BMT5_ENUM_SYMBOL_TRADE_MODE` (5)"
    ```protobuf
    BMT5_SYMBOL_TRADE_MODE_DISABLED = 0
    BMT5_SYMBOL_TRADE_MODE_LONGONLY = 1
    BMT5_SYMBOL_TRADE_MODE_SHORTONLY = 2
    BMT5_SYMBOL_TRADE_MODE_CLOSEONLY = 3
    BMT5_SYMBOL_TRADE_MODE_FULL = 4
    ```

??? info "`trade_exe_mode` -> `BMT5_ENUM_SYMBOL_TRADE_EXECUTION` (4)"
    ```protobuf
    BMT5_SYMBOL_TRADE_EXECUTION_REQUEST = 0
    BMT5_SYMBOL_TRADE_EXECUTION_INSTANT = 1
    BMT5_SYMBOL_TRADE_EXECUTION_MARKET = 2
    BMT5_SYMBOL_TRADE_EXECUTION_EXCHANGE = 3
    ```

??? info "`swap_mode` -> `BMT5_ENUM_SYMBOL_SWAP_MODE` (10)"
    ```protobuf
    BMT5_SYMBOL_SWAP_MODE_DISABLED = 0
    BMT5_SYMBOL_SWAP_MODE_POINTS = 1
    BMT5_SYMBOL_SWAP_MODE_CURRENCY_SYMBOL = 2
    BMT5_SYMBOL_SWAP_MODE_CURRENCY_MARGIN = 3
    BMT5_SYMBOL_SWAP_MODE_CURRENCY_DEPOSIT = 4
    BMT5_SYMBOL_SWAP_MODE_CURRENCY_PROFIT = 5
    BMT5_SYMBOL_SWAP_MODE_INTEREST_CURRENT = 6
    BMT5_SYMBOL_SWAP_MODE_INTEREST_OPEN = 7
    BMT5_SYMBOL_SWAP_MODE_REOPEN_CURRENT = 8
    BMT5_SYMBOL_SWAP_MODE_REOPEN_BID = 9
    ```

??? info "`swap_rollover_3days` -> `BMT5_ENUM_DAY_OF_WEEK` (7)"
    ```protobuf
    BMT5_SUNDAY = 0
    BMT5_MONDAY = 1
    BMT5_TUESDAY = 2
    BMT5_WEDNESDAY = 3
    BMT5_THURSDAY = 4
    BMT5_FRIDAY = 5
    BMT5_SATURDAY = 6
    ```

??? info "`filling_mode` -> `BMT5_ENUM_ORDER_TYPE_FILLING` (4)"
    ```protobuf
    BMT5_ORDER_FILLING_FOK = 0
    BMT5_ORDER_FILLING_IOC = 1
    BMT5_ORDER_FILLING_RETURN = 2
    BMT5_ORDER_FILLING_BOC = 3
    ```

??? info "`order_mode` -> `BMT5_ENUM_ORDER_TYPE` (9)"
    ```protobuf
    BMT5_ORDER_TYPE_BUY = 0
    BMT5_ORDER_TYPE_SELL = 1
    BMT5_ORDER_TYPE_BUY_LIMIT = 2
    BMT5_ORDER_TYPE_SELL_LIMIT = 3
    BMT5_ORDER_TYPE_BUY_STOP = 4
    BMT5_ORDER_TYPE_SELL_STOP = 5
    BMT5_ORDER_TYPE_BUY_STOP_LIMIT = 6
    BMT5_ORDER_TYPE_SELL_STOP_LIMIT = 7
    BMT5_ORDER_TYPE_CLOSE_BY = 8
    ```

??? info "`order_gtc_mode` -> `BMT5_ENUM_SYMBOL_ORDER_GTC_MODE` (3)"
    ```protobuf
    BMT5_SYMBOL_ORDERS_GTC = 0
    BMT5_SYMBOL_ORDERS_DAILY = 1
    BMT5_SYMBOL_ORDERS_DAILY_EXCLUDING_STOPS = 2
    ```

??? info "`option_mode` -> `BMT5_ENUM_SYMBOL_OPTION_MODE` (2)"
    ```protobuf
    BMT5_SYMBOL_OPTION_MODE_EUROPEAN = 0
    BMT5_SYMBOL_OPTION_MODE_AMERICAN = 1
    ```

??? info "`option_right` -> `BMT5_ENUM_SYMBOL_OPTION_RIGHT` (2)"
    ```protobuf
    BMT5_SYMBOL_OPTION_RIGHT_CALL = 0
    BMT5_SYMBOL_OPTION_RIGHT_PUT = 1
    ```

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `ApiError`. Longer internal deadline — this is a big payload, so **cache it**.
* **Pip size** = `point × (digits == 3 || digits == 5 ? 10 : 1)`.
* **Round volumes** to `volume_step` and clamp to `[volume_min, volume_max]` before trading.
* **Don't call it in a loop** — fetch once, index by `name`, reuse.

---

## 🔗 Usage Examples

### 1) One symbol's spec

```ruby
spec = acct.symbol_params_many.find { |s| s.name == "EURUSD" }
puts "digits #{spec.digits}  point #{spec.point}  min #{spec.volume_min}  step #{spec.volume_step}"
```

### 2) Round a volume to the symbol's step

```ruby
def round_volume(spec, lots)
  step = spec.volume_step.positive? ? spec.volume_step : 0.01
  v = (lots / step).round * step
  v.clamp(spec.volume_min, spec.volume_max)
end
```

### 3) Index the catalog once (cache)

```ruby
SPECS = acct.symbol_params_many.to_h { |s| [s.name, s] }
puts SPECS["EURUSD"].trade_contract_size
```

### 4) Smallest-min-lot instruments

```ruby
acct.symbol_params_many.sort_by(&:volume_min).first(5).each { |s| puts "#{s.name} #{s.volume_min}" }
```

---

## 🔧 Common Patterns

### Spec cache with lazy refresh

```ruby
class SpecCache
  def initialize(acct) = (@acct = acct; @by_name = {})
  def [](sym)
    @by_name = @acct.symbol_params_many.to_h { |s| [s.name, s] } if @by_name.empty?
    @by_name[sym]
  end
end
```

---

## 📚 See Also

* [TickValueWithSize](./TickValueWithSize.md) — just the sizing numbers.
* [SymbolInfoDouble](../2.%20Symbol_Information/SymbolInfoDouble.md) — one property at a time.
* **Friendly layer:** [`MT5Service#symbol_params` / `#symbol_params_all`](../../MT5Service/2.%20Symbol_Methods.md).

---

**Back to:** [Additional Methods — Overview](./Additional_Methods.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
