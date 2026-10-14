# Cheesy Pizza - Fast Food Cafe Management System

A modern, professional Flutter application designed for managing a fast-food cafe with POS order-entry, thermal bill printing, recipe-based stock tracking, and sales & profit analytics.

---

## 🍕 Features Overview

### 1. Dashboard
- **Today's Operations Summary**: Displays live metrics for today's gross sales, estimated profit, completed orders, and total items sold.
- **Fast Food Items Breakdown**: Immediate counts of Pizzas, Burgers, Deals, Fries, and Drinks sold today.
- **Category-wise Sales Summary**: Visual breakdown with progress bars and revenue contribution.
- **Low-Stock Alert Banner**: Warns the cafe manager immediately if critical ingredients (cheese, flour, chicken, buns) fall below threshold.
- **Recent Orders & Instant Reprint**: Quick access to recent bills with one-tap thermal receipt or kitchen slip reprint.

### 2. Fast POS & Order Entry
- **Category Navigation Chips**: Filter by All, Pizza, Burgers, Deals, Fries, Drinks, and Extras.
- **Instant Product Customization**:
  - Multi-size selector (e.g., Small 7", Medium 10", Large 13", Jumbo 16") with dynamic pricing and costs.
  - Optional extra toppings (Extra Mozzarella, Olives, Jalapenos, Mushrooms, etc.).
  - Special preparation notes for the kitchen (e.g., "Crispy crust, less spicy").
- **Cart Sidebar**:
  - Order type selector: **Dine-in**, **Parcel/Takeaway**, and **Home Delivery**.
  - Quantity controls (`+` / `-`) and instant item removal.
  - Live subtotal, customizable discount in PKR, and net bill calculation.
  - Gross profit estimation per order.
  - Payment method selector: Cash, Card, Online.
  - Single-click checkout with automatic receipt and KOT kitchen slip generation.

### 3. Thermal Bill & Kitchen Slip Printing
- **Customer Thermal Bill (80mm standard)**:
  - Cafe Branding (*CHEESY PIZZA - Fast Food Cafe & Pizza Bar*).
  - Order number (`#CP-1001`), timestamp, order type, and table/delivery address.
  - Itemized table with product name, selected size, extra toppings, quantity, unit rate, and line total.
  - Subtotal, discount deduction, net total bill in PKR, and Code 128 order barcode.
- **Kitchen Slip (KOT)**:
  - Dedicated Kitchen Order Ticket with prominent order number, table/parcel badge, timestamp, bold item quantities, sizes, toppings, and kitchen prep notes.
- **Hardware Compatibility**: Ready for Bluetooth, USB, or Network ESC/POS thermal receipt printers via the `printing` and `pdf` packages.

### 4. Inventory & Recipe Stock Tracking
- **Ingredients Stock Monitoring**: Pre-configured with Mozzarella Cheese, Pizza Flour, Chicken Boneless, Brioche Buns, Pizza Sauce, Pepperoni, Fries, Soft Drinks, and Cooking Oil.
- **Automatic Recipe Deduction**: When an order is placed, ingredient quantities configured in the product recipes are automatically deducted from current inventory stock!
- **Low-Stock Warnings**: Visual badges and dedicated filter for ingredients needing restock.
- **Quick Restock Modal**: Allows cafe staff to add incoming supply quantities in one tap.

### 5. Sales Reports & Profit Analytics
- **Flexible Time Period Filter**: Today, This Week, This Month, or Custom Date Range (interactive date range picker).
- **Accurate Profit Calculation**: Calculates estimated net profit based on sold items and ingredient costs rather than treating revenue as profit.
- **Category-wise & Product-wise Performance Tables**:
  - Displays quantity sold, total revenue (PKR), ingredient costs (PKR), net profit (PKR), and profit margin percentage.

### 6. Design & Architecture
- **Theme**: Pizza red (`#C62828`), cheese yellow (`#FFA000`), crisp card surfaces, and dark charcoal (`#212529`).
- **Currency**: Formatted in Pakistani Rupee (`Rs. #,##0`).
- **State Management**: Flutter Riverpod with `StateNotifier` and immutable state models.
- **Data Storage**: Dual-layer architecture:
  - High-performance local storage (auto-seeded with realistic cafe menu & orders).
  - Cloud Firestore integration ready (`categories`, `products`, `inventory`, `orders`).

---

## 🚀 Running the App

### Prerequisites
- Flutter SDK (v3.19+ / Flutter 3.44+)
- Chrome / Edge (Web) or Windows desktop tools

### Run on Web or Windows Desktop:
```bash
# Get dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# Run on Windows Desktop
flutter run -d windows
```

### Run Tests:
```bash
flutter test
```
