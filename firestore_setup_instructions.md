# Firestore Setup & Rules Deployment Instructions

## Step 1: Open Firebase Console
1. Navigate to [Firebase Console](https://console.firebase.google.com/).
2. Select the project **fixmates-v2**.

## Step 2: Update Security Rules
1. In the left navigation menu, click on **Build** -> **Firestore Database**.
2. Click on the **Rules** tab at the top.
3. Replace the entire contents of the editor with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read: if request.auth != null;
      allow create, update: if request.auth != null && request.auth.uid == uid;
    }
    match /workers/{uid} {
      allow read: if request.auth != null;
      allow create, update: if request.auth != null && request.auth.uid == uid && request.resource.data.consentGiven == true;
    }
    match /leads/{leadId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }
    match /contactEvents/{id} {
      allow create, read: if request.auth != null;
    }
  }
}
```
4. Click **Publish**.

## Step 3: Firebase Authentication Providers
1. In Firebase Console, go to **Build** -> **Authentication** -> **Sign-in method**.
2. Ensure **Google** is Enabled.
3. Ensure **Phone** is Enabled.

## Step 4: Register Both Android Apps
1. Go to **Project Settings** (gear icon) -> **General** -> **Your apps**.
2. Ensure both Android package names are registered:
   - `com.fixmates.worker` (FixMates Worker)
   - `com.fixmates.customer` (FixMates)
3. Add the SHA-1 fingerprint to both apps:
   `6A:46:C1:95:24:DB:47:93:3E:A8:AF:90:6A:DC:CA:56:3D:B4:CF:75`
4. Download the respective `google-services.json` files and replace them in `android/app/` for each app.