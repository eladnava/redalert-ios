//
//  AlertTableViewCell.swift
//  RedAlert
//
//  Created by Elad on 10/16/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import UIKit

class AlertTableViewCell: UITableViewCell {
    @IBOutlet weak var city: UILabel!
    @IBOutlet weak var desc: UILabel!
    @IBOutlet weak var time: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
