//
//  SecondViewController.swift
//  Crime Reports
//
//  Created by Chris Haen on 3/7/18.
//  Copyright © 2018 Christopher Haen. All rights reserved.
//

import UIKit

class SecondViewController: UITableViewController {
    
    //SODA Client 3CYKTT42HJUDGalN2tURvsYoi
    let client = SODAClient(domain: "data.seattle.gov", token: "3CYKTT42HJUDGalN2tURvsYoi")
    //Crime Reports
    let cellId = "EventSummaryCell"
    var data: [[String: Any]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Create a pull-to-refresh control
        refreshControl = UIRefreshControl ()
        refreshControl?.addTarget(self, action: #selector(SecondViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        
        // Auto-refresh
        refresh(self)
    }

    /// Asynchronous performs the data query then updates the UI
    /// Asynchronous performs the data query then updates the UI
    @objc func refresh (_ sender: Any) {
        // there are about a dozen 1990 records in this particular database that have an incorrectly formatted
        // cad_event_number, so we'll filter them out to get most recent events first.
        let cngQuery = client.query(dataset: "3k2p-39jp").filter("event_clearance_group IS NOT NULL AND cad_event_number < '9000209585'")
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        cngQuery.orderDescending("cad_event_number").get { res in
            switch res {
            case .dataset (let data):
                // Update our data
                self.data = data
            case .error (let err):
                let errorMessage = (err as NSError).userInfo.debugDescription
                let alertController = UIAlertController(title: "Error Refreshing", message: errorMessage, preferredStyle:.alert)
                self.present(alertController, animated: true, completion: nil)
            }
            
            // Update the UI
            self.refreshControl?.endRefreshing()
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let c = tableView.dequeueReusableCell(withIdentifier: cellId) as UITableViewCell!
        
        let item = data[indexPath.row]
        
        let name = item["event_clearance_description"]! as! String
        c?.textLabel?.text = name
        
        let street = item["hundred_block_location"]! as! String
        let city = "Seattle"
        let state = "WA"
        c?.detailTextLabel?.text = "\(street), \(city), \(state)"
        
        return c!
    }
}

