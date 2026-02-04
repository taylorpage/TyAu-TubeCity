//
//  TubeCityExtensionParameterAddresses.h
//  TubeCityExtension
//
//  Created by Taylor Page on 1/22/26.
//

#pragma once

#include <AudioToolbox/AUParameters.h>

typedef NS_ENUM(AUParameterAddress, TubeCityExtensionParameterAddress) {
    tubegain = 0,
    bypass = 1,
    neutraltube = 2,
    warmtube = 3,
    aggressivetube = 4
};
