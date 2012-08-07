//
//  QRReaderResult.h
//  MIT Mobile
//
//  Created by Blake Skinner on 8/6/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MITScannerImage;

@interface QRReaderResult : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSData * thumbnailData;
@property (nonatomic, retain) NSNumber * scanOrientation;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain, readonly) UIImage * image;

@property (nonatomic, readonly, retain) MITScannerImage *imageData;
@property (nonatomic, retain) UIImage *scanImage;
@property (nonatomic, retain) UIImage *thumbnail;

+ (CGSize)defaultThumbnailSize;
@end
