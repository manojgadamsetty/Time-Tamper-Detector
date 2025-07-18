# Time Tamper Detector iOS App

A robust iOS application designed to detect time tampering on devices using system boot time analysis, trusted server time synchronization, and stored reference comparison.

## 🎥 Demo Video

> **Video File**: `Simulator Screen Recording - iPhone 16 - 2025-07-18 at 20.15.05.mp4`

### 📱 **What the Demo Shows:**
- Real-time time tamper detection in action
- Material Design UI with smooth animations  
- Three-tab navigation (Scanner, History, System Info)
- Network synchronization and offline detection
- Detailed scan results and confidence scoring
- Export functionality and system information

## Features

### 🔒 **Time Tamper Detection**
- **Network-based validation**: Synchronizes with trusted time servers (Apple, Google, Cloudflare)
- **Stored reference comparison**: Uses locally stored trusted time references for offline detection
- **Boot time analysis**: Leverages system boot time for tamper detection
- **Multi-layered confidence scoring**: High, Medium, and Low confidence levels

### 🎨 **Material Design UI**
- **Material Design components**: Custom-built components following Material Design principles
- **CRED-inspired interface**: Modern, card-based layout with smooth animations
- **Responsive design**: Optimized for all iPhone sizes
- **Dark/Light theme support**: Adaptive UI components

### 📊 **Comprehensive Monitoring**
- **Real-time scanning**: On-demand time integrity verification
- **Scan history**: Persistent storage of all detection results
- **System information**: Detailed device and time zone information
- **Export functionality**: JSON export of scan history

### 🧪 **Robust Testing**
- **Unit tests**: Comprehensive test coverage for all core components
- **Mock services**: Complete mock implementations for testing
- **Integration tests**: End-to-end testing scenarios

## Architecture

### 🏗️ **SOLID Principles Implementation**

#### **S - Single Responsibility Principle**
- `TimeTamperDetector`: Handles only time tampering detection logic
- `NetworkTimeService`: Manages network time fetching exclusively
- `TimeReferenceStorage`: Responsible only for data persistence
- `SystemTimeService`: Focuses solely on system time operations

#### **O - Open/Closed Principle**
- Protocol-based architecture allows extension without modification
- New detection methods can be added without changing existing code
- UI components are extensible through composition

#### **L - Liskov Substitution Principle**
- All service implementations are interchangeable through protocols
- Mock services can replace real services seamlessly
- ViewModels work with any implementation of service protocols

#### **I - Interface Segregation Principle**
- Focused protocols for each service type
- No forced implementation of unused methods
- Clean separation of concerns

#### **D - Dependency Inversion Principle**
- High-level modules depend on abstractions (protocols)
- Dependency injection throughout the application
- Easy testing through mock implementations

### 📁 **Project Structure**

```
Time Tamper Detector/
├── Models/
│   └── TimeTamperModel.swift           # Data models and configuration
├── Services/
│   ├── TimeTamperDetector.swift        # Core detection logic
│   ├── NetworkTimeService.swift       # Network time fetching
│   ├── TimeReferenceStorage.swift     # Data persistence
│   └── SystemTimeService.swift        # System time operations
├── ViewModels/
│   └── TimeTamperViewModel.swift       # MVVM view model
├── Views/
│   ├── Components/
│   │   └── MaterialComponents.swift   # Reusable UI components
│   ├── ContentView.swift              # Main tab view
│   ├── TimeTamperMainView.swift       # Primary scanning interface
│   ├── DetectionDetailsView.swift     # Detailed results view
│   ├── ScanHistoryView.swift          # History management
│   └── SystemInfoView.swift           # System information
└── Time_Tamper_DetectorApp.swift      # App entry point
```

## Detection Logic

### 🔍 **Multi-Layered Detection Approach**

1. **Primary: Network Synchronization**
   - Fetches time from multiple trusted servers
   - Compares device time with server time
   - Accounts for network latency
   - High confidence when successful

2. **Fallback: Stored Reference Comparison**
   - Uses previously stored trusted time references
   - Validates against device boot time
   - Checks for device reboots since reference creation
   - Medium to high confidence based on reference age

3. **Last Resort: Boot Time Analysis**
   - Analyzes system boot time patterns
   - Provides basic tamper detection
   - Low confidence due to limited data

### ⚙️ **Configuration Parameters**

