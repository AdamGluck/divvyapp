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
#import "BGLDivvyDataAccess.h"
#import "GoogleBikeRoute.h"

@interface DivvyMapViewController () <BGLDivvyDataAccessDelegate, GoogleBikeRouteDelegate>
@property (weak, nonatomic) IBOutlet UIView *mapViewContainer;
@property (strong, nonatomic) BGLDivvyDataAccess * dataAccess;

@end

@implementation DivvyMapViewController {
    GMSMapView *mapView_;
}


- (void)loadMap
{
    NSLog(@"Loading map view");
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:41.8739580629 longitude:-87.6277394859 zoom:10]; // Chicago (zoomed out)
    mapView_ = [GMSMapView mapWithFrame:CGRectMake(0, 0, 200, 200) camera:camera];
    mapView_.myLocationEnabled = YES;
    [self.mapViewContainer addSubview:mapView_];
}

- (void)addMarkerForStation:(NSDictionary *)station
{
    GMSMarker *marker = [[GMSMarker alloc] init];
    CLLocationDegrees latitude = (CLLocationDegrees)[station[@"latitude"] floatValue];
    CLLocationDegrees longitude = (CLLocationDegrees)[station[@"longitude"] floatValue];
    marker.position = CLLocationCoordinate2DMake(latitude, longitude);
    marker.title = station[@"stationName"];
    marker.map = mapView_;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.dataAccess = [[BGLDivvyDataAccess alloc] init];
    
    self.dataAccess.delegate = self;
    // for testing
    // "latitude":41.8739580629,"longitude":-87.6277394859 should be the station on State St & Harrison St
    
    [self loadMap];
    
    [self.dataAccess fillStationDataSynchronously];
    [self.dataAccess grabNearestStationToDeviceWithOption:kNearestStationAny];
}

-(void) nearestStationToDeviceFoundWithStation: (BGLStationObject *) station{
    
    NSLog(@"station found == %@", station.stationName);
    NSString *positionString1 = [[NSString alloc] initWithFormat:@"%f,%f", station.latitude,station.longitude];
    
    NSString *positionString2 = @"41.8739580629,-87.6277394859";
    
    NSArray * waypoints = @[positionString1, positionString2];
    
    GoogleBikeRoute * route = [[GoogleBikeRoute alloc] init];
    
    route.waypoints = waypoints;
    route.appDoesUseGPS = YES;
    route.delegate = self;
    [route go];
}

-(void) routeWithPolyline: (GMSPolyline *) polyline{
    polyline.map = mapView_;
}
-(void) directionsFromServer: (NSDictionary *) directionsDictionary{
    NSLog(@"directions = %@", directionsDictionary);
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
