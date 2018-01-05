//
//  RecordViewController.swift
//  P1 PitchPerfect
//
//  Created by Feras Allaou on 12/28/17.
//  Copyright © 2017 Feras Allaou. All rights reserved.
//

import UIKit
import AVFoundation

class RecordViewController: UIViewController, AVAudioRecorderDelegate {

    var audioRecorder:AVAudioRecorder!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var stopBtn: UIButton!
    @IBOutlet weak var textLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        flipBtnStatus(true)
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func recordBtnPressed(_ sender: Any) {
        flipBtnStatus(false)
        record()
    }
    
    @IBAction func stopBtnPressed(_ sender: Any) {
        flipBtnStatus(true)
        
        audioRecorder.stop()
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setActive(false)
    }
    
    func flipBtnStatus(_ status: Bool){
        recordButton.isEnabled = status
        stopBtn.isEnabled = !status
        textLabel.text = ((!status) ? "Recording...." : "Press to record")
    }
    
    func record(){
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)[0] as String
        let recordingName = "recordedVoice.wav"
        let pathArray = [dirPath, recordingName]
        let filePath = URL(string: pathArray.joined(separator: "/"))
        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSessionCategoryPlayAndRecord, with:AVAudioSessionCategoryOptions.defaultToSpeaker)
        
        try! audioRecorder = AVAudioRecorder(url: filePath!, settings: [:])
        audioRecorder.isMeteringEnabled = true
        audioRecorder.delegate = self
        audioRecorder.prepareToRecord()
        audioRecorder.record()
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag{
            performSegue(withIdentifier: "showEffects", sender: audioRecorder.url)
        }else{
            print("Error")
        }
    }
    
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEffects"{
            let myIntent = segue.destination as! EffectsViewController
            myIntent.recordedAudioURL = sender as! URL
        }
    }
}

