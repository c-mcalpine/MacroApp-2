# MacroApp - Your Personal Meal Prep Assistant

MacroApp is a modern, user-friendly application designed to make meal preparation easier, cheaper, and more accessible for young adults. The app focuses on promoting healthy eating habits while making the process enjoyable and rewarding.

## Features

### Authentication & User Management
- Phone number-based authentication with OTP verification
- Secure user data storage
- Personalized user profiles
- Seamless login/logout functionality

### Recipe Management
- Browse through a curated collection of healthy recipes
- View detailed recipe information including ingredients and instructions
- Save favorite recipes for quick access
- Create custom recipe lists
- AI-powered recipe recommendations based on preferences

### Shopping & Meal Planning
- Generate shopping lists from selected recipes
- Instacart integration for easy grocery shopping
- Create grocery lists in Apple Notes (iOS)
- Track macro requirements and serving sizes
- Plan meals in advance

### User Experience
- Modern, sleek UI design appealing to Gen Z users
- Smooth animations and transitions
- Intuitive navigation
- Responsive layout for various screen sizes

## Technical Stack

### Frontend
- Flutter for cross-platform development
- Material Design components
- Custom animations and transitions
- State management with Provider
- Local storage with SharedPreferences

### Backend
- RESTful API architecture
- Supabase for data storage
- Environment variable management
- Secure authentication system

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- Git

### Installation
1. Clone the repository
```bash
git clone https://github.com/yourusername/macroapp.git
```

2. Navigate to the frontend directory
```bash
cd frontend
```

3. Install dependencies
```bash
flutter pub get
```

4. Create a .env file in the frontend directory with the following variables:
```
API_BASE_URL=your_api_base_url
```

5. Run the app
```bash
flutter run
```
6. Build for iOS before archiving
```bash
flutter build ios --release
cd ios && pod install
```
Then open `Runner.xcworkspace` in Xcode and archive the app.

### Backend Environment Variables

The API layer requires an Instacart API key and store ID for generating
shopping lists. Create a `.env` file in `macro-app-api` with the following
variables:

```
INSTACART_API_KEY=your_instacart_api_key
INSTACART_STORE_ID=your_store_id
```


## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## License
This project is licensed under the MIT License - see the LICENSE file for details. 
