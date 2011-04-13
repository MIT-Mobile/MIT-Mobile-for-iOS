//
//  QRReaderResult.h
//  MIT Mobile
//
//  Created by Blake Skinner on 4/13/11.
//  Copyright (c) 2011 MIT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface QRReaderResult : NSManagedObject {
@private
}
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) id image;

@end
