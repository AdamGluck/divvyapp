//
//  BGLDataAccess.h
//  DivvyApp
//
//  Created by Adam Gluck on 7/2/13.
//  Copyright (c) 2013 BGL. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol BGLDivvyDataAccessDelegate <NSObject>

@optional

-(void) asynchroniousFillRequestComplete: (NSArray *) data;
-(void) requestFailedWithError: (NSError *) error;

@end

@interface BGLDivvyDataAccess : NSObject

@property (strong, nonatomic) NSArray * stationData;
@property (weak, nonatomic) id <BGLDivvyDataAccessDelegate> delegate;

// if this is set then the station data will refresh automatically every 60 seconds, and will call asynchroniousFillRequestComplete
// note that as soon as this method is set it begins to refresh, so setting this will also call fillStationDataASynchroniously
// thus you do not need to call the below methods once this is used and you can assume that your stationData is up to date
@property (nonatomic, assign, setter = setAutoRefresh:) BOOL autoRefresh;

// Fill station data fills stationData with up to date information about the divvy bike system
// note that this calls synchroniously, so the main thread will freeze if this is called and the server request takes too long
-(void) fillStationDataSynchroniously;

// this will make the request to server in a background thread
// it will fill stationData with fresh data and call asynchroniousFillDataRequestFinished when complete
-(void) fillStationDataASynchroniously;

@end
