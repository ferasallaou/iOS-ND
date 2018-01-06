//
//  EffectsViewController.swift
//  P1 PitchPerfect
//
//  Created by Feras Allaou on 12/29/17.
//  Copyright © 2017 Feras Allaou. All rights reserved.
//

import UIKit
import AVFoundation

class EffectsViewController: UIViewController {
    
    var audioFile:AVAudioFile!
    var audioEngine:AVAudioEngine!
    var audioPlayerNode: AVAudioPlayerNode!
    var stopTimer: Timer!
    var recordedAudioURL: URL!
    let lowPitch: Float = 1000
    let highPitch: Float = -1000
    let slowSpeed: Float = 0.5
    let highSpeed: Float = 1.5
    
    @IBOutlet weak var slowButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var lowePitchButton: UIButton!
    @IBOutlet weak var highPitchButton: UIButton!
    @IBOutlet weak var fastModeButton: UIButton!
    @IBOutlet weak var reverbModeButton: UIButton!
    @IBOutlet weak var echoModeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        togglePlayPause(false, false)
        setupAudio()
        setButtonsAspect()
        // Do any additional setup after loading the view.
    }

    @IBAction func backAndDismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func effectButtonPressed(_ sender: Any) {
        let pressedButton = sender as! UIButton
        togglePlayPause(true, false)
        switch (pressedButton.tag)
        {
        case 0:
            playSound(pitch: lowPitch)
        case 1:
            playSound(pitch: highPitch)
        case 2:
            playSound(rate: slowSpeed)
        case 3:
            playSound(rate: highSpeed)
        case 4:
            playSound(reverb: true)
        case 5:
            playSound(echo: true)
        default: break
            //do nothing !
        }
    }
    
    @IBAction func playButtonPressed(_ sender: Any) {
        togglePlayPause(true, false)
        audioPlayerNode.play()
    }
    
    @IBAction func pauseButtonPressed(_ sender: Any) {
        audioPlayerNode.pause()
        togglePlayPause(false, true)
    }
    
    func togglePlayPause(_ pause: Bool, _ play: Bool){
        pauseButton.isEnabled = pause
        playButton.isEnabled = play
    }
    
    func setupAudio() {
        // initialize (recording) audio file
        do {
            audioFile = try AVAudioFile(forReading: recordedAudioURL as URL)
        } catch {
            showAlert(Alerts.AudioFileError, message: String(describing: error))
        }
    }
    
    @objc func stopAudio() {
        if let audioPlayerNode = audioPlayerNode {
            audioPlayerNode.stop()
        }
        
        if let stopTimer = stopTimer {
            stopTimer.invalidate()
        }
        
        //configureUI(.notPlaying)
        
        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.reset()
        }
        
        togglePlayPause(false, false)
    }
    
    func connectAudioNodes(_ nodes: AVAudioNode...) {
        for x in 0..<nodes.count-1 {
            audioEngine.connect(nodes[x], to: nodes[x+1], format: audioFile.processingFormat)
        }
    }
    
    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Alerts.DismissAlert, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func playSound(rate: Float? = nil, pitch: Float? = nil, echo: Bool = false, reverb: Bool = false) {
        
        // initialize audio engine components
        audioEngine = AVAudioEngine()
        
        // node for playing audio
        audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attach(audioPlayerNode)
        
        // node for adjusting rate/pitch
        let changeRatePitchNode = AVAudioUnitTimePitch()
        if let pitch = pitch {
            changeRatePitchNode.pitch = pitch
        }
        if let rate = rate {
            changeRatePitchNode.rate = rate
        }
        audioEngine.attach(changeRatePitchNode)
        
        // node for echo
        let echoNode = AVAudioUnitDistortion()
        echoNode.loadFactoryPreset(.multiEcho1)
        audioEngine.attach(echoNode)
        
        // node for reverb
        let reverbNode = AVAudioUnitReverb()
        reverbNode.loadFactoryPreset(.cathedral)
        reverbNode.wetDryMix = 50
        audioEngine.attach(reverbNode)
        
        // connect nodes
        if echo == true && reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, reverbNode, audioEngine.outputNode)
        } else if echo == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, audioEngine.outputNode)
        } else if reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, reverbNode, audioEngine.outputNode)
        } else {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, audioEngine.outputNode)
        }
        
        // schedule to play and start the engine!
        audioPlayerNode.stop()
        audioPlayerNode.scheduleFile(audioFile, at: nil) {
            
            var delayInSeconds: Double = 0
            
            if let lastRenderTime = self.audioPlayerNode.lastRenderTime, let playerTime = self.audioPlayerNode.playerTime(forNodeTime: lastRenderTime) {
                
                if let rate = rate {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate) / Double(rate)
                } else {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate)
                }
            }
            
            // schedule a stop timer for when audio finishes playing
            self.stopTimer = Timer(timeInterval: delayInSeconds, target: self, selector: #selector(self.stopAudio), userInfo: nil, repeats: false)
            RunLoop.main.add(self.stopTimer!, forMode: RunLoopMode.defaultRunLoopMode)
        }
        
        do {
            try audioEngine.start()
        } catch {
            showAlert(Alerts.AudioEngineError, message: String(describing: error))
            return
        }
        
        // play the recording!
        audioPlayerNode.play()
    }
    
       struct Alerts {
    static let DismissAlert = "Dismiss"
    static let RecordingDisabledTitle = "Recording Disabled"
    static let RecordingDisabledMessage = "You've disabled this app from recording your microphone. Check Settings."
    static let RecordingFailedTitle = "Recording Failed"
    static let RecordingFailedMessage = "Something went wrong with your recording."
    static let AudioRecorderError = "Audio Recorder Error"
    static let AudioSessionError = "Audio Session Error"
    static let AudioRecordingError = "Audio Recording Error"
    static let AudioFileError = "Audio File Error"
    static let AudioEngineError = "Audio Engine Error"
    }
    
    func setButtonsAspect(){
        slowButton.imageView?.contentMode = .scaleAspectFit
        fastModeButton.imageView?.contentMode = .scaleAspectFit
        echoModeButton.imageView?.contentMode = .scaleAspectFit
        reverbModeButton.imageView?.contentMode = .scaleAspectFit
        highPitchButton.imageView?.contentMode = .scaleAspectFit
        lowePitchButton.imageView?.contentMode = .scaleAspectFit
        playButton.imageView?.contentMode = .scaleAspectFit
        pauseButton.imageView?.contentMode = .scaleAspectFit
    }
}
