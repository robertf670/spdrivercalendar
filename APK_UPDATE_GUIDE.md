# APK Update Guide - Preserving Google Calendar

## 🎯 **Recommended: In-Place Update** (Preserves Google Auth)

### **Option 1: Direct APK Install**
1. Download the new APK from GitHub Releases
2. **DO NOT uninstall** the existing app
3. Simply install the new APK directly over the old one
4. Android will update in-place, preserving all data

### **Option 2: Using ADB (If Available)**
```bash
adb install -r app-release.apk
```

## 🔧 **If Google Calendar Stops Working**

If you accidentally did a fresh install and Google Calendar breaks:

### **Quick Fix:**
1. Open the app → **Settings** (⚙️ icon)
2. Scroll to **Google Calendar** section  
3. Tap **"Re-authenticate Google"** (orange refresh icon)
4. Sign in again - your events will sync back

### **Manual Reset (If Re-auth Doesn't Work):**
1. **Settings** → **"Disconnect"** from Google Calendar
2. **Settings** → **"Connect Google Calendar"**  
3. Sign in fresh

## ⚠️ **APK Signing Important**

- APKs from GitHub Actions are signed with the **same debug key**
- Always download APKs from **official GitHub Releases**
- Don't install APKs from other sources (different signatures will force fresh install)

## ✅ **What Gets Preserved in Updates**
- ✅ All shift data
- ✅ Google Calendar authentication  
- ✅ App settings and preferences
- ✅ Rest day patterns
- ✅ Backup files

## 🚀 **Auto-Update Feature**
The app now automatically checks for updates and will guide you through the process! 