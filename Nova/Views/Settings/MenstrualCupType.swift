//
//  MenstrualCupType.swift
//  Nova
//
//  Created by Anna Quinlan on 9/16/20.
//  Copyright © 2020 Anna Quinlan. All rights reserved.
//

// Values from https://putacupinit.com/chart/
enum MenstrualCupType: String, Equatable, CaseIterable {
    case blossomSmall = "Blossom (S)"
    case blossomLarge = "Blossom (L)"
    
    case divaXsmall = "Diva Cup (XS)"
    case divaSmall = "Diva Cup (S)"
    case divaLarge = "Diva Cup (L)"
    
    case femmyCycleSmall = "FemmyCycle (S)"
    case femmyCycleLarge = "FemmyCycle (L)"
    
    case flexSmall = "Flex (S)"
    case flexLarge = "Flex (L)"
    
    case honeyPotSmall = "Honey Pot (S)"
    case honeyPotLarge = "Honey Pot (L)"
    
    case lunetteSmall = "Lunette (S)"
    case lunetteLarge = "Lunette (L)"
    
    case lenaSmall = "Lena (S)"
    case lenaLarge = "Lena (L)"
    
    case lilySmall = "Lily Cup (S)"
    case lilyLarge = "Lily Cup (L)"
    
    case melunaSmall = "MeLuna (S)"
    case melunaMedium = "MeLuna (M)"
    case melunaLarge = "MeLuna (L)"
    case melunaXL = "MeLuna (XL)"
    
    case melunaShortSmall = "MeLuna Shorty (S)"
    case melunaShortMedium = "MeLuna Shorty (M)"
    case melunaShortLarge = "MeLuna Shorty (L)"
    case melunaShortXL = "MeLuna Shorty (XL)"
    
    case saaltSmall = "Saalt Cup (S)"
    case saaltLarge = "Saalt Cup (L)"
    
    case superJennieSmall = "Super Jennie (S)"
    case superJennieLarge = "Super Jennie (L)"
    
    // Unit: mL
    var maxVolume: Double {
        switch self {
        case .melunaShortSmall:
            return 8
        case .melunaShortMedium:
            return 10
        case .melunaShortLarge:
            return 14
        case .melunaSmall:
            return 15
        case .melunaShortXL:
            return 16
        case .divaXsmall:
            return 17
        case .femmyCycleSmall:
            return 18
        case .melunaMedium:
            return 20
        case .flexSmall:
            return 22
        case .divaSmall, .melunaLarge:
            return 24
        case .lenaSmall, .saaltSmall, .blossomSmall, .lunetteSmall, .honeyPotSmall, .lilySmall:
            return 25
        case .divaLarge, .lilyLarge, .melunaXL:
            return 28
        case .lenaLarge, .saaltLarge, .blossomLarge, .lunetteLarge, .honeyPotLarge, .flexLarge, .femmyCycleLarge:
            return 30
        case .superJennieSmall:
            return 32
        case .superJennieLarge:
            return 41
        }
    }
}
