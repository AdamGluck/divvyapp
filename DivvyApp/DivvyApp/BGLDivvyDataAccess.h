//
//  BGLDataAccess.h
//  DivvyApp
//
//  Created by Adam Gluck on 7/2/13.
//  Copyright (c) 2013 BGL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
@protocol BGLDivvyDataAccessDelegate <NSObject>

@optional

// These delegate methods are called in response to attempts to grab data from the server
// The names are fairly self-explanatory, although e-mail me if you have need of further clarification.
// Note: asynchronousFillRequestComplete: will not be called if the request fails
-(void) asynchronousFillRequestComplete: (NSDictionary *) data;
-(void) requestFailedWithError: (NSError *) error;

// Names here are self explanatory again, are called in response to grabNearestStationToDevice being called.
-(void) deviceLocationFoundAtLocation: (CLLocation *) deviceLocation;
-(void) deviceLocationNotFoundWithError: (NSError *) error;
-(void) nearestStationToDeviceFoundWithStation: (NSDictionary *) station;

@end

@interface BGLDivvyDataAccess : NSObject

@property (weak, nonatomic) id <BGLDivvyDataAccessDelegate> delegate;

/* These properties and methods all relate to filling raw station data */

// note: the data is a dictionary with two keys:
// "executionTime"  has a timestamp of the execution
// "stationBeanList"  has bike station data
@property (strong, nonatomic) NSDictionary * stationData;

// if this is set then the station data will refresh automatically every 60 seconds, and will call asynchronousFillRequestComplete
// note that as soon as this method is set it begins to refresh, so setting this will also call fillStationDataASynchronously
// thus you do not need to call the below methods once this is used and you can assume that your stationData is up to date
@property (nonatomic, assign, setter = setAutoRefresh:) BOOL autoRefresh;

// Fill station data fills stationData with up to date information about the divvy bike system
// note that this calls synchroniously, so the main thread will freeze if this is called and the server request takes too long
-(void) fillStationDataSynchronously;

// this will make the request to server in a background thread so the UI does not freeze when called
// it will fill stationData with fresh data and call asynchronousFillDataRequestFinished when complete
// note: if you want to guarentee a method gets called using the newly updated station data and you are using this method, implement the code after you get the station data in the deleget method asynchronousFillRequestComplete:
-(void) fillStationDataASynchronously;

/* these properties allow you to grab particular properties as arrays of the station data */

// this assumes that the station data has been filled
-(NSDictionary *) grabNearestStationTo: (CLLocation *) location;

// This returns the nearest station in the delegate method nearestStationToDeviceFoundWithStation:
// It also returns the location of the nearest station, and errors if it cannot connect to the GPS in the appropriate methods
-(void) grabNearestStationToDevice;


@end
