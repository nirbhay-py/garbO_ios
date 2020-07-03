//
//  profileViewController.swift
//  classifyTrash
//
//  Created by Nirbhay Singh on 03/07/20.
//  Copyright © 2020 Nirbhay Singh. All rights reserved.
//

import UIKit
import Charts

class profileViewController: UIViewController {
    @IBOutlet weak var itemLbl: UILabel!
    
    @IBOutlet weak var pieChart1: PieChartView!
    override func viewDidLoad() {
        super.viewDidLoad()
        if(globalUser.itemsScanned != 0){
            itemLbl.text = String(globalUser.itemsScanned) + " items"
            if(globalUser.plasticScanned != 0){
                setChart()
            }else{
                pieChart1.isHidden = true
            }
        }else{
            showAlert(msg: "You haven't scanned any images yet.")
            self.performSegue(withIdentifier: "back", sender: nil)
        }
        
        // Do any additional setup after loading the view.
    }

    func setChart() {
        let plastics = PieChartDataEntry(value: Double(globalUser.plasticScanned!))
        let nonPlastics = PieChartDataEntry(value: Double(globalUser.itemsScanned-globalUser.plasticScanned))
        let dataset = PieChartDataSet(entries:[plastics,nonPlastics],label:"Plastics vs Non-plastics")
        dataset.colors = ChartColorTemplates.colorful()
        pieChart1.legend.font = UIFont.systemFont(ofSize: 20)
        pieChart1.legend.textColor = UIColor.white
        pieChart1.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
        let data = PieChartData(dataSet: dataset)
        pieChart1.data = data
        pieChart1.notifyDataSetChanged()

    }
}
