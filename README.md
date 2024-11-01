<p align="center" style="margin-top: 50px">
  <img src="assets/images/logo/nia.png" alt="NIA Logo" width="150">
</p>

<h1 align="center">NIA - Your AI Language Learning Assistant</h1>

<p align="center">
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Flutter-3.0+-blue.svg">
  </a>
  <a href="https://firebase.google.com">
    <img src="https://img.shields.io/badge/Firebase-Latest-orange.svg">
  </a>
  <a href="https://platform.openai.com">
    <img src="https://img.shields.io/badge/OpenAI-GPT--4o-green.svg">
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/badge/License-MIT-yellow.svg">
  </a>
</p>

<p align="center">
NIA is an artificial intelligence assistant designed for language learning and speaking skill development. By leveraging OpenAI's powerful language models, NIA provides an interactive and personalized learning experience, adapting to each user's needs and helping them practice any language they choose.
</p>

## Features
- [x] Voice-based AI Conversations
- [x] Multi-language Support (English, Spanish, Catalan)
- [x] Real-time Chat Interface
- [x] Social Authentication (Google, Facebook, Apple)
- [x] User Profiles
- [x] Low-latency Audio Processing
- [x] Cross-platform Support
- [ ] Chat History Timeline
- [ ] Advanced Language Analytics

## Project Structure
```
lib/
├── common_widgets/     # Reusable UI components
├── constants/          # App-wide constants
├── features/          
│   ├── authentication/ # Auth-related screens and logic
│   ├── core/          # Main app features
│   └── onboarding/    # User onboarding
├── repository/         # Data layer
├── routing/           # Navigation
└── utils/             # Helpers and utilities
```

## Getting Started
### Prerequisites
- Flutter SDK
- Dart SDK
- Firebase project setup
- OpenAI API key

### Installation
```bash
# Clone the repository
git clone https://github.com/bielcarpi/nia_flutter.git

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Configuration
1. Add Firebase configuration files:
    - `google-services.json` for Android
    - `GoogleService-Info.plist` for iOS
2. Update Firebase settings in `firebase_options.dart`
3. Configure API endpoints in repository classes

## Architecture
NIA uses the GetX framework for state management and follows a clean architecture pattern:
- **Features**: Modular app functionality
- **Repository**: Data management
- **Routing**: Navigation with middleware
- **Utils**: Helper functions

## Backend Integration
This app works in conjunction with [NIA Backend](https://github.com/bielcarpi/nia_backend) for audio processing and OpenAI integration.