//
//  GoogleBikeRoute.m
//  DivvyApp
//
//  Created by Adam Gluck on 7/7/13.
//  Copyright (c) 2013 BGL. All rights reserved.
//

#import "GoogleBikeRoute.h"

@interface GoogleBikeRoute (){
    BOOL _sensor;
    BOOL _alternatives;
}

@property (strong, nonatomic) NSURL * directionsURL;

@end

@implementation GoogleBikeRoute

@synthesize waypoints = _waypoints;
@synthesize directionsURL = _directionsURL;

static NSString *kMDDirectionsURL = @"http://maps.googleapis.com/maps/api/directions/json?";


#pragma mark - Lazy Instantiation

-(NSURL *) directionsURL{
    
    if (!_directionsURL){
        _directionsURL = [[NSURL alloc] init];
    }
    
    return _directionsURL;
}

-(NSArray *) waypoints{
    
    if (!_waypoints){
        _waypoints = [[NSArray alloc] init];
    }
    
    return _waypoints;
}


#pragma mark - core methods


- (void)setDirectionsQuery:(NSDictionary *)query{
    NSLog(@"query = %@", query);
    self.waypoints = [query objectForKey:@"waypoints"];
    NSString *origin = [self.waypoints objectAtIndex:0];
    int waypointCount = [self.waypoints count];
    int destinationPos = waypointCount -1;
    NSString *destination = [self.waypoints objectAtIndex:destinationPos];
    NSString *sensor = [query objectForKey:@"sensor"];
    NSMutableString *url =
    [NSMutableString stringWithFormat:@"%@&origin=%@&destination=%@&sensor=%@&mode=bicycling",
     kMDDirectionsURL,origin,destination, sensor];
    if(waypointCount>2) {
        [url appendString:@"&waypoints=optimize:true"];
        int wpCount = waypointCount-2;
        for(int i=1;i<wpCount;i++){
            [url appendString: @"|"];
            [url appendString:[self.waypoints objectAtIndex:i]];
        }
    }
    url = [[url
           stringByAddingPercentEscapesUsingEncoding: NSASCIIStringEncoding] mutableCopy];
    self.directionsURL = [NSURL URLWithString:url];
    [self retrieveDirections];
}

- (void)retrieveDirections{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSData* data =
        [NSData dataWithContentsOfURL:self.directionsURL];
        [self fetchedData:data];
    });
}

- (void)fetchedData:(NSData *)data{
    
    NSError* error;
    NSDictionary *json = [NSJSONSerialization
                          JSONObjectWithData:data
                          options:kNilOptions
                          error:&error];
    
    if ([self.delegate respondsToSelector:@selector(routeWithPolyline:)] && json){
        [self buildPolyline:json];
    }
    
    if ([self.delegate respondsToSelector:@selector(directionsFromServer:)]){
        [self.delegate directionsFromServer:json];
    }
    
}

- (void)buildPolyline:(NSDictionary *)json {
    
    if ([self.delegate respondsToSelector:@selector(routeWithPolyline:)]){
        NSDictionary *routes = [json objectForKey:@"routes"][0];
        
        NSDictionary *route = [routes objectForKey:@"overview_polyline"];
        NSString *overview_route = [route objectForKey:@"points"];
        GMSPath *path = [GMSPath pathFromEncodedPath:overview_route];
        GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
        [self.delegate routeWithPolyline:polyline];
    }
    
}

#pragma mark - Class Public Methods

-(void) go {
    
    NSString * sensor;
    
    if (self.appDoesUseGPS)
        sensor = @"true";
    else
        sensor = @"false";
    
    NSDictionary * query = @{@"sensor" : sensor, @"waypoints": self.waypoints};
    
    [self setDirectionsQuery:query];
}

@end