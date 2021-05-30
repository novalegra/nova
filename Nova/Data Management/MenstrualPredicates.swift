//
//  MenstrualPredicates.swift
//  Nova
//
//  Created by Anna Quinlan on 5/30/21.
//  Copyright © 2021 Anna Quinlan. All rights reserved.
//

import HealthKit

class MenstrualPredicates {
    static let noFlowPredicate = HKQuery.predicateForCategorySamples(
        with: .equalTo,
        value: HKCategoryValueMenstrualFlow.none.rawValue
    )
    
    static let hadFlowPredicate = HKQuery.predicateForCategorySamples(
        with: .equalTo,
        value: HKCategoryValueMenstrualFlow.unspecified.rawValue
    )
    
    static let lightFlowPredicate = HKQuery.predicateForCategorySamples(
        with: .equalTo,
        value: HKCategoryValueMenstrualFlow.light.rawValue
    )
    
    static let mediumFlowPredicate = HKQuery.predicateForCategorySamples(
        with: .equalTo,
        value: HKCategoryValueMenstrualFlow.medium.rawValue
    )
    
    static let heavyFlowPredicate = HKQuery.predicateForCategorySamples(
        with: .equalTo,
        value: HKCategoryValueMenstrualFlow.heavy.rawValue
    )
}
