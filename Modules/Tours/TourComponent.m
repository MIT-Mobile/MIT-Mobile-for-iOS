#import "TourComponent.h"
#import "CampusTour.h"
#import "TourSiteOrRoute.h"
#import "CampusTourSideTrip.h"
#import "TourStartLocation.h"

@implementation TourComponent 

@dynamic body;
@dynamic photoURL;
@dynamic title;
@dynamic audioURL;
@dynamic componentID;

- (void)deleteCachedMedia {
    for (NSString *path in [NSArray arrayWithObjects:[self photoFile], [self audioFile], nil]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            DLog(@"deleting file %@", path);
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
    }
}

- (NSData *)photo {
    NSData *data = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.photoFile]) {
        data = [NSData dataWithContentsOfFile:self.photoFile];
    }
    return data;
}

- (void)setPhoto:(NSData *)data {
    UIImage *image = [UIImage imageWithData:data];
    if (image) {
        [data writeToFile:self.photoFile atomically:YES];
    }
}

- (NSString *)photoFile {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentPath = [paths objectAtIndex:0];
    NSString *photoDir = [documentPath stringByAppendingPathComponent:@"photos"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:photoDir]) {
        NSError* error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:photoDir
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
    }
    
    NSString *filename = [NSString stringWithFormat:@"%@-%@", [self tourID], self.componentID];
    return [photoDir stringByAppendingPathComponent:filename];
}

- (NSString *)audioFile {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentPath = [paths objectAtIndex:0];
    NSString *audioDir = [documentPath stringByAppendingPathComponent:@"audio"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:audioDir]) {
        NSError* error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:audioDir
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
    }
    // TODO: get extension from original url
    NSString *filename = [NSString stringWithFormat:@"%@-%@.mp3", [self tourID], self.componentID];
    return [audioDir stringByAppendingPathComponent:filename];
}

- (NSString *)tourID {
    NSString *tourID = nil;
    if ([self isKindOfClass:[TourSiteOrRoute class]]) {
        tourID = ((TourSiteOrRoute *)self).tour.tourID;
    } else if ([self isKindOfClass:[TourStartLocation class]]) {
        tourID = ((TourStartLocation *)self).startSite.tour.tourID;
    } else if ([self isKindOfClass:[CampusTourSideTrip class]]) {
        tourID = ((CampusTourSideTrip *)self).component.tour.tourID;
    }
    return tourID;
}

@end
