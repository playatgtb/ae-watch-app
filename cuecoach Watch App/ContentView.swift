
import SwiftUI
import HealthKit
import CoreMotion

struct HeartRateView: View {
    
    @State private var heartRate: Double = 0
    @State private var x: Double = 0
    @State private var y: Double = 0
    @State private var z: Double = 0
    
    @State private var accelerometerData: String = ""
    @State private var attitudeData: String = ""
    @State private var gyroData: String = ""
    
    
    var healthStore = HKHealthStore()
    
    var body: some View {
        VStack {
            Button(action: {self.getHeartRate()}) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.green)
                
                Text("heart rate: \(Int(self.heartRate))")
                    .font(.headline)
            }.padding([.bottom], 5)
            
            Text("Attitude Pitch,Roll,Yaw")
            Text(attitudeData).padding([.bottom], 5)
            
            Text("Accelerometer X,Y,Z")
            Text(accelerometerData)
        }
        .onAppear() {
            self.initialize()
        }
    }
    
    private func initialize() {
        self.authorizeHealthKit()
        self.heartRate = 0
        self.startAccelerometers()
        //self.getBsm()
    }
    
    let motion = CMMotionManager()

    func startAccelerometers() {
        var timer: Timer
        
        // Make sure motion hardware is available.
        if self.motion.isDeviceMotionAvailable {
           
           self.motion.accelerometerUpdateInterval = 1.0 / 2.0
           self.motion.startAccelerometerUpdates()
           self.motion.showsDeviceMovementDisplay = true
           self.motion.startDeviceMotionUpdates(using: .xMagneticNorthZVertical)

           timer = Timer(fire: Date(), interval: self.motion.accelerometerUpdateInterval, repeats: true, block: { (timer) in
               
             if let data = self.motion.accelerometerData {
                let x = data.acceleration.x
                let y = data.acceleration.y
                let z = data.acceleration.z

                 self.x = x
                 self.y = y
                 self.z = z
                 
                 accelerometerData = "\(String(format: "%.1f", x)), \(String(format: "%.1f", y)), \(String(format: "%.1f", z))"
             }
               
             if let data = self.motion.deviceMotion {
                // Get the attitude relative to the magnetic north reference frame.
                let p = data.attitude.pitch
                let r = data.attitude.roll
                let y = data.attitude.yaw
               
                attitudeData = "\(String(format: "%1.f", 180*p/Double.pi)), \(String(format: "%1.f", 180*r/Double.pi)), \(String(format: "%1.f", 180*y/Double.pi))"
             }

          })

           RunLoop.current.add(timer, forMode: RunLoop.Mode.default)
       }
    }
    
    private func authorizeHealthKit() {
        let quantityType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let allTypes = Set([
            HKObjectType.workoutType(),
            quantityType
        ])

        healthStore.requestAuthorization(toShare: nil, read: allTypes) { (result, error) in
            if let error = error {
                print ("error", error.localizedDescription)
              return
            }
            guard result else {
              print ("failed request")
              return
            }
            print ("yes authorized")
        }
    }
    
    private func getHeartRate() {
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { query, results, error in
            if let error = error {
                print("Error querying heart rate data: \(error.localizedDescription)")
                return
            }
            
            if let sample = results?.first as? HKQuantitySample {
                let heartRateUnit = HKUnit(from: "count/min")
                let heartRate = sample.quantity.doubleValue(for: heartRateUnit)
                DispatchQueue.main.async {
                    self.heartRate = heartRate
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    func getBsm() {
        let bsm = CMBatchedSensorManager()
        bsm.startDeviceMotionUpdates()
        if let data = bsm.deviceMotionBatch {
            print(data)
        } else {
            print("nada")
        }
    }
    
}
