//
//  ViewController.swift
//  ARTestCode
//
//  Created by LeeWanJae on 12/16/24.
//

import ARKit
import RealityKit

final class ViewController: UIViewController {
    // MARK: - Properties
    var arView: ARView
    
    // MARK: - Initializer
    init() {
        arView = ARView(frame: .zero)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        setupARConfiguration()
    }
    
    // MARK: - UI
    private func setUI() {
        arView = ARView(frame: view.bounds)
        view.addSubview(arView)
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
}

// MARK: Delegate
extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let objectAnchor = anchor as? ARObjectAnchor {
                guard objectAnchor.referenceObject.name == "bottleScanTest" || objectAnchor.referenceObject.name == "diary" else { continue }
                
                print("객체가 인식되었습니다: \(objectAnchor.referenceObject.name ?? "이름 없음")")
                
                addARContent(objectAnchor: objectAnchor)
            }
        }
    }
    
    private func addARContent(objectAnchor: ARObjectAnchor) {
        let anchorEntity = AnchorEntity(anchor: objectAnchor)
        
        let modelEntity: ModelEntity
        do {
            modelEntity = try ModelEntity.loadModel(named: "anemone.usdz")
        } catch {
            print("anemone.usdz 파일을 로드할 수 없습니다: \(error.localizedDescription)")
            return
        }
        
        modelEntity.position = SIMD3(0, 0, 0)
    
        modelEntity.generateCollisionShapes(recursive: true)
        arView.installGestures([.translation, .rotation, .scale], for: modelEntity)

        anchorEntity.addChild(modelEntity)
        
        arView.scene.addAnchor(anchorEntity)
    }
}
