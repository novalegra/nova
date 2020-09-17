//
//  MenstrualCupType.swift
//  Nova
//
//  Created by Anna Quinlan on 9/16/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

// Values from https://putacupinit.com/chart/
enum MenstrualCupType: String, Equatable, CaseIterable {
    case lenaSmall = "Lena (S)"
    case lenaLarge = "Lena (L)"
    
    case divaXsmall = "Diva Cup (XS)"
    case divaSmall = "Diva Cup (S)"
    case divaLarge = "Diva Cup (L)"
    
    case saaltSmall = "Saalt Cup (S)"
    case saaltLarge = "Saalt Cup (L)"
    
    case blossomSmall = "Blossom (S)"
    case blossomLarge = "Blossom (L)"
    
    case lunetteSmall = "Lunette (S)"
    case lunetteLarge = "Lunette (L)"
    
    case honeyPotSmall = "Honey Pot (S)"
    case honeyPotLarge = "Honey Pot (L)"
    
    case lilySmall = "Lily Cup (S)"
    case lilyLarge = "Lily Cup (L)"
    
    case flexSmall = "Flex (S)"
    case flexLarge = "Flex (L)"
    
    case femmyCycleSmall = "FemmyCycle (S)"
    case femmyCycleLarge = "FemmyCycle (L)"
    
    case superJennieSmall = "Super Jennie (S)"
    case superJennieLarge = "Super Jennie (L)"
    
    // Unit: mL
    var maxVolume: Int {
        switch self {
        case .lenaSmall, .saaltSmall, .blossomSmall, .lunetteSmall, .honeyPotSmall, .lilySmall:
            return 25
        case .lenaLarge, .saaltLarge, .blossomLarge, .lunetteLarge, .honeyPotLarge, .flexLarge, .femmyCycleLarge:
            return 30
        case .divaXsmall:
            return 17
        case .divaSmall:
            return 24
        case .divaLarge, .lilyLarge:
            return 28
        case .flexSmall:
            return 22
        case .femmyCycleSmall:
            return 18
        case .superJennieSmall:
            return 32
        case .superJennieLarge:
            return 41
        }
    }
}
