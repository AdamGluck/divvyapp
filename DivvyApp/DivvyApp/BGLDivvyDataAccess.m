//
//  BGLDataAccess.m
//  DivvyApp
//
//  Created by Adam Gluck on 7/2/13.
//  Copyright (c) 2013 BGL. All rights reserved.
//

#import "BGLDivvyDataAccess.h"

@interface BGLDivvyDataAccess()

@property (strong, nonatomic) NSTimer * refreshTimer;

@end

@implementation BGLDivvyDataAccess

@synthesize stationData = _stationData;


#pragma mark - easy request functions

- (NSArray *) myGetRequest: (NSURL *) url{
    
    NSArray *json = [[NSArray alloc] init];
    
    NSError * dataGrabbingError;
    
    NSData* data = [NSData dataWithContentsOfURL:
                    url options: NSDataReadingUncached error:&dataGrabbingError];

    if (dataGrabbingError){
        [self performSelector:@selector(errorGrabbingData:) onThread:[NSThread mainThread] withObject:dataGrabbingError waitUntilDone:NO];
        return @[];
    }
    
    NSError *error;
    
    NSLog(@"before if called");
    
    if (data)
        json = [NSJSONSerialization
                JSONObjectWithData:data
                options:kNilOptions
                error:&error];
        
    
    return json;
}

#pragma mark - getters

-(NSArray *) stationData{
    
    if (!_stationData){
        _stationData = [[NSArray alloc] init];
    }
    
    return _stationData;
}

#pragma mark - setters

-(void) setAutoRefresh: (BOOL) theBool{
    
    
    if (self.autoRefresh != theBool){
        
        _autoRefresh = theBool;
        
        if (theBool){
            self.refreshTimer = [[NSTimer alloc] init];
            self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(refresh) userInfo:nil repeats:YES];
            [self fillStationDataASynchroniously];
        } else {
            [self.refreshTimer invalidate];
            self.refreshTimer = nil;
        }
        
    }
    
    
}


#pragma mark - fill data methods

-(void) fillStationDataSynchroniously{
    NSString * requestString = [[NSString alloc] initWithFormat:@"https://divvybikes.com/stations/json"];
    NSURL * url = [[NSURL alloc] initWithString:requestString];
    self.stationData = [self myGetRequest:url];
}

-(void) fillStationDataASynchroniously{
    __block NSArray * blockStationData;
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("Grab Divvy Data", NULL);
    dispatch_async(downloadQueue, ^{
        NSURL * url = [[NSURL alloc] initWithString:@"http://divvybikes.com/stations/json"];
        blockStationData = [self myGetRequest:url];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (blockStationData != 0)
                self.stationData = blockStationData;
            
            if ([blockStationData count] != 0 && [self.delegate respondsToSelector:@selector(asynchroniousFillRequestComplete:)]){
                NSLog(@"responds and is sending to delegate");
                [self.delegate asynchroniousFillRequestComplete: self.stationData];
            }
            
        });
    });
}

#pragma mark - Timer Function

-(void) refresh{
    [self fillStationDataASynchroniously];
    NSLog(@"refresh called");
}

#pragma mark - error selector

-(void) errorGrabbingData: (NSError *) error{
    if ([self.delegate respondsToSelector:@selector(requestFailedWithError:)])
        [self.delegate requestFailedWithError:error];
}








@end
