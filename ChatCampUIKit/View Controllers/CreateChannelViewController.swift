//
//  CreateChannelViewController.swift
//  ChatCamp Demo
//
//  Created by Saurabh Gupta on 14/06/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import Foundation

import UIKit
import ChatCamp
import MBProgressHUD

class CreateChannelViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var creatButton: UIBarButtonItem!
    @IBOutlet weak var channelNameTextField: UITextField!
    @IBOutlet weak var channelNameTextFieldHightConstraint: NSLayoutConstraint!
    
    var viewModel = ParticipantViewModel()
    
    var users: [CCPUser] = []
    fileprivate var usersToFetch: Int = 20
    fileprivate var loadingUsers = false
    var usersQuery: CCPUserListQuery!
    var channel: CCPGroupChannel?
    fileprivate var existingParticipantsIds: [String] = []
    var isAddingParticipants = false
    var participantsAdded: (() -> Void)?
    var channelCreated: ((CCPGroupChannel, Sender) -> Void)?
    let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            // Do nothing
        }
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = "Search Users"
        searchController.dimsBackgroundDuringPresentation = false
        if #available(iOS 11.0, *) {
            navigationItem.searchController = self.searchController
        } else {
            tableView?.tableHeaderView = searchController.searchBar
        }
        definesPresentationContext = true
        
        setupTableView()
        if isAddingParticipants {
            setupUI()
        }
        
        usersQuery = CCPClient.createUserListQuery()
        loadUsers(limit: usersToFetch)
        
        viewModel.didToggleSelection = { [weak self] hasSelection in
            self?.creatButton.isEnabled = hasSelection
        }
        
        viewModel.loadMoreUsers = {
            if (self.tableView?.indexPathsForVisibleRows?.contains([0, self.users.count - 1]) ?? false) && !self.loadingUsers {
                self.loadUsers(limit: self.usersToFetch)
            }
        }
    }
    
    func setupTableView() {
        tableView?.register(UINib(nibName: String(describing: ChatTableViewCell.self), bundle: Bundle(for: ChatTableViewCell.self)), forCellReuseIdentifier: ChatTableViewCell.identifier)
        tableView?.estimatedRowHeight = 100
        tableView?.rowHeight = UITableView.automaticDimension
        tableView?.allowsMultipleSelection = true
        tableView?.dataSource = viewModel
        tableView?.delegate = viewModel
    }
    
    func setupUI() {
        title = "Add Participants"
        creatButton.title = "Add"
        channelNameTextFieldHightConstraint.constant = 0
        guard let groupChannel = channel else { return }
        for paticipant in groupChannel.getParticipants() {
            existingParticipantsIds.append(paticipant.getId())
        }
    }
    
    fileprivate func loadUsers(limit: Int) {
        let progressHud = MBProgressHUD.showAdded(to: self.view, animated: true)
        progressHud.label.text = "Loading..."
        progressHud.contentColor = .black
        loadingUsers = true
        usersQuery.load(limit: limit) { [unowned self] (users, error) in
            progressHud.hide(animated: true)
            if error == nil {
                guard let users = users else { return }
                let filteredUsers = users.filter({ $0.getId() != CCPClient.getCurrentUser().getId() })
                if self.isAddingParticipants {
                    self.users.append(contentsOf: users.filter({
                        for id in self.existingParticipantsIds {
                            if id == $0.getId() {
                                return false
                            }
                        }
                        
                        return true
                    }))
                } else {
                    self.users.append(contentsOf: filteredUsers)
                }
                
                DispatchQueue.main.async {
                    self.viewModel.users.append(contentsOf: filteredUsers.map { ParticipantViewModelItem(user: $0) })
                    self.loadingUsers = false
                    self.tableView?.reloadData()
                }
            } else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Can't Load Users", message: "Unable to load Users right now. Please try later.", actionText: "Ok")
                    self.loadingUsers = false
                }
            }
        }
    }
    
    fileprivate func refreshUsers(searchText: String?) {
        usersQuery = CCPClient.createUserListQuery()
        loadingUsers = true
        if let text = searchText {
            usersQuery.setDisplayNameSearch(text)
        }
        usersQuery.load(limit: usersToFetch) { [unowned self] (users, error) in
            if error == nil {
                guard let users = users else { return }
                let filteredUsers = users.filter({ $0.getId() != CCPClient.getCurrentUser().getId() })
                if self.isAddingParticipants {
                    self.users = users.filter({
                        for id in self.existingParticipantsIds {
                            if id == $0.getId() {
                                return false
                            }
                        }
                        
                        return true
                    })
                } else {
                    self.users = filteredUsers
                }
                
                DispatchQueue.main.async {
                    self.viewModel.users = filteredUsers.map { ParticipantViewModelItem(user: $0) }
                    self.loadingUsers = false
                    self.tableView?.reloadData()
                }
            } else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Can't Load Users", message: "Unable to load Users right now. Please try later.", actionText: "Ok")
                    self.loadingUsers = false
                }
            }
        }
    }
    
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    func filterContentForSearchText(_ searchText: String) {
        if isFiltering() {
            refreshUsers(searchText: searchText)
        } else if searchController.isActive && searchBarIsEmpty() {
            refreshUsers(searchText: nil)
        } else if !searchController.isActive && searchBarIsEmpty() {
            refreshUsers(searchText: nil)
        }
}
    
    @IBAction func didTapOnCreate(_ sender: UIBarButtonItem) {
        if isAddingParticipants {
            let participants = viewModel.selectedItems.map { $0.userId }
            guard let groupChannel = channel else { return }
            groupChannel.inviteParticipants(participants: participants) { error in
                if error == nil {
                    self.dismiss(animated: true, completion: {
                        self.participantsAdded?()
                    })
                } else {
                    self.showAlert(title: "Error!", message: "Some error occured, please try again.", actionText: "OK")
                }
            }
        } else {
        
            let channelName = channelNameTextField.text ?? ""
            
            if channelName.isEmpty {
                showAlert(title: "Empty Channel Name!", message: "Channel Name cannot be blank", actionText: "OK")
                
                return
            }
            
            if viewModel.selectedItems.isEmpty || viewModel.selectedItems.count == 1 {
                showAlert(title: "Empty Participants!", message: "Minimum 2 participants are required to create a channel.", actionText: "OK")

                return
            }
            
            CCPGroupChannel.create(name: channelName, userIds: viewModel.selectedItems.map { $0.userId }, isDistinct: false) { groupChannel, error in
                if error == nil, let channel = groupChannel {
                    self.dismiss(animated: false, completion: {
                        let sender = Sender(id: CCPClient.getCurrentUser().getId(), displayName: CCPClient.getCurrentUser().getDisplayName() ?? "")
                        self.channelCreated?(channel, sender)
                    })
                } else {
                    self.showAlert(title: "Error!", message: "Some error occured, please try again.", actionText: "OK")
                }
            }
        }
    }
    
    @IBAction func didTapOnCancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension CreateChannelViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}

