//
//  DivvyMapViewController.m
//  DivvyApp
//
//  Created by Andrew Beinstein on 7/7/13.
//  Copyright (c) 2013 BGL. All rights reserved.
//

#import "DivvyMapViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <GoogleMaps/GoogleMaps.h>

@interface DivvyMapViewController ()
@property (weak, nonatomic) IBOutlet UIView *mapViewContainer;

@end

@implementation DivvyMapViewController {
    GMSMapView *mapView_;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self loadMap];
}



- (void)loadMap
{
    NSLog(@"Loading map view");
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:41.8739580629 longitude:-87.6277394859 zoom:10]; // Chicago (zoomed out)
    mapView_ = [GMSMapView mapWithFrame:self.view.bounds camera:camera];
    mapView_.myLocationEnabled = YES;
    [self.mapViewContainer addSubview:mapView_];
}

// Adds a Google Maps marker at a station
- (void)addMarkerForStation:(NSDictionary *)station
{
    GMSMarker *marker = [[GMSMarker alloc] init];
    CLLocationDegrees latitude = (CLLocationDegrees)[station[@"latitude"] floatValue];
    CLLocationDegrees longitude = (CLLocationDegrees)[station[@"longitude"] floatValue];
    marker.position = CLLocationCoordinate2DMake(latitude, longitude);
    marker.title = station[@"stationName"];
    marker.map = mapView_;
}

/* Lazy Instantiation */
- (NSString *)startLocation
{
    if (!_startLocation) _startLocation = [[NSString alloc] init];
    return _startLocation;
}

- (NSString *)endLocation
{
    if (!_endLocation) _endLocation = [[NSString alloc] init];
    return _endLocation;
}


@end
