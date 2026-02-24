# Privacy Policy

**Last Updated: January 2025**

---

## Introduction

Thank you for using MyStory. We take your privacy seriously and are committed to protecting your personal information. This Privacy Policy explains how we collect, use, store, and protect your personal data, as well as your rights regarding your information.

**Please read this Privacy Policy carefully to understand our practices regarding your personal data.** If you have any questions about this policy, please feel free to contact us.

---

## 1. Data Collection

### 1.1 What Information We Collect

MyStory is a completely local personal journal application. We only collect information that you actively provide while using the app:

- **Story Content**
  - Text content (titles, body text)
  - Media files such as photos and videos
  - Timestamps and dates you add

- **Location Information** (Optional)
  - Only collected when you explicitly authorize and use the location feature
  - Used to record location information for your stories
  - You can revoke location permission at any time in system settings

- **Categories and Settings Preferences**
  - Category structures you create
  - Personalized settings such as app theme, font size, and language

### 1.2 What We Do NOT Collect

We do **NOT** collect:
- Your contact list
- Your browsing history
- Usage information from other apps
- Device identifiers (for tracking purposes)
- Any data for advertising or analytics

---

## 2. Data Storage

### 2.1 Local Storage

**All your data is stored locally on your device. We do not upload your data to any cloud servers or third-party servers.**

- **Text Content**: Stored in Core Data database, managed by iOS system
- **Media Files**: Encrypted using **AES-256-GCM algorithm** and stored in the app's sandbox directory
- **Encryption Keys**: Stored in iOS Keychain with system-level protection
- **Settings**: Stored in Core Data database

### 2.2 Data Security

We use iOS system-level security mechanisms to protect your data:
- **Local Storage**: All data is stored on your device using iOS secure sandbox mechanism
- **Access Control**: Other apps cannot access your data

### 2.3 Data Backup

- If you enable iCloud backup, your app data may be included in iCloud backups
- You can manage backups in iPhone's "Settings > Apple ID > iCloud > Manage Storage"

---

## 3. Permissions

The app will request necessary system permissions when you first use related features. All permissions are optional, and you can deny them or modify them at any time in system settings.

### 3.1 Camera Permission
- **Purpose**: Take photos or record videos
- **When Requested**: When you first tap the camera button
- **Description**: NSCameraUsageDescription

### 3.2 Photo Library Permission
- **Purpose**: Select existing photos or videos to add to your stories
- **When Requested**: When you first tap the select image/video button
- **Description**: NSPhotoLibraryUsageDescription

### 3.3 Location Permission
- **Purpose**: Record location information for your stories
- **When Requested**: When you first use the location feature
- **Description**: NSLocationWhenInUseUsageDescription
- **Precision Control**: We only obtain "When In Use" location information, not background location
- **Privacy Protection**: Location information is processed to show place names rather than exact coordinates

### 3.4 Local Network and Bluetooth Permissions
- **Purpose**: For peer-to-peer data synchronization between devices
- **When Requested**: When you first use the data sync feature
- **Description**: NSLocalNetworkUsageDescription, NSBluetoothAlwaysUsageDescription
- **Use Case**: Only when you actively initiate data migration (e.g., switching to a new phone)

**You can view and modify these permissions at any time in "Settings > Privacy & Security". Denying permissions will not affect other app features.**

---

## 4. AI Services

### 4.1 AI Text Polish Feature

When you use the "AI Text Polish" feature:
- **Data Transfer**: Your selected text content will be sent to **Alibaba Cloud Tongyi Qianwen API** for processing
- **Data Retention**: We do **NOT** save any text content you send on our servers
- **Third-Party Processing**: Tongyi Qianwen API provider (Alibaba Cloud) may process data according to their privacy policy
- **Security Advice**: Do not input sensitive personal information such as ID numbers or bank card numbers in AI polish

### 4.2 Using AI Services

- AI features are **completely optional**, and you can choose not to use them
- You will be clearly notified before data is sent to third-party APIs
- You can stop using AI features at any time

---

## 5. Device-to-Device Data Sync

### 5.1 Sync Method

MyStory provides **peer-to-peer (P2P) data sync** functionality for migrating data when switching devices:
- **No Server Required**: Two devices connect directly via local network or Bluetooth to transfer data
- **PIN Code Verification**: Uses 6-digit PIN code for device pairing to prevent data from being received by wrong devices

### 5.2 Sync Process

