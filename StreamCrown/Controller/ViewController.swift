//
//  ViewController.swift
//  StreamCrown
//
//  Created by Fatemeh on 9/22/22.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        Task{
            try await mainStream()
            
        }

        // Do any additional setup after loading the view.
    }
    
    func mainStream() async throws{
        
        let neurosity = Neurositysdk(options: K.options)
        try await neurosity.login(credentials: K.credentials)
        neurosity.brainwaves_raw(){
            data in
         
        }
        
    }


}

