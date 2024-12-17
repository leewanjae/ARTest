//
//  ARMainView.swift
//  ARTestCode
//
//  Created by LeeWanJae on 12/16/24.
//

import ARKit
import RealityKit
import UIKit

final class ARMainView: UIViewController {
    // MARK: - Properties
    var referenceARObjectName = UILabel()
    var restartButton = UIButton()
    var arView = ARView(frame: .zero)
    var processedAnchors = Set<UUID>()
    var processedObjectName = Set<String>()
    
    // MARK: - Initializer
    init() {
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
        setupARConfiguration()
    }
    
    // MARK: - UI
    private func addView() {
        view.addSubview(arView)
        view.addSubview(referenceARObjectName)
        view.addSubview(restartButton)
    }
    
    private func setUI() {
        arView = ARView(frame: view.bounds)
        
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
            
            restartButton.topAnchor.constraint(equalTo: referenceARObjectName.topAnchor),
            restartButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
        ])
    }
    
    // MARK: - AR
    private func setupARConfiguration() {
        let configuration = ARWorldTrackingConfiguration()
        
        if let referenceObjects = ARReferenceObject.referenceObjects(inGroupNamed: "AR Resources", bundle: nil) {
            configuration.detectionObjects = referenceObjects
        }
        
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        arView.session.delegate = self
    }
    
    @objc private func restartARSession() {
        print("AR 세션 재시작")
        
        let configuration = ARWorldTrackingConfiguration()
        
        if let referenceObjects = ARReferenceObject.referenceObjects(inGroupNamed: "AR Resources", bundle: nil) {
            configuration.detectionObjects = referenceObjects
        }
        
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        processedAnchors.removeAll()
        DispatchQueue.main.async {
            self.referenceARObjectName.text = "AR Session Restarted"
        }
    }
}

// MARK: Delegate
extension ARMainView: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let objectAnchor = anchor as? ARObjectAnchor {
                guard !processedAnchors.contains(objectAnchor.identifier) else { continue }
                processedAnchors.insert(objectAnchor.identifier)
                
                guard let objectName = objectAnchor.referenceObject.name, !processedObjectName.contains(objectName) else {
                    print("이미 인식된 객체: \(objectAnchor.referenceObject.name ?? "이름 없음")")
                    continue
                }
                processedObjectName.insert(objectName)
                
                guard objectAnchor.referenceObject.name == "City" else { continue }
                
                let position = objectAnchor.transform.columns.3
                let x = position.x
                let y = position.y
                let z = position.z
                
                let xFormatted = String(format: "%.2f", x)
                let yFormatted = String(format: "%.2f", y)
                let zFormatted = String(format: "%.2f", z)
                
                DispatchQueue.main.async {
                    self.referenceARObjectName.text = "object: \(objectAnchor.referenceObject.name ?? "N/A"), x: \(xFormatted), y: \(yFormatted), z: \(zFormatted)"
                }
                
                print("객체 위치 - x: \(xFormatted), y: \(yFormatted), z: \(zFormatted)")
                print("객체가 인식되었습니다: \(objectAnchor.referenceObject.name ?? "이름 없음")")
                addARContent(objectAnchor: objectAnchor)
            }
        }
    }
    
    private func addARContent(objectAnchor: ARObjectAnchor) {
        let arObjectanchor = AnchorEntity(anchor: objectAnchor)
        
        let city: ModelEntity
        do {
            city = try ModelEntity.loadModel(named: "City")
        } catch {
            print("파일을 로드할 수 없습니다: \(error.localizedDescription)")
            return
        }
        
        city.position = SIMD3(0, 0, 0)
        city.generateCollisionShapes(recursive: true)
        
        arObjectanchor.addChild(city)
        
        arView.installGestures([.translation, .rotation, .scale], for: city)
        arView.scene.addAnchor(arObjectanchor)
    }
}
