import Foundation
import AVFoundation

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    private var audioPlayer: AVAudioPlayer?
    
    private init() {}
    
    enum AlertSound: String {
        case emergency = "emergency"
        case warning = "warning"
        case notification = "notification"
        
        var filename: String {
            switch self {
            case .emergency: return "emergency_alert.wav"
            case .warning: return "warning_alert.wav"
            case .notification: return "notification.wav"
            }
        }
    }
    
    func playSound(_ sound: AlertSound) {
        guard let soundURL = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") else {
            print("Could not find sound file: \(sound.filename)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Could not play sound: \(error.localizedDescription)")
        }
    }
    
    func stopSound() {
        audioPlayer?.stop()
    }
    
    // Play sound based on alert priority
    func playAlertSound(for priority: AlertPriority) {
        switch priority {
        case .immediate:
            playSound(.emergency)
        case .important:
            playSound(.warning)
        case .informational:
            playSound(.notification)
        }
    }
}
