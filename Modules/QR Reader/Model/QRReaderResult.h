#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface QRReaderResult : NSManagedObject {
@private
}
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) id image;

@end
