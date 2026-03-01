// GaitTrackingManager.swift
// Manages background workout session for persistent gait tracking
import Foundation
import HealthKit
import WatchKit
import Combine
import CoreMotion

final class GaitTrackingManager: NSObject, ObservableObject {
    @Published var isTracking = false
    @Published var workoutState: HKWorkoutSessionState = .notStarted
    
    private var workoutSession: HKWorkoutSession?
    private var healthStore: HKHealthStore?
    private let motionDetector: MotionDetector
    
    // Workout configuration
    private let workoutConfiguration = HKWorkoutConfiguration()
    
    init(motionDetector: MotionDetector) {
        self.motionDetector = motionDetector
        super.init()
        
        // Configure workout type for background execution
        workoutConfiguration.activityType = .walking
        workoutConfiguration.locationType = .outdoor
        
        // Request HealthKit authorization if available
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
            requestAuthorization()
        }
    }
    
    private func requestAuthorization() {
        guard let healthStore = healthStore else { return }
        
        let typesToShare: Set<HKSampleType> = [HKObjectType.workoutType()]
        let typesToRead: Set<HKObjectType> = [HKObjectType.workoutType()]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] success, error in
            if let error = error, error.localizedDescription.contains("entitlement") {
                #if DEBUG
                print("[GaitTrackingManager] HealthKit entitlement missing, will use fallback when tracking starts")
                #endif
                DispatchQueue.main.async { self?.healthStore = nil }
            }
        }
    }
    
    func startTracking() {
        guard !isTracking else { return }
        guard let healthStore = healthStore else {
            startTrackingWithoutWorkout()
            return
        }
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
            workoutSession?.delegate = self
            workoutSession?.startActivity(with: Date())
            isTracking = true
            #if DEBUG
            print("[GaitTrackingManager] Workout session started")
            #endif
        } catch {
            #if DEBUG
            print("[GaitTrackingManager] HealthKit unavailable (\(error.localizedDescription)), using fallback")
            #endif
            startTrackingWithoutWorkout()
        }
    }
    
    private func startTrackingWithoutWorkout() {
        // Start tracking without HealthKit workout session
        isTracking = true
        workoutState = .running
        
        // Trigger haptic when session begins
        WKInterfaceDevice.current().play(.start)
        
        #if DEBUG
        print("[GaitTrackingManager] Tracking started without workout session")
        #endif
    }
    
    func stopTracking() {
        guard isTracking else { return }
        
        workoutSession?.end()
        workoutSession = nil
        isTracking = false
        
        #if DEBUG
        print("[GaitTrackingManager] Tracking stopped")
        #endif
    }
}

// MARK: - HKWorkoutSessionDelegate

extension GaitTrackingManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async { [weak self] in
            self?.workoutState = toState
            
            switch toState {
            case .running:
                #if DEBUG
                print("[GaitTrackingManager] Workout session is running")
                #endif
            case .ended:
                #if DEBUG
                print("[GaitTrackingManager] Workout session ended")
                #endif
                self?.isTracking = false
            case .paused:
                #if DEBUG
                print("[GaitTrackingManager] Workout session paused")
                #endif
            case .prepared:
                #if DEBUG
                print("[GaitTrackingManager] Workout session prepared")
                #endif
            case .stopped:
                #if DEBUG
                print("[GaitTrackingManager] Workout session stopped")
                #endif
                self?.isTracking = false
            case .notStarted:
                #if DEBUG
                print("[GaitTrackingManager] Workout session not started")
                #endif
            @unknown default:
                #if DEBUG
                print("[GaitTrackingManager] Workout session unknown state")
                #endif
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        #if DEBUG
        print("[GaitTrackingManager] Workout session failed: \(error.localizedDescription), falling back to tracking without HealthKit")
        #endif
        
        DispatchQueue.main.async { [weak self] in
            self?.workoutSession?.end()
            self?.workoutSession = nil
            self?.startTrackingWithoutWorkout()
        }
    }
}
