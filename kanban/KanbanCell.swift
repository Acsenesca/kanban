//
//  KanbanCell.swift
//  kanban
//
//  Created by Stevanus Prasetyo Soemadi on 24/11/21.
//

import UIKit
import MobileCoreServices

class KanbanCell: UICollectionViewCell {

    @IBOutlet weak var tableView: UITableView!
    weak var parentVC: KanbanController?
    var kanban: Kanban?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.cornerRadius = 10.0
        self.backgroundColor = .lightGray
        
        self.setupTableView()
    }
    
    func setupTableView() {
        tableView.dragInteractionEnabled = true
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.layer.cornerRadius = 10.0
        
        tableView.register(UINib(nibName: "DetailCell", bundle: nil), forCellReuseIdentifier: "DetailCell")
        tableView.tableFooterView = UIView()
        tableView.contentInset = UIEdgeInsets.init(top: 5, left: 5, bottom: 5, right: 5)
        tableView.isScrollEnabled = false
    }
    
    func setup(with data: Kanban) {
        self.kanban = data
        tableView.reloadData()
    }
    
    @IBAction func addTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Add Item", message: nil, preferredStyle: .alert)
        alertController.addTextField(configurationHandler: nil)
        alertController.addAction(UIAlertAction(title: "Add", style: .default, handler: { (_) in
            guard let text = alertController.textFields?.first?.text, !text.isEmpty else {
                return
            }
            
            guard let data = self.kanban else {
                return
            }
            
            data.items.append(text)
            let addedIndexPath = IndexPath(item: data.items.count - 1, section: 0)
            
            self.tableView.insertRows(at: [addedIndexPath], with: .automatic)
            self.tableView.scrollToRow(at: addedIndexPath, at: UITableView.ScrollPosition.bottom, animated: true)
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        parentVC?.present(alertController, animated: true, completion: nil)
    }
}

extension KanbanCell: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return kanban?.items.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return kanban?.title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath) as! DetailCell
        cell.label?.text = "\(kanban!.items[indexPath.row])"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension KanbanCell: UITableViewDragDelegate {
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let kanban = kanban, let stringData = kanban.items[indexPath.row].data(using: .utf8) else {
            return []
        }
        
        let itemProvider = NSItemProvider(item: stringData as NSData, typeIdentifier: kUTTypePlainText as String)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        session.localContext = (kanban, indexPath, tableView)
        
        return [dragItem]
    }
    
    func tableView(_ tableView: UITableView, dragSessionWillBegin session: UIDragSession) {
        self.parentVC?.setupRemoveBarButtonItem()
        self.parentVC?.navigationItem.rightBarButtonItem = nil
    }
    
    func tableView(_ tableView: UITableView, dragSessionDidEnd session: UIDragSession) {
        self.parentVC?.setupAddButtonItem()
        self.parentVC?.navigationItem.leftBarButtonItem = nil
    }
}

extension KanbanCell: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        if coordinator.session.hasItemsConforming(toTypeIdentifiers: [kUTTypePlainText as String]) {
            coordinator.session.loadObjects(ofClass: NSString.self) { (items) in
                guard let string = items.first as? String else {
                    return
                }
                
                switch (coordinator.items.first?.sourceIndexPath, coordinator.destinationIndexPath) {
                case (.some(let sourceIndexPath), .some(let destinationIndexPath)):
                    let updatedIndexPaths: [IndexPath]
                    if sourceIndexPath.row < destinationIndexPath.row {
                        updatedIndexPaths =  (sourceIndexPath.row...destinationIndexPath.row).map { IndexPath(row: $0, section: 0) }
                    } else if sourceIndexPath.row > destinationIndexPath.row {
                        updatedIndexPaths =  (destinationIndexPath.row...sourceIndexPath.row).map { IndexPath(row: $0, section: 0) }
                    } else {
                        updatedIndexPaths = []
                    }
                    self.tableView.beginUpdates()
                    self.kanban?.items.remove(at: sourceIndexPath.row)
                    self.kanban?.items.insert(string, at: destinationIndexPath.row)
                    self.tableView.reloadRows(at: updatedIndexPaths, with: .automatic)
                    self.tableView.endUpdates()
                    break
                    
                case (nil, .some(let destinationIndexPath)):
                    self.removeSourceTableData(localContext: coordinator.session.localDragSession?.localContext)
                    self.tableView.beginUpdates()
                    self.kanban?.items.insert(string, at: destinationIndexPath.row)
                    self.tableView.insertRows(at: [destinationIndexPath], with: .automatic)
                    self.tableView.endUpdates()
                    break
                    
                    
                case (nil, nil):
                    self.removeSourceTableData(localContext: coordinator.session.localDragSession?.localContext)
                    self.tableView.beginUpdates()
                    self.kanban?.items.append(string)
                    self.tableView.insertRows(at: [IndexPath(row: self.kanban!.items.count - 1 , section: 0)], with: .automatic)
                    self.tableView.endUpdates()
                    break
                    
                default: break
                    
                }
            }
        }
    }
    
    func removeSourceTableData(localContext: Any?) {
        if let (dataSource, sourceIndexPath, tableView) = localContext as? (Kanban, IndexPath, UITableView) {
            tableView.beginUpdates()
            dataSource.items.remove(at: sourceIndexPath.row)
            tableView.deleteRows(at: [sourceIndexPath], with: .automatic)
            tableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
}
