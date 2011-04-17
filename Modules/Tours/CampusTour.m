#import "CampusTour.h"

#import "TourLink.h"
#import "TourSiteOrRoute.h"

@implementation CampusTour 

@dynamic tourID;
@dynamic summary;
@dynamic moreInfo;
@dynamic title;
@dynamic feedbackSubject;
@dynamic lastModified;
@dynamic components;
@dynamic links;
@dynamic startLocationHeader;

- (void)deleteCachedMedia {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentPath = [paths objectAtIndex:0];
    NSError *error = nil;

    for (NSString *pathComponent in [NSArray arrayWithObjects:@"photos", @"audio", nil]) {
        NSString *aDirectory = [documentPath stringByAppendingPathComponent:pathComponent];
        if ([[NSFileManager defaultManager] fileExistsAtPath:aDirectory]) {
            NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:aDirectory error:&error];
            for (NSString *filename in files) {
                if ([filename rangeOfString:self.tourID].location == 0) {
                    NSString *path = [aDirectory stringByAppendingPathComponent:filename];
                    DLog(@"deleting file %@", path);
                    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
                }
            }
        }
    }
}

@end
