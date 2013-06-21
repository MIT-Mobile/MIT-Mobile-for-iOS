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
@dynamic photoThumbnailURL;

- (void)deleteCachedMedia {
    for (NSString *path in [NSArray arrayWithObjects:[self photoFile], [self audioFile], nil]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            DDLogVerbose(@"deleting file %@", path);
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
    }
}

- (NSData *)photo {
    return [self photoWithPath:self.photoFile];
}

- (void)setPhoto:(NSData *)data {
    [self setPhoto:data withPath:self.photoFile];
}

- (NSString *)photoFile {
    NSString *filename = [NSString stringWithFormat:@"%@-%@", [self tourID], self.componentID];
    return [self photoFileWithName:filename];
}


- (NSData *)photoThumbnail {
    return [self photoWithPath:self.thumbnailPhotoFile];
}

- (void)setPhotoThumbnail:(NSData *)data {
    [self setPhoto:data withPath:self.thumbnailPhotoFile];
}

- (NSString *)thumbnailPhotoFile {
    NSString *filename = [NSString stringWithFormat:@"%@-%@-thumbnail", [self tourID], self.componentID];
    return [self photoFileWithName:filename];
}


- (NSData *)photoWithPath:(NSString *)path {
    NSData *data = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        data = [NSData dataWithContentsOfFile:path];
    }
    return data;
}

- (void)setPhoto:(NSData *)data withPath:(NSString *)path {
    UIImage *image = [UIImage imageWithData:data];
    if (image) {
        [data writeToFile:path atomically:YES];
    }
}

- (NSString *)photoFileWithName:(NSString *)name {
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
    
    return [photoDir stringByAppendingPathComponent:name];
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
