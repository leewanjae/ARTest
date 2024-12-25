//
//  ARMainViewController.swift
//  ARTestCode
//
//  Created by LeeWanJae on 12/16/24.
//

import ARKit
import RealityKit
import UIKit

import SnapKit

final class ARMainViewController: UIViewController {
    // MARK: - Properties
    private var arView = ARView()
    private var referenceARObjectName = UILabel()
    private var restartButton = UIButton()
    private var loadingView = UIView()
    private var loadingLabel = UILabel()
    private var loadingImage = UIImageView()
    private var addModelButton = UIButton()
    private var lightButton = UIButton()
    
    private var viewModel = ARMainViewModel()
    
    // MARK: - Initialize
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
        arView.session.delegate = self
        viewModel.setupARSession(arView: arView)
        addGesture()
    }
    
    // MARK: - UI
    private func addView() {
        loadingView.addSubview(loadingLabel)
        loadingView.addSubview(loadingImage)
        
        view.addSubview(arView)
        view.addSubview(referenceARObjectName)
        view.addSubview(restartButton)
        view.addSubview(addModelButton)
        view.addSubview(lightButton)
        view.addSubview(loadingView)
    }
    
    private func setUI() {
        arView.frame = view.bounds
        
        referenceARObjectName.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        referenceARObjectName.textColor = .white
        referenceARObjectName.text = "Loading..."
        
        restartButton.setImage(UIImage(systemName: "trash"), for: .normal)
        restartButton.tintColor = .black
        restartButton.backgroundColor = .white
        restartButton.layer.shadowRadius = 5
        restartButton.layer.shadowOpacity = 0.5
        restartButton.layer.cornerRadius = 10
        restartButton.addTarget(self, action: #selector(restartARSession), for: .touchUpInside)
        
        addModelButton.setTitle("🐝", for: .normal)
        addModelButton.backgroundColor = .white
        addModelButton.layer.shadowColor = UIColor.black.cgColor
        addModelButton.layer.shadowRadius = 5
        addModelButton.layer.shadowOpacity = 0.5
        addModelButton.layer.cornerRadius = 10
        addModelButton.addTarget(self, action: #selector(addBeeButtonTapped), for: .touchUpInside)
        
        lightButton.backgroundColor = .white
        lightButton.layer.shadowColor = UIColor.black.cgColor
        lightButton.layer.shadowRadius = 5
        lightButton.layer.shadowOpacity = 0.5
        lightButton.layer.cornerRadius = 10
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
    
    private func addGesture() {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(deleteBeeModelTapped(gesture:)))
        doubleTapGesture.numberOfTapsRequired = 2
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gesture:)))
        
        let swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(upSwipeGesture(gesture:)))
        swipeUpGesture.direction = .up
        
        arView.addGestureRecognizer(longPressGesture)
        arView.addGestureRecognizer(doubleTapGesture)
        arView.addGestureRecognizer(swipeUpGesture)
    }
    
    // MARK: @objc
    @objc private func restartARSession() {
        viewModel.restartARSession(for: arView)
        referenceARObjectName.text = "Loading..."
    }
    
    @objc private func addBeeButtonTapped() {
        viewModel.addBeeModel(arView: arView)
    }
    
    @objc private func deleteBeeModelTapped(gesture: UITapGestureRecognizer) {
        viewModel.deleteModel(arView: arView, model: "Bee")
    }
    
    @objc private func handleLongPress(gesture: UITapGestureRecognizer) {
        viewModel.toggleBeeAnimation(arView: arView)
    }
    
    @objc private func upSwipeGesture(gesture: UITapGestureRecognizer) {
    }
    
    @objc private func lightChange() {
        if let isDay = viewModel.toggleLightMode(arView: arView) {
            lightButton.setTitle("\(isDay ? "☀️" : "🌙")", for: .normal)
        }
    }
}

// MARK: Delegate
extension ARMainViewController: ARSessionDelegate {
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
                guard let objectName = objectAnchor.referenceObject.name, objectName == "ScanReferenceObj" else {
                    print("필터링: \(objectAnchor.referenceObject.name ?? "알 수 없음")는 처리되지 않습니다.")
                    continue
                }
                
                let position = objectAnchor.transform.columns.3
                let xFormatted = String(format: "%.2f", position.x)
                let yFormatted = String(format: "%.2f", position.y)
                let zFormatted = String(format: "%.2f", position.z)
                
                referenceARObjectName.text = "object: \(objectAnchor.referenceObject.name ?? "N/A"), x: \(xFormatted), y: \(yFormatted), z: \(zFormatted)"
                
                viewModel.addReferenceObjectOnApplePark(objectAnchor: objectAnchor, arView: arView)
            }
        }
    }
}
