#import <CoreData/CoreData.h>


@interface TourComponent :  NSManagedObject  
{
}

- (void)deleteCachedMedia;

@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSString * photoURL;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * audioURL;
@property (nonatomic, retain) NSString * componentID;

// saving photos and audio as files instead of binary fields in core data
// so that webviews can access photos and AVAudioPlayer can access audio
// on the device's filesystem.
@property (nonatomic, retain) NSData * photo; // contents of photoFile
@property (nonatomic, readonly) NSString *photoFile; // path to cached site image on device
@property (nonatomic, readonly) NSString *audioFile; // path to cached mp3 on device

@property (nonatomic, readonly) NSString *tourID;

@end



