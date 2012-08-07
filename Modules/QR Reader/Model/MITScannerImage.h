//
//  MITScannerImage.h
//  MIT Mobile
//
//  Created by Blake Skinner on 8/6/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MITScannerImage : NSManagedObject

@property (nonatomic, retain) NSData * imageData;
@property (nonatomic, retain) NSNumber * orientation;

@end
