//
//  ChannelProfileViewController.swift
//  ChatCamp Demo
//
//  Created by Saurabh Gupta on 23/04/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit
import ChatCamp

class ChannelProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var channelAvatarImageView: UIImageView! {
        didSet {
            channelAvatarImageView.layer.cornerRadius = channelAvatarImageView.bounds.width/2
            channelAvatarImageView.layer.masksToBounds = true
        }
    }
    
    var participants: [CCPParticipant]?
    var channel: CCPGroupChannel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Group info"
        setupTableView()
        if let avatarUrl = channel?.getAvatarUrl() {
            channelAvatarImageView.sd_setImage(with: URL(string: avatarUrl), completed: nil)
        } else {
            channelAvatarImageView.setImageForName(string: channel?.getName() ?? "?", circular: true, textAttributes: nil)
        }
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.tableFooterView = UIView()
    }
}

extension ChannelProfileViewController {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
 
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            guard let participantCount = participants?.count else { return 0 }
            
            return participantCount + 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelProfileCell", for: indexPath) as! ChannelProfileTableViewCell
        
        if indexPath.section == 0 {
            if let avatarUrl = channel?.getAvatarUrl() {
                cell.avatarImageView.sd_setImage(with: URL(string: avatarUrl), completed: nil)
            } else {
                cell.avatarImageView.setImageForName(string: channel?.getName() ?? "?", circular: true, textAttributes: nil)
            }
            cell.displayNameLabel.text = channel?.getName()
        } else {
            if indexPath.row == 0 {
                cell.avatarImageView.image = UIImage(named: "add_participant", in: Bundle(for: Message.self), compatibleWith: nil)
                cell.displayNameLabel.text = "Add Participants"
                cell.displayNameLabel.textColor = UIColor.sendButtonBlue
            } else {
                if let avatarURL = participants?[indexPath.row - 1].getAvatarUrl() {
                    cell.avatarImageView.sd_setImage(with: URL(string: avatarURL), completed: nil)
                } else {
                    cell.avatarImageView.setImageForName(string: participants?[indexPath.row - 1].getDisplayName() ?? "?", circular: true, textAttributes: nil)
                }
                cell.displayNameLabel.text = participants?[indexPath.row - 1].getDisplayName()
                if participants?[indexPath.row - 1].ifOnline() ?? false {
                    cell.onlineStatusImageView.image = UIImage(named: "online", in: Bundle(for: Message.self), compatibleWith: nil)
                } else {
                    cell.onlineStatusImageView.image = UIImage(named: "offline", in: Bundle(for: Message.self), compatibleWith: nil)
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "PARTICIPANTS"
        } else {
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                let createChannelViewController = UIViewController.createChannelViewController()
                if let viewController = createChannelViewController.topViewController as? CreateChannelViewController {
                    viewController.isAddingParticipants = true
                    viewController.channel = self.channel
                    viewController.participantsAdded = {
                        guard let id = self.channel?.getId() else { return }
                        CCPGroupChannel.get(groupChannelId: id, completionHandler: { (channel, error) in
                            if error ==  nil {
                                DispatchQueue.main.async {
                                    self.channel = channel
                                    self.participants = self.channel?.getParticipants()
                                    self.tableView.reloadData()
                                }
                            }
                        })
                    }
                }
                present(createChannelViewController, animated: true, completion: nil)
            } else {
                let profileViewController = UIViewController.profileViewController()
                profileViewController.participant = participants?[indexPath.row - 1]
                self.navigationController?.pushViewController(profileViewController, animated: true)
            }
        }
    }
}
