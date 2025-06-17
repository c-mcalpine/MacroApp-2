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
- Serverless API built with Next.js
- Deployed to Vercel
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

4. Provide configuration values using `--dart-define` when running or building.
   Example:
```bash
flutter run \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=SUPABASE_URL=your_supabase_url \
  --dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key
```

5. Build for iOS before archiving
```bash
flutter build ios --release \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=SUPABASE_URL=your_supabase_url \
  --dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key
cd ios && pod install
```
Then open `Runner.xcworkspace` in Xcode and archive the app.

### Backend Environment Variables

Create a `.env` file in `macro-app-api` with the following variables:

```
SUPABASE_URL=
SUPABASE_ANON_KEY=
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_VERIFY_SERVICE_SID=
OPENAI_API_KEY=
JWT_SECRET=
INSTACART_API_KEY=
INSTACART_STORE_ID=
UPSTASH_REDIS_REST_URL=
UPSTASH_REDIS_REST_TOKEN=
```

For the Flutter app, pass values via `--dart-define` as shown above. A sample set
of variables is listed in `.env.example` for reference.


## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## License
This project is licensed under the MIT License - see the LICENSE file for details. 
