# 🎯 TOEIC Tracker Admin Suite

**TOEIC Tracker Admin Suite** is a powerful internal management system designed to operate and optimize the TOEIC Tracker learning application. The system integrates advanced Artificial Intelligence (AI) to reduce data entry time by 90% and intelligently manage student data.

![Admin Banner](https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter)
![AI-Powered](https://img.shields.io/badge/AI-Gemini_1.5_Pro-orange?style=for-the-badge&logo=google-gemini)
![Desktop-Ready](https://img.shields.io/badge/Desktop-Electron-green?style=for-the-badge&logo=electron)

---

## ✨ Cutting-Edge Features

### 🤖 AI Auto Import (Mun AI)
A breakthrough exam digitization technology powered by **Gemini 1.5 Pro**. Simply upload an exam PDF and MP3 audio, and the AI will automatically analyze and extract data into a standard JSON format ready for the app in seconds.

### 🏝️ Dynamic Island Notifications
A modern status notification system inspired by iOS, providing a smooth and premium user experience on both Web and Desktop platforms.

### 📊 Resources & Dashboard
*   **Bandwidth/Storage Statistics**: Real-time estimation of Firebase resource usage.
*   **Leaderboard**: Visually track the top-performing students across the entire system.
*   **Streak System**: Monitor the study consistency and distribution of the student community.

---

## 🛠 Core Management Modules

### 👥 User Management
*   **Status Control**: Lock or unlock user accounts with a single tap.
*   **Detailed Profiles**: Track high scores, exam history, and consistency for each student.

### 📝 Exam Management (Exam CRUD)
*   **Comprehensive Workflow**: Create, edit, and manage exam metadata, time limits, and difficulty levels.
*   **Instant Publishing**: Toggle exam visibility on the user application in real-time.

### 📚 Question Bank
*   **Granular Control**: Manage question content, answer options, detailed explanations, and media URLs (Audio/Images).
*   **Auto-Categorization**: Automatically classify questions into standard TOEIC Parts (Part 1 - Part 7).

### 🔔 Notification Management (Push Notification)
*   **Real-time Interaction**: Send direct push notifications to student devices for new exams or important announcements.
*   **Broadcast History**: Store and manage sent notifications to optimize engagement campaigns.

---

## 🚀 Installation Guide

### 🌐 Web Version (Flutter Web)
To run the project as a Web application:

1.  **Install Dependencies**:
    ```powershell
    flutter pub get
    ```
2.  **Run Locally**:
    ```powershell
    flutter run -d chrome
    ```
3.  **Build for Production**:
    ```powershell
    flutter build web --release --base-href "./"
    ```

### 💻 Desktop Version (Electron)
The project supports packaging as a portable `.exe` for Windows via Electron:

1.  Open PowerShell in the project root directory.
2.  Run the automated build script:
    ```powershell
    ./build_desktop.ps1
    ```
    *This script builds the Flutter Web version and then triggers Electron-Builder to package it into a portable executable located in `build/desktop`.*

---

## 🔐 Security & AI Configuration

The project uses a dual-layer security mechanism for API Keys:
1.  **Firebase Config**: Pre-configured in `lib/config/firebase_config.dart`.
2.  **Gemini API Key**: To use the AI Auto Import feature, enter your API Key in the **Settings** menu within the Admin App. This key is securely stored in the `config/secrets` document on Firestore (accessible only by Administrators).

---

## 🛠 Tech Stack
*   **Framework**: Flutter (Web & Desktop)
*   **Backend**: Firebase (Auth, Firestore, Storage)
*   **AI Engine**: Google Gemini 1.5 Pro
*   **Desktop Wrapper**: Electron JS

---
💎 **Developed by Hung Den** - *Technological solutions for modern education.*
