BookSwap is a Flutter app that I built to help students swap textbooks with no need to buy new textbooks every time.

BookSwap Features
User Authentication - 
Book Listings -A user posts a book they want to trade with photos and the details of the book 
Swap Requests - A user can request and accept to swap books with other students
Real-time Chat - One can message another user to talk more about the swap
Live Updates - Everything sync automatically
Settings - Manages Notifications

Project Structure
lib/
├── models/           Data classes (User, Book, Swap, Message)
├── services/         Firebase interactions (Auth, Firestore, Storage)
├── providers/        State management with Provider pattern
├── screens/          UI screens (Auth, Home, Browse, Chat, etc.)
└── widgets/          Reusable components (buttons, cards, forms)

Architecture
The app flows a clean architecture with three main layers:
UI layer - Consumer widgets
State Management - Change Notifiers
Service layer - Firebase SDK

How data Flows
A user taps on My Listings then clicks on the plus sign, Encrypts the Book Tittle,Author, states what book he/she wants to swap for, Select the condition of the book(New,Like New Good,Used) and uploads an image then clicks post. UI updates automatically and one is able to see it on the home page of my listing page.

State Management
I used four providers:
AuthProvider -  User authentication
BookProvider -  Operates Book CRUD
SwapProvider -  Handles Swap Requests
SettingsProvider - User Preference

Firebase Setup:
Create a Firebase project at 
Enable Email/Password Authentication
Create a Firestore Database
Setup Firebase Storage for book cover images
Add Config files Android,IOS,Web

Firestore Security Rules
javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    match /books/{bookId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.ownerId;
    }
    match /swaps/{swapId} {
      allow read, create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.senderId 
                    || request.auth.uid == resource.data.receiverId;
    }
  }
}

How to Run it
git clone
Install dependencies using flutter pub get
flutter run 

Firestore collections
Users - user profile (name,email,verification)
Books - book listings (title,author,condition,image)
Swaps - swap requests (sender,receiver,status) 
Chat - real-time messages

Key Dependencies
 Package | Purpose |
|---------|---------|
| firebase_auth | Email/password authentication |
| cloud_firestore | Real-time NoSQL database |
| firebase_storage | Book cover image uploads |
| provider | State management |
| image_picker | Select and upload images |
| cached_network_image | Image caching |

Design Decisions
I chose Provider over Bloc since provider is more beginner friendly and easy to learn hence Bloc is complex
I also chose Firebase over custom backend since Firebase gave zero server maintenance and fast development.
I made verification compulsory to prevent fake accounts.
I used Firebase Storage integration since real images uploads with integration
I run Dart analyzer to check the quality of the code

flutter analyze 

To test
 flutter test
