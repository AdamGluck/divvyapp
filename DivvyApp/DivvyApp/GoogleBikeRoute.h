//
//  GoogleBikeRoute.h
//  DivvyApp
//
//  Created by Adam Gluck on 7/7/13.
//  Copyright (c) 2013 BGL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMaps/GoogleMaps.h>

@protocol GoogleBikeRouteDelegate <NSObject>

@optional
-(void) routeWithPolyline: (GMSPolyline *) polyline;
-(void) directionsFromServer: (NSDictionary *) directionsDictionary;

@end

@interface GoogleBikeRoute : NSObject

// takes an array of waypoint strings
// formatted this way:
//  NSString *positionString = [[NSString alloc] initWithFormat:@"%f,%f", coordinate.latitude,coordinate.longitude];
@property (strong, nonatomic) NSArray * waypoints;

// set to true if the app is using GPS to build the class
@property (assign, nonatomic) BOOL appDoesUseGPS;
@property (strong, nonatomic) id <GoogleBikeRouteDelegate> delegate;

-(void) go;

@end
