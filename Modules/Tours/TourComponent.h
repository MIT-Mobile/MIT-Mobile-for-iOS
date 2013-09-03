#import <CoreData/CoreData.h>


@interface TourComponent :  NSManagedObject  
{
}

- (void)deleteCachedMedia;

@property (nonatomic, copy) NSString * body;
@property (nonatomic, copy) NSString * photoURL;
@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSString * audioURL;
@property (nonatomic, copy) NSString * componentID;

// saving photos and audio as files instead of binary fields in core data
// so that webviews can access photos and AVAudioPlayer can access audio
// on the device's filesystem.
@property (nonatomic, copy) NSData * photo; // contents of photoFile
@property (nonatomic, copy, readonly) NSString *photoFile; // path to cached site image on device
@property (nonatomic, copy, readonly) NSString *audioFile; // path to cached mp3 on device

@property (nonatomic, copy, readonly) NSString *tourID;

@end