```swift
struct TimeTamperConfig {
    static let maxAllowedTimeDrift: TimeInterval = 300 // 5 minutes
    static let referenceValidityDuration: TimeInterval = 86400 // 24 hours
    static let networkTimeoutDuration: TimeInterval = 10 // 10 seconds
    static let trustedTimeServers = [
        "time.apple.com",
        "time.google.com", 
        "pool.ntp.org",
        "time.cloudflare.com"
    ]
}
```

## User Interface

### 📱 **Main Features**

#### **Scanner Tab**
- Large, prominent scan button with animation
- Real-time status indicators
- Quick stats overview
- Detailed results with confidence scoring

#### **History Tab**
- Chronological list of all scans
- Filter by tampered/clean results
- Export functionality
- Detailed view for each scan

#### **System Tab**
- Device information display
- Current time and timezone details
- Boot time and uptime information
- Settings and configuration options

### 🎨 **Material Design Components**

- **MaterialCard**: Elevated cards with shadows and rounded corners
- **MaterialButton**: Consistent button styling with loading states
- **StatusIndicator**: Color-coded status indicators
- **AnimatedCheckmark/XMark**: Smooth result animations
- **InfoRow**: Consistent information display format

## 📸 Screenshots

| Scanner Interface | Detection Results | Scan History |
|:---:|:---:|:---:|
| ![Scanner](https://via.placeholder.com/300x600/007ACC/FFFFFF?text=Scanner+Tab) | ![Results](https://via.placeholder.com/300x600/28A745/FFFFFF?text=Detection+Results) | ![History](https://via.placeholder.com/300x600/6F42C1/FFFFFF?text=Scan+History) |

| System Information | Material Design | Settings |
|:---:|:---:|:---:|
| ![System](https://via.placeholder.com/300x600/FD7E14/FFFFFF?text=System+Info) | ![Design](https://via.placeholder.com/300x600/E83E8C/FFFFFF?text=Material+Design) | ![Settings](https://via.placeholder.com/300x600/20C997/FFFFFF?text=Settings) |

> **Replace placeholders**: Add actual screenshots by uploading images to GitHub and updating the URLs above.

## Testing

### 🧪 **Test Coverage**

#### **Unit Tests**
- `TimeTamperDetectorTests`: Core detection logic
- `TimeTamperViewModelTests`: ViewModel behavior
- `NetworkTimeServiceTests`: Network operations
- `TimeReferenceStorageTests`: Data persistence
- `SystemTimeServiceTests`: System operations

#### **Mock Services**
- `MockNetworkTimeService`: Network simulation
- `MockTimeReferenceStorage`: Storage simulation
- `MockSystemTimeService`: System operation simulation
- `MockTimeTamperDetector`: Detection logic simulation

#### **Test Scenarios**
- Successful time validation
- Tampering detection
- Network unavailability
- Stored reference validation
- Device reboot scenarios
- Data persistence verification

## Installation & Setup

### 📋 **Requirements**
- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

### 🚀 **Getting Started**

1. **Clone the repository**
   ```bash
   git clone [repository-url]
   cd Time-Tamper-Detector
   ```

2. **Open in Xcode**
   ```bash
   open "Time Tamper Detector.xcodeproj"
   ```

3. **Build and Run**
   - Select your target device/simulator
   - Press ⌘R to build and run

4. **Run Tests**
   - Press ⌘U to run all unit tests
   - View test results in the Test navigator

## Security Considerations

### 🔐 **Security Features**

- **Multiple time server validation**: Prevents single point of failure
- **Boot time correlation**: Detects system-level tampering
- **Encrypted local storage**: Protects stored time references
- **Network timeout protection**: Prevents hanging operations
- **Confidence scoring**: Provides transparency in detection reliability

### ⚠️ **Limitations**

- Requires network connectivity for highest confidence detection
- Cannot detect tampering that occurs before app installation
- Dependent on system API availability for boot time
- May have reduced accuracy in airplane mode

## Contributing

### 🤝 **Development Guidelines**

1. **Follow SOLID principles** in all new code
2. **Write unit tests** for all new functionality
3. **Maintain Material Design** consistency in UI
4. **Document public APIs** with comprehensive comments
5. **Use dependency injection** for testability

### 📝 **Code Style**

- Swift API Design Guidelines
- 4-space indentation
- 120-character line limit
- Comprehensive documentation comments

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions, issues, or contributions, please reach out through the project's issue tracker.

---

**Built with ❤️ using Swift, SwiftUI, and Material Design principles**
