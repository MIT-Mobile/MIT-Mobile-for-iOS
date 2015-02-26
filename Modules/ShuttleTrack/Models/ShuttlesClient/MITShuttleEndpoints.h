//
//  MITShuttleEndpoints.h
//  MITShuttleApi
//
//  Created by Logan Wright on 2/25/15.
//  Copyright (c) 2015 LowriDevs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PlayDoh/PDEndpoint.h>

@interface MITShuttleBase : PDEndpoint
@end

@interface MITShuttleVehicleListEndpoint : MITShuttleBase
@end

@interface MITShuttleRoutesEndpoint : MITShuttleBase
@end

@interface MITShuttleStopEndpoint : MITShuttleRoutesEndpoint
@end

@interface MITShuttlesPredictionsEndpoint : MITShuttleBase
@end
