//
//  ARMainViewController.swift
//  ARTestCode
//
//  Created by LeeWanJae on 12/16/24.
//

import ARKit
import SceneKit
import UIKit
import SnapKit


final class ARMainViewController: UIViewController {
    // MARK: - Properties
    private let sceneView = ARSCNView()
    private let referenceARObjectName = UILabel()
    private let loadingView = UIView()
    private let loadingLabel = UILabel()
    private let loadingImage = UIImageView()
    private var detectedFloorY: Float?
    
    private var viewModel = ARMainViewModel()
    private let restartButton = DefaultButton()
    private let addModelButton = DefaultButton()
    private let lightButton = DefaultButton()
    
    // MARK: - Initialize
    init() {
        super.init(nibName: nil, bundle: nil)
        viewModel.setupLighting(sceneView: sceneView)
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
        sceneView.session.delegate = self
        sceneView.delegate = self
        viewModel.setupARSession(sceneView: sceneView)
        addGesture()
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
    }
    
    // MARK: - UI
    private func addView() {
        loadingView.addSubview(loadingLabel)
        loadingView.addSubview(loadingImage)
        
        view.addSubview(sceneView)
        view.addSubview(referenceARObjectName)
        view.addSubview(restartButton)
        view.addSubview(addModelButton)
        view.addSubview(lightButton)
        view.addSubview(loadingView)
    }
    
    private func setUI() {
        sceneView.frame = view.bounds
        
        referenceARObjectName.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        referenceARObjectName.textColor = .white
        referenceARObjectName.text = "Loading..."
        
        restartButton.setImage(UIImage(systemName: "trash"), for: .normal)
        restartButton.addTarget(self, action: #selector(restartARSession), for: .touchUpInside)
        
        addModelButton.setTitle("🐝", for: .normal)
        addModelButton.addTarget(self, action: #selector(addBeeButtonTapped), for: .touchUpInside)
        
        lightButton.setTitle(("☀️"), for: .normal)
        lightButton.addTarget(self, action: #selector(lightChange), for: .touchUpInside)
        
        
        loadingView.backgroundColor = .black
        loadingView.frame = view.bounds
        
        loadingLabel.text = " Park\n\nApple Park is the new home for 12,000 Apple employees.\nit is designed to combine an ideal working environment with \nthe natural beauty of the California native landscape."
        loadingLabel.numberOfLines = 0
        loadingLabel.textAlignment = .center
        loadingLabel.textColor = .white
        loadingLabel.font = .systemFont(ofSize: 10, weight: .bold)
        
        loadingImage.image = .appleLogo
        loadingImage.contentMode = .scaleAspectFit
    }
    
    private func setAutoLayout() {
        referenceARObjectName.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            $0.leading.equalTo(view.snp.leading).offset(10)
        }
        
        restartButton.snp.makeConstraints {
            $0.top.equalTo(referenceARObjectName.snp.bottom).offset(10)
            $0.leading.equalTo(referenceARObjectName.snp.leading)
            $0.width.height.equalTo(30)
        }
        
        loadingView.snp.makeConstraints {
            $0.leading.trailing.top.bottom.equalToSuperview()
        }
        
        loadingImage.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
            $0.width.height.equalTo(150)
        }
        
        loadingLabel.snp.makeConstraints {
            $0.top.equalTo(loadingImage.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
        }
        
        addModelButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalTo(view.snp.trailing).offset(-10)
            $0.width.height.equalTo(30)
        }
        
        lightButton.snp.makeConstraints {
            $0.top.equalTo(addModelButton.snp.bottom).offset(10)
            $0.trailing.equalTo(addModelButton.snp.trailing)
            $0.width.height.equalTo(30)
        }
    }
    
    
    // MARK: Action
    private func addGesture() {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(deleteBeeModelTapped(gesture:)))
        doubleTapGesture.numberOfTapsRequired = 2
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gesture:)))
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(gesture:)))
        
        let upGesture = UISwipeGestureRecognizer(target: self, action: #selector(upSwipeGesture(gesture:)))
        let downGesture = UISwipeGestureRecognizer(target: self, action: #selector(downSwipeGesture(gesture:)))
        
        upGesture.direction = .up
        downGesture.direction = .down
        
        sceneView.addGestureRecognizer(longPressGesture)
        sceneView.addGestureRecognizer(doubleTapGesture)
        sceneView.addGestureRecognizer(pinchGesture)
        sceneView.addGestureRecognizer(upGesture)
        sceneView.addGestureRecognizer(downGesture)
    }
    
    @objc private func restartARSession() {
        viewModel.restartARSession(for: sceneView)
        referenceARObjectName.text = "Loading..."
    }
    
    @objc private func addBeeButtonTapped() {
        viewModel.addBeeModel(sceneView: sceneView)
    }
    
    @objc private func deleteBeeModelTapped(gesture: UITapGestureRecognizer) {
        viewModel.deleteModel(sceneView: sceneView, model: "Bee")
    }
    
    @objc private func handleLongPress(gesture: UITapGestureRecognizer) {
        viewModel.rotateAnimation(sceneView: sceneView, parentNodeName: "APPLE_PARK", childNodeName: "Bee")
    }
    
    @objc private func lightChange() {
        let isDay = viewModel.toggleDayNightMode(sceneView: sceneView)
        lightButton.setTitle("\(isDay ? "☀️" : "🌙")", for: .normal)
    }
    
    @objc private func upSwipeGesture(gesture: UITapGestureRecognizer) {
        viewModel.updateTransformForNode(rootNode: sceneView.scene.rootNode, parentNodeName: "APPLE_PARK", childNodeName: "Object_2", direction: .up)
    }
    
    @objc private func downSwipeGesture(gesture: UITapGestureRecognizer) {
        viewModel.updateTransformForNode(rootNode: sceneView.scene.rootNode, parentNodeName: "APPLE_PARK", childNodeName: "Object_2", direction: .down)
    }
    
    @objc private func handlePinch(gesture: UIPinchGestureRecognizer) {
        viewModel.pinchModel(sceneView: sceneView, gesture: gesture, modelName: "APPLE_PARK")
    }
}

// MARK: Delegate
extension ARMainViewController: ARSessionDelegate, ARSCNViewDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if frame.camera.trackingState == .normal {
            DispatchQueue.main.async {
                self.loadingView.removeFromSuperview()
            }
        }
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let objectAnchor = anchor as? ARObjectAnchor {
                guard let objectName = objectAnchor.referenceObject.name, objectName == "InoFriendsTop" else {
                    print("필터링: \(objectAnchor.referenceObject.name ?? "알 수 없음")는 처리되지 않습니다.")
                    continue
                }
                
                let referenceObject = objectAnchor.referenceObject
                viewModel.visualBoundingBox(sceneView: sceneView, referenceObject: referenceObject)
                
                let position = anchor.transform.columns.3
                let xFormatted = String(format: "%.2f", position.x)
                let yFormatted = String(format: "%.2f", position.y)
                let zFormatted = String(format: "%.2f", position.z)
                
                referenceARObjectName.text = "object: \(objectAnchor.referenceObject.name ?? "N/A"), x: \(xFormatted), y: \(yFormatted), z: \(zFormatted)"
                
                viewModel.addObjectToScene(objectAnchor: objectAnchor, sceneView: sceneView, modelName: "APPLE_PARK", floorY: detectedFloorY)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            let planeY = planeAnchor.transform.columns.3.y
            if detectedFloorY == nil || planeY < detectedFloorY! {
                detectedFloorY = planeY
                print("바닥 Y 값 업데이트: \(detectedFloorY!)")
            }
        }
    }
}
