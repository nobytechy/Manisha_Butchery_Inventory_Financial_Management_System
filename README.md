Manisha Butchery - Inventory & Financial Management System
<div align="center">
https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white
https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white
https://img.shields.io/badge/Platform-Android%2520%257C%2520iOS-brightgreen?style=for-the-badge
https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge

<h3>A comprehensive multi-shop inventory, stock transfer, and financial reporting system built with Flutter</h3>
</div>

📱 Overview
Manisha Butchery is a production-grade mobile application designed for butchery/meat processing businesses operating across multiple shop locations. The system provides real-time inventory tracking, inter-shop stock transfers, daily closing management, and comprehensive financial reporting.

Built with Flutter and SharedPreferences for local storage, this application demonstrates clean architecture, state management, and complex business logic implementation in a real-world context.
Why this project stands out:
🏪 Multi-shop architecture - Complete separation of inventory by location
🔄 Complex transfer logic - Shop-to-shop and product-to-product transfers with validation
📊 Financial reporting - Trading accounts, P&L statements, and key metrics calculation
📱 Professional UI/UX - Clean, intuitive interface with responsive design
💾 Local-first architecture - No internet required, data persisted locally

✨ Features
🏬 Shop Management
Multi-shop support - Create and manage multiple shop locations
Warehouse designation - Special shop type for central inventory
Shop-specific inventory - Complete separation of stock per location

📦 Product & Inventory
Product catalog - Manage products per shop with custom pricing
Real-time stock tracking - Live inventory counts with automatic calculations
Price history - Track all price changes with timestamps
Auto-closing - Automatic warehouse closing with zero balances

🔄 Transfer System
Shop-to-shop transfers - Move stock between any locations
Product-to-product transfers - Convert one product type to another
Transfer validation - Prevent self-transfers and invalid quantities
Incoming/Outgoing indicators - Clear visual distinction

📊 Stock Reports
Daily stock position - Opening stock, purchases, transfers in/out
Sales calculation - Auto-calculated from closing stock
Profit analysis - Per-product gross profit calculation
Theoretical vs Actual - Variance analysis

💰 Financial Reports
Trading Account - Opening stock + Purchases - Closing stock = COGS
Profit & Loss Statement - Gross profit - Expenses = Net profit
Expense tracking - Categorized expense management
Key metrics - Gross profit %, Net profit %, Expense ratio, Stock turnover
Date range filtering - Custom period analysis

🎨 Professional UI
Responsive design - Works on all screen sizes
Color-coded indicators - Green for profits/incoming, Red for losses/outgoing
Data tables - Horizontal scrolling for large datasets
Card-based layout - Clean, modern interface
Toast notifications - User feedback for all actions

🛠️ Technology Stack
Category	Technology	Purpose
Framework	Flutter 3.x	Cross-platform UI development
Language	Dart 3.x	Application logic
Storage	SharedPreferences	Local JSON persistence
State Management	setState + StatefulBuilder	Local UI state
UUID	uuid package	Unique identifier generation
Notifications	fluttertoast	User feedback
Date Handling	DateTime + intl	Date pickers and formatting
