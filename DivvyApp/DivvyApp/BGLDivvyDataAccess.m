//
//  BGLDataAccess.m
//  DivvyApp
//
//  Created by Adam Gluck on 7/2/13.
//  Given freely to be used on any project, commercial or, ideally, civic.
//

#import "BGLDivvyDataAccess.h"

@interface BGLDivvyDataAccess() <CLLocationManagerDelegate>

@property (strong, nonatomic) NSTimer * refreshTimer;
@property (strong, nonatomic) CLLocationManager * locationManager;

@end

@implementation BGLDivvyDataAccess

@synthesize stationData = _stationData;


#pragma mark - easy request functions

- (id) myGetRequest: (NSURL *) url{
    
    NSArray *json = [[NSArray alloc] init];
    
    NSError * dataGrabbingError;
    
    NSData* data = [NSData dataWithContentsOfURL:
                    url options: NSDataReadingUncached error:&dataGrabbingError];

    if (dataGrabbingError){
        [self performSelector:@selector(errorGrabbingData:) onThread:[NSThread mainThread] withObject:dataGrabbingError waitUntilDone:NO];
        return @[];
    }
    
    NSError *error;
        
    if (data)
        json = [NSJSONSerialization
                JSONObjectWithData:data
                options:kNilOptions
                error:&error];
        
    
    return json;
}

#pragma mark - getters

-(NSDictionary *) stationData{
    
    if (!_stationData){
        _stationData = [[NSDictionary alloc] init];
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
            [self fillStationDataASynchronously];
        } else {
            [self.refreshTimer invalidate];
            self.refreshTimer = nil;
        }
        
    }
    
    
}


#pragma mark - fill data methods

-(void) fillStationDataSynchronously{
    NSString * requestString = [[NSString alloc] initWithFormat:@"https://divvybikes.com/stations/json"];
    NSURL * url = [[NSURL alloc] initWithString:requestString];
    self.stationData = [self myGetRequest:url];
}

-(void) fillStationDataASynchronously{
    __block NSDictionary * blockStationData;
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("Grab Divvy Data", NULL);
    dispatch_async(downloadQueue, ^{
        NSURL * url = [[NSURL alloc] initWithString:@"http://divvybikes.com/stations/json"];
        blockStationData = [self myGetRequest:url];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if ([blockStationData count] != 0)
                self.stationData = blockStationData;
            else
                self.stationData = @{@"error": @"use error delegate method for more information"};
            
            if ([blockStationData count] != 0 && [self.delegate respondsToSelector:@selector(asynchronousFillRequestComplete:)]){
                [self.delegate asynchronousFillRequestComplete: self.stationData];
            }
            
        });
    });
}

#pragma mark - Timer Function

-(void) refresh{
    [self fillStationDataASynchronously];
}

#pragma mark - error selector

-(void) errorGrabbingData: (NSError *) error{
    if ([self.delegate respondsToSelector:@selector(requestFailedWithError:)])
        [self.delegate requestFailedWithError:error];
}

#pragma mark - location grabbing items

-(NSDictionary *) grabNearestStationTo:(CLLocation *)location{
    
    NSDictionary * nearestStation;
    CLLocationDistance shortestDistance;
    for (NSDictionary * station in self.stationData[@"stationBeanList"]){
                
        NSString * lattitudeString = station[@"latitude"];
        NSString * longitudeString = station[@"longitude"];
        CLLocation * stationLocation = [[CLLocation alloc] initWithLatitude: lattitudeString.doubleValue longitude:longitudeString.doubleValue];        
        CLLocationDistance distance = [location distanceFromLocation:stationLocation];
        
        if (distance < shortestDistance){
            shortestDistance = distance;
            nearestStation = station;
        } else if (!shortestDistance){ // for the first run through
            shortestDistance = distance;
        }
    }
    
    NSLog(@"and our location... %@", self.locationManager.location);
    return nearestStation;
}

-(void) grabNearestStationToDevice{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    
}

-(void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    if ([self.delegate respondsToSelector:@selector(deviceLocationFoundAtLocation:)])
        [self.delegate deviceLocationFoundAtLocation:manager.location];
    
    if ([self.delegate respondsToSelector:@selector(nearestStationToDeviceFoundWithStation:)])
        [self.delegate nearestStationToDeviceFoundWithStation:[self grabNearestStationTo:manager.location]];
    
    [manager stopUpdatingLocation];
    
    NSLog(@"location manager did update location to %@", locations.lastObject);

    
}

-(void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    if ([self.delegate respondsToSelector:@selector(deviceLocationNotFoundWithError:)])
        [self.delegate deviceLocationNotFoundWithError:error];
    
    if (error.code == kCLErrorDenied)
        [manager stopUpdatingLocation];
    
}












@end
