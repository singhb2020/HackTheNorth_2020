//
//  ContentView.swift
//  Halcyon
//
//  Created by Bishneet Singh on 2021-01-16.
//

import UIKit
import SwiftUI
import Firebase
import HealthKit


let healthKitStore : HKHealthStore = HKHealthStore()

//<--------------------------Global Variables-------------------------->//
struct globalVars
{
    //These 4 variables need to be assigned with the buttons. Once Assigned run the MainPosting func
    static var happiness : Int!
    static var motivation : Int!
    static var energy : Int!
    static var creativity : Int!
    
    //These can be left alone
//    static var sleep : Int!
//    static var steps : Int!
//    static var activeCalories : Int!
//    static var heartRate : Int!
//    static var headphonesAudio : Int!
    
    //This is the Max amount of data we want from the health app in each category
    static var queryLimit = 500;
}

class BackendProcesses
{
    
    let healthStore = HKHealthStore()
    

    //<--------------------------App Initalization-------------------------->//
    func viewDidLoad()
    {
        //This request Authorizes the app to use the Health Data (Needs to only be called Once)
        requestAuthorization()
        
        //The readHealthData func reads the data from the Health app and uploades it to cloud DB
        readHealthData()
    }
    
    

//<--------------------------Manual Input Database Upload-------------------------->//
    func mainPosting()
    {
        let timeStamp = getTimeStamp()
        
        let happinessInput = globalVars.happiness
        let motivationInput = globalVars.motivation
        let energyInput = globalVars.energy
        let creativityInput = globalVars.creativity
    
        let post : [String : Any] = ["TimeStamp" : timeStamp,
                                     "Motivation" : motivationInput ?? -1,
                                     "Energy" : energyInput ?? -1,
                                     "Creativity" : creativityInput ?? -1,
                                     "Happiness" : happinessInput ?? -1]
        
        let databaseRef = Database.database().reference()
        
        databaseRef.child("Client_Data").child("Manual_Input").childByAutoId().setValue(post)
    }
    
    func getTimeStamp() -> String
    {
        let currentDate = Date()
        let dateFormat = DateFormatter()
        
        dateFormat.timeStyle = .medium
        dateFormat.dateStyle = .medium
        dateFormat.locale = Locale(identifier: "ja_JP")
        
        let stringDate = dateFormat.string(from: currentDate)
        
        return stringDate
    }


    //<--------------------------Helathkit Authorization-------------------------->//
    func requestAuthorization()
    {
        let sleepCount = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
        let stepCount = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        let activeCalorieCount = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!
        let heartRate = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        let headphonesAudio = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.headphoneAudioExposure)!
        
        if !HKHealthStore.isHealthDataAvailable()
        {
            print("Error")
            return
        }
        
        healthKitStore.requestAuthorization(toShare: [], read: [sleepCount, stepCount, activeCalorieCount, heartRate, headphonesAudio]) { (success, error) -> Void in print("Auth Success")}
    }

//<--------------------------Reading Health Data from App-------------------------->//
func readHealthData()
{
    //<-------------Sleep------------->//
    if let sleepType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)
    {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let sleepQuery = HKSampleQuery(sampleType: sleepType, predicate: nil, limit: globalVars.queryLimit, sortDescriptors: [sortDescriptor]){(query, tempResult, error) -> Void in
            if error != nil
            {
                return
            }
            if let result = tempResult
            {
                for item in result
                {
                    if let sample = item as? HKCategorySample{
                        let amount = sample.endDate.timeIntervalSince(sample.startDate)
                        syncPosting(nameInput: "Sleep (seconds)", valueInput: amount, timeInput: (sample.startDate))
                    }}}}
        healthStore.execute(sleepQuery)
    }
    
    
    //<-------------Steps------------->//
    let stepsCount = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
    let stepAssort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

    let stepQuery = HKSampleQuery(sampleType: stepsCount, predicate: nil, limit: globalVars.queryLimit, sortDescriptors : [stepAssort])
        {query, results, error in
            if let result = results as? [HKQuantitySample] {
                for item in result
                {
                    let steps = Double(item.quantity.doubleValue(for: HKUnit.count()))
                    let stepDate = item.startDate
                    syncPosting(nameInput: "Steps", valueInput: steps, timeInput: stepDate)
                }}}
    healthStore.execute(stepQuery)
    
    

    //<-------------Active Calories------------->//
    let ACaloriesCount = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!
    let ACaloriesAssort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

    let ACalQuery = HKSampleQuery(sampleType: ACaloriesCount, predicate: nil, limit: globalVars.queryLimit, sortDescriptors : [ACaloriesAssort])
        {query, results, error in
            if let result = results as? [HKQuantitySample] {
                for item in result
                {
                    let ACalUnit : HKUnit = HKUnit(from: "Cal")
                    let steps = Double(item.quantity.doubleValue(for: ACalUnit))
                    let stepDate = item.startDate
                    syncPosting(nameInput: "Active_Calories (Cal)", valueInput: steps, timeInput: stepDate)
                }}}
    healthStore.execute(ACalQuery)
    
    
    
    //<-------------Hear Rate------------->//
    let heartRateCount = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
    let heartRateAssort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

    let heartRateQuery = HKSampleQuery(sampleType: heartRateCount, predicate: nil, limit: globalVars.queryLimit, sortDescriptors : [heartRateAssort])
        {query, results, error in
            if let result = results as? [HKQuantitySample] {
                for item in result
                {
                    let heartRateUnit : HKUnit = HKUnit(from: "count/min")
                    let steps = Double(item.quantity.doubleValue(for: heartRateUnit))
                    let stepDate = item.startDate
                    syncPosting(nameInput: "Heart_Rate_(bpm)", valueInput: steps, timeInput: stepDate)
                }}}
    healthStore.execute(heartRateQuery)
    
    
    
    //<-------------HeadPhones Audio------------->//
    let headphonesCount = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.headphoneAudioExposure)!
    let headphonesAssort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

    let headphonesQuery = HKSampleQuery(sampleType: headphonesCount, predicate: nil, limit: globalVars.queryLimit, sortDescriptors : [headphonesAssort])
        {query, results, error in
            if let result = results as? [HKQuantitySample] {
                for item in result
                {
                    let headPhonesUnit : HKUnit = HKUnit(from: "dB")
                    let steps = Double(item.quantity.doubleValue(for: headPhonesUnit))
                    let stepDate = item.startDate
                    syncPosting(nameInput: "Headphones_(dB)", valueInput: steps, timeInput: stepDate)
                }}}
    healthStore.execute(headphonesQuery)
    
    
    
    
    
//<--------------------------Syncing Health App to Database-------------------------->//
    func syncPosting(nameInput : String?, valueInput : Double?, timeInput : Date?)
    {
        let recordDate = timeInput
        let dateFormat = DateFormatter()
        
        dateFormat.timeStyle = .medium
        dateFormat.dateStyle = .medium
        dateFormat.locale = Locale(identifier: "ja_JP")
        
        let stringDate = dateFormat.string(from: recordDate ?? Date())
        
        
        let post : [String : Any] = ["TimeStamp" : stringDate ,
                                     nameInput ?? "null" : valueInput ?? 0,]
        
        let databaseRef = Database.database().reference()
        
        databaseRef.child("Client_Data").child(nameInput ?? "Dump").childByAutoId().setValue(post)
        
        }
    }
}

