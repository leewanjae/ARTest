//
//  ARMainViewController.swift
//  ARTestCode
//
//  Created by LeeWanJae on 12/16/24.
//

import ARKit
import RealityKit
import UIKit

final class ARMainViewController: UIViewController {
    // MARK: - Properties
    var referenceARObjectName: UILabel
    var restartButton: UIButton
    var arView: ARView
    
    private var viewModel: ARMainViewModel
    
    // MARK: - Initialize
    init() {
        self.referenceARObjectName = UILabel()
        self.restartButton = UIButton()
        self.arView = ARView(frame: .zero)
        self.viewModel = ARMainViewModel()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        addView()
        setAutoLayout()
        arView.session.delegate = self
        viewModel.setupARSession(arView: arView)
    }
    
    // MARK: - UI
    private func addView() {
        view.addSubview(arView)
        view.addSubview(referenceARObjectName)
        view.addSubview(restartButton)
    }
    
    private func setUI() {
        arView.frame = view.bounds
        
        referenceARObjectName.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        referenceARObjectName.textColor = .white
        referenceARObjectName.translatesAutoresizingMaskIntoConstraints = false
        referenceARObjectName.text = "Loading..."
        
        restartButton.setTitle("restart", for: .normal)
        restartButton.setTitleColor(.white, for: .normal)
        restartButton.translatesAutoresizingMaskIntoConstraints = false
        restartButton.addTarget(self, action: #selector(restartARSession), for: .touchUpInside)
    }
    
    private func setAutoLayout() {
        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            referenceARObjectName.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 10),
            referenceARObjectName.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            
            restartButton.topAnchor.constraint(equalTo: referenceARObjectName.bottomAnchor, constant: 10),
            restartButton.leadingAnchor.constraint(equalTo: referenceARObjectName.leadingAnchor)
        ])
    }
    
    @objc private func restartARSession() {
        viewModel.restartARSession(for: arView)
        referenceARObjectName.text = "Loading..."
    }
}

// MARK: Delegate
extension ARMainViewController: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let objectAnchor = anchor as? ARObjectAnchor {
                guard let objectName = objectAnchor.referenceObject.name, objectName == "4" else {
                    print("필터링: \(objectAnchor.referenceObject.name ?? "알 수 없음")는 처리되지 않습니다.")
                    continue
                }
                
                let position = objectAnchor.transform.columns.3
                
                let xFormatted = String(format: "%.2f", position.x)
                let yFormatted = String(format: "%.2f", position.y)
                let zFormatted = String(format: "%.2f", position.z)
                
                referenceARObjectName.text = "object: \(objectAnchor.referenceObject.name ?? "N/A"), x: \(xFormatted), y: \(yFormatted), z: \(zFormatted)"
                
                viewModel.addARContent(objectAnchor: objectAnchor, arView: arView)
            }
        }
    }
}
