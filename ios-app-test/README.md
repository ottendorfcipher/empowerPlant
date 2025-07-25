# EmpowerPlant iOS App Testing Guide

## Quick Setup Instructions

### Method 1: Create New Xcode Project (Recommended)

1. **Create New Project in Xcode:**
   - Open Xcode
   - File → New → Project
   - Choose **iOS** → **App**
   - Fill in details:
     - Product Name: `EmpowerPlantTest`
     - Interface: **SwiftUI**
     - Language: **Swift** 
     - Use Core Data: ❌ (unchecked)
     - Include Tests: ✅ (checked)

2. **Replace Default Code:**
   - Open the new project
   - Replace the contents of `ContentView.swift` with the code from `TestEmpowerPlantApp.swift`
   - Make sure to also replace the App file (`EmpowerPlantTestApp.swift`) entry point

3. **Build and Run:**
   - Select iPhone 16 Pro simulator
   - Press `Cmd + R` to build and run

### Method 2: Using Xcode Playgrounds

1. **Create Playground:**
   - Open Xcode
   - File → New → Playground
   - Choose **iOS** template

2. **Add Code:**
   ```swift
   import SwiftUI
   import PlaygroundSupport
   
   // Copy entire TestEmpowerPlantApp.swift content here
   
   // At the bottom, add:
   PlaygroundPage.current.setLiveView(TestAppContentView())
   ```

3. **Run:**
   - Click the play button in the playground

## What You'll Test

### 📱 App Features

**Dashboard Tab:**
- ✅ Welcome header with mock weather
- ✅ Quick stats cards (Plants: 3, Sensors: 3, Water: 125L, Alerts: 2)
- ✅ Recent activity feed with timestamps
- ✅ Chart placeholder for sensor trends

**Plants Tab:**
- ✅ List of 3 mock plants (Tomato, Lettuce, Bell Pepper)
- ✅ Health status indicators
- ✅ Camera buttons (placeholder functionality)
- ✅ Add plant sheet (tap + button)

**Sensors Tab:**
- ✅ 3 mock sensors with real-time values
- ✅ Status indicators (Active/Warning)
- ✅ Sensor types: Soil Moisture, Temperature, pH

**Weather Tab:**
- ✅ Current weather display (24°C, Partly Cloudy)
- ✅ Humidity and wind speed
- ✅ Weather icon and formatting

### 🧪 Testing Checklist

- [ ] App launches without errors
- [ ] All 4 tabs are accessible
- [ ] Navigation works smoothly
- [ ] Mock data displays correctly
- [ ] Add plant sheet opens and closes
- [ ] UI is responsive and well-formatted
- [ ] Colors and styling look professional
- [ ] Icons display properly

### 🔧 Testing Configuration

**Recommended Settings:**
- **Device:** iPhone 16 Pro Simulator
- **iOS Version:** 18.5
- **Orientation:** Portrait
- **Accessibility:** Test with larger text sizes

**Storage:** App uses in-memory mock data only - no persistence required for testing

### 🐛 Common Issues

1. **Build Errors:** Make sure iOS deployment target is set to iOS 16.0+
2. **Simulator Issues:** Try restarting the simulator if it's unresponsive
3. **Missing Icons:** All icons use SF Symbols, should work automatically

### 📈 Next Steps After Testing

Once the basic app is working:
1. Test on different device sizes (iPad, iPhone SE)
2. Test dark mode appearance
3. Verify accessibility features
4. Test with different iOS versions

## Advanced Testing

### Unit Testing Setup
```swift
// In your test target:
@testable import EmpowerPlantTest
import XCTest

class TestDataStoreTests: XCTestCase {
    func testMockDataLoading() {
        let store = TestDataStore()
        XCTAssertEqual(store.plants.count, 3)
        XCTAssertEqual(store.sensors.count, 3)
        XCTAssertNotNil(store.weatherData)
    }
}
```

### UI Testing Examples
```swift
func testTabNavigation() {
    let app = XCUIApplication()
    app.launch()
    
    // Test tab switching
    app.tabBars.buttons["Plants"].tap()
    XCTAssert(app.navigationBars["Plants"].exists)
    
    app.tabBars.buttons["Sensors"].tap()
    XCTAssert(app.navigationBars["Sensors"].exists)
}
```

---

**Ready to test!** 🚀 Follow Method 1 for the full iOS app experience.
