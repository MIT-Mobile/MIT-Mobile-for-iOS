//
//  PeopleFavoriteData.m
//  MIT Mobile
//
//  Created by Yev Motov on 6/19/14.
//
//

#import "PeopleFavoriteData.h"
#import "CoreDataManager.h"

@implementation PeopleFavoriteData

+ (NSArray *) retrieveFavoritePeople
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"favorite == YES"];
    return [CoreDataManager objectsForEntity:@"PersonDetails" matchingPredicate:predicate];
}

+ (void) setPerson:(PersonDetails *)person asFavorite:(BOOL)isFavorite
{
    [person setValue:@(isFavorite) forKey:@"favorite"];
    [CoreDataManager saveData];
}

@end
