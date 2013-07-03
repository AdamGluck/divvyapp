//
//  BGLDataAccess.m
//  DivvyApp
//
//  Created by Adam Gluck on 7/2/13.
//  Copyright (c) 2013 BGL. All rights reserved.
//

#import "BGLDivvyDataAccess.h"

@implementation BGLDivvyDataAccess

@synthesize stationData = _stationData;

#pragma mark - easy request functions

+ (NSArray *) myGetRequest: (NSURL *) url{
    
    NSArray *json = [[NSArray alloc] init];
    
    NSData* data = [NSData dataWithContentsOfURL:
                    url];
    NSError *error;
    
    if (data)
        json = [[NSArray alloc] initWithArray:[NSJSONSerialization
                                               JSONObjectWithData:data
                                               options:kNilOptions
                                               error:&error]];
    
    
    return json;
}

#pragma mark - getters

-(NSArray *) stationData{
    
}


@end
