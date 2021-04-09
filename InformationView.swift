//
//  InformationView.swift
//  MWCameraPlugin
//
//  Created by Eric Sans on 9/4/21.
//

import UIKit

final class InformationView: UIVisualEffectView {
    
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel(frame: .zero)
        titleLabel.text = self.titleText
        titleLabel.font = UIFont.systemFont(ofSize: 21, weight: .bold)
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .center
        
        return titleLabel
    }()
    
    private lazy var detailLabel: UILabel = {
        let detailLabel = UILabel(frame: .zero)
        detailLabel.text = self.detailText
        detailLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        detailLabel.numberOfLines = 0
        detailLabel.textAlignment = .center
        
        return detailLabel
    }()
    
    private lazy var stackView: UIStackView = {
        var arrangedSubviews = [self.detailLabel]
        if let _ = self.titleText {
            arrangedSubviews.insert(self.titleLabel, at: 0)
        }
        let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
        stackView.distribution = .equalSpacing
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        self.contentView.addSubview(stackView)
        
        return stackView
    }()
    
    private let titleText: String?
    private let detailText: String
    
    init(title: String? = nil, description: String) {
        self.titleText = title
        self.detailText = description
        super.init(effect: UIBlurEffect(style: .systemMaterial))
        
        self.layer.cornerRadius = 4
        self.layer.masksToBounds = true
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8),
            stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8)
        ])
    }
}
