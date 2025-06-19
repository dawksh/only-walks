# Only Walks - Product Requirements Document

## Product Overview

**Product Name:** Only Walks  
**Platform:** iOS (Swift)  
**Target Audience:** Casual to serious walkers and runners who want a minimalist tracking experience

## Core Value Proposition

A clean, artistic approach to fitness tracking that transforms walking and running paths into beautiful pencil-style doodles, focusing on the journey rather than overwhelming metrics.

## Technical Architecture

### Core Technologies

-   **Language:** Swift 5.9+
-   **Minimum iOS Version:** iOS 15.0
-   **Frameworks:**
    -   Core Location (GPS tracking)
    -   MapKit (path processing)
    -   Core Graphics (doodle rendering)
    -   Core Data (local storage)
    -   HealthKit (optional integration)

### Authentication & Data Storage

-   Local-first architecture with optional cloud sync
-   Biometric authentication (Face ID/Touch ID) preferred
-   Core Data for local persistence
-   CloudKit for cross-device synchronization

## Feature Specifications

### 1. Authentication Flow

**Requirements:**

-   App launches to login screen if user not authenticated
-   Support for biometric authentication
-   Simple account creation flow
-   Automatic login persistence

**Technical Considerations:**

-   Keychain integration for secure credential storage
-   AuthenticationServices framework for secure authentication

### 2. Home Screen (Walk Gallery)

**UI Components:**

-   Vertical scrolling grid (2-3 columns on iPhone, adaptive)
-   Each cell displays pencil doodle representation of walk path
-   Empty state with animated pointer to "Start Walk" button
-   Pull-to-refresh functionality

**Doodle Rendering:**

-   Convert GPS coordinates to simplified path using Douglas-Peucker algorithm
-   Render with CGContext using pencil-like stroke properties:
    -   Variable line width (2-4 pts)
    -   Slight opacity variations (0.7-0.9)
    -   Subtle texture overlay
-   Cache rendered doodles as images for performance

**Grid Layout:**

-   UICollectionView with custom flow layout
-   Dynamic cell sizing based on walk duration/distance
-   Smooth scrolling with prefetching

### 3. Walk Detail View

**Transition:**

-   Hero animation from grid cell to full screen
-   Zoom effect with spring animation (duration: 0.6s, damping: 0.8)

**Information Display:**

-   Large doodle view (full width, 60% of screen height)
-   Metrics below doodle:
    -   **Distance:** Miles/kilometers with one decimal precision
    -   **Pace:** Minutes per mile/kilometer
    -   **Duration:** Hours:minutes:seconds format
-   Clean typography (SF Pro Display for headers, SF Pro Text for metrics)

### 4. Start Walk Button

**Positioning:**

-   Fixed bottom button (safe area + 20pt margin)
-   Full-width minus 32pt horizontal padding
-   54pt height with rounded corners (27pt radius)

**States:**

-   Default: "Start Walk" with walking icon
-   Active: "Stop Walk" with stop icon + elapsed time
-   Loading: Activity indicator during GPS acquisition

### 5. Walk Tracking

**Core Functionality:**

-   Background location tracking with significant location changes
-   Efficient battery usage with adaptive GPS accuracy
-   Real-time path visualization during active walk
-   Automatic pause detection for stationary periods >2 minutes

**Data Collection:**

-   GPS coordinates with timestamp
-   Calculate real-time metrics (distance, pace, duration)
-   Store raw coordinate data for post-processing

## User Experience Flow

### First Launch

1. Authentication screen
2. Location permissions request
3. HealthKit permissions (optional)
4. Empty state home screen with animated pointer

### Regular Usage

1. Home screen with walk gallery
2. Tap "Start Walk" → GPS acquisition → tracking begins
3. Live tracking view with current metrics
4. Tap "Stop Walk" → save confirmation → return to home
5. New walk appears in grid

### Walk Interaction

1. Tap walk card → hero animation
2. Detail view with full doodle and metrics
3. Swipe down or back button to return

## Performance Requirements

### Rendering Performance

-   Grid scrolling at 60fps minimum
-   Doodle rendering <100ms per walk
-   Hero animation smooth at 60fps
-   Memory usage <100MB for 1000+ walks

### Battery Optimization

-   GPS accuracy balanced for battery life
-   Background app refresh optimization
-   Efficient Core Data queries with proper indexing

### Storage Management

-   Compress coordinate data using binary encoding
-   Implement walk data pruning for very old walks
-   Cache management for rendered doodles

## Design Specifications

### Color Palette

-   **Primary:** System Blue (#007AFF)
-   **Background:** System Background (adaptive)
-   **Doodle Stroke:** Charcoal (#36454F)
-   **Text:** Label (adaptive)

### Typography

-   **Headers:** SF Pro Display Bold 24pt
-   **Metrics:** SF Pro Text Medium 18pt
-   **Body:** SF Pro Text Regular 16pt

### Spacing & Layout

-   **Grid Padding:** 16pt horizontal, 12pt vertical
-   **Cell Spacing:** 8pt
-   **Button Margins:** 20pt from safe areas
-   **Detail Padding:** 24pt horizontal

## Technical Implementation Notes

### GPS Processing

```swift
// Simplified path using Douglas-Peucker algorithm
func simplifyPath(_ coordinates: [CLLocationCoordinate2D], tolerance: Double) -> [CLLocationCoordinate2D]
```

### Doodle Rendering

```swift
// Core Graphics context for pencil effect
func renderDoodle(_ path: [CGPoint], in rect: CGRect) -> UIImage
```

### Animation Framework

-   Use UIView.animate with spring damping for hero transitions
-   CADisplayLink for smooth real-time tracking updates
-   Core Animation for button state transitions

## Success Metrics

### Engagement

-   Daily active users completing walks
-   Average walks per user per week
-   Session duration during active walks

### Technical Performance

-   App launch time <2 seconds
-   Walk save completion rate >98%
-   Crash-free sessions >99.5%

### User Experience

-   Time to start first walk <30 seconds
-   Walk detail view interaction rate
-   User retention at 7, 30, 90 days

## Future Considerations

### Phase 2 Features

-   Social sharing of doodle walks
-   Walk challenges and achievements
-   Export functionality (PDF, SVG)
-   Apple Watch companion app

### Technical Debt Prevention

-   Comprehensive unit tests for GPS processing
-   UI automation tests for critical flows
-   Performance monitoring and alerting
-   Accessibility compliance (VoiceOver, Dynamic Type)