1. **Sender (Old Phone)**: Creates backup package
2. **Receiver (New Phone)**: Generates PIN code and waits for connection
3. **Device Pairing**: Establishes connection via MultipeerConnectivity framework
4. **Data Transfer**: Backup data package is transferred over local network
5. **Data Restoration**: Receiver restores data

**Throughout the process, data is not uploaded to any internet servers.**

---

## 6. Your Rights

As a user of the app, you have complete control over your data:

### 6.1 Right to Access
- You can view all stories, media files, and category information stored in the app at any time
- The app provides complete browsing and search functionality

### 6.2 Right to Modify
- You can edit any saved story content at any time
- You can modify category structures, names, icons, etc.

### 6.3 Right to Delete
- You can delete individual stories, including their associated media files
- You can delete entire categories and all their contents
- You can clear temporary files via "Settings > Cache Cleanup"
- You can completely delete all data by uninstalling the app

### 6.4 Right to Export
- You can export all your data to another device via the "Data Sync" feature
- Exported data includes complete story content, media files, and category structures

---

## 7. Data Security

We take multiple technical and administrative measures to protect your data:

### 7.1 Encryption Protection
- **File Encryption**: All media files are encrypted using AES-256-GCM algorithm
- **Key Protection**: Encryption keys are stored in iOS Keychain with system-level protection
- **Transfer Encryption**: Device-to-device data transfers use end-to-end encryption

### 7.2 App Security
- **No Third-Party SDKs**: The app does not contain any third-party analytics, advertising, or statistics SDKs
- **No Network Tracking**: The app does not collect or upload your usage data
- **Minimal Permissions**: The app only requests necessary system permissions

### 7.3 System Integration
- **iOS Security Features**: Fully leverages iOS system security mechanisms (Keychain, App Sandbox, etc.)
- **Data Isolation**: App data is completely isolated from other apps

---

## 8. Children's Privacy

MyStory does not knowingly collect personal information from children under 13. If you are a parent or guardian and discover that your child has provided us with personal information without your consent, please contact us and we will promptly delete such information.

---

## 9. Third-Party Services

### 9.1 Tongyi Qianwen AI Service
- **Provider**: Alibaba Cloud Computing Co., Ltd.
- **Purpose**: AI text polish feature
- **Privacy Policy**: [Alibaba Cloud Privacy Policy](https://terms.aliyun.com/legal-agreement/terms/suit_bu1_ali_cloud/suit_bu1_ali_cloud202103041549_34132.html)

### 9.2 Other Notes
- Except for the AI service mentioned above, the app does not use any other third-party services
- The app does not contain advertising SDKs
- The app does not contain data analytics or statistics SDKs

---

## 10. International Data Transfers

Since app data is stored entirely locally on your device, there are no cross-border data transfers. When using the AI polish feature, text data may be transferred to Alibaba Cloud servers (located in mainland China), subject to Alibaba Cloud's privacy policy.

---

## 11. Policy Changes

### 11.1 Update Notifications
We may update this Privacy Policy from time to time to reflect:
- Changes in app functionality
- Legal and regulatory requirements
- Improvements in privacy protection technology

### 11.2 Effective Method
- Updated policies will be published within the app and marked with the update date
- Significant changes will be notified via in-app notifications or pop-ups
- Continued use of the app indicates your acceptance of the updated Privacy Policy

### 11.3 How to Review
You can view the latest version of the Privacy Policy at any time in "Settings > Privacy Policy".

---

## 12. Contact Us

If you have any questions, comments, or suggestions about this Privacy Policy, or need to exercise your rights, please contact us:

- **Contact Method**: Contact us through the developer contact information on the App Store
- **Response Time**: We will respond to your request within 15 business days

---

## 13. Governing Law

The interpretation, validity, and dispute resolution of this Privacy Policy shall be governed by the laws of the People's Republic of China. If any dispute or controversy arises between you and us, it should first be resolved through friendly negotiation; if negotiation fails, you agree to submit the dispute or controversy to the people's court with jurisdiction where our company is located.

---

## Appendix: Technical Details

### Data Storage Locations
- **App Sandbox**: `/var/mobile/Containers/Data/Application/[UUID]/`
- **Core Data**: `Documents/MyStory.sqlite`
- **Media Files**: `Documents/Media/`

---

**Thank you for trusting and using MyStory. We will continue to work hard to protect your privacy and data security.**

---

*This Privacy Policy was last updated in January 2025*
