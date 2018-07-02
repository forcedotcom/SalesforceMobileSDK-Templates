/*
  SyncProgressViewController.swift
  Consumer

  Created by Nicholas McDonald on 2/24/18.

 Copyright (c) 2018-present, salesforce.com, inc. All rights reserved.
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import UIKit

class SyncProgressViewController: UIViewController {
    
    var progressView = PercentLine()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = true
        
        self.view.backgroundColor = UIColor.white
        
        self.progressView.valueSuffix = "%"
        self.progressView.color = UIColor(displayP3Red: 0.145, green: 0.145, blue: 0.145, alpha: 1.0)
        self.progressView.trackColor = UIColor(displayP3Red: 0.8823, green: 0.8823, blue: 0.8823, alpha: 1.0)
        self.progressView.valueTextColor = UIColor(displayP3Red: 0.145, green: 0.145, blue: 0.145, alpha: 1.0)
        self.progressView.valueFont = UIFont(name: "HelveticaNeueLTStd-UltLt", size: 64)
        self.progressView.thickness = 4.0
        self.progressView.decimalCountToDisplay = 0
        self.progressView.capStyle = .butt
        self.progressView.showTrack = true
        self.progressView.goalValue = 100.0
        self.progressView.delegate = self
        self.view.addSubview(self.progressView)
        self.progressView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 20.0).isActive = true
        self.progressView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -20.0).isActive = true
        self.progressView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        self.progressView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.progressView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func updateProgress(_ progress:Float) {
        self.progressView.finalValue = progress
    }
}

extension SyncProgressViewController: PercentLineCompletionDelegate {
    func lineDidCompleteAnimation() {
        //
    }
}
