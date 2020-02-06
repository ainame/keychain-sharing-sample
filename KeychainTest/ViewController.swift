//
//  ViewController.swift
//  KeychainTest
//
//  Created by Satoshi Namai on 06/02/2020.
//  Copyright © 2020 Satoshi Namai. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    private let label: UILabel = {
        let label = UILabel()
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(stackView)
        stackView.addArrangedSubview(label)

        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: label.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: label.centerYAnchor),
        ])

        guard let bundleID = Bundle.main.bundleIdentifier,
            let accessGroup = Bundle.main.object(forInfoDictionaryKey: "SharedAccessGroup") as? String else { return }
        let keychain = Keychain(service: "tokyo.ainame.Keychain-Test-Service", sharedAccessGroup: accessGroup)

        do {
            if bundleID == "tokyo.ainame.Keychain-Test"  {
                print("save")
                try keychain.save("shared secret🔑", forKey: "abc", toSharedKeychain: true)
                let value = try keychain.readValue(forKey: "abc", fromSharedKeychain: true) ?? ""
                print(value)
                label.text = "scecret written: \(value)"
            } else {
                print("read")
                let secret = try keychain.readValue(forKey: "abc", fromSharedKeychain: true)
                label.text = "scecret read: \(secret ?? "")"
            }
        } catch {
            label.text = "error: \(error)"
        }
    }


}

