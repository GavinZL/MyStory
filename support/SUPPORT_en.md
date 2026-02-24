# MyStory Technical Support

Welcome to MyStory! This document will help you resolve common issues you may encounter while using the app.

**Last Updated: January 2025**

---

## 📱 App Information

- **App Name**: MyStory
- **Current Version**: 1.0.0
- **System Requirements**: iOS 16.0 or later
- **Supported Devices**: iPhone, iPad
- **App Size**: Approximately 50 MB
- **Supported Languages**: Simplified Chinese, English

---

## 📋 Table of Contents

1. [Features](#features)
2. [FAQ](#faq)
3. [Tutorials](#tutorials)
4. [Permissions](#permissions)
5. [Data Security](#data-security)
6. [Troubleshooting](#troubleshooting)
7. [Contact Us](#contact-us)

---

## Features

### ✨ Core Features

#### 1. Timeline Story Recording
- **Description**: Display all your stories in timeline format for intuitive life tracking
- **Supported Content**:
  - Text records (supports rich text format)
  - Images (multiple images supported)
  - Videos (automatic thumbnail generation)
  - Location information (optional)
- **How to Use**:
  - Tap "+" button at top right to create new story
  - Scroll up and down to browse historical stories
  - Tap card to view full content

#### 2. AI Text Polish
- **Description**: Use AI to intelligently optimize your text expression
- **Use Cases**:
  - Polish diary text
  - Optimize language expression
  - Adjust writing style
- **How to Use**:
  - Select text in story editor
  - Tap AI polish button in toolbar
  - Review and choose polished result

#### 3. Three-Level Category Management
- **Description**: Flexible category system to organize your stories
- **Category Levels**:
  - Level 1: Major categories (e.g., Travel, Work, Life)
  - Level 2: Sub-categories (e.g., Travel > Domestic)
  - Level 3: Fine categories (e.g., Travel > Domestic > Hangzhou Trip)
- **Customization Options**:
  - Custom category names
  - Choose icons (SF Symbols or custom)
  - Set display colors
  - Set display mode (card/list)

#### 4. Multimedia Support
- **Image Features**:
  - Select from photo library
  - Capture with camera
  - Multiple image upload
  - Image cropping
- **Video Features**:
  - Short video recording
  - Automatic thumbnail generation
  - Video preview playback

#### 5. Location Recording
- **Description**: Record where stories take place
- **Features**:
  - Auto-detect current location
  - Manual place search
  - Location search history
  - Map preview (reserved)
- **Privacy Protection**:
  - Location stored locally only
  - Not uploaded to any servers
  - Can delete location anytime

#### 6. Search Function
- **Search Scope**:
  - Story titles
  - Story content
  - Category names
  - Location information
- **Search Features**:
  - Keyword highlighting
  - Search history
  - Quick result navigation

#### 7. Settings & Personalization
- **Language Settings**:
  - Simplified Chinese
  - English
  - Real-time switching, no restart needed
- **Theme Settings**:
  - 7 theme options
  - Light/dark mode support
  - Real-time preview
- **Font Settings**:
  - 4 font sizes (Small, Standard, Large, Extra Large)
  - Real-time adjustment preview

#### 8. Data Sync
- **Device Migration**:
  - Peer-to-peer data transfer
  - No internet server needed
  - End-to-end encryption
  - PIN code security
- **Data Backup**:
  - Create local backups
  - Quick data restoration
  - Preserve complete data structure

---

## FAQ

### Q1: How to create a new story?
**A:** 
1. On timeline page, tap "+" button at top right
2. Enter story title and content
3. (Optional) Add images, videos, or location
4. (Optional) Select category
5. Tap "Save" to complete

### Q2: How many images can I add to a story?
**A:** No limit on quantity. However, for best viewing experience, we recommend no more than 9 images per story.

### Q3: How to use AI text polish feature?
**A:** 
1. In story editor, enter or select text to polish
2. Tap "AI Polish" button in toolbar
3. Wait for AI processing (usually 2-5 seconds)
4. Review polished results and select preferred version
5. Tap "Apply" to replace text in editor

**Note**: AI feature requires internet connection. Your text will be sent to Alibaba Cloud Tongyi Qianwen API for processing.

### Q4: Is location information required?
**A:** No, it's optional. Location is completely optional and you can disable location permission in system settings if not needed.

### Q5: How to create and manage categories?
**A:** 
1. Tap "Category" tab in bottom navigation
2. Tap "+" button at top right to create new category
3. Enter category name, select level and parent category
4. Choose icon and color
5. Tap "Save" to complete

**Edit Category**: In category list, swipe left on category card, select "Edit" or "Delete".

### Q6: What happens when I delete a category?
**A:** A confirmation dialog will show what will be deleted:
- The category itself
- All subcategories
- All stories under this category
- All related media files

**This action cannot be undone**. Please export important data before deletion.

### Q7: How to switch languages?
**A:** 
1. Go to "Settings" page
2. Tap "Language" option
3. Select desired language (Simplified Chinese or English)
4. Tap "Done"
5. App interface will switch immediately

### Q8: How to change theme?
**A:** 
1. Go to "Settings" page
2. Tap "Theme" option
3. Browse and select preferred theme
4. Theme applies to all pages instantly

Available themes: Classic, Ocean, Sunset, Night Sky, Forest, Lavender, Dark Mode.

### Q9: How to adjust font size?
**A:** 
1. Go to "Settings" page
2. Tap "Font" option
3. Drag slider or tap preset options (Small, Standard, Large, Extra Large)
4. Preview effect in real-time
5. Tap "Done" to save

### Q10: How to search for stories?
**A:** 
1. On timeline page, tap search bar at top
2. Enter keywords (searches titles, content, locations, categories)
3. View search results with highlighted keywords
4. Tap result to view full story

**Search History**: Recent searches appear in search bar, tap to quickly search again.

### Q11: Where is my data stored?
**A:** 
- **All data is stored locally on your device**
- Text content stored in Core Data database
- Images and videos encrypted with AES-256-GCM and stored in app sandbox
- Encryption keys stored in iOS system Keychain
- **We do not upload your data to any servers**

### Q12: How to migrate data to new phone?
**A:** Use built-in "Data Sync" feature:

**Old Phone (Sender)**:
1. Go to "Settings" > "Data Sync"
2. Tap "Create Local Sync Backup"
3. Tap "Start Connection" to search for receiver
4. Enter PIN code displayed on new phone
5. Tap "Send PIN Verification and Transfer"

**New Phone (Receiver)**:
1. Go to "Settings" > "Data Sync"
2. Tap "Wait for Data"
3. Note the 6-digit PIN code displayed
4. Wait for old phone to connect and transfer
5. Tap "Restore Data" after transfer completes

**Note**: Both devices need to be on same WiFi network or have Bluetooth enabled.

### Q13: How to clear cache?
**A:** 
1. Go to "Settings" page
2. Tap "Cache Cleanup" option
3. Confirm cleanup operation
4. System will clean temporary files and archives

**Note**: Cache cleanup won't affect your stories and media data, only temporary files.

### Q14: What if app crashes or freezes?
**A:** 
1. **Force quit app**: Double-tap Home button (or swipe up from bottom), find app and swipe up to close
2. **Restart device**: Long press power button, slide to power off, then restart
3. **Check storage**: Ensure device has sufficient free storage (recommend at least 1GB)
4. **Update app**: Check App Store for available updates
5. **Reinstall**: Uninstall and reinstall (Note: will clear all data, backup first)

### Q15: Why doesn't AI polish work?
**A:** Possible reasons:
1. **Network issue**: Check internet connection
2. **Service busy**: AI provider may be temporarily busy, try again later
3. **Text too long**: Single polish should not exceed 2000 characters
4. **Sensitive content**: Certain sensitive words may cause API rejection

---

## Tutorials

### 📝 Create Your First Story

#### Step 1: Enter Editor
- On timeline page, tap "+" button at top right
- Or in category page, tap "Create Story" on category card

#### Step 2: Fill Basic Information
- **Title**: Enter story title (required)
- **Content**: Enter story content, Markdown supported
- **Time**: Defaults to current time, manually adjustable

#### Step 3: Add Media (Optional)
- Tap "Add Image/Video" button
- Choose "Take Photo" or "Choose from Library"
- Can add multiple images or videos

#### Step 4: Add Location (Optional)
- Tap "Add Location" button
- Choose "Use Current Location" or "Search Place"
- Confirm location information

#### Step 5: Select Category (Optional)
- Tap "Select Category" button
- Browse and select appropriate category
- Supports multi-level category navigation

#### Step 6: Save Story
- Tap "Save" button at top right
- Story automatically saves and displays on timeline

---

### 🗂️ Manage Category System

#### Create Level 1 Category
1. Enter "Category" tab
2. Tap "+" button at top right
3. Enter category name (e.g., "Travel")
4. Select "Level 1 Category"
5. Choose icon and color
6. Tap "Save"

#### Create Level 2 Category
1. In category list, tap level 1 category to enter
2. Tap "+" button at top right
3. Enter category name (e.g., "Domestic")
4. Level automatically set to "Level 2 Category"
5. Parent category automatically selected
6. Choose icon and color
7. Tap "Save"

#### Create Level 3 Category
1. Navigate to level 2 category page
2. Tap "+" button at top right
3. Enter category name (e.g., "Hangzhou Trip")
4. Level automatically set to "Level 3 Category"
5. Parent category automatically selected
6. Choose icon and color
7. Tap "Save"

#### Category Display Modes
- **Card Mode**: Display as cards, suitable for visual browsing
- **List Mode**: Display as list, more compact information

Tap icon at top right of category page to switch modes.

---

### 🔍 Advanced Search Tips

#### Keyword Search
- Enter keywords directly, supports Chinese and English
- Automatically searches titles, content, locations, category names
- Search results highlight matched keywords

#### Search History
- Recent searches saved below search bar
- Tap history to quickly search again
- Tap "Clear" button to empty search history

#### View Search Results
- Results divided into categories and stories sections
- Tap category result to enter and view all stories
- Tap story result to view story details directly

---

### 🎨 Personalization

#### Theme Customization
1. Go to "Settings" > "Theme"
2. Browse 7 theme styles
3. Tap theme to view detailed description
4. Applies in real-time after selection
5. Theme affects entire app color scheme

#### Font Adjustment
1. Go to "Settings" > "Font"
2. View real-time preview content
3. Select appropriate font size
4. Font adjustment affects all text display

#### Language Switching
1. Go to "Settings" > "Language"
2. Select "Simplified Chinese" or "English"
3. Interface switches immediately
4. All text and date formats adjust accordingly

---

## Permissions

### 📸 Camera Permission
- **Purpose**: Take photos or record videos for stories
- **When Requested**: When first tapping camera button
- **Can Deny**: Yes, denying prevents camera use but can still select from library
- **How to Modify**: iPhone Settings > Privacy & Security > Camera > MyStory

### 🖼️ Photo Library Permission
- **Purpose**: Select existing photos or videos for stories
- **When Requested**: When first tapping select image/video button
- **Can Deny**: Yes, denying prevents library selection but can still use camera
- **How to Modify**: iPhone Settings > Privacy & Security > Photos > MyStory

### 📍 Location Permission
- **Purpose**: Record where stories take place
- **When Requested**: When first using location feature
- **Permission Type**: When In Use (not background location)
- **Can Deny**: Yes, location is completely optional
- **How to Modify**: iPhone Settings > Privacy & Security > Location Services > MyStory

### 📡 Local Network Permission
- **Purpose**: Peer-to-peer data sync between devices
- **When Requested**: When first using data sync feature
- **Can Deny**: Yes, denying prevents device-to-device migration
- **How to Modify**: iPhone Settings > Privacy & Security > Local Network > MyStory

### 🔵 Bluetooth Permission
- **Purpose**: Establish data sync connection with nearby devices
- **When Requested**: When first using data sync feature
- **Can Deny**: Yes, denying prevents device-to-device migration (if not on same WiFi)
- **How to Modify**: iPhone Settings > Privacy & Security > Bluetooth > MyStory

---

## Data Security

### 🔒 Data Storage Security

#### Local Storage
- **All data stored locally on your device**
- Uses iOS system secure sandbox mechanism
- Other apps cannot access your data

#### Encryption Protection
- **Text Content**: Stored in Core Data database
- **Media Files**: Encrypted using **AES-256-GCM** algorithm
- **Encryption Keys**: Stored in iOS system Keychain with system-level protection
- **Encryption Strength**: Military-grade encryption standard, secure and reliable

#### Data Transfer Security
- **Device Sync**: End-to-end encryption, data fully encrypted during transfer
- **PIN Code Verification**: 6-digit PIN ensures data transfers to correct device
- **No Server Transit**: Peer-to-peer transfer, data not uploaded to any internet servers

### 🛡️ Privacy Protection

#### We Do NOT Collect
- ❌ Your personal identity information
- ❌ Device unique identifiers (for tracking)
- ❌ Contact lists
- ❌ Browsing history
- ❌ Other app usage

#### We Only Process
- ✅ Story content you actively input (stored locally only)
- ✅ Images and videos you choose to add (encrypted storage)
- ✅ Location information you authorize (stored locally only)
- ✅ Your personalization settings (language, theme, etc.)

#### AI Service Notice
- When using AI text polish, your text is sent to **Alibaba Cloud Tongyi Qianwen API**
- We do **NOT** save your text content on servers
- AI service provider may process data according to their privacy policy
- Avoid entering sensitive personal information in AI polish

### 🗑️ Data Deletion

#### Delete Individual Story
- On timeline page, swipe left on story card
- Tap "Delete" button
- Confirm deletion
- Story and associated media files permanently deleted

#### Delete Category
- On category page, swipe left on category card
- Tap "Delete" button
- System prompts what will be deleted (subcategories, stories, media)
- Permanently deleted after confirmation

#### Clear Cache
- Go to "Settings" > "Cache Cleanup"
- Clean temporary files and archives
- Won't affect your stories and media data

#### Complete Data Deletion
- Uninstalling app deletes all local data
- Recommend using "Data Sync" to export data before uninstall

---

## Troubleshooting

### ⚠️ App Won't Start

**Possible Causes**:
- iOS version too old
- Insufficient storage
- App files corrupted

**Solutions**:
1. Check iOS version is 16.0 or higher
2. Free up device storage, keep at least 1GB available
3. Try restarting device
4. Reinstall app (note: backup data first)

### ⚠️ Images Won't Load

**Possible Causes**:
- File corrupted or missing
- Insufficient storage
- Permission issue

**Solutions**:
1. Check if photo library permission is enabled
2. Ensure device has sufficient storage
3. Try re-adding images
4. Contact technical support if issue persists

### ⚠️ Videos Won't Play

**Possible Causes**:
- Unsupported video format
- File corrupted
- Insufficient system resources

**Solutions**:
1. Supported formats: MP4, MOV
2. Try restarting app
3. Check device storage space
4. Try re-importing video

### ⚠️ Can't Get Location

**Possible Causes**:
- Location permission not enabled
- Weak GPS signal
- Location services disabled

**Solutions**:
1. Check location permission (iPhone Settings > Privacy & Security > Location Services)
2. Ensure location services are enabled
3. Move to open area, avoid indoor or tall buildings
4. Try manual place search

### ⚠️ AI Polish Failed

**Possible Causes**:
- Network connection issue
- AI service busy
- Text content issue

**Solutions**:
1. Check network connection
2. Try again later (service may be temporarily busy)
3. Reduce text length (recommend under 2000 characters)
4. Check if text contains sensitive words

### ⚠️ Data Sync Failed

**Possible Causes**:
- Devices not on same network
- Bluetooth or WiFi not enabled
- Incorrect PIN code

**Solutions**:
1. Ensure both devices on same WiFi network
2. Or ensure both devices have Bluetooth enabled
3. Check PIN code is entered correctly
4. Close app and try again
5. Restart both devices

### ⚠️ App Lagging or Slow

**Possible Causes**:
- Insufficient device performance
- Low storage space
- Too many cache files
- Large amount of data

**Solutions**:
1. Free up device storage
2. Use "Cache Cleanup" feature
3. Close other background apps
4. Restart device
5. If data is very large (over 1000 stories), consider archiving old data

### ⚠️ Interface Display Issues

**Possible Causes**:
- System language settings issue
- Theme conflict
- App cache problem

**Solutions**:
1. Try switching language then switching back
2. Re-select theme
3. Restart app
4. Restart device

---

## 📧 Contact Us

If you encounter issues not covered in this document, or have any suggestions, please contact us:

### Contact Methods
- **App Store Feedback**: Leave comments or ratings on App Store app page
- **Developer Contact**: Via developer contact information on App Store app details page
- **Privacy Policy**: View complete privacy protection statement in app "Settings" > "Privacy Policy"

### Feedback
We value your feedback. Please provide when contacting us:
1. **Issue Description**: Detailed description of the problem
2. **Device Info**: iPhone/iPad model, iOS version
3. **App Version**: Current app version number
4. **Reproduction Steps**: How to reproduce the issue
5. **Screenshots/Videos**: If possible, provide screenshots or screen recordings

### Response Time
- We respond within **5 business days** after receiving feedback
- Urgent issues prioritized
- Holidays may extend response time

---

## 📚 Additional Resources

### Privacy Policy
- View in app: Settings > Privacy Policy
- Learn how we protect your data

### App Updates
- Regularly check App Store updates
- Get latest features and performance improvements
- Fix known issues

### Usage Tips
- Regularly backup important data
- Plan category structure wisely
- Use search to quickly locate stories
- Try different themes to find best fit

---

## 🔄 Version History

### v1.0.0 (Current Version)
**Release Date**: January 2025

**New Features**:
- ✨ Timeline story recording
- ✨ AI text polish
- ✨ Three-level category management
- ✨ Multimedia support (images, videos)
- ✨ Location recording
- ✨ Full-text search
- ✨ Multi-language support
- ✨ Theme customization
- ✨ Device-to-device data migration
- ✨ Data encryption protection

---

## ⚖️ Legal Notice

This app is provided "as is". The developer is not liable for any direct or indirect damages resulting from app use. Users assume all risks associated with using this app.

This document content may change with app updates without prior notice. We recommend regularly checking the latest version of support documentation.

---

**Thank you for using MyStory. Enjoy!** 📖✨
