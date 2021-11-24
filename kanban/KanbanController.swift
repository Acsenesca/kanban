//
//  KanbanController.swift
//  kanban
//
//  Created by Stevanus Prasetyo Soemadi on 23/11/21.
//

import Foundation
import UIKit
import MobileCoreServices

class KanbanController: UIViewController {
    var collectionView: UICollectionView?

    var kanbans = [
        Kanban(title: "Todo", items: ["Database Migration", "Schema Design", "Storage Management", "Model Abstraction"]),
        Kanban(title: "In Progress", items: ["Push Notification", "Analytics", "Machine Learning"]),
        Kanban(title: "Done", items: ["System Architecture", "Alert & Debugging"])
    ]
    
    fileprivate func setupCollectionView() {
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height), collectionViewLayout: UICollectionViewFlowLayout())
        collectionView?.delegate = self
        collectionView?.dataSource = self
        view.addSubview(collectionView!)
        collectionView?.register(UINib(nibName: "KanbanCell", bundle: nil), forCellWithReuseIdentifier: "KanbanCell")
        collectionView?.translatesAutoresizingMaskIntoConstraints = false
        collectionView?.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        collectionView?.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        collectionView?.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        collectionView?.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        
        if let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }
        
        self.collectionView?.contentInset = UIEdgeInsets.init(top: 0, left: 5, bottom: 0, right: 5)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupNavigationBar()
        updateCollectionViewItem(with: view.bounds.size)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateCollectionViewItem(with: size)
    }
    
    private func updateCollectionViewItem(with size: CGSize) {
        guard let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        layout.itemSize = CGSize(width: 260, height: size.height * 0.8)
    }
    
    private func setupNavigationBar() {
        self.edgesForExtendedLayout = []
        setupAddButtonItem()
    }
 
    func setupAddButtonItem() {
        let addButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addListTapped(_:)))
        navigationItem.rightBarButtonItem = addButtonItem
    }
    func setupRemoveBarButtonItem() {
        let button = UIButton(type: .system)
        button.setTitle("Delete", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.addInteraction(UIDropInteraction(delegate: self))
        let removeBarButtonItem = UIBarButtonItem(customView: button)
        navigationItem.leftBarButtonItem = removeBarButtonItem
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @objc func addListTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Add List", message: nil, preferredStyle: .alert)
        alertController.addTextField(configurationHandler: nil)
        alertController.addAction(UIAlertAction(title: "Add", style: .default, handler: { (_) in
            guard let text = alertController.textFields?.first?.text, !text.isEmpty else {
                return
            }
            
            self.kanbans.append(Kanban(title: text, items: []))
            
            let addedIndexPath = IndexPath(item: self.kanbans.count - 1, section: 0)
            
            self.collectionView?.insertItems(at: [addedIndexPath])
            self.collectionView?.scrollToItem(at: addedIndexPath, at: UICollectionView.ScrollPosition.centeredHorizontally, animated: true)
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true)
    }
}

extension KanbanController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return kanbans.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "KanbanCell", for: indexPath) as! KanbanCell
        
        cell.setup(with: kanbans[indexPath.item])
        cell.parentVC = self
        return cell
    }
}

extension KanbanController: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .move)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        
        if session.hasItemsConforming(toTypeIdentifiers: [kUTTypePlainText as String]) {
            session.loadObjects(ofClass: NSString.self) { (items) in
                guard let _ = items.first as? String else {
                    return
                }
                
                if let (dataSource, sourceIndexPath, tableView) = session.localDragSession?.localContext as? (Kanban, IndexPath, UITableView) {
                    tableView.beginUpdates()
                    dataSource.items.remove(at: sourceIndexPath.row)
                    tableView.deleteRows(at: [sourceIndexPath], with: .automatic)
                    tableView.endUpdates()
                }
            }
        }
    }
}

