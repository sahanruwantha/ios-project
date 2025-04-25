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
    
    // Plays a specific alert sound from the app's sound library
    // Handles audio session setup and error handling
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
    
    // Immediately stops any currently playing alert sound
    // Used when alerts are dismissed or new sounds need to play
    func stopSound() {
        audioPlayer?.stop()
    }
    
    // Selects and plays appropriate alert sound based on priority level
    // Higher priority alerts have more attention-grabbing sounds
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
